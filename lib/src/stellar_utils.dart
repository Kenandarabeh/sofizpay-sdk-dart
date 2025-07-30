
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'stellar_models.dart';

class StellarUtils {
  static Future<Map<String, dynamic>> sendPayment({
    required String sourceKey,
    required String destinationPublicKey,
    required double amount,
    String? memo,
  }) async {
    final startTime = DateTime.now();

    try {
      if (sourceKey.isEmpty) throw Exception('Source key is required');
      if (destinationPublicKey.isEmpty) throw Exception('Destination public key is required');
      if (amount <= 0) throw Exception('Amount must be greater than 0');

      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      final sourceKeyPair = KeyPair.fromSecretSeed(sourceKey);
      final sourcePublicKey = sourceKeyPair.accountId;

      final AccountResponse account = await sdk.accounts.account(sourcePublicKey);

      final Asset asset = Asset.createNonNativeAsset(StellarConfig.assetCode, StellarConfig.assetIssuer);

      final PaymentOperation paymentOperation = PaymentOperationBuilder(
        destinationPublicKey,
        asset,
        amount.toString(),
      ).build();

      final TransactionBuilder transactionBuilder = TransactionBuilder(account)
          .addOperation(paymentOperation);

      if (memo != null && memo.isNotEmpty) {
        if (memo.length > 28) {
          final truncatedMemo = memo.substring(0, 28);
          transactionBuilder.addMemo(Memo.text(truncatedMemo));
        } else {
          transactionBuilder.addMemo(Memo.text(memo));
        }
      }

      final Transaction transaction = transactionBuilder.build();
      
      transaction.sign(sourceKeyPair, Network.PUBLIC);

      final SubmitTransactionResponse result = await sdk.submitTransaction(transaction);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds / 1000;

      if (result.success) {
        return {
          'success': true,
          'hash': result.hash,
          'duration': duration,
        };
      } else {
        throw Exception('Transaction failed: ${result.resultXdr}');
      }
    } catch (error) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds / 1000;

      return {
        'success': false,
        'error': error.toString(),
        'duration': duration,
      };
    }
  }

  static Future<double> getBalance(String publicKey) async {
    try {
      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      final AccountResponse account = await sdk.accounts.account(publicKey);
      
      for (final Balance balance in account.balances) {
        if (balance.assetType != Asset.TYPE_NATIVE &&
            balance.assetCode == StellarConfig.assetCode &&
            balance.assetIssuer == StellarConfig.assetIssuer) {
          return double.tryParse(balance.balance) ?? 0.0;
        }
      }
      return 0.0;
    } catch (error) {
      rethrow;
    }
  }

  static String getPublicKeyFromSecret(String secretKey) {
    try {
      if (secretKey.isEmpty) throw Exception('Secret key is required.');
      
      final keyPair = KeyPair.fromSecretSeed(secretKey);
      return keyPair.accountId;
    } catch (error) {
      rethrow;
    }
  }

  static Future<List<StellarTransaction>> getTransactions(
    String publicKey, {
    int limit = 200,
  }) async {
    try {
      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      final transactions = <StellarTransaction>[];
      
      final Page<OperationResponse> payments = await sdk.payments
          .forAccount(publicKey)
          .order(RequestBuilderOrder.DESC)
          .limit(limit)
          .execute();
      
      for (final OperationResponse response in payments.records) {
        if (response is PaymentOperationResponse) {
          final PaymentOperationResponse payment = response;
          
          if (payment.assetType != Asset.TYPE_NATIVE &&
              payment.assetCode == StellarConfig.assetCode &&
              payment.assetIssuer == StellarConfig.assetIssuer) {
            
            String memoValue = '';
            try {
              final TransactionResponse txResponse = await sdk.transactions.transaction(payment.transactionHash);
              if (txResponse.memo != null) {
                final memo = txResponse.memo;
                if (memo is MemoText) {
                  memoValue = memo.text ?? '';
                } else {
                  String memoStr = memo.toString();
                  if (memoStr.contains('MemoText')) {
                    final startIndex = memoStr.indexOf("'") + 1;
                    final endIndex = memoStr.lastIndexOf("'");
                    if (startIndex > 0 && endIndex > startIndex) {
                      memoValue = memoStr.substring(startIndex, endIndex);
                    }
                  } else {
                    memoValue = memoStr;
                  }
                }
              }
            } catch (e) {
              // Ignore memo errors
            }
            
            final transaction = StellarTransaction(
              id: payment.id,
              hash: payment.transactionHash,
              memo: memoValue,
              amount: double.tryParse(payment.amount) ?? 0.0,
              status: 'completed',
              sourceAccount: payment.from,
              destination: payment.to,
              assetCode: payment.assetCode ?? '',
              assetIssuer: payment.assetIssuer ?? '',
              createdAt: DateTime.tryParse(payment.createdAt) ?? DateTime.now(),
              processedAt: DateTime.now(),
              type: payment.from == publicKey ? 'sent' : 'received',
            );
            
            transactions.add(transaction);
          }
        }
      }
      
      return transactions;
    } catch (error) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTransactionByHash(String transactionHash) async {
    if (transactionHash.isEmpty) {
      throw Exception('Transaction hash is required.');
    }

    try {
      print('Searching for transaction: $transactionHash');
      
      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      final TransactionResponse transaction = await sdk.transactions.transaction(transactionHash);
      
      final Page<OperationResponse> operations = await sdk.operations.forTransaction(transactionHash).execute();
      
      print('Transaction found: ${transaction.hash}');
      
      String memoText = '';
      if (transaction.memo != null) {
        final memo = transaction.memo;
        if (memo is MemoText) {
          memoText = memo.text ?? '';
        } else {
          String memoStr = memo.toString();
          if (memoStr.contains('MemoText')) {
            final startIndex = memoStr.indexOf("'") + 1;
            final endIndex = memoStr.lastIndexOf("'");
            if (startIndex > 0 && endIndex > startIndex) {
              memoText = memoStr.substring(startIndex, endIndex);
            }
          } else {
            memoText = memoStr;
          }
        }
      }
      
      final formattedTransaction = {
        'id': transaction.id,
        'hash': transaction.hash,
        'ledger': transaction.ledger,
        'created_at': transaction.createdAt,
        'source_account': transaction.sourceAccount,
        'source_account_sequence': transaction.sourceAccountSequence,
        'fee_charged': transaction.feeCharged,
        'operation_count': transaction.operationCount,
        'memo': memoText,
        'successful': transaction.successful,
        'paging_token': transaction.pagingToken,
        'operations': <Map<String, dynamic>>[],
      };

      for (final op in operations.records) {
        if (op is PaymentOperationResponse) {
          final operation = {
            'id': op.id,
            'type': 'payment',
            'created_at': op.createdAt,
            'transaction_hash': op.transactionHash,
            'source_account': op.sourceAccount,
            'from': op.from,
            'to': op.to,
            'amount': op.amount,
            'asset_type': op.assetType,
            'asset_code': op.assetCode,
            'asset_issuer': op.assetIssuer,
          };
          
          (formattedTransaction['operations'] as List).add(operation);
        }
      }

      final sofizPayOperations = (formattedTransaction['operations'] as List).where((op) =>
        op['type'] == 'payment' &&
        op['asset_code'] == StellarConfig.assetCode &&
        op['asset_issuer'] == StellarConfig.assetIssuer
      ).toList();

      final primaryPaymentOperation = (formattedTransaction['operations'] as List).isNotEmpty 
          ? (formattedTransaction['operations'] as List).first 
          : null;
      
      if (primaryPaymentOperation != null) {
        formattedTransaction['amount'] = primaryPaymentOperation['amount'];
        formattedTransaction['from'] = primaryPaymentOperation['from'];
        formattedTransaction['to'] = primaryPaymentOperation['to'];
        formattedTransaction['asset_code'] = primaryPaymentOperation['asset_code'];
        formattedTransaction['asset_issuer'] = primaryPaymentOperation['asset_issuer'];
        formattedTransaction['operation_type'] = primaryPaymentOperation['type'];
      }

      return {
        'success': true,
        'found': true,
        'transaction': formattedTransaction,
        'has_operations': sofizPayOperations.isNotEmpty,
        'operations_count': sofizPayOperations.length,
        'payment_operations_count': (formattedTransaction['operations'] as List).length,
        'operations': sofizPayOperations,
        'hash': transactionHash,
        'message': 'Transaction found with ${(formattedTransaction['operations'] as List).length} payment operations (${sofizPayOperations.length} payments)',
      };

    } catch (error) {
      print('Error fetching transaction by hash: $error');
      
      if (error.toString().contains('404')) {
        return {
          'success': false,
          'found': false,
          'message': 'Transaction not found on Stellar network',
          'hash': transactionHash,
          'error': 'Transaction does not exist',
        };
      }

      return {
        'success': false,
        'found': false,
        'message': 'Error while searching for transaction',
        'hash': transactionHash,
        'error': error.toString(),
      };
    }
  }
}


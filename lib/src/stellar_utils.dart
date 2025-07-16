import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'stellar_models.dart';

class StellarUtils {
  static Future<Map<String, dynamic>> sendPayment({
    required String sourceKey,
    required String destinationPublicKey,
    required double amount,
    String assetCode = 'DZT',
    String assetIssuer = 'GCAZI7YBLIDJWIVEL7ETNAZGPP3LC24NO6KAOBWZHUERXQ7M5BC52DLV',
    String? memo,
  }) async {
    print('Starting transaction...');
    final startTime = DateTime.now();

    try {
      if (sourceKey.isEmpty) {
        throw Exception('Source secret key is required and cannot be empty.');
      }
      if (!sourceKey.startsWith('S') || sourceKey.length != 56) {
        throw Exception('Invalid source secret key format. Secret keys must start with "S" and be 56 characters long.');
      }
      if (destinationPublicKey.isEmpty) {
        throw Exception('Destination public key is required and cannot be empty.');
      }
      if (!destinationPublicKey.startsWith('G') || destinationPublicKey.length != 56) {
        throw Exception('Invalid destination public key format. Public keys must start with "G" and be 56 characters long.');
      }
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0.');
      }
      if (amount > 1000000) {
        throw Exception('Amount is too large. Maximum amount is 1,000,000 DZT.');
      }

      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      final sourceKeyPair = KeyPair.fromSecretSeed(sourceKey);
      final sourcePublicKey = sourceKeyPair.accountId;
      print('Source public key: $sourcePublicKey');

      print('Loading account from Stellar network...');
      final AccountResponse account = await sdk.accounts.account(sourcePublicKey);
      print('Account loaded, sequence: ${account.sequenceNumber}');

      final Asset asset = Asset.createNonNativeAsset(assetCode, assetIssuer);

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
          print('Memo too long (${memo.length} chars), truncated to: $truncatedMemo');
          transactionBuilder.addMemo(Memo.text(truncatedMemo));
        } else {
          print('Adding memo: $memo');
          transactionBuilder.addMemo(Memo.text(memo));
        }
      }

      final Transaction transaction = transactionBuilder.build();
      print('Transaction built, signing...');
      
      transaction.sign(sourceKeyPair, Network.PUBLIC);
      print('Transaction signed');

      print('Submitting transaction to Stellar network...');
      
      final SubmitTransactionResponse result = await sdk.submitTransaction(transaction);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds / 1000;
      print('Transaction completed in ${duration}s');

      if (result.success) {
        print('Transaction successful: ${result.hash}');
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
      
      String friendlyError = error.toString();
      
      if (friendlyError.contains('404')) {
        friendlyError = 'Account not found on Stellar network. Make sure the source account exists and is funded.';
      } else if (friendlyError.contains('Checksum invalid')) {
        friendlyError = 'Invalid key format. Please check your secret key or destination public key.';
      } else if (friendlyError.contains('timeout')) {
        friendlyError = 'Network timeout. Please check your internet connection and try again.';
      } else if (friendlyError.contains('insufficient balance')) {
        friendlyError = 'Insufficient balance. Please make sure you have enough DZT tokens and XLM for fees.';
      } else if (friendlyError.contains('no_trust')) {
        friendlyError = 'Destination account does not trust the DZT asset. The recipient needs to add a trustline for DZT token.';
      }
      
      print('Transaction failed: $friendlyError');

      return {
        'success': false,
        'error': friendlyError,
        'duration': duration,
      };
    }
  }

  static Future<double> getDZTBalance(String publicKey) async {
    try {
      if (publicKey.isEmpty) {
        throw Exception('Public key is required and cannot be empty.');
      }
      
      if (!publicKey.startsWith('G')) {
        throw Exception('Invalid public key format. Public keys must start with "G".');
      }
      
      if (publicKey.length != 56) {
        throw Exception('Invalid public key length. Public keys must be exactly 56 characters long.');
      }
      
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
      if (error.toString().contains('404')) {
        throw Exception('Account not found on Stellar network. Make sure the account exists and is funded.');
      } else if (error.toString().contains('Checksum invalid')) {
        throw Exception('Invalid public key format. Please check your public key.');
      } else if (error.toString().contains('timeout')) {
        throw Exception('Network timeout. Please check your internet connection and try again.');
      }
      
      print('Error fetching DZT balance: $error');
      rethrow;
    }
  }

  static String getPublicKeyFromSecret(String secretKey) {
    try {
      if (secretKey.isEmpty) {
        throw Exception('Secret key is required and cannot be empty.');
      }
      
      if (!secretKey.startsWith('S')) {
        throw Exception('Invalid secret key format. Secret keys must start with "S".');
      }
      
      if (secretKey.length != 56) {
        throw Exception('Invalid secret key length. Secret keys must be exactly 56 characters long.');
      }
      
      final keyPair = KeyPair.fromSecretSeed(secretKey);
      return keyPair.accountId;
    } catch (error) {
      if (error.toString().contains('Checksum invalid')) {
        throw Exception('Invalid secret key format. Please check your secret key and try again.');
      } else if (error.toString().contains('Invalid character')) {
        throw Exception('Secret key contains invalid characters. Only base32 characters are allowed.');
      }
      
      print('Error extracting public key from secret: $error');
      rethrow;
    }
  }

  static Future<List<StellarTransaction>> getDZTTransactions(
    String publicKey, {
    int limit = 200,
  }) async {
    try {
      if (!isValidPublicKey(publicKey)) {
        throw Exception('Invalid public key format. Public keys must start with "G" and be 56 characters long.');
      }
      
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
              print('Could not fetch memo for transaction ${payment.transactionHash}: $e');
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
      if (error.toString().contains('404')) {
        throw Exception('Account not found on Stellar network. Make sure the account exists and is funded.');
      } else if (error.toString().contains('Checksum invalid')) {
        throw Exception('Invalid public key format. Please check your public key.');
      } else if (error.toString().contains('timeout')) {
        throw Exception('Network timeout. Please check your internet connection and try again.');
      }
      
      print('Error fetching DZT transactions: $error');
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

      final dztOperations = (formattedTransaction['operations'] as List).where((op) =>
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
        'has_dzt_operations': dztOperations.isNotEmpty,
        'dzt_operations_count': dztOperations.length,
        'payment_operations_count': (formattedTransaction['operations'] as List).length,
        'dzt_operations': dztOperations,
        'hash': transactionHash,
        'message': 'Transaction found with ${(formattedTransaction['operations'] as List).length} payment operations (${dztOperations.length} DZT payments)',
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

  static StreamController<StellarTransaction>? _streamController;
  static Timer? _pollingTimer;
  static Set<String> _processedTransactionIds = {};
  static bool _isFirstRun = true;

  static Stream<StellarTransaction> setupTransactionStream(
    String publicKey, {
    Duration pollingInterval = const Duration(seconds: 5),
  }) {
    _streamController?.close();
    _pollingTimer?.cancel();
    
    _streamController = StreamController<StellarTransaction>.broadcast();
    _processedTransactionIds.clear();
    _isFirstRun = true;
    
    print('🔄 Setting up stream for new transactions only...');
    
    _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
      try {
        final transactions = await getDZTTransactions(publicKey, limit: 20);
        
        if (_isFirstRun) {
          for (final transaction in transactions) {
            _processedTransactionIds.add(transaction.id);
          }
          _isFirstRun = false;
          print('✅ Stream initialized. Monitoring for new transactions...');
        } else {
          for (final transaction in transactions) {
            if (!_processedTransactionIds.contains(transaction.id)) {
              print('🆕 New transaction detected: ${transaction.id}');
              _processedTransactionIds.add(transaction.id);
              _streamController!.add(transaction);
            }
          }
        }
      } catch (error) {
        print('Error in transaction stream: $error');
        _streamController!.addError(error);
      }
    });
    
    return _streamController!.stream;
  }

  static void closeTransactionStream() {
    _pollingTimer?.cancel();
    _streamController?.close();
    _streamController = null;
    _pollingTimer = null;
    _processedTransactionIds.clear();
    _isFirstRun = true;
    print('🛑 Transaction stream closed');
  }

  static Map<String, String> generateTestKeyPair() {
    try {
      final keyPair = KeyPair.random();
      return {
        'secretKey': keyPair.secretSeed,
        'publicKey': keyPair.accountId,
      };
    } catch (error) {
      throw Exception('Failed to generate key pair: $error');
    }
  }

  static bool isValidSecretKey(String secretKey) {
    try {
      if (secretKey.isEmpty) return false;
      if (!secretKey.startsWith('S')) return false;
      if (secretKey.length != 56) return false;
      
      KeyPair.fromSecretSeed(secretKey);
      return true;
    } catch (error) {
      return false;
    }
  }

  static bool isValidPublicKey(String publicKey) {
    try {
      if (publicKey.isEmpty) return false;
      if (!publicKey.startsWith('G')) return false;
      if (publicKey.length != 56) return false;
      
      KeyPair.fromAccountId(publicKey);
      return true;
    } catch (error) {
      return false;
    }
  }

  static Future<bool> accountExists(String publicKey) async {
    try {
      if (!isValidPublicKey(publicKey)) return false;
      
      final StellarSDK sdk = StellarSDK.PUBLIC;
      await sdk.accounts.account(publicKey);
      return true;
    } catch (error) {
      return false;
    }
  }
}


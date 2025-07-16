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
      // Validate inputs
      if (sourceKey.isEmpty) throw Exception('Source key is required');
      if (destinationPublicKey.isEmpty) throw Exception('Destination public key is required');
      if (amount <= 0) throw Exception('Amount must be greater than 0');

      // Create SDK instance
      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      // Create key pair from secret key
      final sourceKeyPair = KeyPair.fromSecretSeed(sourceKey);
      final sourcePublicKey = sourceKeyPair.accountId;
      print('Source public key: $sourcePublicKey');

      // Load account from Stellar network
      final AccountResponse account = await sdk.accounts.account(sourcePublicKey);
      print('Account loaded, sequence: ${account.sequenceNumber}');

      // Create custom asset
      final Asset asset = Asset.createNonNativeAsset(assetCode, assetIssuer);

      // Build payment operation
      final PaymentOperation paymentOperation = PaymentOperationBuilder(
        destinationPublicKey,
        asset,
        amount.toString(),
      ).build();

      // Build transaction
      final TransactionBuilder transactionBuilder = TransactionBuilder(account)
          .addOperation(paymentOperation);

      // Add memo if provided
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
      
      // Sign transaction
      transaction.sign(sourceKeyPair, Network.PUBLIC);
      print('Transaction signed');

      print('Submitting transaction...');
      
      // Submit transaction
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
      print('Transaction failed: $error');
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds / 1000;

      return {
        'success': false,
        'error': error.toString(),
        'duration': duration,
      };
    }
  }

  static Future<double> getDZTBalance(String publicKey) async {
    try {
      // Create SDK instance
      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      // Load account from Stellar network
      final AccountResponse account = await sdk.accounts.account(publicKey);
      
      // Find DZT balance
      for (final Balance balance in account.balances) {
        if (balance.assetType != Asset.TYPE_NATIVE &&
            balance.assetCode == StellarConfig.assetCode &&
            balance.assetIssuer == StellarConfig.assetIssuer) {
          return double.tryParse(balance.balance) ?? 0.0;
        }
      }
      return 0.0;
    } catch (error) {
      print('Error fetching DZT balance: $error');
      rethrow;
    }
  }

  static String getPublicKeyFromSecret(String secretKey) {
    try {
      if (secretKey.isEmpty) throw Exception('Secret key is required.');
      
      // Use the real Stellar SDK to extract public key from secret key
      final keyPair = KeyPair.fromSecretSeed(secretKey);
      return keyPair.accountId;
    } catch (error) {
      print('Error extracting public key from secret: $error');
      rethrow;
    }
  }

  static Future<List<StellarTransaction>> getDZTTransactions(
    String publicKey, {
    int limit = 200,
  }) async {
    try {
      // Create SDK instance
      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      final transactions = <StellarTransaction>[];
      
      // Get payments for the account
      final Page<OperationResponse> payments = await sdk.payments
          .forAccount(publicKey)
          .order(RequestBuilderOrder.DESC)
          .limit(limit)
          .execute();
      
      for (final OperationResponse response in payments.records) {
        if (response is PaymentOperationResponse) {
          final PaymentOperationResponse payment = response;
          
          // Check if it's a DZT payment
          if (payment.assetType != Asset.TYPE_NATIVE &&
              payment.assetCode == StellarConfig.assetCode &&
              payment.assetIssuer == StellarConfig.assetIssuer) {
            
            // Get transaction details to get memo
            String memoValue = '';
            try {
              final TransactionResponse txResponse = await sdk.transactions.transaction(payment.transactionHash);
              if (txResponse.memo != null) {
                final memo = txResponse.memo;
                if (memo is MemoText) {
                  memoValue = memo.text ?? '';
                } else {
                  // For other memo types, extract the value using toString and clean it up
                  String memoStr = memo.toString();
                  if (memoStr.contains('MemoText')) {
                    // Extract text from MemoText string representation
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
      
      // Create SDK instance
      final StellarSDK sdk = StellarSDK.PUBLIC;
      
      // Get transaction by hash
      final TransactionResponse transaction = await sdk.transactions.transaction(transactionHash);
      
      // Get operations for this transaction
      final Page<OperationResponse> operations = await sdk.operations.forTransaction(transactionHash).execute();
      
      print('Transaction found: ${transaction.hash}');
      
      // Extract memo text properly
      String memoText = '';
      if (transaction.memo != null) {
        final memo = transaction.memo;
        if (memo is MemoText) {
          memoText = memo.text ?? '';
        } else {
          // For other memo types, extract the value using toString and clean it up
          String memoStr = memo.toString();
          if (memoStr.contains('MemoText')) {
            // Extract text from MemoText string representation
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
}


import 'dart:async';
import 'stellar_models.dart';
import 'stellar_utils.dart';

class SofizPayResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String timestamp;

  SofizPayResponse({
    required this.success,
    this.data,
    this.error,
  }) : timestamp = DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
      'timestamp': timestamp,
    };
  }
}

class SofizPayTransactionResponse {
  final bool success;
  final String? transactionId;
  final String? transactionHash;
  final double? amount;
  final String? memo;
  final String? destinationPublicKey;
  final double? duration;
  final String? error;
  final String timestamp;

  SofizPayTransactionResponse({
    required this.success,
    this.transactionId,
    this.transactionHash,
    this.amount,
    this.memo,
    this.destinationPublicKey,
    this.duration,
    this.error,
  }) : timestamp = DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'transactionHash': transactionHash,
      'amount': amount,
      'memo': memo,
      'destinationPublicKey': destinationPublicKey,
      'duration': duration,
      'error': error,
      'timestamp': timestamp,
    };
  }
}

class SofizPaySDK {
  static const String version = '1.0.0';
  
  final Map<String, Map<String, dynamic>> _activeStreams = {};
  final Map<String, Function(StellarTransaction)> _transactionCallbacks = {};

  Future<SofizPayTransactionResponse> submit({
    required String secretkey,
    required String destinationPublicKey,
    required double amount,
    required String memo,
    String assetCode = 'DZT',
    String assetIssuer = 'GCAZI7YBLIDJWIVEL7ETNAZGPP3LC24NO6KAOBWZHUERXQ7M5BC52DLV',
  }) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }
      if (destinationPublicKey.isEmpty) {
        throw Exception('Destination public key is required.');
      }
      if (amount <= 0) {
        throw Exception('Valid amount is required.');
      }
      if (memo.isEmpty) {
        throw Exception('Memo is required.');
      }

      final result = await StellarUtils.sendPayment(
        sourceKey: secretkey,
        destinationPublicKey: destinationPublicKey,
        amount: amount,
        assetCode: assetCode,
        assetIssuer: assetIssuer,
        memo: memo,
      );

      if (result['success'] == true) {
        return SofizPayTransactionResponse(
          success: true,
          transactionId: result['hash'],
          transactionHash: result['hash'],
          amount: amount,
          memo: memo,
          destinationPublicKey: destinationPublicKey,
          duration: result['duration'],
        );
      } else {
        throw Exception(result['error'] ?? 'Transaction failed');
      }
    } catch (error) {
      return SofizPayTransactionResponse(
        success: false,
        error: error.toString(),
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> getTransactions(
    String secretkey, {
    int limit = 50,
  }) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }

      final publicKey = StellarUtils.getPublicKeyFromSecret(secretkey);
      final dztTransactions = await StellarUtils.getDZTTransactions(
        publicKey,
        limit: limit,
      );

      final formattedTransactions = dztTransactions.map((tx) => {
        'id': tx.hash,
        'transactionId': tx.hash,
        'hash': tx.hash,
        'amount': tx.amount,
        'memo': tx.memo,
        'type': tx.type,
        'from': tx.sourceAccount,
        'to': tx.destination,
        'asset_code': tx.assetCode,
        'asset_issuer': tx.assetIssuer,
        'status': 'completed',
        'timestamp': tx.createdAt.toIso8601String(),
        'created_at': tx.createdAt.toIso8601String(),
      }).toList();

      return SofizPayResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'transactions': formattedTransactions,
          'total': formattedTransactions.length,
          'publicKey': publicKey,
            'message': 'All transactions fetched (${formattedTransactions.length} transactions)',

        },
      );
    } catch (error) {
      print('Error fetching transactions: $error');
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
        data: {'transactions': []},
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> getDZTBalance(String secretkey) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }

      final publicKey = StellarUtils.getPublicKeyFromSecret(secretkey);
      final balance = await StellarUtils.getDZTBalance(publicKey);

      return SofizPayResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'balance': balance,
          'publicKey': publicKey,
          'asset_code': 'DZT',
          'asset_issuer': 'GCAZI7YBLIDJWIVEL7ETNAZGPP3LC24NO6KAOBWZHUERXQ7M5BC52DLV',
        },
      );
    } catch (error) {
      print('Error fetching DZT balance: $error');
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
        data: {'balance': 0},
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> getPublicKey(String secretkey) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }

      final publicKey = StellarUtils.getPublicKeyFromSecret(secretkey);

      return SofizPayResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'publicKey': publicKey,
          'secretKey': secretkey,
        },
      );
    } catch (error) {
      print('Error extracting public key: $error');
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
        data: {'publicKey': null},
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> startTransactionStream(
    String secretkey,
    Function(Map<String, dynamic>) onNewTransaction,
  ) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }

      final publicKey = StellarUtils.getPublicKeyFromSecret(secretkey);

      if (_activeStreams.containsKey(publicKey)) {
        return SofizPayResponse<Map<String, dynamic>>(
          success: false,
          error: 'Transaction stream already active for this account',
          data: {'publicKey': publicKey},
        );
      }

      void transactionHandler(StellarTransaction newTransaction) {
        final formattedTransaction = {
          'id': newTransaction.id,
          'transactionId': newTransaction.id,
          'hash': newTransaction.hash,
          'amount': newTransaction.amount,
          'memo': newTransaction.memo,
          'type': newTransaction.destination == publicKey ? 'received' : 'sent',
          'from': newTransaction.sourceAccount,
          'to': newTransaction.destination,
          'asset_code': newTransaction.assetCode,
          'asset_issuer': newTransaction.assetIssuer,
          'status': newTransaction.status,
          'timestamp': newTransaction.createdAt.toIso8601String(),
          'created_at': newTransaction.createdAt.toIso8601String(),
          'processed_at': newTransaction.processedAt.toIso8601String(),
        };

        onNewTransaction(formattedTransaction);
      }

      final stream = StellarUtils.setupTransactionStream(publicKey);
      final subscription = stream.listen(transactionHandler);

      _activeStreams[publicKey] = {
        'secretkey': secretkey,
        'startTime': DateTime.now().toIso8601String(),
        'isActive': true,
        'subscription': subscription,
      };

      _transactionCallbacks[publicKey] = transactionHandler;

      return SofizPayResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'message': 'Transaction stream started successfully',
          'publicKey': publicKey,
        },
      );
    } catch (error) {
      print('Error starting transaction stream: $error');
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> stopTransactionStream(String secretkey) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }

      final publicKey = StellarUtils.getPublicKeyFromSecret(secretkey);

      if (!_activeStreams.containsKey(publicKey)) {
        return SofizPayResponse<Map<String, dynamic>>(
          success: false,
          error: 'No active transaction stream found for this account',
          data: {'publicKey': publicKey},
        );
      }

      final streamInfo = _activeStreams[publicKey];
      final subscription = streamInfo?['subscription'] as StreamSubscription?;
      await subscription?.cancel();

      _activeStreams.remove(publicKey);
      _transactionCallbacks.remove(publicKey);
      StellarUtils.closeTransactionStream();

      return SofizPayResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'message': 'Transaction stream stopped successfully',
          'publicKey': publicKey,
        },
      );
    } catch (error) {
      print('Error stopping transaction stream: $error');
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> getStreamStatus(String secretkey) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }

      final publicKey = StellarUtils.getPublicKeyFromSecret(secretkey);
      final streamInfo = _activeStreams[publicKey];

      return SofizPayResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'isActive': streamInfo != null,
          'publicKey': publicKey,
          'streamInfo': streamInfo,
        },
      );
    } catch (error) {
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
        data: {'isActive': false},
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> searchTransactionsByMemo(
    String secretkey,
    String memo, {
    int limit = 50,
  }) async {
    try {
      if (secretkey.isEmpty) {
        throw Exception('Secret key is required.');
      }
      if (memo.isEmpty) {
        throw Exception('Memo is required for search.');
      }

      final publicKey = StellarUtils.getPublicKeyFromSecret(secretkey);
      final dztTransactions = await StellarUtils.getDZTTransactions(publicKey, limit: 200);

      final filteredTransactions = dztTransactions.where((tx) {
        return tx.memo.toLowerCase().contains(memo.toLowerCase());
      }).take(limit).toList();

      final formattedTransactions = filteredTransactions.map((tx) => {
        'id': tx.hash,
        'transactionId': tx.hash,
        'hash': tx.hash,
        'amount': tx.amount,
        'memo': tx.memo,
        'type': tx.type,
        'from': tx.sourceAccount,
        'to': tx.destination,
        'asset_code': tx.assetCode,
        'asset_issuer': tx.assetIssuer,
        'status': 'completed',
        'timestamp': tx.createdAt.toIso8601String(),
        'created_at': tx.createdAt.toIso8601String(),
      }).toList();

      return SofizPayResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'transactions': formattedTransactions,
          'total': formattedTransactions.length,
          'totalFound': filteredTransactions.length,
          'searchMemo': memo,
          'publicKey': publicKey,
            'message': '${filteredTransactions.length} transactions found containing "$memo"',
        },
      );
    } catch (error) {
      print('Error searching transactions by memo: $error');
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
        data: {
          'transactions': [],
          'searchMemo': memo,
        },
      );
    }
  }

  Future<SofizPayResponse<Map<String, dynamic>>> getTransactionByHash(String transactionHash) async {
    try {
      if (transactionHash.isEmpty) {
        throw Exception('Transaction hash is required.');
      }

      final result = await StellarUtils.getTransactionByHash(transactionHash);

      if (result['success'] == true && result['found'] == true) {
        return SofizPayResponse<Map<String, dynamic>>(
          success: true,
          data: {
            'found': true,
            'transaction': result['transaction'],
            'has_dzt_operations': result['has_dzt_operations'],
            'dzt_operations_count': result['dzt_operations_count'],
            'dzt_operations': result['dzt_operations'],
            'hash': transactionHash,
            'message': result['message'],
          },
        );
      } else {
        return SofizPayResponse<Map<String, dynamic>>(
          success: true,
          data: {
            'found': false,
            'transaction': null,
            'hash': transactionHash,
            'message': result['message'] ?? 'Transaction not found',
            'error': result['error'],
          },
        );
      }
    } catch (error) {
      print('Error searching for transaction by hash: $error');
      return SofizPayResponse<Map<String, dynamic>>(
        success: false,
        error: error.toString(),
        data: {
          'found': false,
          'transaction': null,
          'hash': transactionHash,
        },
      );
    }
  }

  String getVersion() {
    return version;
  }

  void dispose() {
    for (final streamInfo in _activeStreams.values) {
      final subscription = streamInfo['subscription'] as StreamSubscription?;
      subscription?.cancel();
    }
    _activeStreams.clear();
    _transactionCallbacks.clear();
    StellarUtils.closeTransactionStream();
  }
}

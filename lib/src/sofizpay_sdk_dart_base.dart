import 'dart:async';
import 'stellar_models.dart';
import 'stellar_utils.dart';

class SofizPayTransactionResponse {
  final bool success;
  final String? transactionHash;
  final double? amount;
  final String? memo;
  final String? destinationPublicKey;
  final double? duration;
  final String? error;
  final String timestamp;

  SofizPayTransactionResponse({
    required this.success,
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
  static const String version = '1.1.1';
  
  final Map<String, Map<String, dynamic>> _activeStreams = {};
  final Map<String, Function(StellarTransaction)> _transactionCallbacks = {};
  final Map<String, Timer> _pollingTimers = {};
  final Map<String, Set<String>> _seenTransactionHashes = {};

  Future<SofizPayTransactionResponse> submit({
    required String secretkey,
    required String destinationPublicKey,
    required double amount,
    required String memo,
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
        memo: memo,
      );

      if (result['success'] == true) {
        return SofizPayTransactionResponse(
          success: true,
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

  Future<Map<String, dynamic>> getTransactions(
    String publicKey, {
    int limit = 50,
  }) async {
    if (publicKey.isEmpty) {
      throw Exception('Public key is required.');
    }

    final transactions = await StellarUtils.getTransactions(
      publicKey,
      limit: limit,
    );

    final formattedTransactions = transactions.map((tx) => {
      'id': tx.hash,
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

    return {
      'transactions': formattedTransactions,
      'total': formattedTransactions.length,
      'publicKey': publicKey,
      'message': 'All transactions fetched (${formattedTransactions.length} transactions)',
    };
  }

  Future<Map<String, dynamic>> getBalance(String publicKey) async {
    if (publicKey.isEmpty) {
      throw Exception('Public key is required.');
    }

    final balance = await StellarUtils.getBalance(publicKey);

    return {
      'balance': balance,
      'publicKey': publicKey,
      'asset_code': StellarConfig.assetCode,
      'asset_issuer': StellarConfig.assetIssuer,
    };
  }

  String getPublicKey(String secretkey) {
    if (secretkey.isEmpty) {
      throw Exception('Secret key is required.');
    }

    return StellarUtils.getPublicKeyFromSecret(secretkey);
  }


  Future<Map<String, dynamic>> searchTransactionsByMemo(
    String publicKey,
    String memo, {
    int limit = 50,
  }) async {
    if (publicKey.isEmpty) {
      throw Exception('Public key is required.');
    }
    if (memo.isEmpty) {
      throw Exception('Memo is required for search.');
    }

    final transactions = await StellarUtils.getTransactions(publicKey, limit: 200);

    final filteredTransactions = transactions.where((tx) {
      return tx.memo.toLowerCase().contains(memo.toLowerCase());
    }).take(limit).toList();

    final formattedTransactions = filteredTransactions.map((tx) => {
      'id': tx.hash,
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

    return {
      'transactions': formattedTransactions,
      'total': formattedTransactions.length,
      'totalFound': filteredTransactions.length,
      'searchMemo': memo,
      'publicKey': publicKey,
      'message': '${filteredTransactions.length} transactions found containing "$memo"',
    };
  }

  Future<Map<String, dynamic>> getTransactionByHash(String transactionHash) async {
    if (transactionHash.isEmpty) {
      throw Exception('Transaction hash is required.');
    }

    final result = await StellarUtils.getTransactionByHash(transactionHash);

    if (result['success'] == true && result['found'] == true) {
      return {
        'found': true,
        'transaction': result['transaction'],
        'has_operations': result['has_operations'],
        'operations_count': result['operations_count'],
        'operations': result['operations'],
        'hash': transactionHash,
        'message': result['message'],
      };
    } else {
      return {
        'found': false,
        'transaction': null,
        'hash': transactionHash,
        'message': result['message'] ?? 'Transaction not found',
        'error': result['error'],
      };
    }
  }

  Future<Map<String, dynamic>> makeCIBTransaction(Map<String, dynamic> transactionData) async {
    if (!transactionData.containsKey('account') || transactionData['account'] == null || transactionData['account'].toString().isEmpty) {
      throw Exception('Account is required.');
    }
    if (!transactionData.containsKey('amount') || transactionData['amount'] == null || double.tryParse(transactionData['amount'].toString()) == null || double.parse(transactionData['amount'].toString()) <= 0) {
      throw Exception('Valid amount is required.');
    }
    if (!transactionData.containsKey('full_name') || transactionData['full_name'] == null || transactionData['full_name'].toString().isEmpty) {
      throw Exception('Full name is required.');
    }
    if (!transactionData.containsKey('phone') || transactionData['phone'] == null || transactionData['phone'].toString().isEmpty) {
      throw Exception('Phone number is required.');
    }
    if (!transactionData.containsKey('email') || transactionData['email'] == null || transactionData['email'].toString().isEmpty) {
      throw Exception('Email is required.');
    }

    const String baseUrl = 'https://www.sofizpay.com/make-cib-transaction/';
    
    List<String> queryParams = [];
    queryParams.add('account=${transactionData['account']}');
    queryParams.add('amount=${transactionData['amount']}');
    queryParams.add('full_name=${transactionData['full_name']}');
    queryParams.add('phone=${transactionData['phone']}');
    queryParams.add('email=${transactionData['email']}');
    
    if (transactionData.containsKey('return_url') && transactionData['return_url'] != null) {
      queryParams.add('return_url=${transactionData['return_url']}');
    }
    if (transactionData.containsKey('memo') && transactionData['memo'] != null) {
      final safeMemo = Uri.encodeComponent(transactionData['memo'].toString());
      queryParams.add('memo=$safeMemo');
    }
    if (transactionData.containsKey('redirect')) {
      queryParams.add('redirect=no');
    }

    final String fullUrl = '$baseUrl?${queryParams.join('&')}';
    
    final response = await HttpUtil.fetchWithRetry(fullUrl);

    return {
      'data': response,
      'url': fullUrl,
      'request_data': {
        'account': transactionData['account'],
        'amount': transactionData['amount'],
        'full_name': transactionData['full_name'],
        'phone': transactionData['phone'],
        'email': transactionData['email'],
        'return_url': transactionData['return_url'],
        'memo': transactionData['memo'],
        'redirect': 'no',
      },
    };
  }

  String getVersion() {
    return version;
  }

  void dispose() {
    // إيقاف جميع timers
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    
    // تنظيف جميع البيانات
    _pollingTimers.clear();
    _activeStreams.clear();
    _transactionCallbacks.clear();
    _seenTransactionHashes.clear();
  }
}

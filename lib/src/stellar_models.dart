import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StellarConfig {
  static const String horizonUrl = 'https://horizon.stellar.org';
  static const String assetCode = 'DZT';
  static const String assetIssuer = 'GCAZI7YBLIDJWIVEL7ETNAZGPP3LC24NO6KAOBWZHUERXQ7M5BC52DLV';
  static const String networkPassphrase = 'Public Global Stellar Network ; September 2015';
}

class StellarTransaction {
  final String id;
  final String hash;
  final String memo;
  final double amount;
  final String status;
  final String sourceAccount;
  final String destination;
  final String assetCode;
  final String assetIssuer;
  final DateTime createdAt;
  final DateTime processedAt;
  final String type;

  StellarTransaction({
    required this.id,
    required this.hash,
    required this.memo,
    required this.amount,
    required this.status,
    required this.sourceAccount,
    required this.destination,
    required this.assetCode,
    required this.assetIssuer,
    required this.createdAt,
    required this.processedAt,
    required this.type,
  });

  factory StellarTransaction.fromJson(Map<String, dynamic> json) {
    return StellarTransaction(
      id: json['id'] ?? '',
      hash: json['hash'] ?? '',
      memo: json['memo'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'unknown',
      sourceAccount: json['source_account'] ?? '',
      destination: json['destination'] ?? json['to'] ?? '',
      assetCode: json['asset_code'] ?? '',
      assetIssuer: json['asset_issuer'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      processedAt: DateTime.tryParse(json['processed_at'] ?? '') ?? DateTime.now(),
      type: json['type'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hash': hash,
      'memo': memo,
      'amount': amount,
      'status': status,
      'source_account': sourceAccount,
      'destination': destination,
      'asset_code': assetCode,
      'asset_issuer': assetIssuer,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt.toIso8601String(),
      'type': type,
    };
  }
}

class HttpUtil {
  static Future<Map<String, dynamic>> fetchWithRetry(
    String url, {
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 429 && i < retries - 1) {
          print('Rate limited, retrying... (${i + 1}/$retries)');
          await Future.delayed(delay);
          continue;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (error) {
        if (i == retries - 1) rethrow;
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  static Future<Map<String, dynamic>> postWithRetry(
    String url,
    Map<String, dynamic> body, {
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return json.decode(response.body);
        } else if (response.statusCode == 429 && i < retries - 1) {
          print('Rate limited, retrying... (${i + 1}/$retries)');
          await Future.delayed(delay);
          continue;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (error) {
        if (i == retries - 1) rethrow;
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }
}

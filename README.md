<div align="center">
  <img src="https://github.com/kenandarabeh/sofizpay-sdk/blob/main/assets/sofizpay-logo.png?raw=true" alt="SofizPay Logo" width="200" />
</div>

# SofizPay SDK Dart

**The official Dart SDK for secure digital payments and transactions.**

[![pub package](https://img.shields.io/pub/v/sofizpay_sdk_dart.svg)](https://pub.dev/packages/sofizpay_sdk_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  sofizpay_sdk_dart: ^1.1.1
```

Then run:

```bash
dart pub get
```
 
### Basic Usage

```dart
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

void main() async {
  final sdk = SofizPaySDK();

  // Send payment
  final result = await sdk.submit(
    secretkey: 'YOUR_SECRET_KEY',
    destinationPublicKey: 'RECIPIENT_PUBLIC_KEY',
    amount: 100.0,
    memo: 'Payment description',
  );

  print(result.success ? 'Payment sent!' : result.error);
}
```

## Features

- ✅ **Send Secure Payments** - Instant digital transactions
- ✅ **Get Account Balance** - Real-time balance checking
- ✅ **Transaction History** - Complete transaction records
- ✅ **Search & Filter** - Find transactions by memo or hash
- ✅ **Bank Integration** - CIB transaction support
- ✅ **Multi-platform** - Works on Flutter, Dart VM, and Web
- ✅ **Type Safety** - Full Dart type safety and null safety

## Usage Examples

### Flutter App

```dart
import 'package:flutter/material.dart';
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final SofizPaySDK sdk = SofizPaySDK();
  double balance = 0.0;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  Future<void> loadBalance() async {
    setState(() => loading = true);
    
    try {
      final result = await sdk.getBalance('YOUR_PUBLIC_KEY');
      setState(() {
        balance = result['balance'] ?? 0.0;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading balance: $e')),
      );
    }
  }

  Future<void> sendPayment() async {
    final result = await sdk.submit(
      secretkey: 'YOUR_SECRET_KEY',
      destinationPublicKey: 'RECIPIENT_KEY',
      amount: 25.0,
      memo: 'Flutter payment',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'Payment sent!' : result.error ?? 'Failed'),
      ),
    );

    if (result.success) {
      loadBalance(); // Refresh balance
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SofizPay Wallet')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Balance'),
                subtitle: loading 
                  ? Text('Loading...') 
                  : Text('${balance.toStringAsFixed(2)} DZT'),
                trailing: IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: loadBalance,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendPayment,
              child: Text('Send Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Dart Console Application

```dart
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

void main() async {
  final sdk = SofizPaySDK();

  print('SofizPay SDK Dart v${sdk.getVersion()}');

  try {
    // Check balance
    final balanceResult = await sdk.getBalance('YOUR_PUBLIC_KEY');
    print('Current balance: ${balanceResult['balance']}');

    // Send payment
    final paymentResult = await sdk.submit(
      secretkey: 'YOUR_SECRET_KEY',
      destinationPublicKey: 'RECIPIENT_KEY',
      amount: 100.0,
      memo: 'Console payment',
    );

    if (paymentResult.success) {
      print('Payment sent successfully!');
      print('Transaction Hash: ${paymentResult.transactionHash}');
      print('Duration: ${paymentResult.duration}s');
    } else {
      print('Payment failed: ${paymentResult.error}');
    }

    // Get transaction history
    final historyResult = await sdk.getTransactions('YOUR_PUBLIC_KEY', limit: 10);
    print('Recent transactions: ${historyResult['total']}');
    
  } catch (e) {
    print('Error: $e');
  }
}
```

## API Reference

### Core Methods

| Method | Description | Return Type |
|--------|-------------|-------------|
| `submit()` | Send secure payment | `Future<SofizPayTransactionResponse>` |
| `getBalance()` | Get account balance | `Future<Map<String, dynamic>>` |
| `getTransactions()` | Get transaction history | `Future<Map<String, dynamic>>` |
| `getTransactionByHash()` | Find transaction by hash | `Future<Map<String, dynamic>>` |
| `searchTransactionsByMemo()` | Search by memo | `Future<Map<String, dynamic>>` |
| `getPublicKey()` | Get public key from secret key | `String` |
| `makeCIBTransaction()` | Create bank transaction | `Future<Map<String, dynamic>>` |
| `getVersion()` | Get SDK version | `String` |

### Transaction Response

The `submit()` method returns a `SofizPayTransactionResponse` object:

```dart
class SofizPayTransactionResponse {
  final bool success;
  final String? transactionHash;  // تم تصحيح الاسم من transactionId
  final double? amount;
  final String? memo;
  final String? destinationPublicKey;
  final double? duration;
  final String? error;
  final String timestamp;
}
```

### Advanced Usage Examples

```dart
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

void main() async {
  final sdk = SofizPaySDK();

  // Get public key from secret key
  try {
    final publicKey = sdk.getPublicKey('YOUR_SECRET_KEY');
    print('Your public key: $publicKey');
    
    // Use this public key for balance checking
    final balance = await sdk.getBalance(publicKey);
    print('Balance: ${balance['balance']}');
  } catch (e) {
    print('Error getting public key: $e');
  }

  // Search transactions by memo
  final searchResult = await sdk.searchTransactionsByMemo(
    'YOUR_PUBLIC_KEY',
    'payment',
    limit: 20,
  );

  if (searchResult['total'] > 0) {
    print('Found ${searchResult['total']} transactions');
    for (final tx in searchResult['transactions']) {
      print('${tx['type']}: ${tx['amount']} - ${tx['memo']} (${tx['timestamp']})');
    }
  }

  // Get specific transaction by hash
  final txResult = await sdk.getTransactionByHash('TRANSACTION_HASH_HERE');
  if (txResult['found']) {
    final transaction = txResult['transaction'];
    print('Transaction found: ${transaction['amount']} - ${transaction['memo']}');
  } else {
    print('Transaction not found');
  }

  // Get complete transaction history
  final allTransactions = await sdk.getTransactions('YOUR_PUBLIC_KEY', limit: 100);
  print('Total transactions: ${allTransactions['total']}');
  
  for (final tx in allTransactions['transactions']) {
    print('${tx['created_at']}: ${tx['type']} ${tx['amount']} - ${tx['memo']}');
  }
}
```

### CIB Integration

```dart
// Create bank transaction
final bankResult = await sdk.makeCIBTransaction({
  'account': 'YOUR_SECRET_KEY',
  'amount': 150.0,
  'full_name': 'Ahmed Sofizpay',
  'phone': '+213*********',
  'email': 'ahmed@sofizpay.com',
  'memo': 'Bank payment',
  'return_url': 'https://yourapp.com/payment-success',
  'redirect': false, 
});

if (bankResult['data'] != null) {
  print('Bank transaction URL: ${bankResult['url']}');
  // Open the URL in browser or WebView
} else {
  print('Bank transaction failed');
}
```

### Error Handling

```dart
try {
  final result = await sdk.submit(
    secretkey: 'YOUR_SECRET_KEY',
    destinationPublicKey: 'RECIPIENT_KEY',
    amount: 50.0,
    memo: 'Test payment',
  );

  if (result.success) {
    print('Success: ${result.transactionHash}');  // تم تصحيح من transactionId
  } else {
    print('Payment failed: ${result.error}');
  }
} catch (e) {
  print('Exception occurred: $e');
}
```

## Response Format

All methods return consistent response formats:

### Success Response
```dart
{
  'success': true,
  // ... method-specific data
  'timestamp': '2025-07-28T10:30:00.000Z'
}
```

### Error Response
```dart
{
  'success': false,
  'error': 'Error description',
  'timestamp': '2025-07-28T10:30:00.000Z'
}
```

### Transaction History Response
```dart
{
  'transactions': [
    {
      'id': 'transaction_hash',     // تم تصحيح: id يحتوي على hash
      'hash': 'transaction_hash',
      'amount': 100.0,
      'memo': 'Payment memo',
      'type': 'sent|received',
      'from': 'sender_public_key',  // sourceAccount في الكود
      'to': 'recipient_public_key', // destination في الكود
      'asset_code': 'DZT',          // من StellarConfig
      'asset_issuer': 'issuer_key', // من StellarConfig
      'status': 'completed',
      'timestamp': '2025-07-28T10:30:00.000Z',
      'created_at': '2025-07-28T10:30:00.000Z'
    }
  ],
  'total': 1,
  'publicKey': 'account_public_key',
  'message': 'All transactions fetched (1 transactions)'  // رسالة إضافية
}
```

### Balance Response
```dart
{
  'balance': 1000.0,
  'publicKey': 'account_public_key',
  'asset_code': 'DZT',         // من StellarConfig
  'asset_issuer': 'issuer_key' // من StellarConfig
}
```

### Search Transactions Response
```dart
{
  'transactions': [...],  // نفس تنسيق getTransactions
  'total': 5,
  'totalFound': 5,        // إضافة من الكود
  'searchMemo': 'payment',
  'publicKey': 'account_public_key',
  'message': '5 transactions found containing "payment"'
}
```

### Transaction by Hash Response
```dart
{
  'found': true,
  'transaction': {
    // بيانات المعاملة
  },
  'has_operations': true,      // إضافة من الكود
  'operations_count': 1,       // إضافة من الكود
  'operations': [...],         // إضافة من الكود
  'hash': 'transaction_hash',
  'message': 'Transaction found'
}
```

## Configuration

The SDK is pre-configured for secure digital transactions. All network settings and security configurations are handled internally.

## Security Best Practices

⚠️ **Important Security Notes:**

- Never expose secret keys in client-side code
- Use environment variables for sensitive data
- Always validate inputs before sending transactions
- Test thoroughly before production deployment

```dart
// ✅ Good - Environment variable
final secretKey = Platform.environment['SECRET_KEY'];

// ❌ Bad - Hardcoded in code
final secretKey = 'SXXXXXXXXXXXXX...';
```

## Examples

### E-commerce Integration
```dart
class PaymentService {
  final SofizPaySDK _sdk = SofizPaySDK();

  Future<bool> processOrderPayment({
    required String customerKey,
    required double orderTotal,
    required String orderId,
  }) async {
    final result = await _sdk.submit(
      secretkey: Platform.environment['STORE_SECRET_KEY']!,
      destinationPublicKey: customerKey,
      amount: orderTotal,
      memo: 'Order #$orderId',
    );

    return result.success;
  }
}
```

### Account Management
```dart
class WalletManager {
  final SofizPaySDK _sdk = SofizPaySDK();

  Future<Map<String, dynamic>> getAccountInfo(String publicKey) async {
    final balance = await _sdk.getBalance(publicKey);
    final transactions = await _sdk.getTransactions(publicKey, limit: 10);

    return {
      'balance': balance['balance'],
      'recent_transactions': transactions['transactions'],
    };
  }
}
```

## Flutter Integration

### Adding to pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  sofizpay_sdk_dart: ^1.0.9
  # Other dependencies...
```

### Using in Flutter Widgets
```dart
import 'package:flutter/material.dart';
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

class PaymentButton extends StatelessWidget {
  final SofizPaySDK sdk = SofizPaySDK();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await sdk.submit(
          secretkey: 'YOUR_SECRET_KEY',
          destinationPublicKey: 'RECIPIENT_KEY',
          amount: 25.0,               
          memo: 'Flutter payment',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Payment sent!' : 'Failed'),
          ),
        );
      },
      child: Text('Send Payment'),
    );
  }
}
```

## Performance

- **Speed**: Sub-second transaction processing
- **Reliability**: 99.9% uptime guarantee
- **Scalability**: Handles high-volume operations
- **Memory Efficient**: Optimized for mobile and server applications

## Platform Support

- ✅ **Flutter** (iOS, Android, Web, Desktop)
- ✅ **Dart VM** (Server applications)
- ✅ **Web** (Dart compiled to JavaScript)

## Troubleshooting

### Common Issues

**Issue**: `Exception: Secret key is required`
```dart
// Solution: Ensure secret key is not empty
final secretKey = Platform.environment['SECRET_KEY'];
if (secretKey?.isNotEmpty == true) {
  // Use secretKey
}
```

**Issue**: Transaction fails with network error
```dart
// Solution: Add proper error handling
try {
  final result = await sdk.submit(/* ... */);
} catch (e) {
  print('Network error: $e');
  // Handle network issues
}
```

## SDK Methods Details

### dispose()
```dart
// تنظيف الموارد عند انتهاء الاستخدام
final sdk = SofizPaySDK();
// استخدام SDK...
sdk.dispose(); // تنظيف timers والبيانات المؤقتة
```

## Support

- 📚 **Documentation**: [GitHub Repository](https://github.com/kenandarabeh/sofizpay-sdk-dart#readme)
- 🐛 **Issues**: [Report Bug](https://github.com/kenandarabeh/sofizpay-sdk-dart/issues)
- 💬 **Discussions**: [Community Help](https://github.com/kenandarabeh/sofizpay-sdk-dart/discussions)
- 🌐 **Website**: [SofizPay.com](https://sofizpay.com)

## Use Cases

### Mobile Payment Apps
Perfect for Flutter applications requiring secure payment processing:
```dart
class MobileWallet extends StatefulWidget {
  // Implementation for mobile payment features
}
```

### Server-side Integration
Built for backend services requiring payment processing:
```dart
import 'dart:io';
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

void main() async {
  final server = await HttpServer.bind('localhost', 8080);
  final sdk = SofizPaySDK();
  
  await for (HttpRequest request in server) {
    // Handle payment requests
  }
}
```

### E-commerce Integration
Scalable for online stores and marketplaces:
```dart
class ShoppingCart {
  Future<bool> checkout(List<Product> items) async {
    final total = items.fold<double>(0, (sum, item) => sum + item.price);
    // Process payment with SofizPay
  }
}
```

## License

MIT © [SofizPay Team](https://github.com/kenandarabeh)

---

**Built with ❤️ for Dart & Flutter | Version `1.1.1`**
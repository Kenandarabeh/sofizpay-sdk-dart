# SofizPay SDK for Dart

<div align="center">
  <img src="assets/sofizpay-logo.png" alt="SofizPay Logo" width="200" height="200">
  
  <h3>🚀 A powerful Dart SDK for Stellar blockchain DZT token payments</h3>
  
  [![Pub Version](https://img.shields.io/pub/v/sofizpay_sdk_dart.svg)](https://pub.dev/packages/sofizpay_sdk_dart)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![GitHub Stars](https://img.shields.io/github/stars/kenandarabeh/sofizpay-sdk-dart.svg)](https://github.com/kenandarabeh/sofizpay-sdk-dart/stargazers)
  [![Issues](https://img.shields.io/github/issues/kenandarabeh/sofizpay-sdk-dart.svg)](https://github.com/kenandarabeh/sofizpay-sdk-dart/issues)
</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Usage Examples](#usage-examples)
- [Real-time Transaction Monitoring](#real-time-transaction-monitoring)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## 🌟 Overview

SofizPay SDK is a powerful Dart library for Stellar blockchain DZT token payments with real-time transaction monitoring and comprehensive payment management.

**Key Benefits:**
- 🔐 Secure Stellar blockchain integration
- ⚡ Real-time transaction monitoring  
- 🎯 Simple, intuitive API
- 📱 Cross-platform support

---

## ✨ Features

- ✅ **Send DZT Payments**: Secure token transfers with memo support
- ✅ **Transaction History**: Retrieve and filter transaction records  
- ✅ **Balance Checking**: Real-time DZT balance queries
- ✅ **Transaction Search**: Find transactions by memo or hash
- ✅ **Real-time Streams**: Live transaction monitoring with callbacks
- ✅ **Error Handling**: Robust error management and reporting

---

## 📦 Installation

Add SofizPay SDK to your `pubspec.yaml`:

```yaml
dependencies:
  sofizpay_sdk_dart: ^1.0.0
```

Then run:

```bash
dart pub get
```

For Flutter projects:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Import the SDK

```dart
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';
```

### 2. Initialize the SDK

```dart
final sofizPay = SofizPaySDK();
```

### 3. Your First Payment

```dart
// Send a DZT payment
final result = await sofizPay.submit(
  secretkey: 'YOUR_SECRET_KEY',
  destinationPublicKey: 'DESTINATION_PUBLIC_KEY',
  amount: 10.0,
  memo: 'Payment for services',
);

if (result.success) {
  print('Payment successful! TX: ${result.transactionHash}');
} else {
  print('Payment failed: ${result.error}');
}
```

---

## 📚 API Reference

### `submit()` - Send Payment
```dart
final result = await sofizPay.submit(
  secretkey: 'YOUR_SECRET_KEY',
  destinationPublicKey: 'DESTINATION_PUBLIC_KEY', 
  amount: 10.0,
  memo: 'Payment memo',
);
```

### `getDZTBalance()` - Check Balance
```dart
final result = await sofizPay.getDZTBalance(secretkey);
print('Balance: ${result.data!['balance']} DZT');
```

### `getTransactions()` - Transaction History
```dart
final result = await sofizPay.getTransactions(secretkey, limit: 50);
```

### `startTransactionStream()` - Real-time Monitoring
```dart
await sofizPay.startTransactionStream(secretkey, (transaction) {
  print('New ${transaction['type']}: ${transaction['amount']} DZT');
});
```

### Other Methods
- `getPublicKey()` - Extract public key from secret key
- `searchTransactionsByMemo()` - Search transactions by memo
- `getTransactionByHash()` - Get transaction by hash

---

## 🔄 Real-time Transaction Monitoring

```dart
// Start monitoring
await sofizPay.startTransactionStream(secretkey, (transaction) {
  print('New ${transaction['type']}: ${transaction['amount']} DZT');
  if (transaction['type'] == 'received') {
    handleIncomingPayment(transaction);
  }
});

// Check status
final status = await sofizPay.getStreamStatus(secretkey);

// Stop monitoring
await sofizPay.stopTransactionStream(secretkey);
```

---

## 💡 Usage Examples

### Complete Payment Flow
```dart
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

void main() async {
  final sofizPay = SofizPaySDK();
  const secretKey = 'YOUR_SECRET_KEY';
  
  try {
    // Check balance
    final balanceResult = await sofizPay.getDZTBalance(secretKey);
    final balance = balanceResult.data!['balance'];
    print('Balance: $balance DZT');
    
    // Send payment
    if (balance >= 10.0) {
      final result = await sofizPay.submit(
        secretkey: secretKey,
        destinationPublicKey: 'DESTINATION_PUBLIC_KEY',
        amount: 10.0,
        memo: 'Service payment',
      );
      
      if (result.success) {
        print('Payment successful: ${result.transactionHash}');
      }
    }
  } finally {
    sofizPay.dispose();
  }
}
```

### Payment Monitoring System
```dart
class PaymentMonitor {
  final SofizPaySDK _sdk = SofizPaySDK();
  
  Future<void> startMonitoring(String secretKey) async {
    await _sdk.startTransactionStream(secretKey, (transaction) {
      if (transaction['type'] == 'received') {
        print('💰 Payment received: ${transaction['amount']} DZT');
        print('From: ${transaction['from']}');
        // Process payment...
      }
    });
  }
  
  void dispose() => _sdk.dispose();
}
```

---

## ⚠️ Error Handling

All methods return structured response objects:

```dart
final result = await sofizPay.submit(/* parameters */);

if (result.success) {
  print('Success: ${result.transactionHash}');
} else {
  print('Error: ${result.error}');
}
```

**Common errors:**
- `'Secret key is required.'`
- `'Valid amount is required.'`
- `'Destination public key is required.'`

---

## 🏆 Best Practices

```dart
// ✅ Store secret keys securely (use secure storage in production)
// ✅ Always check result.success before accessing data
// ✅ Dispose SDK instances when done: sofizPay.dispose()
// ✅ Validate inputs before API calls
// ✅ Use appropriate transaction limits for better performance
```

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

```bash
# Development setup
git clone https://github.com/kenandarabeh/sofizpay-sdk-dart.git
cd sofizpay-sdk-dart
dart pub get
dart test
```

---

## 📞 Support

- 📖 [Documentation](https://github.com/kenandarabeh/sofizpay-sdk-dart#readme)
-  [Report Issues](https://github.com/kenandarabeh/sofizpay-sdk-dart/issues)
- � [Discussions](https://github.com/kenandarabeh/sofizpay-sdk-dart/discussions)
- ⭐ [Star the Project](https://github.com/kenandarabeh/sofizpay-sdk-dart)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built on the robust [Stellar Network](https://stellar.org)
- Powered by [stellar_flutter_sdk](https://pub.dev/packages/stellar_flutter_sdk)
- Inspired by the growing DeFi ecosystem

---

<div align="center">
  <p>Made by the SofizPay Team</p>
  <p>
    <a href="https://github.com/kenandarabeh/sofizpay-sdk-dart">GitHub</a> •
    <a href="https://pub.dev/packages/sofizpay_sdk_dart">pub.dev</a> •
    <a href="https://github.com/kenandarabeh/sofizpay-sdk-dart/issues">Support</a>
  </p>
</div>
  
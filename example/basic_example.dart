import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

/// Simple example demonstrating basic SofizPay SDK usage
void main() async {
  // Create SDK instance
  final sofizPay = SofizPaySDK();
  
  // Replace with your actual secret key
  const secretKey = 'YOUR_SECRET_KEY_HERE';
  
  print('🚀 SofizPay SDK Basic Example');
  print('Version: ${sofizPay.getVersion()}');
  print('=' * 40);
  
  try {
    // 1. Get public key from secret key
    print('📍 1. Getting Public Key...');
    final publicKeyResult = await sofizPay.getPublicKey(secretKey);
    if (publicKeyResult.success) {
      print('✅ Public Key: ${publicKeyResult.data!['publicKey']}');
    } else {
      print('❌ Error: ${publicKeyResult.error}');
      return;
    }
    
    // 2. Check DZT balance
    print('\n💰 2. Checking DZT Balance...');
    final balanceResult = await sofizPay.getDZTBalance(secretKey);
    if (balanceResult.success) {
      print('✅ DZT Balance: ${balanceResult.data!['balance']} DZT');
    } else {
      print('❌ Error: ${balanceResult.error}');
    }
    
    // 3. Get recent transactions
    print('\n📋 3. Getting Recent Transactions...');
    final transactionsResult = await sofizPay.getTransactions(secretKey, limit: 5);
    if (transactionsResult.success) {
      final transactions = transactionsResult.data!['transactions'] as List;
      print('✅ Found ${transactions.length} recent transactions');
      
      for (int i = 0; i < transactions.length; i++) {
        final tx = transactions[i];
        print('   ${i + 1}. ${tx['type']} - ${tx['amount']} DZT - "${tx['memo']}"');
      }
    } else {
      print('❌ Error: ${transactionsResult.error}');
    }
    
    // 4. Send a test payment (uncomment to test)
    /*
    print('\n💸 4. Sending Test Payment...');
    final paymentResult = await sofizPay.submit(
      secretkey: secretKey,
      destinationPublicKey: 'DESTINATION_PUBLIC_KEY_HERE',
      amount: 1.0,
      memo: 'Test payment from SDK example',
    );
    
    if (paymentResult.success) {
      print('✅ Payment successful!');
      print('   Transaction ID: ${paymentResult.transactionId}');
      print('   Amount: ${paymentResult.amount} DZT');
    } else {
      print('❌ Payment failed: ${paymentResult.error}');
    }
    */
    
  } catch (error) {
    print('❌ Unexpected error: $error');
  } finally {
    // Always cleanup resources
    sofizPay.dispose();
    print('\n🧹 Resources cleaned up');
    print('✨ Example completed!');
  }
}

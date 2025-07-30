import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

/// Example demonstrating SofizPay transaction submission
/// This shows how to send DZT payments using the SDK
void main() async {
  // Create SDK instance
  final sofizPay = SofizPaySDK();
  
  // Replace with your actual secret key
  const secretKey = 'SBKNMEIHTHOVSVV7GLWDPC5DACK7GO3CDUABKMKFYBJA4TARLLFT7EC4';
  
  // Replace with actual destination public key
  const destinationPublicKey = 'GB6MXBJGI4A7DJKBKUUTMLEUPPG3YWH2IBZQUHXZQJPLUVJOTAKCRDVC';
  
  print('🚀 SofizPay SDK Submit Transaction Example');
  print('Version: ${sofizPay.getVersion()}');
  print('=' * 50);
  
  try {
    // Get sender's public key
    final senderPublicKey = sofizPay.getPublicKey(secretKey);
    print('👤 Sender Public Key: $senderPublicKey');
    print('');
    
    // Check balance before sending
    print('💰 Checking balance before transaction...');
    final balanceData = await sofizPay.getBalance(senderPublicKey);
    final currentBalance = balanceData['balance'];
    print('✅ Current Balance: $currentBalance DZT');
    print('');
    
    // Transaction details
    const double amount = 1.0;
    const String memo = 'Test';
    
    print('📝 Transaction Details:');
    print('   💸 Amount: $amount DZT');
    print('   📝 Memo: "$memo"');
    print('   👤 From: $senderPublicKey');
    print('   👤 To: $destinationPublicKey');
    print('');
    
    // Check if we have enough balance
    if (currentBalance < amount) {
      print('❌ Insufficient balance! You need at least $amount DZT');
      print('   Current balance: $currentBalance DZT');
      print('   Required: $amount DZT');
      return;
    }
    
    print('🔄 Submitting transaction...');
    print('⏳ Please wait...');
    
    // Submit the transaction
    final startTime = DateTime.now();
    final transactionResult = await sofizPay.submit(
      secretkey: secretKey,
      destinationPublicKey: destinationPublicKey,
      amount: amount,
      memo: memo,
    );
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    // Transaction successful
    print('✅ Transaction submitted successfully!');
    print('');
    print('📊 Transaction Results:');
    print('   🔗 Transaction Hash: ${transactionResult.transactionHash}');
    print('   💰 Amount: ${transactionResult.amount} DZT');
    print('   📝 Memo: "${transactionResult.memo}"');
    print('   👤 Destination: ${transactionResult.destinationPublicKey}');
    print('   ⏱️  Duration: ${duration.inMilliseconds}ms');
    print('   📅 Timestamp: ${transactionResult.timestamp}');
    print('');
    
    // Check balance after sending
    print('💰 Checking balance after transaction...');
    final newBalanceData = await sofizPay.getBalance(senderPublicKey);
    final newBalance = newBalanceData['balance'];
    print('✅ New Balance: $newBalance DZT');
    print('💸 Amount deducted: ${currentBalance - newBalance} DZT');
    print('');
    
    // Optional: Verify the transaction by getting it back
    print('🔍 Verifying transaction...');
    final verificationData = await sofizPay.getTransactionByHash(transactionResult.transactionHash!);
    if (verificationData['found'] == true) {
      print('✅ Transaction verified successfully!');
      final txData = verificationData['transaction'];
      print('   Status: ${txData['successful'] ? 'Successful' : 'Failed'}');
    } else {
      print('⚠️  Transaction not found yet (may take a moment to propagate)');
    }
    
  } catch (error) {
    print('❌ Transaction failed: $error');
    print('');
    print('💡 Common issues:');
    print('   • Invalid secret key');
    print('   • Invalid destination public key');
    print('   • Insufficient balance');
    print('   • Network connectivity issues');
    print('   • Stellar network issues');
  } finally {
    // Always cleanup resources
    sofizPay.dispose();
    print('');
    print('🧹 Resources cleaned up');
    print('✨ Example completed!');
  }
}

import 'package:flutter/material.dart';
import 'package:sofizpay_sdk_dart/sofizpay_sdk_dart.dart';

void main() {
  runApp(const SofizPayApp());
}

class SofizPayApp extends StatelessWidget {
  const SofizPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SofizPay SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const SofizPayDemo(),
    );
  }
}

class SofizPayDemo extends StatefulWidget {
  const SofizPayDemo({super.key});

  @override
  State<SofizPayDemo> createState() => _SofizPayDemoState();
}

class _SofizPayDemoState extends State<SofizPayDemo> {
  final SofizPaySDK _sdk = SofizPaySDK();
  final TextEditingController _secretKeyController = TextEditingController();
  String _result = '';
  bool _loading = false;

  void _updateResult(String message) {
    setState(() {
      _result += '$message\n';
    });
  }

  Future<void> _generateKeys() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      _updateResult('🔧 إنشاء مفاتيح جديدة...');
      final keyPair = StellarUtils.generateTestKeyPair();
      
      _updateResult('✅ تم الإنشاء بنجاح!');
      _updateResult('🔑 المفتاح العام: ${keyPair['publicKey']}');
      _updateResult('📋 المفتاح السري: ${keyPair['secretKey']}');
      
      // وضع المفتاح السري في الحقل
      _secretKeyController.text = keyPair['secretKey']!;
      
      _updateResult('\n💡 تم وضع المفتاح السري في الحقل أعلاه');
      _updateResult('💡 يمكنك الآن اختبار الوظائف الأخرى');
      
    } catch (e) {
      _updateResult('❌ خطأ: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _getPublicKey() async {
    if (_secretKeyController.text.isEmpty) {
      _updateResult('❌ الرجاء إدخال المفتاح السري أولاً');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      _updateResult('\n🔍 استخراج المفتاح العام...');
      final result = await _sdk.getPublicKey(_secretKeyController.text);
      
      if (result.success && result.data != null) {
        _updateResult('✅ المفتاح العام: ${result.data!['publicKey']}');
      } else {
        _updateResult('❌ فشل: ${result.error}');
      }
    } catch (e) {
      _updateResult('❌ خطأ: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _checkBalance() async {
    if (_secretKeyController.text.isEmpty) {
      _updateResult('❌ الرجاء إدخال المفتاح السري أولاً');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      _updateResult('\n💰 فحص رصيد DZT...');
      final result = await _sdk.getDZTBalance(_secretKeyController.text);
      
      if (result.success && result.data != null) {
        _updateResult('✅ الرصيد: ${result.data!['balance']} DZT');
      } else {
        _updateResult('❌ فشل: ${result.error}');
        _updateResult('💡 ملاحظة: الحسابات الجديدة تحتاج لتمويل أولاً');
      }
    } catch (e) {
      _updateResult('❌ خطأ: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _getTransactions() async {
    if (_secretKeyController.text.isEmpty) {
      _updateResult('❌ الرجاء إدخال المفتاح السري أولاً');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      _updateResult('\n📋 جلب المعاملات...');
      final result = await _sdk.getTransactions(_secretKeyController.text, limit: 10);
      
      if (result.success && result.data != null) {
        final transactions = result.data!['transactions'] as List;
        _updateResult('✅ عدد المعاملات: ${transactions.length}');
        
        if (transactions.isNotEmpty) {
          for (int i = 0; i < transactions.length && i < 3; i++) {
            final tx = transactions[i];
            _updateResult('  ${i + 1}. ${tx['amount']} DZT - ${tx['memo']}');
          }
        }
      } else {
        _updateResult('❌ فشل: ${result.error}');
        _updateResult('💡 ملاحظة: الحسابات الجديدة لا تملك معاملات');
      }
    } catch (e) {
      _updateResult('❌ خطأ: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  void _clearResult() {
    setState(() {
      _result = '';
    });
  }

  @override
  void dispose() {
    _sdk.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SofizPay SDK Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SofizPay SDK v${_sdk.getVersion()}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _secretKeyController,
                      decoration: const InputDecoration(
                        labelText: 'المفتاح السري (Secret Key)',
                        border: OutlineInputBorder(),
                        hintText: 'أدخل المفتاح السري أو أنشئ مفاتيح جديدة',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _generateKeys,
                          icon: const Icon(Icons.add_moderator),
                          label: const Text('إنشاء مفاتيح'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _getPublicKey,
                          icon: const Icon(Icons.key),
                          label: const Text('المفتاح العام'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _checkBalance,
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('الرصيد'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _getTransactions,
                          icon: const Icon(Icons.history),
                          label: const Text('المعاملات'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'النتائج',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              if (_loading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _clearResult,
                                icon: const Icon(Icons.clear),
                                tooltip: 'مسح',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _result.isEmpty ? 'اضغط على أحد الأزرار أعلاه لبدء الاختبار...' : _result,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

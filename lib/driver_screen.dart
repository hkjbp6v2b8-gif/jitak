import 'package:flutter/material.dart';
import 'driver_profile_screen.dart';
import 'driver_wallet_screen.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isOnline = true;
  double _currentDebt = 22.5; // الدين الحالي على السائق (د.ل)
  final double _maxDebtLimit = 30.0; // حد التوقف (30 دينار)

  @override
  Widget build(BuildContext context) {
    bool isBlocked = _currentDebt >= _maxDebtLimit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة السائق'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverWalletScreen()),
              );
            },
            tooltip: 'المحفظة والأرباح',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverProfileScreen()),
              );
            },
            tooltip: 'الملف الشخصي',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة إدارة الرصيد والديون
            Card(
              elevation: 4,
              color: isBlocked ? Colors.red.shade50 : Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isBlocked ? Colors.red : Colors.teal.shade200,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'محفظة العمولة والديون',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Icon(
                          isBlocked
                              ? Icons.warning_amber_rounded
                              : Icons.account_balance_wallet,
                          color: isBlocked ? Colors.red : Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'الديون المتراكمة: $_currentDebt د.ل (الحد الأقصى: $_maxDebtLimit د.ل)',
                      style: TextStyle(
                        color: isBlocked ? Colors.red.shade700 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (_currentDebt / _maxDebtLimit)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      backgroundColor: Colors.grey.shade300,
                      color: isBlocked ? Colors.red : Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    if (isBlocked)
                      const Text(
                        'تنبيه: تجاوزت الحد الأقصى للديون (30 د.ل). تم ايقاف استقبال الرحلات حتى تسديد الدين.',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      )
                    else
                      const Text(
                        'الحساب متاح لاستقبال الطلبات بشكل طبيعي.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // محاكاة تسديد الديون (سيُربط بالخادم لاحقاً)
                        setState(() {
                          _currentDebt = 0.0;
                          _isOnline = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'تم تسديد الدين بنجاح! تم تفعيل الحساب.')),
                        );
                      },
                      icon: const Icon(Icons.payment,
                          color: Colors.white, size: 18),
                      label: const Text('تسديد الدين وتعبئة الرصيد',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? Colors.red : Colors.teal,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // حالة الاتصال وقبول الرحلات
            SwitchListTile(
              title: const Text('أنت متصل الآن لاستقبال الرحلات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isBlocked
                  ? 'متوقف تلقائياً بسبب الديون'
                  : (_isOnline
                      ? 'تستقبل طلبات الزبائن حالياً'
                      : 'أنت في وضع عدم الاتصال')),
              value: isBlocked ? false : _isOnline,
              activeColor: Colors.teal,
              onChanged: isBlocked
                  ? null
                  : (bool value) {
                      setState(() {
                        _isOnline = value;
                      });
                    },
            ),
            const Divider(height: 30),
            const Text(
              'الطلبات القريبة المتاحة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // قائمة الطلبات (تتوقف إذا كان الحساب موقوفاً)
            Expanded(
              child: isBlocked || !_isOnline
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            isBlocked
                                ? 'الحساب موقوف مؤقتاً لتجاوز الدين'
                                : 'أنت غير متصل حالياً',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        Card(
                          elevation: 2,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.tealAccent,
                              child: Icon(Icons.person, color: Colors.teal),
                            ),
                            title: const Text('رحلة إلى: ميدان الشهداء',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text(
                                'المسافة: 3.5 كم • التكلفة: 15 د.ل'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تم قبول الرحلة بنجاح!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal),
                              child: const Text('قبول',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

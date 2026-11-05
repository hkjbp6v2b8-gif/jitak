import 'package:flutter/material.dart';

class DriverWalletScreen extends StatelessWidget {
  const DriverWalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محفظة الأرباح - جِيتك'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة الرصيد والأرباح الكلية
            Card(
              elevation: 4,
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.teal.shade200, width: 1.5),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'إجمالي أرباح اليوم',
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '125.00 د.ل',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('رحلات اليوم', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('8 رحلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        VerticalDivider(),
                        Column(
                          children: [
                            Text('أرباح الأسبوع', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('840.00 د.ل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'سجل العمليات المالية الأخيرة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // قائمة العمليات المالية
            Expanded(
              child: ListView(
                children: const [
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Icon(Icons.arrow_downward, color: Colors.teal),
                      ),
                      title: Text('رحلة توصيل #1042', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('العميل: محمد علي • اليوم، 04:30 م'),
                      trailing: Text('+ 18.00 د.ل', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Icon(Icons.arrow_downward, color: Colors.teal),
                      ),
                      title: Text('رحلة توصيل #1041', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('العميل: أحمد حسن • اليوم، 02:15 م'),
                      trailing: Text('+ 22.00 د.ل', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.payment, color: Colors.white),
                      ),
                      title: Text('تسديد عمولة التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('تحويل رصيد / دفع مباشر • الأمس'),
                      trailing: Text('- 15.00 د.ل', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
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

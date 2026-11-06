import 'package:flutter/material.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({Key? key}) : super(key: key);

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  // حالات إرفاق الصور (محاكاة الرفع)
  bool _hasProfilePhoto = false;
  bool _hasPassportPhoto = false;
  bool _hasLicensePhoto = false;
  bool _hasCarExteriorPhoto = false;
  bool _hasCarInteriorPhoto = false;

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUploaded ? Colors.green.shade100 : Colors.teal.shade50,
          child: Icon(
            isUploaded ? Icons.check_circle : Icons.cloud_upload,
            color: isUploaded ? Colors.green : Colors.teal,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isUploaded ? Colors.grey.shade400 : Colors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            isUploaded ? 'تم الرفع' : 'إرفاق',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل كابتن جديد - جِيتك'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البيانات الشخصية والسيارة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'الاسم الثلاثي',
                prefixIcon: const Icon(Icons.person, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carModelController,
                    decoration: InputDecoration(
                      labelText: 'نوع وموديل السيارة',
                      prefixIcon: const Icon(Icons.directions_car, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _plateNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: const Icon(Icons.pin, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'إرفاق الوثائق الرسمية والمستندات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 6),
            const Text(
              'يرجى إرفاق صور واضحة لضمان تفعيل حسابك من قبل الإدارة.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // قائمة الرفع
            _buildUploadTile(
              title: 'الصورة الشخصية',
              subtitle: 'صورة خلفية بيضاء واضحة للوجه',
              isUploaded: _hasProfilePhoto,
              onTap: () => setState(() => _hasProfilePhoto = !_hasProfilePhoto),
            ),
            _buildUploadTile(
              title: 'جواز السفر',
              subtitle: 'صورة ملونة لصفحة البيانات الحالية',
              isUploaded: _hasPassportPhoto,
              onTap: () => setState(() => _hasPassportPhoto = !_hasPassportPhoto),
            ),
            _buildUploadTile(
              title: 'رخصة القيادة',
              subtitle: 'صورة الرخصة سارية المفعول (الوجهين)',
              isUploaded: _hasLicensePhoto,
              onTap: () => setState(() => _hasLicensePhoto = !_hasLicensePhoto),
            ),
            _buildUploadTile(
              title: 'صورة السيارة (من الخارج)',
              subtitle: 'صورة واضحة تظهر السيارة ورقم اللوحة',
              isUploaded: _hasCarExteriorPhoto,
              onTap: () => setState(() => _hasCarExteriorPhoto = !_hasCarExteriorPhoto),
            ),
            _buildUploadTile(
              title: 'صورة السيارة (من الداخل)',
              subtitle: 'صورة تظهر نظافة المقاعد والمقصورة',
              isUploaded: _hasCarInteriorPhoto,
              onTap: () => setState(() => _hasCarInteriorPhoto = !_hasCarInteriorPhoto),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_fullNameController.text.isEmpty || !_hasProfilePhoto || !_hasPassportPhoto || !_hasLicensePhoto || !_hasCarExteriorPhoto || !_hasCarInteriorPhoto) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء تعبئة كافة البيانات وإرفاق جميع المستندات المطلوبة!')),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تم تقديم الطلب بنجاح'),
                    content: const Text('طلبك الآن قيد المراجعة والتدقيق من قبل فريق الإدارة. سيتم إشعارك فور تفعيل الحساب.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('موافق'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('إرسال الطلب للمراجعة', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

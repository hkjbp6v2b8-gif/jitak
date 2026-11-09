import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// إعدادات المحفظة (غيّرها هنا فقط)
class WalletConfig {
  static const double commissionRate = 0.15; // عمولة الشركة 15%
  static const double debtLimit = 30.0; // حد الدين الذي يوقف الاستقبال (د.ل)
}

class WalletData {
  final bool loading;
  final bool error;
  final int tripsToday;
  final int tripsTotal;
  final double grossToday;
  final double grossWeek;
  final double grossTotal;
  final double paidTotal;
  final List<Map<String, dynamic>> payments;

  const WalletData({
    this.loading = false,
    this.error = false,
    this.tripsToday = 0,
    this.tripsTotal = 0,
    this.grossToday = 0,
    this.grossWeek = 0,
    this.grossTotal = 0,
    this.paidTotal = 0,
    this.payments = const [],
  });

  bool get ready => !loading && !error;
  double get commissionTotal => grossTotal * WalletConfig.commissionRate;
  double get netToday => grossToday * (1 - WalletConfig.commissionRate);
  double get netWeek => grossWeek * (1 - WalletConfig.commissionRate);

  // المستحق للشركة بعد خصم ما دُفع
  double get debt {
    final value = commissionTotal - paidTotal;
    return value > 0 ? value : 0;
  }

  factory WalletData.from(
    List<Map<String, dynamic>> rides,
    List<Map<String, dynamic>> payments,
  ) {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));

    double gross = 0, today = 0, week = 0;
    int tripsToday = 0;

    for (final ride in rides) {
      final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
      gross += fare;
      final t = ride['completedAt'];
      if (t is Timestamp) {
        final d = t.toDate();
        if (!d.isBefore(startToday)) {
          today += fare;
          tripsToday++;
        }
        if (d.isAfter(weekAgo)) week += fare;
      }
    }

    double paid = 0;
    for (final p in payments) {
      paid += (p['amount'] as num?)?.toDouble() ?? 0.0;
    }

    final sorted = List<Map<String, dynamic>>.from(payments);
    sorted.sort((a, b) {
      final ta = a['createdAt'];
      final tb = b['createdAt'];
      if (ta is! Timestamp || tb is! Timestamp) return 0;
      return tb.compareTo(ta);
    });

    return WalletData(
      tripsToday: tripsToday,
      tripsTotal: rides.length,
      grossToday: today,
      grossWeek: week,
      grossTotal: gross,
      paidTotal: paid,
      payments: sorted,
    );
  }
}

// يقرأ رحلات السائق المكتملة ودفعاته مباشرة، ويمرر المحفظة محسوبة
class WalletBuilder extends StatefulWidget {
  final String driverId;
  final Widget Function(BuildContext context, WalletData wallet) builder;

  const WalletBuilder({Key? key, required this.driverId, required this.builder})
      : super(key: key);

  @override
  State<WalletBuilder> createState() => _WalletBuilderState();
}

class _WalletBuilderState extends State<WalletBuilder> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _rides;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _payments;

  void _init() {
    final db = FirebaseFirestore.instance;
    _rides = db
        .collection('rides')
        .where('driverId', isEqualTo: widget.driverId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
    _payments = db
        .collection('driverPayments')
        .where('driverId', isEqualTo: widget.driverId)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(WalletBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverId != widget.driverId) _init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _rides,
      builder: (context, rides) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _payments,
          builder: (context, pays) {
            if (rides.hasError || pays.hasError) {
              return widget.builder(context, const WalletData(error: true));
            }
            if (!rides.hasData || !pays.hasData) {
              return widget.builder(context, const WalletData(loading: true));
            }
            final wallet = WalletData.from(
              rides.data!.docs.map((d) => d.data()).toList(),
              pays.data!.docs.map((d) => d.data()).toList(),
            );
            return widget.builder(context, wallet);
          },
        );
      },
    );
  }
}
// نهاية الملف

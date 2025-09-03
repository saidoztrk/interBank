// lib/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// DbProvider/Modeller sende varsa (transfer/payment vs.)
// burada içeri alıp gerçek veriyle doldurabiliriz.
// import '../providers/db_provider.dart';

class AppColors {
  static const background = Color(0xFF0A1628);
  static const primary = Color(0xFF1E3A8A);
  static const primary2 = Color(0xFF3B82F6);
  static const accent = Color(0xFFFFD700);
  static const textLight = Color(0xFFE5E7EB);
  static const textSub = Color(0xFFD1D5DB);
  static const cardBg = Color(0xFF1F2937);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Sekmeler
  int _tab = 0; // 0: Tümü, 1: Faturalar, 2: Transfer, 3: Kart

  // Demo veriler — gerçek API/DbProvider bağlayınca burayı kaldıracağız.
  late final List<_Tx> _all = [
    _Tx(
        title: 'Elektrik Faturası',
        sub: 'Başarısız',
        amount: -480,
        date: DateTime(2019, 10, 30),
        kind: _Kind.bill,
        status: _Status.fail),
    _Tx(
        title: 'Su Faturası',
        sub: 'Başarılı',
        amount: -280,
        date: DateTime(2019, 10, 22),
        kind: _Kind.bill,
        status: _Status.ok),
    _Tx(
        title: 'Maaş: Ekim',
        sub: 'Gelir',
        amount: 1200,
        date: DateTime(2019, 9, 30),
        kind: _Kind.card,
        status: _Status.ok),
    _Tx(
        title: 'Jane\'e Gönderim',
        sub: 'Havale',
        amount: -500,
        date: DateTime(2019, 9, 28),
        kind: _Kind.transfer,
        status: _Status.ok),
    _Tx(
        title: 'İnternet',
        sub: 'Başarılı',
        amount: -100,
        date: DateTime(2019, 8, 30),
        kind: _Kind.bill,
        status: _Status.ok),
    _Tx(
        title: 'ATM Yatırma',
        sub: 'Nakit',
        amount: 750,
        date: DateTime(2019, 8, 18),
        kind: _Kind.card,
        status: _Status.ok),
    _Tx(
        title: 'Kira Ödemesi',
        sub: 'EFT',
        amount: -4800,
        date: DateTime(2019, 7, 30),
        kind: _Kind.transfer,
        status: _Status.ok),
    _Tx(
        title: 'Mobil Fatura',
        sub: 'Başarılı',
        amount: -140,
        date: DateTime(2019, 7, 22),
        kind: _Kind.bill,
        status: _Status.ok),
    _Tx(
        title: 'Market (Kart)',
        sub: 'Temassız',
        amount: -360,
        date: DateTime(2019, 6, 30),
        kind: _Kind.card,
        status: _Status.ok),
    _Tx(
        title: 'Elektrik Faturası',
        sub: 'Başarılı',
        amount: -480,
        date: DateTime(2019, 5, 30),
        kind: _Kind.bill,
        status: _Status.ok),
  ];

  List<_Tx> get _filtered {
    switch (_tab) {
      case 1:
        return _all.where((t) => t.kind == _Kind.bill).toList();
      case 2:
        return _all.where((t) => t.kind == _Kind.transfer).toList();
      case 3:
        return _all.where((t) => t.kind == _Kind.card).toList();
      default:
        return _all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByMonth(_filtered);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text('İşlem geçmişi',
            style: TextStyle(
                color: AppColors.textLight, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildTabs(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                return _MonthSection(title: g.label, items: g.items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Tümü', 'Faturalar', 'Transfer', 'Kart'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final selected = _tab == i;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: tabs.length,
      ),
    );
  }

  // Yardımcılar
  List<_MonthGroup> _groupByMonth(List<_Tx> items) {
    items.sort((a, b) => b.date.compareTo(a.date)); // yeni üstte
    final map = <String, List<_Tx>>{};
    for (final t in items) {
      final key = _monthLabel(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries
        .map((e) => _MonthGroup(label: e.key, items: e.value))
        .toList();
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${months[d.month - 1]}';
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.title, required this.items});
  final String title;
  final List<_Tx> items;

  String _formatTRY(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final ri = intPart.length - 1 - i;
      buf.write(intPart[i]);
      if (ri % 3 == 0 && i != intPart.length - 1) buf.write('.');
    }
    return '${buf.toString()},$decPart ₺';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(.15)),
      ),
      child: Column(
        children: [
          // Başlık satırı
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  )),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 2),
          // Elemanlar
          ...items.map((t) {
            final isIncome = t.amount >= 0;
            final amountStr = (isIncome ? '+' : '-') +
                _formatTRY(t.amount.abs().toDouble()).replaceAll(' ₺', '');
            final statusColor = switch (t.status) {
              _Status.ok => AppColors.success,
              _Status.warn => AppColors.warning,
              _Status.fail => AppColors.error,
            };
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      t.kind.icon,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Durum: ',
                              style: TextStyle(
                                color: AppColors.textSub.withOpacity(.9),
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              t.status.label,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tutar: ',
                              style: TextStyle(
                                color: AppColors.textSub.withOpacity(.9),
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              '$amountStr ₺',
                              style: TextStyle(
                                color: isIncome
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFFF4D67),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _ddMMyyyy(t.date),
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 12.5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _ddMMyyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

enum _Kind { bill, transfer, card }

extension on _Kind {
  IconData get icon => switch (this) {
        _Kind.bill => Icons.receipt_long,
        _Kind.transfer => Icons.sync_alt,
        _Kind.card => Icons.credit_card,
      };
}

enum _Status { ok, warn, fail }

extension on _Status {
  String get label => switch (this) {
        _Status.ok => 'Başarılı',
        _Status.warn => 'Uyarı',
        _Status.fail => 'Başarısız',
      };
}

class _Tx {
  final String title;
  final String sub;
  final int amount; // + gelir, - gider
  final DateTime date;
  final _Kind kind;
  final _Status status;

  _Tx({
    required this.title,
    required this.sub,
    required this.amount,
    required this.date,
    required this.kind,
    required this.status,
  });
}

class _MonthGroup {
  final String label;
  final List<_Tx> items;
  _MonthGroup({required this.label, required this.items});
}

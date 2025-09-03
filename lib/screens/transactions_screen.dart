// lib/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../providers/db_provider.dart';
import '../models/account.dart';
import '../models/transfer_history_item.dart';
import '../models/transaction_item.dart';

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
  int _tab = 0; // 0: Tümü, 1: Faturalar, 2: Transfer, 3: Kart
  bool _initialized = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
    
    _initialized = true;
  }

  Future<void> _initializeData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dbp = Provider.of<DbProvider>(context, listen: false);
      
      if (kDebugMode) {
        print('[Erenay][TXNS] Initializing transaction data...');
        print('[Erenay][TXNS] Available accounts: ${dbp.accounts.length}');
      }

      if (dbp.accounts.isNotEmpty) {
        final Account acc = dbp.accounts.first;
        final accountId = acc.accountId ?? acc.accountId;
        
        if (kDebugMode) {
          print('[Erenay][TXNS] Loading transfers for account: $accountId');
        }
        
        await dbp.loadTransfersByAccount(accountId);
        
        if (kDebugMode) {
          print('[Erenay][TXNS] Loaded ${dbp.transfers.length} transfers');
        }
      } else {
        if (kDebugMode) {
          print('[Erenay][TXNS] No accounts available');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Erenay][TXNS] Error loading transfers: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer geçmişi yüklenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<_Tx> _mapTransfers(List<TransferHistoryItem> list) {
    if (kDebugMode) {
      print('[Erenay][TXNS] Mapping ${list.length} transfers');
    }
    
    return list.map((t) {
      try {
        final isIncome = t.direction == TransferDirection.IN;
        
        // Status mapping - daha güvenli
        _Status status;
        final statusLower = t.status.toLowerCase();
        if (statusLower.contains('posted') || statusLower.contains('success') || statusLower.contains('completed')) {
          status = _Status.ok;
        } else if (statusLower.contains('pend') || statusLower.contains('process')) {
          status = _Status.warn;
        } else {
          status = _Status.fail;
        }

        // Amount mapping - null check eklendi
        final amountAsInt = (t.amount).round() * (isIncome ? 1 : -1);

        // Title - daha dinamik
        String title = t.title;
        if (title.isEmpty || title == t.counterparty) {
          title = isIncome ? 'Gelen Havale' : 'Giden Havale';
        }

        // Sub text - daha anlamlı
        String sub = 'Havale';
        if (t.counterparty.isNotEmpty && t.counterparty != title) {
          sub = 'Hesap: ${t.counterparty}';
        }

        if (kDebugMode) {
          print('[Erenay][TXNS] Mapped transfer: ${t.id} - $title - ${isIncome ? '+' : '-'}${t.amount} ${t.currency}');
        }

        return _Tx(
          title: title,
          sub: sub,
          amount: amountAsInt,
          date: t.occurredAt,
          kind: _Kind.transfer,
          status: status,
        );
      } catch (e) {
        if (kDebugMode) {
          print('[Erenay][TXNS] Error mapping transfer ${t.id}: $e');
        }
        // Fallback _Tx
        return _Tx(
          title: 'Transfer Hatası',
          sub: 'Hata',
          amount: 0,
          date: DateTime.now(),
          kind: _Kind.transfer,
          status: _Status.fail,
        );
      }
    }).toList();
  }

  List<_Tx> _mapCardTx(List<TransactionItem> list) {
    if (kDebugMode) {
      print('[Erenay][TXNS] Mapping ${list.length} card transactions');
    }
    
    return list.map((x) {
      try {
        final isIncome = x.isIncome;
        final statusText = (x.status ?? '').toLowerCase();
        final status = statusText.contains('pend')
            ? _Status.warn
            : (statusText.isEmpty || statusText.contains('ok') || statusText.contains('post'))
                ? _Status.ok
                : _Status.fail;

        final dt = x.date ?? DateTime.now();
        final title = (x.merchantName?.isNotEmpty == true)
            ? x.merchantName!
            : (x.description?.isNotEmpty == true ? x.description! : 'Kart İşlemi');

        final amountAsInt = (x.amount).round() * (isIncome ? 1 : -1);

        return _Tx(
          title: title,
          sub: x.category?.isNotEmpty == true ? x.category! : 'Kart',
          amount: amountAsInt,
          date: dt,
          kind: _Kind.card,
          status: status,
        );
      } catch (e) {
        if (kDebugMode) {
          print('[Erenay][TXNS] Error mapping transaction ${x.id}: $e');
        }
        return _Tx(
          title: 'İşlem Hatası',
          sub: 'Hata',
          amount: 0,
          date: DateTime.now(),
          kind: _Kind.card,
          status: _Status.fail,
        );
      }
    }).toList();
  }

  List<_Tx> _buildAll(DbProvider dbp) {
    final all = <_Tx>[];

    try {
      // 1) Transferler
      if (dbp.transfers.isNotEmpty) {
        if (kDebugMode) {
          print('[Erenay][TXNS] Adding ${dbp.transfers.length} transfers');
        }
        all.addAll(_mapTransfers(dbp.transfers));
      }

      // 2) Kart işlemleri
      if (dbp.recentTransactions.isNotEmpty) {
        if (kDebugMode) {
          print('[Erenay][TXNS] Adding ${dbp.recentTransactions.length} card transactions');
        }
        all.addAll(_mapCardTx(dbp.recentTransactions));
      }

      // 3) Faturalar (şimdilik boş)

      if (kDebugMode) {
        print('[Erenay][TXNS] Total transactions: ${all.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Erenay][TXNS] Error building transaction list: $e');
      }
    }

    return all;
  }

  List<_Tx> _filtered(List<_Tx> all) {
    switch (_tab) {
      case 1: // Faturalar
        return all.where((t) => t.kind == _Kind.bill).toList();
      case 2: // Transfer
        return all.where((t) => t.kind == _Kind.transfer).toList();
      case 3: // Kart
        return all.where((t) => t.kind == _Kind.card).toList();
      default: // Tümü
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Consumer<DbProvider>(
              builder: (context, dbp, child) {
                if (_isLoading || dbp.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  );
                }

                if (dbp.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Veriler yüklenirken hata oluştu',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dbp.error!,
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _initializeData(),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final all = _buildAll(dbp);
                final filtered = _filtered(all);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: AppColors.textSub,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz işlem bulunmuyor',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final groups = _groupByMonth(filtered);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return _MonthSection(title: g.label, items: g.items);
                  },
                );
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

  List<_MonthGroup> _groupByMonth(List<_Tx> items) {
    items.sort((a, b) => b.date.compareTo(a.date));
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
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[d.month - 1]}';
  }
}

// Widget sınıfları aynı kalıyor...
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
  final int amount;
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
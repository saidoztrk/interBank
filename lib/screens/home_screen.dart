// lib/screens/home_screen.dart - Güncellenmiş tam sürüm
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
//saide selam

import '../services/session_manager.dart';
import '../providers/db_provider.dart';
import '../models/customer.dart';
import '../models/account.dart';
import '../models/debit_card.dart';
import '../models/credit_card.dart';
import 'login_screen.dart';
import 'cards_screen.dart';

class AppColors {
  static const background = Color(0xFF0A1628);
  static const primary    = Color(0xFF1E3A8A);
  static const primary2   = Color(0xFF3B82F6);
  static const accent     = Color(0xFFFFD700);
  static const textLight  = Color(0xFFE5E7EB);
  static const textSub    = Color(0xFFD1D5DB);
  static const cardBg     = Color(0xFF1F2937);
  static const success    = Color(0xFF22C55E);
  static const warning    = Color(0xFFF59E0B);
  static const error      = Color(0xFFEF4444);
}

// Asset paths
const String kIconHome    = 'lib/assets/images/captain/home/home.png';
const String kIconApps    = 'lib/assets/images/captain/home/apps.png';
const String kIconSend    = 'lib/assets/images/captain/home/send.png';
const String kIconPay     = 'lib/assets/images/captain/home/pay.png';
const String kIconCaptain = 'lib/assets/images/captain/captain.png';

const double kNavHeight = 140.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _hideBalance = false;
  bool _loading = true;
  String? _error;

  // Dynamic data
  Customer? _customer;
  Account? _primaryAccount;
  DebitCard? _primaryDebitCard;
  CreditCard? _primaryCreditCard;
  List<Account> _allAccounts = [];
  
  // Selected card info from cards screen
  Map<String, dynamic>? _selectedCardInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache navigation icons
    for (final asset in [kIconHome, kIconApps, kIconSend, kIconPay, kIconCaptain]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  Future<void> _loadUserData() async {
    setState(() { _loading = true; _error = null; });

    try {
      final cNo = SessionManager.customerNo;
      if (cNo == null) {
        throw Exception('Oturum bulunamadı');
      }

      final dbp = context.read<DbProvider>();

      // Load customer information
      if (dbp.customer == null || dbp.customer!.customerId != cNo) {
        await dbp.loadCustomerById(cNo);
      }
      _customer = dbp.customer;

      // Load accounts
      await dbp.loadAccountsByCustomer(cNo);
      _allAccounts = dbp.accounts;

      // Load cards
      await dbp.loadCardsByCustomer(cNo);

      // Select primary items based on selected card info or defaults
      if (_selectedCardInfo != null) {
        _selectPrimaryItemsFromSelection();
      } else {
        _selectPrimaryAccount();
        _selectPrimaryCards();
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _selectPrimaryItemsFromSelection() {
    if (_selectedCardInfo == null) return;
    
    final dbp = context.read<DbProvider>();
    final type = _selectedCardInfo!['type'] as String;
    final id = _selectedCardInfo!['id'] as String;

    switch (type) {
      case 'account':
        // Find the selected account
        _primaryAccount = _allAccounts.cast<Account?>().firstWhere(
          (acc) => acc?.accountId == id,
          orElse: () => null,
        );
        // Clear card selections when account is selected
        _primaryDebitCard = null;
        _primaryCreditCard = null;
        break;
        
      case 'debit':
        // Find the selected debit card
        _primaryDebitCard = dbp.debitCards.cast<DebitCard?>().firstWhere(
          (card) => card?.cardId == id,
          orElse: () => null,
        );
        // Find linked account for debit card
        if (_primaryDebitCard?.accountId != null) {
          _primaryAccount = _allAccounts.cast<Account?>().firstWhere(
            (acc) => acc?.accountId == _primaryDebitCard!.accountId,
            orElse: () => null,
          );
        }
        _primaryCreditCard = null;
        break;
        
      case 'credit':
        // Find the selected credit card
        _primaryCreditCard = dbp.creditCards.cast<CreditCard?>().firstWhere(
          (card) => card?.cardId == id,
          orElse: () => null,
        );
        // For credit cards, we might not have a direct account link
        // Use default account selection
        _selectPrimaryAccount();
        _primaryDebitCard = null;
        break;
    }

    // If no primary account found, use default selection
    if (_primaryAccount == null) {
      _selectPrimaryAccount();
    }
  }

  void _selectPrimaryAccount() {
    // First look for active, TRY, current accounts
    Account? primary = _allAccounts.cast<Account?>().firstWhere(
      (acc) => acc != null && 
               acc.currency.toUpperCase() == 'TRY' && 
               acc.type.toLowerCase().contains('vadesiz') &&
               (acc.status?.toLowerCase() != 'closed'),
      orElse: () => null,
    );

    // If not found, get first TRY account
    if (primary == null) {
      primary = _allAccounts.cast<Account?>().firstWhere(
        (acc) => acc != null && acc.currency.toUpperCase() == 'TRY',
        orElse: () => null,
      );
    }

    // If still not found, get first account
    primary ??= _allAccounts.isNotEmpty ? _allAccounts.first : null;
    
    _primaryAccount = primary;
  }

  void _selectPrimaryCards() {
    final dbp = context.read<DbProvider>();
    
    // Select active debit card
    _primaryDebitCard = dbp.debitCards.cast<DebitCard?>().firstWhere(
      (card) => card != null && (card.isActive == true),
      orElse: () => dbp.debitCards.isNotEmpty ? dbp.debitCards.first : null,
    );

    // Select active credit card
    _primaryCreditCard = dbp.creditCards.cast<CreditCard?>().firstWhere(
      (card) => card != null && (card.isActive == true),
      orElse: () => dbp.creditCards.isNotEmpty ? dbp.creditCards.first : null,
    );
  }

  String _formatTRY(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    String intPart = parts[0];
    final decPart = parts[1];
    
    // Add thousand separators
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final reverseIndex = intPart.length - 1 - i;
      buffer.write(intPart[i]);
      if (reverseIndex % 3 == 0 && i != intPart.length - 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()},$decPart ₺';
  }

  String _getAccountStatusColor() {
    if (_primaryAccount?.status?.toLowerCase() == 'frozen') return 'warning';
    if (_primaryAccount?.status?.toLowerCase() == 'closed') return 'error';
    if (_primaryAccount?.isBlocked == 1) return 'error';
    return 'success';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success': return AppColors.success;
      case 'warning': return AppColors.warning;
      case 'error': return AppColors.error;
      default: return AppColors.textSub;
    }
  }

  Widget _buildAccountCard() {
    if (_primaryAccount == null && _primaryCreditCard == null) return _buildEmptyCard();

    final screenW = MediaQuery.of(context).size.width;
    final contentW = math.min(screenW - 32, 640.0);
    final cardH = contentW / 1.58;
    final scale = (screenW / 390).clamp(0.90, 1.10);
    
    // Determine what to display based on selection
    String statusColor = 'success';
    double balance = 0.0;
    String cardBrand = 'BANK';
    String cardType = 'Hesap';
    String displayName = _customer?.fullName ?? 'Müşteri';
    String? statusText;
    String? ibanText;

    if (_selectedCardInfo != null && _selectedCardInfo!['type'] == 'credit') {
      // Credit card selected
      if (_primaryCreditCard != null) {
        balance = _selectedCardInfo!['availableLimit'] ?? 0.0;
        cardBrand = _primaryCreditCard!.cardBrand ?? 'CREDIT';
        cardType = 'Kredi Kartı';
        
        if (_primaryCreditCard!.isBlocked == true) {
          statusColor = 'error';
          statusText = 'BLOKLU';
        } else if (_primaryCreditCard!.isActive != true) {
          statusColor = 'warning';
          statusText = 'PASIF';
        }
      }
    } else {
      // Account or debit card selected (or default)
      if (_primaryAccount != null) {
        balance = _primaryAccount!.balance;
        statusColor = _getAccountStatusColor();
        cardType = '${_primaryAccount!.type} ${_primaryAccount!.currency}';
        ibanText = _primaryAccount!.iban;
        statusText = _primaryAccount!.status;
        
        if (_primaryDebitCard != null) {
          cardBrand = _primaryDebitCard!.cardBrand ?? 'BANK';
          if (_primaryDebitCard!.isBlocked == true) {
            statusColor = 'error';
            statusText = 'BLOKLU';
          }
        }
      }
    }

    final formattedBalance = _formatTRY(balance);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: GestureDetector(
          onTap: _openCards,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: contentW,
            height: cardH,
            child: Stack(
              children: [
                // Card background - color based on status
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: statusColor == 'error' 
                        ? [const Color(0xFF7F1D1D), const Color(0xFFDC2626)]
                        : statusColor == 'warning'
                        ? [const Color(0xFF92400E), const Color(0xFFF59E0B)]
                        : [const Color(0xFF251E73), const Color(0xFF2AA4FF)],
                      begin: Alignment.topLeft, 
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
                    ],
                  ),
                ),
                
                // Decorative elements
                Positioned(
                  left: -contentW * .15,
                  top: cardH * .05,
                  child: Container(
                    width: contentW * .65,
                    height: contentW * .65,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                Positioned(
                  right: contentW * .04,
                  top: cardH * .10,
                  child: Container(
                    width: contentW * .35,
                    height: contentW * .35,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.22),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer name and status
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19 * scale,
                                  ),
                                ),
                                if (statusText != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10 * scale,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _hideBalance = !_hideBalance),
                            child: Icon(
                              _hideBalance ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withOpacity(.90),
                              size: 20 * scale,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Account/Card type
                      Text(
                        cardType,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.90),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5 * scale,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // IBAN (only for accounts)
                      if (ibanText != null) ...[
                        Text(
                          ibanText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.95),
                            fontWeight: FontWeight.w700,
                            fontSize: 14 * scale,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Balance and action button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              _hideBalance ? "•••••••• ₺" : formattedBalance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22 * scale,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                cardBrand,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .6,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: Colors.white.withOpacity(.95)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return const Center(
      child: Text(
        'Hesap bilgisi bulunamadı',
        style: TextStyle(color: AppColors.textSub),
      ),
    );
  }

  Widget _buildAccountsList() {
    if (_allAccounts.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tüm Hesaplarım',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            ..._allAccounts.map((account) => _buildAccountItem(account)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountItem(Account account) {
    final isBlocked = account.isBlocked == 1;
    final isClosed = account.status?.toLowerCase() == 'closed';
    
    Color statusColor = AppColors.success;
    if (isBlocked || isClosed) statusColor = AppColors.error;
    else if (account.status?.toLowerCase() == 'frozen') statusColor = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              account.type.toLowerCase().contains('kredi') 
                ? Icons.credit_card 
                : Icons.account_balance_wallet,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${account.type} ${account.currency}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (account.iban != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    account.iban!,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (account.status != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      account.status!,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatTRY(account.balance),
            style: TextStyle(
              color: account.balance >= 0 ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsPreview() {
    final items = <_TxItem>[
      _TxItem(icon: Icons.opacity, iconBg: const Color(0xFF5B6CFF), title: 'Su Faturası', sub: 'Başarısız', amount: -280, date: DateTime.now()),
      _TxItem(icon: Icons.work, iconBg: const Color(0xFFFF5B8A), title: 'Maaş: Ekim', sub: 'Başarılı', amount: 1200, date: DateTime.now().subtract(const Duration(days: 1))),
      _TxItem(icon: Icons.bolt, iconBg: const Color(0xFF28C2FF), title: 'Elektrik Faturası', sub: 'Başarılı', amount: -480, date: DateTime.now().subtract(const Duration(days: 1))),
      _TxItem(icon: Icons.card_giftcard, iconBg: const Color(0xFFFFA726), title: 'Jane gönd.', sub: 'Gelir', amount: 500, date: DateTime.now().subtract(const Duration(days: 1))),
      _TxItem(icon: Icons.wifi, iconBg: const Color(0xFF00C49A), title: 'İnternet', sub: 'Başarılı', amount: -100, date: DateTime.now().subtract(const Duration(days: 2))),
    ];

    void goAll() {
      try {
        Navigator.pushNamed(context, '/transactions');
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlemler ekranı henüz eklenmedi.')),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: goAll,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent.withOpacity(.20), width: 1),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text('Son İşlemler',
                        style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: goAll,
                    child: const Text('Tümünü gör', style: TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Transaction list
              ...items.take(3).map((t) => _buildTransactionItem(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(_TxItem t) {
    final isIncome = t.amount >= 0;
    final amountStr = (isIncome ? '+' : '-') + _formatTRY(t.amount.abs().toDouble()).replaceAll(' ₺', '');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: t.iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(t.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(t.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSub, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$amountStr ₺',
            style: TextStyle(
              color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFFF4D67),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCards() async {
    // Open cards page
    HapticFeedback.selectionClick();
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CardsScreen(),
        ),
      );
      
      // Handle the returned card selection
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _selectedCardInfo = result;
        });
        // Reload data with the new selection
        await _loadUserData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double contentTop = math.max(100, size.height * 0.15);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildWavyHeader(context),
          Padding(
            padding: EdgeInsets.only(top: contentTop),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                    ? _buildErrorView()
                    : SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: kNavHeight + MediaQuery.of(context).padding.bottom + 24,
                        ),
                        child: Column(
                          children: [
                            _buildAccountCard(),
                            const SizedBox(height: 16),
                            _buildAccountsList(),
                            const SizedBox(height: 16),
                            _buildQuickActions(),
                            const SizedBox(height: 16),
                            _buildTransactionsPreview(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSub),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildWavyHeader(BuildContext context) {
    return ClipPath(
      clipper: _BottomWaveClipper(),
      child: Container(
        height: 260,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(top: 36, left: -10, child: _decorativeBubble(70, AppColors.accent.withOpacity(.15))),
            Positioned(top: 20, right: -6, child: _decorativeBubble(46, Colors.white.withOpacity(.20))),
            Positioned(bottom: 18, right: 40, child: _decorativeBubble(28, AppColors.accent.withOpacity(.12))),
            Positioned(top: 80, right: 20, child: Icon(Icons.anchor, size: 24, color: Colors.white.withOpacity(0.3))),
            Positioned(bottom: 40, left: 30, child: Icon(Icons.sailing, size: 20, color: AppColors.accent.withOpacity(0.4))),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.menu, color: Colors.white, size: 24),
                    const Row(
                      children: [
                        Icon(Icons.sailing, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "CaptainBank",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    ),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BankStyleLoginScreen()),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              "Çıkış",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionChip(Icons.send, "Para Gönder", AppColors.accent),
          _actionChip(Icons.receipt_long, "Fatura Öde", Colors.amber),
          _actionChip(Icons.qr_code, "QR İşlemleri", Colors.teal),
          _actionChip(Icons.anchor, "IBAN Paylaş", Colors.deepPurpleAccent),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: SizedBox(
        height: kNavHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 48,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, -2)),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(12, 0, 28, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navIcon(kIconHome, 'Ana Sayfa', _tab == 0, () => setState(() => _tab = 0)),
                    _navIcon(kIconApps, 'Başvurular', _tab == 1, () => setState(() => _tab = 1)),
                    const SizedBox(width: 88),
                    _navIcon(kIconSend, 'Para Gönder', _tab == 2, () => setState(() => _tab = 2)),
                    _navIcon(kIconPay, 'Ödeme Yap', _tab == 3, () => setState(() => _tab = 3)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -6,
              child: Transform.translate(
                offset: const Offset(-12, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pushNamed(context, '/chat');
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 86, height: 86,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary2],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
                            BoxShadow(color: Color(0x553B82F6), blurRadius: 30, spreadRadius: -8, offset: Offset(0, 10)),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Image.asset( kIconCaptain,
  width: 105,   // 🔹 görselin genişliği
  height: 105,  // 🔹 görselin yüksekliği
  fit: BoxFit.contain,
  filterQuality: FilterQuality.high),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kaptan',
                      style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .2),
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

  Widget _navIcon(String asset, String label, bool selected, VoidCallback onTap) {
    final BoxDecoration bg = selected
        ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary2],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
              BoxShadow(color: Color(0x553B82F6), blurRadius: 28, spreadRadius: -8, offset: Offset(0, 10)),
            ],
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0x11000000)),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 6))],
          );

    final Widget iconImg = Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain, filterQuality: FilterQuality.high);
    final Color labelColor = selected ? AppColors.primary : Colors.grey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 48,
              height: 48,
              decoration: bg,
              child: Center(child: iconImg),
            ),
            const SizedBox(height: 8),
            Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor)),
          ],
        ),
      ),
    );
  }

  Widget _decorativeBubble(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _TxItem {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String sub;
  final int amount; // + income, - expense
  final DateTime date;
  
  _TxItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.sub,
    required this.amount,
    required this.date,
  });
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 60);
    final c1 = Offset(size.width * 0.25, size.height);
    final p1 = Offset(size.width * 0.5, size.height - 30);
    final c2 = Offset(size.width * 0.75, size.height - 90);
    final p2 = Offset(size.width, size.height - 50);
    path
      ..quadraticBezierTo(c1.dx, c1.dy, p1.dx, p1.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, p2.dx, p2.dy)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
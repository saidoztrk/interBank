// lib/screens/cards_screen.dart - Güncellenmiş sürüm
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/db_provider.dart';
import '../models/account.dart';
import '../models/debit_card.dart';
import '../models/credit_card.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({
    Key? key,
    this.initialTab = 1, // 0: Account, 1: Card
    this.initialSelectedId,
  }) : super(key: key);

  final int initialTab;
  final String? initialSelectedId;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int _tab = 1;
  String? _selectedId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _selectedId = widget.initialSelectedId;
  }

  String _formatTRY(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    String intPart = parts[0];
    final decPart = parts[1];
    
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

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.isEmpty) return '';
    final cleaned = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 8) return cardNumber;
    final first4 = cleaned.substring(0, 4);
    final last4 = cleaned.substring(cleaned.length - 4);
    return '$first4 •••• •••• $last4';
  }

  Color _getAccountStatusColor(Account account) {
    if (account.status?.toLowerCase() == 'closed') return Colors.red;
    if (account.status?.toLowerCase() == 'frozen') return Colors.orange;
    if (account.isBlocked == 1) return Colors.red;
    return Colors.green;
  }

  Color _getCardStatusColor(bool? isActive, bool? isBlocked) {
    if (isBlocked == true) return Colors.red;
    if (isActive != true) return Colors.orange;
    return Colors.green;
  }

  List<Color> _getCardGradient(String? brand, bool? isBlocked) {
    if (isBlocked == true) {
      return [const Color(0xFF7F1D1D), const Color(0xFFDC2626)]; // Kırmızı
    }
    
    switch (brand?.toUpperCase()) {
      case 'VISA':
        return [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]; // Mavi
      case 'MASTERCARD':
        return [const Color(0xFFDC2626), const Color(0xFFEF4444)]; // Kırmızı
      case 'TROY':
        return [const Color(0xFF059669), const Color(0xFF10B981)]; // Yeşil
      case 'AMEX':
      case 'AMERICAN EXPRESS':
        return [const Color(0xFF7C3AED), const Color(0xFFA855F7)]; // Mor
      default:
        return [const Color(0xFF374151), const Color(0xFF6B7280)]; // Gri
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _tab == 0 ? _buildAccountsTab() : _buildCardsTab(),
                  ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const SizedBox(width: 6),
          const Text(
            'Hesaplar ve Kartlar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF122033),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.06)),
        ),
        child: Row(
          children: [
            _segBtn('Hesaplar', _tab == 0, () => setState(() => _tab = 0)),
            const SizedBox(width: 8),
            _segBtn('Kartlar', _tab == 1, () => setState(() => _tab = 1)),
          ],
        ),
      ),
    );
  }

  Widget _segBtn(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : const Color(0xFF0F1A2B),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTab() {
    final dbProvider = context.watch<DbProvider>();
    final accounts = dbProvider.accounts;

    if (accounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'Hesap bulunamadı',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final account = accounts[index];
        final selected = _selectedId == account.accountId;
        final statusColor = _getAccountStatusColor(account);

        return GestureDetector(
          onTap: () {
            setState(() => _selectedId = account.accountId);
            Navigator.pop(context, {
              'type': 'account',
              'id': account.accountId,
              'accountId': account.accountId,
              'display': account.iban ?? account.accountNo ?? account.accountId,
              'balance': account.balance,
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(.06),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? [
                const BoxShadow(
                  color: Color(0x333B82F6),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ] : [
                const BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    account.type.toLowerCase().contains('kredi') 
                        ? Icons.credit_card 
                        : Icons.account_balance_wallet,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${account.type} ${account.currency}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (account.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(.5)),
                              ),
                              child: Text(
                                account.status!,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kullanılabilir bakiye',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTRY(account.balance),
                        style: TextStyle(
                          color: account.balance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      if (account.iban != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          account.iban!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardsTab() {
    final dbProvider = context.watch<DbProvider>();
    final debitCards = dbProvider.debitCards;
    final creditCards = dbProvider.creditCards;

    if (debitCards.isEmpty && creditCards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'Kart bulunamadı',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        // Banka Kartları
        if (debitCards.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Banka Kartları',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final card in debitCards) ...[
            _buildDebitCardWidget(card),
            const SizedBox(height: 14),
          ],
        ],

        // Kredi Kartları
        if (creditCards.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: debitCards.isNotEmpty ? 16 : 8),
            child: const Text(
              'Kredi Kartları',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final card in creditCards) ...[
            _buildCreditCardWidget(card),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }

  Widget _buildDebitCardWidget(DebitCard card) {
    final w = MediaQuery.of(context).size.width - 32;
    final h = w / 1.58;
    final selected = _selectedId == card.cardId;
    final statusColor = _getCardStatusColor(card.isActive, card.isBlocked);
    final gradient = _getCardGradient(card.cardBrand, card.isBlocked);

    // Bağlı hesabı bul
    final dbProvider = context.read<DbProvider>();
    final linkedAccount = dbProvider.accounts.cast<Account?>().firstWhere(
      (acc) => acc?.accountId == card.accountId,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = card.cardId);
        Navigator.pop(context, {
          'type': 'debit',
          'id': card.cardId,
          'display': _maskCardNumber(card.cardNumber),
          'cardBrand': card.cardBrand,
          'balance': linkedAccount?.balance ?? 0.0,
        });
      },
      child: Container(
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
            if (selected)
              BoxShadow(
                color: gradient[1].withOpacity(.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
          border: selected ? Border.all(color: Colors.white.withOpacity(.5), width: 2) : null,
        ),
        child: Stack(
          children: [
            // Dekoratif daireler
            Positioned(
              left: -w * .18,
              top: h * .06,
              child: Container(
                width: w * .55,
                height: w * .55,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: w * .04,
              top: h * .10,
              child: Container(
                width: w * .30,
                height: w * .30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.read<DbProvider>().customer?.fullName ?? 'Kart Sahibi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      // Durum göstergesi
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Banka Kartı',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (card.isBlocked == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BLOKLU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  // Kart numarası
                  Text(
                    _maskCardNumber(card.cardNumber),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Alt satır
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Bakiye
                      if (linkedAccount != null)
                        Text(
                          _formatTRY(linkedAccount.balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      const Spacer(),
                      // Marka ve seçim butonu
                      Row(
                        children: [
                          Text(
                            card.cardBrand ?? 'BANK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
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
    );
  }

  Widget _buildCreditCardWidget(CreditCard card) {
    final w = MediaQuery.of(context).size.width - 32;
    final h = w / 1.58;
    final selected = _selectedId == card.cardId;
    final statusColor = _getCardStatusColor(card.isActive, card.isBlocked);
    final gradient = _getCardGradient(card.cardBrand, card.isBlocked);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = card.cardId);
        Navigator.pop(context, {
          'type': 'credit',
          'id': card.cardId,
          'display': _maskCardNumber(card.cardNumber),
          'cardBrand': card.cardBrand,
          'availableLimit': card.availableLimit ?? 0.0,
          'currentDebt': card.currentDebt ?? 0.0,
        });
      },
      child: Container(
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
            if (selected)
              BoxShadow(
                color: gradient[1].withOpacity(.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
          border: selected ? Border.all(color: Colors.white.withOpacity(.5), width: 2) : null,
        ),
        child: Stack(
          children: [
            // Dekoratif daireler
            Positioned(
              left: -w * .18,
              top: h * .06,
              child: Container(
                width: w * .55,
                height: w * .55,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: w * .04,
              top: h * .10,
              child: Container(
                width: w * .30,
                height: w * .30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.read<DbProvider>().customer?.fullName ?? 'Kart Sahibi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Kredi Kartı',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (card.isBlocked == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BLOKLU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  // Kart numarası
                  Text(
                    _maskCardNumber(card.cardNumber),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Alt satır
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Kullanılabilir limit
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (card.availableLimit != null) ...[
                            Text(
                              'Kullanılabilir',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.8),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _formatTRY(card.availableLimit!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      // Marka
                      Row(
                        children: [
                          Text(
                            card.cardBrand ?? 'CREDIT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
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
    );
  }
}
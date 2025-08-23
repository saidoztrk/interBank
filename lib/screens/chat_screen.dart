// lib/screens/chat_screen.dart — GÜNCEL İMPORTLAR
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// 👉 QR entegrasyonu (package import)
import 'package:interbank/qr/qr_intents.dart' show isQrPayIntent, QRPaymentData;
import 'package:interbank/qr/qr_scan_screen.dart';

// Servis & modeller (package import)
import 'package:interbank/models/session_info.dart';
import 'package:interbank/models/message_model.dart';
import 'package:interbank/models/bot_badge_state.dart';
import 'package:interbank/services/api_service_manager.dart';
import 'package:interbank/services/session_manager.dart';
import 'package:interbank/widgets/chat_bubble.dart';
import 'package:interbank/widgets/message_input.dart';
import 'package:interbank/screens/no_connection_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? initialSessionId;
  final ServiceType? preferredService;

  const ChatScreen({
    super.key,
    this.initialSessionId,
    this.preferredService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final List<ChatMessage> _messages = [
    ChatMessage.bot(
      '🏦 Merhaba! Ben CaptainBank asistanınızım. Banking işlemlerinizde size nasıl yardımcı olabilirim?',
      badge: BotBadgeState.sekreter,
    ),
  ];

  final ScrollController _scrollCtrl = ScrollController();

  bool _waitingReply = false;
  bool _hasConnection = true;

  // Çoklu servis sağlık durumu
  ServiceHealthStatus _serviceHealth = const ServiceHealthStatus(
    mcpAgentAvailable: false,
    externalApiAvailable: false,
  );

  // Aktif servis
  ServiceType _activeService = ServiceType.mcpAgent;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Scroll titremesini azaltmak için throttle
  bool _scrollScheduled = false;

  // Bağlantı başarılı mesajını bir kez gösterme guard'ı
  bool _announcedMcpUp = false;
  bool _announcedExternalUp = false;

  // Pastel renk
  static const _pastelPrimary = Color(0xFF8AB4F8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialSessionId != null) {
      ApiServiceManager.setCurrentSessionId(widget.initialSessionId!);
    }
    if (widget.preferredService != null) {
      ApiServiceManager.setServiceType(widget.preferredService!);
      _activeService = widget.preferredService!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollToBottom();
      _precacheBotAssets();
      _checkAllServicesHealth();
    });

    _checkInitialConnection();
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.dispose();
    _subscription.cancel();
    super.dispose();
  }

  // ---- Servis Sağlık Kontrolü ----
  Future<void> _checkAllServicesHealth() async {
    try {
      final healthStatus = await ApiServiceManager.checkAllServicesHealth();
      if (!mounted) return;

      setState(() {
        _serviceHealth = healthStatus;
      });

      if (!_serviceHealth.anyServiceAvailable) {
        setState(() {
          _messages.add(
            ChatMessage.bot(
              '❌ Hiçbir backend servisi çalışmıyor.\n\n'
              'Kontrol listesi:\n'
              '• MCP Agent: Python (port 8081)\n'
              '• External API: Ekibin FastAPI servisi (port 8083)',
              badge: BotBadgeState.noConnection,
            ),
          );
        });
      } else {
        // Guard'lı ilan
        if (_serviceHealth.mcpAgentAvailable && !_announcedMcpUp) {
          _announcedMcpUp = true;
          setState(() {
            _messages.add(ChatMessage.bot('MCP Agent bağlantısı başarılı!',
                badge: BotBadgeState.connection));
          });
        }
        if (_serviceHealth.externalApiAvailable && !_announcedExternalUp) {
          _announcedExternalUp = true;
          setState(() {
            _messages.add(ChatMessage.bot('External API bağlantısı başarılı!',
                badge: BotBadgeState.connection));
          });
        }

        // Tercih edilen servis ayakta değilse fallback
        final preferredUp = _activeService == ServiceType.mcpAgent
            ? _serviceHealth.mcpAgentAvailable
            : _serviceHealth.externalApiAvailable;

        if (!preferredUp) {
          if (_serviceHealth.mcpAgentAvailable) {
            _activeService = ServiceType.mcpAgent;
            ApiServiceManager.setServiceType(ServiceType.mcpAgent);
            setState(() {
              _messages.add(
                ChatMessage.bot('🔄 MCP Agent\'e geçiş yapıldı.',
                    badge: BotBadgeState.connection),
              );
            });
          } else if (_serviceHealth.externalApiAvailable) {
            _activeService = ServiceType.externalApi;
            ApiServiceManager.setServiceType(ServiceType.externalApi);
            setState(() {
              _messages.add(
                ChatMessage.bot('🔄 External API\'ye geçiş yapıldı.',
                    badge: BotBadgeState.connection),
              );
            });
          }
        }
      }

      _scheduleScrollToBottom();
    } catch (e) {
      debugPrint('❌ Service health check error: $e');
    }
  }

  // ---- Servis Değiştirme ----
  void _switchService(ServiceType newService) {
    setState(() {
      _activeService = newService;
      ApiServiceManager.setServiceType(newService);
      final name = _getServiceDisplayName(newService);
      _messages.add(
        ChatMessage.bot('🔄 $name\'ye geçiş yapıldı.',
            badge: BotBadgeState.connection),
      );
    });
    _scheduleScrollToBottom();
  }

  // ---- Bağlantı Yönetimi ----
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (_hasConnection == isConnected) return;

    setState(() {
      _hasConnection = isConnected;

      if (!isConnected) {
        _messages.add(
          ChatMessage.bot('İnternet bağlantısı koptu. Çevrimdışısınız.',
              badge: BotBadgeState.noConnection),
        );
      } else {
        _messages.add(
          ChatMessage.bot('İnternet bağlantısı geri geldi! 🌐',
              badge: BotBadgeState.connection),
        );
        _checkAllServicesHealth();
      }
    });

    _scheduleScrollToBottom();
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  Future<void> _precacheBotAssets() async {
    const assets = [
      'lib/assets/images/captain/captain.png',
      'lib/assets/images/captain/captain_thinking.png',
      'lib/assets/images/captain/captain_writing.png',
      'lib/assets/images/captain/captain_connection.png',
      'lib/assets/images/captain/captain_noconnection.png',
      'lib/assets/images/captain/captain_sekreter.png',
    ];
    for (final asset in assets) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (e) {
        debugPrint('Asset precache hatası: $asset - $e');
      }
    }
  }

  void _scheduleScrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if ((target - _scrollCtrl.position.pixels).abs() < 2) return;
      _scrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // ---- Mesaj Gönderimi ----
  Future<void> _sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 👉 QR niyeti
    if (isQrPayIntent(trimmed)) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
      });
      _scheduleScrollToBottom();
      await _startQrFlow();
      return;
    }

    // Bağlantı kontrol
    if (!_hasConnection) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(
          ChatMessage.bot(
              'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
              badge: BotBadgeState.noConnection),
        );
      });
      _scheduleScrollToBottom();
      return;
    }

    // Servis uygunluğu
    if (!_serviceHealth.anyServiceAvailable) {
      setState(() {
        _messages.add(ChatMessage.user(trimmed));
        _messages.add(
          ChatMessage.bot(
              '🔧 Hiçbir backend servisi kullanılamıyor. Lütfen sunucuları başlatın.',
              badge: BotBadgeState.noConnection),
        );
      });
      _scheduleScrollToBottom();
      return;
    }

    // Aktif servis ayakta mı?
    final currentServiceUp = _activeService == ServiceType.mcpAgent
        ? _serviceHealth.mcpAgentAvailable
        : _serviceHealth.externalApiAvailable;

    if (!currentServiceUp) {
      if (_serviceHealth.mcpAgentAvailable) {
        _switchService(ServiceType.mcpAgent);
      } else if (_serviceHealth.externalApiAvailable) {
        _switchService(ServiceType.externalApi);
      }
    }

    // Kullanıcı mesajını ekle + typing indicator
    setState(() {
      _messages.add(ChatMessage.user(trimmed));
      _waitingReply = true;
    });
    _scheduleScrollToBottom();

    try {
      final response = await ApiServiceManager.sendMessage(
        message: trimmed,
        customerNo: SessionManager.customerNo,
        sessionId: ApiServiceManager.getCurrentSessionId(),
        serviceType: _activeService,
      );

      if (!mounted) return;
      setState(() {
        _messages
            .add(ChatMessage.bot(response.message, badge: response.badgeState));
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.bot('Hata: ${e.message}',
            badge: BotBadgeState.noConnection));
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
      await _tryFallbackService(trimmed);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.bot(
            'Beklenmeyen bir hata oluştu. Lütfen tekrar dener misiniz?',
            badge: BotBadgeState.noConnection));
        _waitingReply = false;
      });
      _scheduleScrollToBottom();
    }
  }

  Future<void> _tryFallbackService(String message) async {
    final fallback = _activeService == ServiceType.mcpAgent
        ? ServiceType.externalApi
        : ServiceType.mcpAgent;

    final fallbackUp = fallback == ServiceType.mcpAgent
        ? _serviceHealth.mcpAgentAvailable
        : _serviceHealth.externalApiAvailable;

    if (!fallbackUp) return;

    try {
      setState(() {
        _messages.add(ChatMessage.bot(
            '🔄 ${_getServiceDisplayName(fallback)}\'ye geçiş yapılıyor...',
            badge: BotBadgeState.thinking));
      });
      _scheduleScrollToBottom();

      final response = await ApiServiceManager.sendMessage(
        message: message,
        customerNo: SessionManager.customerNo,
        sessionId: ApiServiceManager.getCurrentSessionId(),
        serviceType: fallback,
      );

      if (!mounted) return;
      setState(() {
        // geçiş mesajını kaldır
        if (_messages.isNotEmpty &&
            _messages.last.text.contains('geçiş yapılıyor')) {
          _messages.removeLast();
        }

        _activeService = fallback;
        ApiServiceManager.setServiceType(fallback);

        _messages
            .add(ChatMessage.bot(response.message, badge: response.badgeState));
      });
      _scheduleScrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last.text.contains('geçiş yapılıyor')) {
          _messages.removeLast();
        }
      });
    }
  }

  String _getServiceDisplayName(ServiceType service) {
    switch (service) {
      case ServiceType.mcpAgent:
        return 'MCP Agent';
      case ServiceType.externalApi:
        return 'External API';
    }
  }

  Color _getServiceStatusColor() {
    if (!_serviceHealth.anyServiceAvailable) return Colors.red;

    final up = _activeService == ServiceType.mcpAgent
        ? _serviceHealth.mcpAgentAvailable
        : _serviceHealth.externalApiAvailable;

    return up ? Colors.green : Colors.orange;
  }

  // ---- Oturum İşlemleri ----
  Future<void> _startNewSession() async {
    try {
      final newId = await ApiServiceManager.startNewSession();
      ApiServiceManager.setCurrentSessionId(newId);

      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage.bot(
              '🆕 Yeni sohbet oturumu başlatıldı. Nasıl yardımcı olabilirim?',
              badge: BotBadgeState.sekreter),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni oturum başlatıldı')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oturum başlatılırken hata: $e')),
      );
    }
  }

  Future<void> _clearCurrentSession() async {
    try {
      await ApiServiceManager.clearCurrentSession();

      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage.bot(
              '🧹 Sohbet geçmişi temizlendi. Yeni bir soruyla başlayalım!',
              badge: BotBadgeState.sekreter),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli oturum temizlendi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Temizlenemedi: $e')),
      );
    }
  }

  Future<void> _showSessionHistory() async {
    try {
      final sessions = await ApiServiceManager.listSessions(
          userId: SessionManager.customerNo ?? 0);
      if (!mounted) return;

      if (sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıtlı oturum yok')),
        );
        return;
      }

      final selected = await showDialog<SessionInfo>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oturum Geçmişi'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (_, i) {
                final s = sessions[i];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(s.title ?? 'Oturum ${s.id}'),
                  subtitle: Text(s.updatedAt?.toString() ?? ''),
                  onTap: () => Navigator.of(ctx).pop(s),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );

      if (selected != null) {
        ApiServiceManager.setCurrentSessionId(selected.id);
        setState(() {
          _messages.clear();
          _messages.add(
            ChatMessage.bot(
                '📂 "${selected.title ?? selected.id}" oturumu yüklendi. Devam edebilirsiniz.',
                badge: BotBadgeState.connection),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oturumlar alınamadı: $e')),
      );
    }
  }

  // ====== QR FLOW (scan -> confirm -> pay) ======
  Future<void> _startQrFlow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QRScanScreen()), // const kaldırıldı
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _messages.add(ChatMessage.bot("QR okutma iptal edildi."));
      });
      _scheduleScrollToBottom();
      return;
    }

    // Tür yükseltmeyi korumak için yeni değişken:
    final r = result;
    if (r is! QRPaymentData) {
      setState(() {
        _messages.add(ChatMessage.bot("Geçersiz QR verisi alındı."));
      });
      _scheduleScrollToBottom();
      return;
    }
    final data = r; // QRPaymentData

    // Tutarı kesinleştir (null-safe)
    double amount = data.amount ?? 0;
    if (amount <= 0) {
      final entered = await _askAmount();
      if (entered == null || entered <= 0) {
        setState(() {
          _messages.add(ChatMessage.bot("Tutar girilmedi, işlem iptal."));
        });
        _scheduleScrollToBottom();
        return;
      }
      amount = entered;
    }

    final ok = await _askConfirm(
      receiverName: data.receiverName,
      iban: data.receiverIban,
      amount: amount,
      note: data.note,
    );
    if (ok != true) {
      setState(() {
        _messages.add(ChatMessage.bot("Ödeme iptal edildi."));
      });
      _scheduleScrollToBottom();
      return;
    }

    await _payQr(
      receiverIban: data.receiverIban,
      receiverName: data.receiverName,
      amount: amount,
      note: data.note,
    );
  }

  Future<bool?> _askConfirm({
    required String receiverName,
    required String iban,
    required double amount,
    String? note,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ödeme Onayı"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alıcı: $receiverName"),
            Text("IBAN: $iban"),
            Text("Tutar: ${amount.toStringAsFixed(2)} TL"),
            if (note != null && note.isNotEmpty) Text("Açıklama: $note"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("İptal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Onayla")),
        ],
      ),
    );
  }

  Future<void> _payQr({
    required String receiverIban,
    required String receiverName,
    required double amount,
    String? note,
  }) async {
    setState(() {
      _messages.add(ChatMessage.bot("Ödeme işleniyor…"));
    });
    _scheduleScrollToBottom();

    try {
      final resp = await ApiServiceManager.payQr(
        receiverIban: receiverIban,
        receiverName: receiverName,
        amount: amount,
        note: note,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.bot(
            "✅ Ödeme tamamlandı\n"
            "Referans: ${resp.reference}\n"
            "Tutar: ${resp.amount.toStringAsFixed(2)} TL\n"
            "Alıcı: ${resp.receiverName}",
          ),
        );
      });
    } on ApiServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.bot("❌ QR ödeme hatası: ${e.message}"),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.bot("❌ Ödeme başarısız: $e"),
        );
      });
    }
    _scheduleScrollToBottom();
  }

  Future<double?> _askAmount() async {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tutar gir"),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: "Örn: 150.75"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(",", "."));
              Navigator.pop(ctx, v);
            },
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: _pastelPrimary,
      colorScheme:
          Theme.of(context).colorScheme.copyWith(primary: _pastelPrimary),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smart_toy, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CaptainBank AI',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getServiceDisplayName(_activeService),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getServiceStatusColor(),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            PopupMenuButton<ServiceType>(
              icon: const Icon(Icons.swap_horiz, color: Colors.grey),
              tooltip: 'Servis Değiştir',
              onSelected: _switchService,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ServiceType.mcpAgent,
                  enabled: _serviceHealth.mcpAgentAvailable,
                  child: Row(
                    children: [
                      Icon(Icons.memory,
                          color: _serviceHealth.mcpAgentAvailable
                              ? Colors.green
                              : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'MCP Agent',
                        style: TextStyle(
                          color: _serviceHealth.mcpAgentAvailable
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                      if (_activeService == ServiceType.mcpAgent)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.check, color: Colors.green, size: 16),
                        ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ServiceType.externalApi,
                  enabled: _serviceHealth.externalApiAvailable,
                  child: Row(
                    children: [
                      Icon(Icons.cloud,
                          color: _serviceHealth.externalApiAvailable
                              ? Colors.blue
                              : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'External API',
                        style: TextStyle(
                          color: _serviceHealth.externalApiAvailable
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                      if (_activeService == ServiceType.externalApi)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.check, color: Colors.green, size: 16),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _checkAllServicesHealth,
              tooltip: 'Servisleri kontrol et',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                switch (value) {
                  case 'new_session':
                    _startNewSession();
                    break;
                  case 'session_history':
                    _showSessionHistory();
                    break;
                  case 'clear_history':
                    _clearCurrentSession();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'new_session',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline),
                      SizedBox(width: 8),
                      Text('Yeni Sohbet'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'session_history',
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text('Oturum Geçmişi'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_history',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 8),
                      Text('Geçmişi Temizle'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: !_hasConnection
            ? NoConnectionScreen(onRetry: _checkInitialConnection)
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SafeArea(
                  child: Column(
                    children: [
                      if (!_serviceHealth.anyServiceAvailable)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.red.shade100,
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Hiçbir backend servisi aktif değil.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              TextButton(
                                onPressed: _checkAllServicesHealth,
                                child: const Text('Tekrar Dene'),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        if (_activeService == ServiceType.mcpAgent &&
                            !_serviceHealth.mcpAgentAvailable)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color: Colors.orange.shade100,
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'MCP Agent offline. External API\'ye geçebilirsiniz.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _switchService(ServiceType.externalApi),
                                  child: const Text('Geç'),
                                ),
                              ],
                            ),
                          ),
                        if (_activeService == ServiceType.externalApi &&
                            !_serviceHealth.externalApiAvailable)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color: Colors.orange.shade100,
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'External API offline. MCP Agent\'a geçebilirsiniz.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _switchService(ServiceType.mcpAgent),
                                  child: const Text('Geç'),
                                ),
                              ],
                            ),
                          ),
                      ],
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 8),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: _messages.length + (_waitingReply ? 1 : 0),
                          itemBuilder: (context, index) {
                            final typingItem =
                                _waitingReply && index == _messages.length;
                            if (typingItem) {
                              return const Padding(
                                padding: EdgeInsets.only(left: 18, bottom: 6),
                                child: _TypingIndicator(),
                              );
                            }
                            final msg = _messages[index];
                            return ChatBubble(message: msg);
                          },
                        ),
                      ),
                      MessageInput(
                        enabled: !_waitingReply &&
                            _serviceHealth.anyServiceAvailable,
                        onSend: _sendUserMessage,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ---- Typing indicator ----
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: Colors.transparent,
          backgroundImage:
              AssetImage('lib/assets/images/captain/captain_writing.png'),
        ),
        SizedBox(width: 10),
        _TypingBubble(),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          'Agent çalışıyor...',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}

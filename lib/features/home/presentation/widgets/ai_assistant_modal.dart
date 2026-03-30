import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show buildModalTitle;
import '../../data/services/chat_api_service.dart';

class AIAssistantModal extends StatefulWidget {
  const AIAssistantModal({super.key});

  @override
  State<AIAssistantModal> createState() => _AIAssistantModalState();

  // Modal constraints'ini oluştur
  static BoxConstraints _buildModalConstraints(BuildContext ctx) {
    return BoxConstraints(
      maxWidth: (MediaQuery.of(ctx).size.width - 96)
          .clamp(0.0, 800.0) // Daha geniş
          .toDouble(),
      maxHeight: (MediaQuery.of(ctx).size.height - 48)
          .clamp(0.0, 900.0)
          .toDouble(),
    );
  }

  /// AI Asistan modalını göster
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ContentDialog(
        constraints: _buildModalConstraints(ctx),
        title: buildModalTitle('AI Asistan', ctx),
        content: const AIAssistantModal(),
        actions: null, // Aksiyonlar içeride yönetiliyor
      ),
    );
  }
}

class _AIAssistantModalState extends State<AIAssistantModal> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatApiService _chatService = ChatApiService();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': 'Merhaba! Ben Akıllı Bina Asistanı. Size nasıl yardımcı olabilirim?',
    },
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      // Backend API çağrısı
      final response = await _chatService.sendMessage(text);
      final answer = response['answer'] as String;
      
      // Kaynakları da alabiliriz (henüz UI'da göstermiyoruz ama konsola basalım)
      final sources = response['sources'] as List<dynamic>?;
      if (sources != null && sources.isNotEmpty) {
        debugPrint('Kullanılan kaynaklar: ${sources.length}');
      }

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': answer,
            'sources': sources, // İleride kaynakları göstermek istersek diye
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Üzgünüm, bir hata oluştu: $e',
            'isError': true,
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      height: 700, // Daha yüksek
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Mesaj Listesi
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.resources.dividerStrokeColorDefault,
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  // Arka plan chatbot figürü (şeffaf ikon)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.25,
                      child: Center(
                        child: Image.asset(
                          'assets/icons/Gemini_Generated_Image_qaf2ptqaf2ptqaf2.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              FluentIcons.robot,
                              size: 420,
                              color: theme.accentColor,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Chat mesajları
                  ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      final isError = msg['isError'] == true;
                      
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser 
                                ? theme.accentColor 
                                : (isError ? Colors.red.withOpacity(0.1) : theme.cardColor),
                            borderRadius: BorderRadius.circular(12).copyWith(
                              bottomRight: isUser ? const Radius.circular(0) : null,
                              bottomLeft: !isUser ? const Radius.circular(0) : null,
                            ),
                            border: !isUser ? Border.all(
                              color: isError ? Colors.red : theme.resources.dividerStrokeColorDefault,
                              width: 1,
                            ) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                Text(
                                  'Asistan',
                                  style: theme.typography.caption?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isError ? Colors.red : theme.accentColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                msg['content'] as String,
                                style: theme.typography.body?.copyWith(
                                  color: isUser ? Colors.white : theme.typography.body?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Asistan yazıyor...',
                    style: theme.typography.caption,
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Giriş Alanı
          Row(
            children: [
              Expanded(
                child: TextBox(
                  controller: _controller,
                  placeholder: 'Bir şeyler sorun... (Örn: Konya Bilim Merkezi\'nin otopark kapasitesi nedir?)',
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isLoading ? null : _sendMessage,
                child: const Icon(FluentIcons.send, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

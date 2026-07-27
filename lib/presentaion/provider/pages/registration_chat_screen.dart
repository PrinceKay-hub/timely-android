import 'package:booking/core/services/registration_chat_service.dart';
import 'package:flutter/material.dart';

const _purple = Color(0xFF8B5CF6);

class RegistrationChatScreen extends StatefulWidget {
  final List<String> categoryNames;

  const RegistrationChatScreen({super.key, required this.categoryNames});

  @override
  State<RegistrationChatScreen> createState() => _RegistrationChatScreenState();
}

class _RegistrationChatScreenState extends State<RegistrationChatScreen> {
  late final RegistrationChatService _service =
      RegistrationChatService(categoryNames: widget.categoryNames);
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isComplete = false;
  bool _isHandingOff = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      role: 'assistant',
      text: "Hi! Let's get your business set up. What's it called, and what kind of service do you offer?",
    ));
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading || _isComplete) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _inputController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final result = await _service.sendMessage(_messages);

      if (result.isComplete) {
        setState(() {
          _isComplete = true;
          _messages.add(ChatMessage(
            role: 'assistant',
            text: "Perfect, I've got everything I need! Setting up your profile...",
          ));
        });
        _scrollToBottom();
        setState(() => _isHandingOff = true);
        // Brief pause so the user actually sees the closing message
        // before the screen pops.
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.pop(context, result.profile);
      } else {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', text: result.question!));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          text: "Sorry, I'm having trouble right now. Mind trying that again?",
        ));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick setup chat'), elevation: 0),
      // resizeToAvoidBottomInset (true by default) handles keyboard avoidance
      // in Flutter automatically — Scaffold + AppBar already account for
      // the app bar height when the keyboard pushes content up.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading && !_isHandingOff ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    // Typing indicator, rendered in the assistant's position
                    return _buildTypingBubble();
                  }
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? _purple : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isHandingOff)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _purple),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Setting up your profile...',
                      style: TextStyle(color: _purple, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else if (!_isComplete)
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 10,
                  bottom: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        enabled: !_isLoading,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Type your answer...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading ? null : _send,
                      icon: Icon(Icons.send, color: _isLoading ? Colors.grey[400] : _purple),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const _TypingDots(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Three bouncing dots, used as the inline "AI is typing" indicator.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.repeat(reverse: true);
      });
      return controller;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            final t = _controllers[i].value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -3 * t),
                child: Opacity(
                  opacity: 0.3 + (0.7 * t),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

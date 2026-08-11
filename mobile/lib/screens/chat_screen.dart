// ignore_for_file: experimental_member_use

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import '../core/app_services.dart';
import '../core/api_client.dart';
import '../core/realtime_client.dart';
import '../core/voice_object_url.dart';
import '../core/voice_platform.dart';
import '../core/voice_recorder.dart';
import '../core/web_voice_player.dart';
import '../models/chat_models.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key, required this.user, required this.conversationId});
  final ChatUser user;
  final String conversationId;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  RealtimeClient? _realtime;
  bool _loading = true;
  bool _connected = false;
  bool _loadingPrevious = false;
  String? _cursor;
  String? _error;
  final _voiceRecorder = VoiceRecorder();
  final _previewPlayer = AudioPlayer();
  VoiceDraft? _voiceDraft;
  Duration _recordDuration = Duration.zero;
  bool _recording = false;
  bool _uploadingVoice = false;
  final _imagePicker = ImagePicker();
  XFile? _imageDraft;
  Uint8List? _imageDraftBytes;
  bool _uploadingImage = false;
  String get _currentUserId => AppServices.instance.session.user!.id;

  @override
  void initState() {
    super.initState();
    _voiceRecorder.onTick = (duration) {
      if (mounted) setState(() => _recordDuration = duration);
    };
    _loadInitial();
    _connect();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_recording) {
        final draft = await _voiceRecorder.stop();
        if (!mounted) return;
        setState(() {
          _recording = false;
          _voiceDraft = draft;
          _recordDuration = draft.duration;
        });
      } else {
        if (_voiceDraft != null) {
          await _cancelDraft();
        }
        await _voiceRecorder.start();
        if (mounted) {
          setState(() {
            _recording = true;
            _recordDuration = Duration.zero;
          });
        }
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not use the microphone: $error')));
      }
    }
  }

  Future<void> _cancelDraft() async {
    await _previewPlayer.stop();
    final draft = _voiceDraft;
    if (draft != null) {
      await deleteVoicePreview(draft.path);
    }
    if (mounted) {
      setState(() {
        _voiceDraft = null;
        _recordDuration = Duration.zero;
      });
    }
  }

  Future<void> _previewDraft() async {
    final draft = _voiceDraft;
    if (draft == null) return;
    try {
      if (_previewPlayer.playing) {
        await _previewPlayer.pause();
      } else {
        if (_previewPlayer.processingState == ProcessingState.idle) {
          await _previewPlayer.setUrl(voicePreviewUrl(draft.path));
        }
        if (_previewPlayer.processingState == ProcessingState.completed) {
          await _previewPlayer.seek(Duration.zero);
        }
        await _previewPlayer.play();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not preview this recording.')));
      }
    }
  }

  Future<void> _sendVoice() async {
    final draft = _voiceDraft;
    if (draft == null || _uploadingVoice) return;
    setState(() => _uploadingVoice = true);
    try {
      final bytes = await readVoiceBytes(draft.path);
      await AppServices.instance.api.uploadVoice(widget.conversationId,
          clientMessageId: const Uuid().v4(),
          duration: draft.duration,
          bytes: bytes,
          filename: draft.filename,
          contentType: draft.contentType);
      await _cancelDraft();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send voice message.')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingVoice = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
          source: source, imageQuality: 86, maxWidth: 1920, maxHeight: 1920);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw StateError('Image must be smaller than 10 MB.');
      }
      if (mounted) {
        setState(() {
          _imageDraft = file;
          _imageDraftBytes = bytes;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not select image: $error')));
      }
    }
  }

  void _showImageSource() {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Send a photo',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _SourceCard(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _pickImage(ImageSource.camera);
                            })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _SourceCard(
                            icon: Icons.photo_library_rounded,
                            label: 'Gallery',
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _pickImage(ImageSource.gallery);
                            }))
                  ])
                ]))));
  }

  Future<void> _sendImage() async {
    final file = _imageDraft;
    final bytes = _imageDraftBytes;
    if (file == null || bytes == null || _uploadingImage) return;
    setState(() => _uploadingImage = true);
    try {
      await AppServices.instance.api.uploadImage(widget.conversationId,
          clientMessageId: const Uuid().v4(),
          bytes: bytes,
          filename: file.name,
          contentType: file.mimeType ?? _imageContentType(file.name));
      if (mounted) {
        setState(() {
          _imageDraft = null;
          _imageDraftBytes = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send image.')));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _connect() {
    _realtime = RealtimeClient(
      token: AppServices.instance.session.token!,
      onMessage: (message) {
        if (message.conversationId != widget.conversationId || !mounted) return;
        final existing = _messages.indexWhere((item) => item.id == message.id);
        setState(() {
          if (existing >= 0) {
            _messages[existing] = message;
          } else {
            _messages.add(message);
          }
        });
        if (message.senderId != _currentUserId) {
          _acknowledgeIncoming(message.id);
        }
        _scrollToBottom();
      },
      onStatus: (event) {
        if (event.conversationId != widget.conversationId || !mounted) return;
        final index =
            _messages.indexWhere((item) => item.id == event.messageId);
        if (index >= 0) {
          setState(() => _messages[index] =
              _messages[index].withStatus(event.status, event.readAt));
        }
      },
      onError: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      },
      onConnectionChanged: (connected) {
        if (mounted) {
          setState(() => _connected = connected);
          if (connected) _markConversationRead();
        }
      },
    )..connect();
  }

  void _acknowledgeIncoming(String messageId) {
    try {
      _realtime?.acknowledgeDelivered(messageId);
      _realtime?.markConversationRead(widget.conversationId);
    } on StateError catch (_) {}
  }

  void _markConversationRead() {
    if (!_connected || _loading) return;
    try {
      _realtime?.markConversationRead(widget.conversationId);
    } on StateError catch (_) {}
  }

  Future<void> _loadInitial() async {
    try {
      final result =
          await AppServices.instance.api.messages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(result.$1);
        _cursor = result.$2;
        _loading = false;
      });
      _scrollToBottom();
      _markConversationRead();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load message history.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPrevious() async {
    if (_cursor == null || _loadingPrevious) return;
    setState(() => _loadingPrevious = true);
    try {
      final result = await AppServices.instance.api
          .messages(widget.conversationId, before: _cursor);
      if (mounted) {
        setState(() {
          _messages.insertAll(0, result.$1);
          _cursor = result.$2;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load older messages.')));
      }
    } finally {
      if (mounted) setState(() => _loadingPrevious = false);
    }
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      _realtime!.sendText(
          conversationId: widget.conversationId,
          text: text,
          clientMessageId: const Uuid().v4());
      _controller.clear();
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _insertEmoji(String emoji) {
    final value = _controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final updated = value.text.replaceRange(start, end, emoji);
    _controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + emoji.length));
  }

  void _showEmojiPicker() {
    const emojis = [
      '😀',
      '😂',
      '🥰',
      '😍',
      '😊',
      '😎',
      '🤩',
      '🥳',
      '😇',
      '🙂',
      '😉',
      '🤗',
      '🤔',
      '😴',
      '😭',
      '😅',
      '❤️',
      '💜',
      '🔥',
      '✨',
      '🎉',
      '👍',
      '👏',
      '🙏',
      '💯',
      '✅',
      '👀',
      '💬',
      '🎧',
      '🎤',
      '🚀',
      '🌟'
    ];
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Choose an emoji',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800))),
                    TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Done'))
                  ]),
                  GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4),
                      itemCount: emojis.length,
                      itemBuilder: (_, index) => InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _insertEmoji(emojis[index]),
                          child: Center(
                              child: Text(emojis[index],
                                  style: const TextStyle(fontSize: 25)))))
                ]))));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _realtime?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _voiceRecorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: Row(children: [
              UserAvatar(user: widget.user, radius: 19),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.user.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                Text(_connected ? 'Real-time connected' : 'Reconnecting…',
                    style: TextStyle(
                        fontSize: 11,
                        color: _connected
                            ? const Color(0xFFFFD45C)
                            : const Color(0xFFFFB58F)))
              ])
            ])),
        body: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF091126)
                : AppTheme.canvas,
            child: CustomPaint(
                painter: _ChatTexturePainter(
                    dark: Theme.of(context).brightness == Brightness.dark),
                child: Column(children: [
                  Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      Text(_error!),
                                      const SizedBox(height: 8),
                                      FilledButton.tonalIcon(
                                          onPressed: () {
                                            setState(() {
                                              _error = null;
                                              _loading = true;
                                            });
                                            _loadInitial();
                                          },
                                          icon:
                                              const Icon(Icons.refresh_rounded),
                                          label: const Text('Try again'))
                                    ]))
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 14, 16),
                                  itemCount: _messages.length + 1,
                                  itemBuilder: (_, index) {
                                    if (index == 0) {
                                      return _cursor == null
                                          ? const SizedBox(height: 8)
                                          : Center(
                                              child: TextButton.icon(
                                                  onPressed: _loadPrevious,
                                                  icon: _loadingPrevious
                                                      ? const SizedBox.square(
                                                          dimension: 15,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2))
                                                      : const Icon(Icons
                                                          .history_rounded),
                                                  label: const Text(
                                                      'Load previous messages')));
                                    }
                                    final message = _messages[index - 1];
                                    return _MessageBubble(
                                        message: message,
                                        mine:
                                            message.senderId == _currentUserId);
                                  })),
                  SafeArea(
                      top: false,
                      child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                  top: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: .35)))),
                          child: _imageDraftBytes != null
                              ? _ImageComposer(
                                  bytes: _imageDraftBytes!,
                                  uploading: _uploadingImage,
                                  onCancel: () => setState(() {
                                        _imageDraft = null;
                                        _imageDraftBytes = null;
                                      }),
                                  onSend: _sendImage)
                              : _voiceDraft != null || _recording
                                  ? _VoiceComposer(
                                      recording: _recording,
                                      uploading: _uploadingVoice,
                                      playingPreview: _previewPlayer.playing,
                                      duration: _recordDuration,
                                      onRecord: _toggleRecording,
                                      onPreview: _previewDraft,
                                      onCancel: _recording
                                          ? () async {
                                              await _voiceRecorder.cancel();
                                              if (mounted) {
                                                setState(() {
                                                  _recording = false;
                                                  _recordDuration =
                                                      Duration.zero;
                                                });
                                              }
                                            }
                                          : _cancelDraft,
                                      onSend: _sendVoice)
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                          Expanded(
                                              child: TextField(
                                                  key:
                                                      const Key('messageInput'),
                                                  controller: _controller,
                                                  minLines: 1,
                                                  maxLines: 5,
                                                  decoration: InputDecoration(
                                                      hintText:
                                                          'Write a message…',
                                                      prefixIcon: IconButton(
                                                          tooltip: 'Add emoji',
                                                          onPressed:
                                                              _showEmojiPicker,
                                                          icon: const Icon(Icons
                                                              .sentiment_satisfied_alt_rounded))))),
                                          const SizedBox(width: 8),
                                          IconButton.filledTonal(
                                              tooltip: 'Camera or gallery',
                                              onPressed: _showImageSource,
                                              icon: const Icon(Icons
                                                  .add_photo_alternate_rounded)),
                                          const SizedBox(width: 4),
                                          IconButton.filledTonal(
                                              key: const Key(
                                                  'recordVoiceButton'),
                                              onPressed: _toggleRecording,
                                              icon: const Icon(
                                                  Icons.mic_rounded)),
                                          const SizedBox(width: 4),
                                          IconButton.filled(
                                              key: const Key('sendButton'),
                                              onPressed:
                                                  _connected ? _sendText : null,
                                              icon: const Icon(
                                                  Icons.arrow_upward_rounded))
                                        ]))),
                ]))),
      );
}

class _ChatTexturePainter extends CustomPainter {
  const _ChatTexturePainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = const Color(0xFF0C4CF5).withValues(alpha: dark ? .10 : .055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final orange = Paint()
      ..color = const Color(0xFFFF5A1F).withValues(alpha: dark ? .11 : .06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dot = Paint()
      ..color = const Color(0xFF0C4CF5).withValues(alpha: dark ? .09 : .045);

    const cell = 118.0;
    for (double y = 34; y < size.height; y += cell) {
      for (double x = 28; x < size.width; x += cell) {
        final row = (y / cell).floor();
        final column = (x / cell).floor();
        final offsetX = row.isOdd ? 38.0 : 0.0;
        final center = Offset(x + offsetX, y);
        final variant = (row + column) % 4;
        if (variant == 0) {
          canvas.drawCircle(center, 3.2, dot);
          canvas.drawCircle(center + const Offset(11, 5), 1.8, dot);
        } else if (variant == 1) {
          final path = Path()
            ..moveTo(center.dx - 10, center.dy)
            ..quadraticBezierTo(
                center.dx, center.dy - 10, center.dx + 10, center.dy)
            ..quadraticBezierTo(
                center.dx, center.dy + 10, center.dx - 10, center.dy);
          canvas.drawPath(path, blue);
        } else if (variant == 2) {
          canvas.drawLine(
              center - const Offset(8, 0), center + const Offset(8, 0), orange);
          canvas.drawLine(
              center - const Offset(0, 8), center + const Offset(0, 8), orange);
          canvas.drawCircle(center, 2, dot);
        } else {
          final path = Path()
            ..moveTo(center.dx - 11, center.dy + 4)
            ..cubicTo(center.dx - 5, center.dy - 8, center.dx + 5,
                center.dy + 13, center.dx + 12, center.dy - 2);
          canvas.drawPath(path, blue);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatTexturePainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;
  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final _player = AudioPlayer();
  final _webPlayer = WebVoicePlayer();
  bool _loadingAudio = false;
  String? _voiceObjectUrl;
  Future<List<int>>? _imageFuture;

  bool get _playing => kIsWeb ? _webPlayer.playing : _player.playing;
  Stream<Duration> get _positionStream =>
      kIsWeb ? _webPlayer.positionStream : _player.positionStream;

  Future<void> _toggleAudio() async {
    if (_loadingAudio) return;
    try {
      if (_playing) {
        if (kIsWeb) {
          await _webPlayer.pause();
        } else {
          await _player.pause();
        }
      } else {
        final needsLoad = kIsWeb
            ? !_webPlayer.loaded
            : _player.processingState == ProcessingState.idle;
        if (needsLoad) {
          setState(() => _loadingAudio = true);
          final bytes = await AppServices.instance.api
              .voiceBytes(widget.message.voiceFileUrl!);
          final contentType =
              widget.message.voiceContentType ?? 'application/octet-stream';
          if (kIsWeb) {
            _voiceObjectUrl = createVoiceObjectUrl(bytes, contentType);
            await _webPlayer.load(_voiceObjectUrl!);
          } else {
            await _player.setAudioSource(_BytesAudioSource(bytes, contentType));
          }
        }
        if (kIsWeb
            ? _webPlayer.completed
            : _player.processingState == ProcessingState.completed) {
          if (kIsWeb) {
            await _webPlayer.seekToStart();
          } else {
            await _player.seek(Duration.zero);
          }
        }
        if (kIsWeb) {
          await _webPlayer.play();
        } else {
          await _player.play();
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not play voice message.')));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAudio = false);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _webPlayer.dispose();
    final objectUrl = _voiceObjectUrl;
    if (objectUrl != null) revokeVoiceObjectUrl(objectUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.mine ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Align(
        alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            constraints: const BoxConstraints(maxWidth: 310),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.fromLTRB(14, 10, 11, 7),
            decoration: BoxDecoration(
                color: widget.mine
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(widget.mine ? 20 : 6),
                    bottomRight: Radius.circular(widget.mine ? 6 : 20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .045),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (widget.message.type == MessageType.text)
                Text(widget.message.text ?? '',
                    style: TextStyle(color: foreground, fontSize: 15))
              else if (widget.message.type == MessageType.voice)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      onPressed: _toggleAudio,
                      icon: _loadingAudio
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: foreground))
                          : Icon(_playing ? Icons.pause : Icons.play_arrow,
                              color: foreground)),
                  SizedBox(
                      width: 120,
                      child: StreamBuilder<Duration>(
                          stream: _positionStream,
                          builder: (_, snapshot) {
                            final duration =
                                widget.message.voiceDuration ?? Duration.zero;
                            final position = snapshot.data ?? Duration.zero;
                            final max = duration.inMilliseconds <= 0
                                ? 1.0
                                : duration.inMilliseconds.toDouble();
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Waveform(
                                      progress: (position.inMilliseconds / max)
                                          .clamp(0, 1),
                                      color: foreground,
                                      seed: widget.message.id.hashCode),
                                  const SizedBox(height: 3),
                                  Text(_formatDuration(duration),
                                      style: TextStyle(
                                          color: foreground, fontSize: 11))
                                ]);
                          }))
                ])
              else
                GestureDetector(
                    onTap: () => _showImage(context),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: FutureBuilder<List<int>>(
                            future: _imageFuture ??= AppServices.instance.api
                                .imageBytes(widget.message.imageFileUrl!),
                            builder: (_, snapshot) {
                              if (snapshot.hasError) {
                                return const SizedBox(
                                    width: 220,
                                    height: 150,
                                    child: Center(
                                        child:
                                            Icon(Icons.broken_image_rounded)));
                              }
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                    width: 220,
                                    height: 150,
                                    child: Center(
                                        child: CircularProgressIndicator()));
                              }
                              return Image.memory(
                                  Uint8List.fromList(snapshot.data!),
                                  width: 220,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true);
                            }))),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    TimeOfDay.fromDateTime(widget.message.createdAt)
                        .format(context),
                    style: TextStyle(
                        color: foreground.withValues(alpha: .68),
                        fontSize: 10)),
                if (widget.mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                      widget.message.status == MessageStatus.sent
                          ? Icons.check
                          : Icons.done_all,
                      size: 14,
                      color: widget.message.status == MessageStatus.read
                          ? const Color(0xFF8FF5E8)
                          : foreground.withValues(alpha: .75))
                ]
              ])
            ])));
  }

  Future<void> _showImage(BuildContext context) async {
    try {
      final bytes = await (_imageFuture ??=
          AppServices.instance.api.imageBytes(widget.message.imageFileUrl!));
      if (!context.mounted) return;
      await showDialog<void>(
          context: context,
          builder: (_) => Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(children: [
                Center(
                    child: InteractiveViewer(
                        minScale: .8,
                        maxScale: 4,
                        child: Image.memory(Uint8List.fromList(bytes)))),
                SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton.filled(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded))))
              ])));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open image.')));
      }
    }
  }
}

// Native platforms can stream authenticated bytes directly into just_audio.
// The web branch uses HTMLAudioElement with a browser Blob URL instead.
class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this.bytes, this.contentType);
  final List<int> bytes;
  final String contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
        sourceLength: bytes.length,
        contentLength: end - start,
        offset: start,
        stream: Stream.value(bytes.sublist(start, end)),
        contentType: contentType);
  }
}

class _ImageComposer extends StatelessWidget {
  const _ImageComposer(
      {required this.bytes,
      required this.uploading,
      required this.onCancel,
      required this.onSend});

  final Uint8List bytes;
  final bool uploading;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child:
                Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Photo ready', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 3),
          Text('Send or choose another photo',
              style: TextStyle(fontSize: 12, color: Color(0xFF77758A)))
        ])),
        IconButton(
            tooltip: 'Cancel',
            onPressed: uploading ? null : onCancel,
            icon: const Icon(Icons.close_rounded)),
        IconButton.filled(
            tooltip: 'Send photo',
            onPressed: uploading ? null : onSend,
            icon: uploading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded))
      ]);
}

class _SourceCard extends StatelessWidget {
  const _SourceCard(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700))
          ])));
}

class _VoiceComposer extends StatelessWidget {
  const _VoiceComposer(
      {required this.recording,
      required this.uploading,
      required this.playingPreview,
      required this.duration,
      required this.onRecord,
      required this.onPreview,
      required this.onCancel,
      required this.onSend});
  final bool recording, uploading, playingPreview;
  final Duration duration;
  final VoidCallback onRecord, onPreview, onCancel, onSend;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: .35))),
      child: Row(children: [
        IconButton(
            onPressed: uploading ? null : onCancel,
            icon: const Icon(Icons.close_rounded)),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Waveform(
              progress: recording || playingPreview ? 1 : 0,
              color: recording
                  ? const Color(0xFFFF5A1F)
                  : Theme.of(context).colorScheme.primary,
              seed: duration.inMilliseconds ~/ 180,
              animated: recording),
          const SizedBox(height: 3),
          Text(
              recording
                  ? 'Recording  ${_formatDuration(duration)}'
                  : 'Preview  ${_formatDuration(duration)}',
              style: const TextStyle(fontSize: 12))
        ])),
        if (!recording)
          IconButton(
              onPressed: uploading ? null : onPreview,
              icon: Icon(playingPreview
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded)),
        if (recording)
          IconButton.filled(
              onPressed: onRecord, icon: const Icon(Icons.stop_rounded))
        else
          IconButton.filled(
              onPressed: uploading ? null : onSend,
              icon: uploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded))
      ]));
}

class _Waveform extends StatelessWidget {
  const _Waveform(
      {required this.progress,
      required this.color,
      required this.seed,
      this.animated = false});

  final double progress;
  final Color color;
  final int seed;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    const count = 24;
    return SizedBox(
        height: 32,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(count, (index) {
              final wave = math.sin((index + seed * .75) * 1.37).abs();
              final pulse = math.cos((index * .73) + seed).abs();
              final height = 7.0 + (wave * 16) + (animated ? pulse * 7 : 0);
              final played = index / count <= progress;
              return Expanded(
                  child: Align(
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: height.clamp(7, 30),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: played ? .92 : .2),
                              borderRadius: BorderRadius.circular(4)))));
            })));
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _imageContentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

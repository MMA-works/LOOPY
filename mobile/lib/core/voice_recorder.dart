import 'dart:async';
import 'package:record/record.dart';
import 'voice_platform.dart';

class VoiceDraft {
  const VoiceDraft(
      {required this.path,
      required this.duration,
      required this.filename,
      required this.contentType});
  final String path;
  final Duration duration;
  final String filename;
  final String contentType;
}

class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  DateTime? _startedAt;
  VoiceRecordingTarget? _target;
  void Function(Duration duration)? onTick;

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw StateError(
          'Microphone permission is required to record a voice message.');
    }
    _target = await createVoiceTarget();
    await _recorder.start(_target!.config, path: _target!.path);
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      onTick?.call(DateTime.now().difference(_startedAt!));
    });
  }

  Future<VoiceDraft> stop() async {
    final duration = DateTime.now().difference(_startedAt!);
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null || duration.inMilliseconds < 1) {
      throw StateError('No voice recording was captured.');
    }
    return VoiceDraft(
        path: path,
        duration: duration,
        filename: _target!.filename,
        contentType: _target!.contentType);
  }

  Future<void> cancel() async {
    _timer?.cancel();
    await _recorder.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
  }
}

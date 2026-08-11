import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WebVoicePlayer {
  final _positions = StreamController<Duration>.broadcast();
  web.HTMLAudioElement? _audio;
  Timer? _timer;

  bool get loaded => _audio != null;
  bool get playing => _audio != null && !_audio!.paused;
  bool get completed => _audio?.ended ?? false;
  Stream<Duration> get positionStream => _positions.stream;

  Future<void> load(String url) async {
    _audio?.pause();
    _audio = web.HTMLAudioElement()
      ..src = url
      ..preload = 'auto';
    _audio!.load();
  }

  Future<void> play() async {
    final audio = _audio;
    if (audio == null) return;
    await audio.play().toDart;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _positions
          .add(Duration(milliseconds: (audio.currentTime * 1000).round()));
      if (audio.ended) _timer?.cancel();
    });
  }

  Future<void> pause() async {
    _audio?.pause();
    _timer?.cancel();
  }

  Future<void> seekToStart() async {
    final audio = _audio;
    if (audio != null) audio.currentTime = 0;
    _positions.add(Duration.zero);
  }

  void dispose() {
    _timer?.cancel();
    _audio?.pause();
    _audio?.removeAttribute('src');
    _positions.close();
  }
}

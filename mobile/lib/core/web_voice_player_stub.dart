class WebVoicePlayer {
  bool get loaded => false;
  bool get playing => false;
  bool get completed => false;
  Stream<Duration> get positionStream => const Stream.empty();
  Future<void> load(String url) async {}
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> seekToStart() async {}
  void dispose() {}
}

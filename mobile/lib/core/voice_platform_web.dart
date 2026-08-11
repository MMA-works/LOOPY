import 'package:http/http.dart' as http;
import 'package:record/record.dart';

class VoiceRecordingTarget {
  const VoiceRecordingTarget(
      this.path, this.config, this.filename, this.contentType);
  final String path;
  final RecordConfig config;
  final String filename;
  final String contentType;
}

Future<VoiceRecordingTarget> createVoiceTarget() async {
  final filename = 'looply-${DateTime.now().microsecondsSinceEpoch}.webm';
  return VoiceRecordingTarget(filename,
      const RecordConfig(encoder: AudioEncoder.opus), filename, 'audio/webm');
}

Future<List<int>> readVoiceBytes(String path) async =>
    (await http.get(Uri.parse(path))).bodyBytes;
String voicePreviewUrl(String path) => path;
Future<void> deleteVoicePreview(String path) async {}

import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
  final directory = await getTemporaryDirectory();
  final filename = 'looply-${DateTime.now().microsecondsSinceEpoch}.m4a';
  return VoiceRecordingTarget(
      '${directory.path}${Platform.pathSeparator}$filename',
      const RecordConfig(encoder: AudioEncoder.aacLc),
      filename,
      'audio/mp4');
}

Future<List<int>> readVoiceBytes(String path) => File(path).readAsBytes();
String voicePreviewUrl(String path) => Uri.file(path).toString();
Future<void> deleteVoicePreview(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

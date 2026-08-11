import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String createVoiceObjectUrl(List<int> bytes, String contentType) {
  final data = Uint8List.fromList(bytes).toJS;
  final blob = web.Blob(
      <web.BlobPart>[data].toJS, web.BlobPropertyBag(type: contentType));
  return web.URL.createObjectURL(blob);
}

void revokeVoiceObjectUrl(String url) => web.URL.revokeObjectURL(url);

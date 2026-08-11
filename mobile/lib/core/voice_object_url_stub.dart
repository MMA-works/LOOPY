String createVoiceObjectUrl(List<int> bytes, String contentType) =>
    Uri.dataFromBytes(bytes, mimeType: contentType).toString();

void revokeVoiceObjectUrl(String url) {}

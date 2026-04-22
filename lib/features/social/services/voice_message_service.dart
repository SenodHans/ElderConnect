// VoiceMessageService — records audio and uploads to Supabase Storage.
// Audio stored in the private voice-messages bucket; URL inserted to
// voice_messages table. NOT processed by mood detection (by design).

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceMessageService {
  final AudioRecorder _recorder = AudioRecorder();

  // Starts recording to a temporary .m4a file.
  // Throws if microphone permission is denied.
  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );
  }

  // Stops recording and returns the file path, or null if nothing was recorded.
  Future<String?> stopRecording() => _recorder.stop();

  // Uploads the recorded file to Supabase Storage and inserts a voice_messages row.
  Future<void> sendVoiceMessage(String filePath) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final fileName = 'voice_${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final fileBytes = await File(filePath).readAsBytes();

    await client.storage.from('voice-messages').uploadBinary(
      fileName,
      fileBytes,
      fileOptions: const FileOptions(contentType: 'audio/m4a'),
    );

    final audioUrl = client.storage
        .from('voice-messages')
        .getPublicUrl(fileName);

    await client.from('voice_messages').insert({
      'sender_id': userId,
      'audio_url': audioUrl,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void dispose() => _recorder.dispose();
}

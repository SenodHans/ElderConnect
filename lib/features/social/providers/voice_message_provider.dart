// voice_message_provider.dart — recorder state for the Talk Button.
// States cycle: idle → recording → sending → sent / error → idle.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_message_service.dart';

enum VoiceMessageStatus { idle, recording, sending, sent, error }

class VoiceMessageState {
  const VoiceMessageState({
    this.status = VoiceMessageStatus.idle,
    this.errorMessage,
  });

  final VoiceMessageStatus status;
  final String? errorMessage;

  VoiceMessageState copyWith({VoiceMessageStatus? status, String? errorMessage}) =>
      VoiceMessageState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class VoiceMessageNotifier extends StateNotifier<VoiceMessageState> {
  VoiceMessageNotifier() : super(const VoiceMessageState());

  final _service = VoiceMessageService();

  Future<void> startRecording() async {
    try {
      await _service.startRecording();
      state = state.copyWith(status: VoiceMessageStatus.recording);
    } catch (e) {
      state = state.copyWith(
        status: VoiceMessageStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopAndSend() async {
    state = state.copyWith(status: VoiceMessageStatus.sending);
    try {
      final path = await _service.stopRecording();
      if (path == null) throw Exception('No audio recorded');
      await _service.sendVoiceMessage(path);
      state = state.copyWith(status: VoiceMessageStatus.sent);
      await Future.delayed(const Duration(seconds: 2));
      state = const VoiceMessageState();
    } catch (e) {
      state = state.copyWith(
        status: VoiceMessageStatus.error,
        errorMessage: 'Failed to send. Please try again.',
      );
    }
  }

  Future<void> cancelRecording() async {
    await _service.stopRecording();
    state = const VoiceMessageState();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

final voiceMessageProvider =
    StateNotifierProvider<VoiceMessageNotifier, VoiceMessageState>(
  (_) => VoiceMessageNotifier(),
);

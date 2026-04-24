/// Handles picking a photo from gallery and uploading it to the
/// post-photos Supabase Storage bucket.
///
/// Returns the public URL on success. Throws on failure.
library;

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoUploadService {
  PhotoUploadService(this._client);

  final SupabaseClient _client;
  final _picker = ImagePicker();

  /// Opens the device gallery. Returns null if the user cancels.
  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

  /// Opens the device camera. Returns null if the user cancels.
  Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

  /// Picks from [source]. Returns null if the user cancels.
  Future<XFile?> pick(ImageSource source) =>
      _picker.pickImage(source: source, imageQuality: 80);

  /// Uploads [file] under `{userId}/{timestamp}.jpg` in the post-photos bucket.
  /// Returns the public URL.
  Future<String> upload(XFile file) async {
    final userId = _client.auth.currentUser!.id;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$ts.jpg';
    final bytes = await file.readAsBytes();

    await _client.storage.from('post-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );

    return _client.storage.from('post-photos').getPublicUrl(path);
  }
}

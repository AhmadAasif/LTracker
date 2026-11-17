import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';

import '../data/store.dart';

class SecureBackup {
  static const _iterations = 210000;
  static final _cipher = AesGcm.with256bits();

  static Future<void> exportToFile(String password) async {
    _validatePassword(password);
    final plain = await Store.createBackup();
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _iterations, bits: 256);
    final key = await kdf.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    final box = await _cipher.encrypt(utf8.encode(plain), secretKey: key, nonce: nonce);
    final envelope = jsonEncode({
      'format': 'elora-encrypted-backup',
      'version': 1,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
    final bytes = Uint8List.fromList(utf8.encode(envelope));
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save encrypted ELORA backup',
      fileName: 'elora-backup-\${DateTime.now().toIso8601String().substring(0, 10)}.elora',
      mimeType: 'application/vnd.elora.backup',
      bytes: bytes,
    );
    if (path == null) throw const BackupCancelled();
  }

  static Future<void> importFromFile(String password) async {
    _validatePassword(password);
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['elora'],
    );
    if (file == null) throw const BackupCancelled();
    final bytes = await file.readAsBytes();
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map || decoded['format'] != 'elora-encrypted-backup' || decoded['version'] != 1) {
      throw const FormatException('This is not a supported encrypted ELORA backup.');
    }
    if (decoded['kdf'] != 'pbkdf2-hmac-sha256' || decoded['iterations'] != _iterations) {
      throw const FormatException('This backup uses an unsupported encryption format.');
    }
    final salt = base64Decode(decoded['salt'] as String);
    final nonce = base64Decode(decoded['nonce'] as String);
    final cipherText = base64Decode(decoded['cipherText'] as String);
    final mac = Mac(base64Decode(decoded['mac'] as String));
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _iterations, bits: 256);
    final key = await kdf.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    try {
      final clear = await _cipher.decrypt(SecretBox(cipherText, nonce: nonce, mac: mac), secretKey: key);
      await Store.restoreBackup(utf8.decode(clear));
    } on SecretBoxAuthenticationError {
      throw const FormatException('Wrong password or damaged backup file.');
    }
  }

  static void _validatePassword(String password) {
    if (password.length < 10) {
      throw const FormatException('Use a backup password with at least 10 characters.');
    }
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

class BackupCancelled implements Exception {
  const BackupCancelled();
}

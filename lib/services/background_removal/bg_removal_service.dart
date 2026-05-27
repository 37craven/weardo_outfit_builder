import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class BgRemovalService {
  final String baseUrl;
  final String? _username;
  final String? _password;

  BgRemovalService({
    this.baseUrl = 'http://localhost:8000',
    String? username,
    String? password,
  })  : _username = username,
        _password = password;

  Map<String, String> get _authHeaders {
    if (_username == null || _password == null) return {};
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    return {'Authorization': 'Basic $credentials'};
  }

  Future<Uint8List> removeBackground(Uint8List imageBytes) async {
    final uri = Uri.parse('$baseUrl/remove-bg');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders);
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
    ));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Background removal failed: ${response.statusCode}');
    }

    final bytes = await response.stream.toBytes();
    return bytes;
  }
}

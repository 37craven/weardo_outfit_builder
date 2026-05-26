import 'dart:typed_data';
import 'package:http/http.dart' as http;

class BgRemovalService {
  final String baseUrl;

  BgRemovalService({this.baseUrl = 'http://localhost:8000'});

  Future<Uint8List> removeBackground(Uint8List imageBytes) async {
    final uri = Uri.parse('$baseUrl/remove-bg');
    final request = http.MultipartRequest('POST', uri);
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

import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>?> _getJson(String url) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl('GET', Uri.parse(url));
    final resp = await req.close();
    if (resp.statusCode != 200) {
      print('Status != 200');
      return null;
    }

    final body = await resp.transform(utf8.decoder).join();
    return jsonDecode(body);
  } catch (e) {
    print('Exception: $e');
    return null;
  } finally {
    client.close();
  }
}

void main() async {
  final artist = 'Bad Bunny';
  final title = 'Yonaguni';
  
  final String query = Uri.encodeQueryComponent('${artist} ${title}'.trim());
  final url = 'https://itunes.apple.com/search?term=$query&entity=song&limit=1';
  print('URL: $url');
  
  final json = await _getJson(url);
  if (json == null || json['results'] == null || (json['results'] as List).isEmpty) {
    print('Failed or empty');
    return;
  }

  final result = json['results'][0];
  String? artworkUrl = result['artworkUrl100'];
  if (artworkUrl != null) {
    artworkUrl = artworkUrl.replaceAll('100x100bb.jpg', '600x600bb.jpg');
    print('Found: $artworkUrl');
  } else {
    print('No artwork');
  }
}

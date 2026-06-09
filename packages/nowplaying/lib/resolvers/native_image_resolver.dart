import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../nowplaying_track.dart';
import 'nowplaying_image_resolver.dart';

class NativeImageResolver implements NowPlayingImageResolver {
  static final RegExp _rationaliseRegExp = RegExp(r' - single|the |and |& |\(.*\)');

  Future<ImageProvider?> resolve(NowPlayingTrack track) async {
    if (track.hasImage) return null;

    final String query = Uri.encodeQueryComponent('${track.artist ?? ''} ${track.title ?? ''}'.trim());
    if (query.isEmpty) return null;

    final url = 'https://itunes.apple.com/search?term=$query&entity=song&limit=1';
    final json = await _getJson(url);
    if (json == null || json['results'] == null || (json['results'] as List).isEmpty) return null;

    final result = json['results'][0];
    String? artworkUrl = result['artworkUrl100'];
    if (artworkUrl != null) {
      artworkUrl = artworkUrl.replaceAll('100x100bb.jpg', '600x600bb.jpg');
      return NetworkImage(artworkUrl);
    }

    return null;
  }

  Future<Map<String, dynamic>?> _getJson(String url) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl('GET', Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) return null;

      final body = await resp.transform(utf8.decoder).join();
      return jsonDecode(body);
    } catch (e) {
      return null;
    } finally {
      client.close();
    }
  }

  String _rationalise(String text) {
    final lowerText = text.toLowerCase().trim();
    if (lowerText == 'the the') return lowerText; // the Matt Johnson exemption
    return lowerText.replaceAll(_rationaliseRegExp, '').trim();
  }
}

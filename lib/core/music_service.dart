import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MusicService {
  static final MusicService instance = MusicService._internal();
  MusicService._internal();

  ValueNotifier<NowPlayingTrack?> currentTrack = ValueNotifier(null);

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    
    try {
      final isEnabled = await NowPlaying.instance.isEnabled();
      if (!isEnabled) {
        await NowPlaying.instance.requestPermissions(force: true);
      }
      
      await NowPlaying.instance.start(resolveImages: true);
      NowPlaying.instance.stream.listen((track) {
        currentTrack.value = track;
      });
    } catch (e) {
      debugPrint("MusicService init error: $e");
    }
  }
}

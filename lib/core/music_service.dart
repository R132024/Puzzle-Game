import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class MusicService {
  static final MusicService instance = MusicService._internal();
  MusicService._internal();

  ValueNotifier<NowPlayingTrack?> currentTrack = ValueNotifier(null);
  ValueNotifier<Color> dominantColor = ValueNotifier(const Color(0xFF00E5FF)); // Default cyan

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final isEnabled = await NowPlaying.instance.isEnabled();
      if (!isEnabled) {
        await NowPlaying.instance.requestPermissions(force: true);
      }

      await NowPlaying.instance.start(resolveImages: true);
      NowPlaying.instance.stream.listen((track) async {
        currentTrack.value = track;
        
        if (track.hasImage && track.image != null) {
          try {
            final palette = await PaletteGenerator.fromImageProvider(
              track.image!,
              maximumColorCount: 10,
            );
            // Prioritize vibrant or dominant color
            final newColor = palette.vibrantColor?.color ?? palette.dominantColor?.color;
            if (newColor != null) {
              dominantColor.value = newColor;
            }
          } catch (e) {
            debugPrint("PaletteGenerator error: $e");
          }
        }
      });
    } catch (e) {
      debugPrint("MusicService init error: $e");
    }
  }
}

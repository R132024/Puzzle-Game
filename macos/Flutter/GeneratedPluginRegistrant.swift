//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_session
import audioplayers_darwin
import package_info_plus
import share_plus
import shared_preferences_foundation
import webview_flutter_wkwebview

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  AudioplayersDarwinPlugin.register(with: registry.registrar(forPlugin: "AudioplayersDarwinPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  SharePlusMacosPlugin.register(with: registry.registrar(forPlugin: "SharePlusMacosPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  WebViewFlutterPlugin.register(with: registry.registrar(forPlugin: "WebViewFlutterPlugin"))
}

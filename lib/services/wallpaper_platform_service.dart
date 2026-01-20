import 'package:flutter/services.dart';
import 'dart:io';

class WallpaperPlatformService {
  static const platform = MethodChannel('com.yourapp.wallpaper/set');

  /// Set wallpaper to lock screen
  static Future<bool> setAsLockScreen(String filePath) async {
    try {
      final result = await platform.invokeMethod('setWallpaper', {
        'filePath': filePath,
        'location': 'lock',
      });
      return result == true;
    } catch (e) {
      print('Error setting lock screen: $e');
      return false;
    }
  }

  /// Set wallpaper to home screen
  static Future<bool> setAsHomeScreen(String filePath) async {
    try {
      final result = await platform.invokeMethod('setWallpaper', {
        'filePath': filePath,
        'location': 'home',
      });
      return result == true;
    } catch (e) {
      print('Error setting home screen: $e');
      return false;
    }
  }

  /// Set wallpaper to both screens
  static Future<bool> setAsBothScreens(String filePath) async {
    try {
      final result = await platform.invokeMethod('setWallpaper', {
        'filePath': filePath,
        'location': 'both',
      });
      return result == true;
    } catch (e) {
      print('Error setting both screens: $e');
      return false;
    }
  }
}
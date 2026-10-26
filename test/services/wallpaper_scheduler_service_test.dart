import 'package:expense_tracker/services/wallpaper_scheduler_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'catch-up does not update wallpaper when automatic updates are off',
    () async {
      SharedPreferences.setMockInitialValues({'wallpaper_enabled': false});

      await WallpaperSchedulerService().runCatchUpIfNeeded();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_wallpaper_update'), isNull);
    },
  );
}

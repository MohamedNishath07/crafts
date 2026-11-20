import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/sqlitedatabase.dart';

/// Persisted theme preference (light / dark).
enum AppThemeMode { light, dark }

extension AppThemeModeExtension on AppThemeMode {
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  static AppThemeMode fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.system:
        return AppThemeMode.light;
    }
  }

  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light Mode';
      case AppThemeMode.dark:
        return 'Dark Mode';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }
}

/// User notification preferences persisted locally.
class NotificationSettings {
  final bool email;
  final bool sms;
  final bool push;

  const NotificationSettings({
    required this.email,
    required this.sms,
    required this.push,
  });

  NotificationSettings copyWith({bool? email, bool? sms, bool? push}) {
    return NotificationSettings(
      email: email ?? this.email,
      sms: sms ?? this.sms,
      push: push ?? this.push,
    );
  }

  static NotificationSettings fromMap(Map<String, dynamic> map) =>
      NotificationSettings(
        email: map['email'] == '1',
        sms: map['sms'] == '1',
        push: map['push'] == '1',
      );
}

/// Theme mode persisted in SQLite (app_settings). Defaults to light.
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light) {
    _load();
  }

  final _db = SQLiteDatabase();

  Future<void> _load() async {
    final value = await _db.getSetting('theme_mode');
    final mode = value != null
        ? AppThemeMode.values.firstWhere(
            (e) => e.name == value,
            orElse: () => AppThemeMode.light,
          )
        : AppThemeMode.light;
    state = mode;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await _db.setSetting('theme_mode', mode.name);
  }
}

/// Notification preferences persisted in SQLite (app_settings).
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier()
    : super(const NotificationSettings(email: true, sms: false, push: true)) {
    _load();
  }

  final _db = SQLiteDatabase();

  Future<void> _load() async {
    final email = await _getBool('notif_email', true);
    final sms = await _getBool('notif_sms', false);
    final push = await _getBool('notif_push', true);
    state = NotificationSettings(email: email, sms: sms, push: push);
  }

  Future<bool> _getBool(String key, bool defaultValue) async {
    final value = await _db.getSetting(key);
    if (value == null) return defaultValue;
    return value == '1';
  }

  Future<void> _setBool(String key, bool value) async {
    await _db.setSetting(key, value ? '1' : '0');
  }

  Future<void> setEmail(bool value) async {
    state = state.copyWith(email: value);
    await _setBool('notif_email', value);
  }

  Future<void> setSms(bool value) async {
    state = state.copyWith(sms: value);
    await _setBool('notif_sms', value);
  }

  Future<void> setPush(bool value) async {
    state = state.copyWith(push: value);
    await _setBool('notif_push', value);
  }
}

/// Provider for the persisted theme mode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
      return ThemeModeNotifier();
    });

/// Provider for the persisted notification preferences.
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((
      ref,
    ) {
      return NotificationSettingsNotifier();
    });

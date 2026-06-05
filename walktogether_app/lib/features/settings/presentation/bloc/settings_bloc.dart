import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/repositories/settings_repository.dart';

/// Settings state
class SettingsState {
  final UserSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  SettingsState copyWith({
    UserSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Settings Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(const SettingsState());

  /// Load settings from server
  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final settings = await _repository.getSettings();
      emit(state.copyWith(settings: settings, isLoading: false));
    } catch (e) {
      debugPrint('SettingsCubit.loadSettings error: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'settings.cannot_load'.tr(),
      ));
    }
  }

  /// Update daily goal steps
  Future<void> updateDailyGoal(int steps) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    try {
      final updated = await _repository.updateSettings(dailyGoalSteps: steps);
      emit(state.copyWith(
        settings: updated,
        isSaving: false,
        successMessage: 'settings.goal_updated',
      ));
    } catch (e) {
      debugPrint('SettingsCubit.updateDailyGoal error: $e');
      emit(state.copyWith(
        isSaving: false,
        error: 'settings.cannot_update_goal'.tr(),
      ));
    }
  }

  /// Toggle a notification setting
  Future<void> toggleNotification(String key, bool value) async {
    final current = state.settings?.notifications ?? const NotificationSettings();
    NotificationSettings updated;
    
    switch (key) {
      case 'chat':
        updated = current.copyWith(chat: value);
        break;
      case 'contest':
        updated = current.copyWith(contest: value);
        break;
      case 'dailyGoal':
        updated = current.copyWith(dailyGoal: value);
        break;
      case 'weeklyReport':
        updated = current.copyWith(weeklyReport: value);
        break;
      default:
        return;
    }

    // Optimistic update
    emit(state.copyWith(
      settings: state.settings?.copyWith(notifications: updated),
      clearSuccess: true,
    ));

    try {
      final result = await _repository.updateSettings(notifications: updated);
      emit(state.copyWith(settings: result));
    } catch (e) {
      debugPrint('SettingsCubit.toggleNotification error: $e');
      // Revert on error
      emit(state.copyWith(
        settings: state.settings?.copyWith(notifications: current),
        error: 'settings.cannot_update_notifications'.tr(),
      ));
    }
  }

  /// Update units preference
  Future<void> updateUnits(String units) async {
    final previous = state.settings?.units;
    
    // Optimistic update
    emit(state.copyWith(
      settings: state.settings?.copyWith(units: units),
      clearSuccess: true,
    ));

    try {
      final result = await _repository.updateSettings(units: units);
      emit(state.copyWith(settings: result));
    } catch (e) {
      debugPrint('SettingsCubit.updateUnits error: $e');
      emit(state.copyWith(
        settings: state.settings?.copyWith(units: previous),
        error: 'settings.cannot_update_units'.tr(),
      ));
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(state.copyWith(
        isSaving: false,
        successMessage: 'settings.password_changed',
      ));
      return true;
    } catch (e) {
      debugPrint('SettingsCubit.changePassword error: $e');
      String message = 'settings.cannot_change_password'.tr();
      if (e.toString().contains('401')) {
        message = 'settings.wrong_current_password'.tr();
      }
      emit(state.copyWith(isSaving: false, error: message));
      return false;
    }
  }

  /// Delete user account (soft delete)
  Future<bool> deleteAccount(String password) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    try {
      await _repository.deleteAccount(password);
      emit(state.copyWith(
        isSaving: false,
        successMessage: 'settings.account_deleted'.tr(),
      ));
      return true;
    } catch (e) {
      debugPrint('SettingsCubit.deleteAccount error: $e');
      String message = 'settings.cannot_delete_account'.tr();
      if (e.toString().contains('401')) {
        message = 'settings.wrong_password'.tr();
      }
      emit(state.copyWith(isSaving: false, error: message));
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

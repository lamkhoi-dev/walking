import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin Dart bridge over the native TikTok Business (App Events) SDK.
///
/// The SDK itself is initialized natively at app startup (AppDelegate on iOS,
/// RunlyApplication on Android) so that automatic Install/Launch events fire as
/// early as possible. This service only forwards in-app events, user identity,
/// logout and the iOS App Tracking Transparency prompt through a MethodChannel.
///
/// All calls are best-effort: any platform error is swallowed (logged in debug)
/// so analytics can never crash or block a user flow.
class TikTokAnalytics {
  TikTokAnalytics._();
  static final TikTokAnalytics instance = TikTokAnalytics._();
  factory TikTokAnalytics() => instance;

  static const MethodChannel _channel = MethodChannel('com.runly.app/tiktok');

  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } catch (e) {
      debugPrint('[TikTokAnalytics] $method failed: $e');
      return null;
    }
  }

  // ===== Lifecycle / identity =====

  /// iOS only: shows the App Tracking Transparency prompt (no-op on Android).
  /// Should be called once the app is active & a UI is on screen.
  Future<void> requestTracking() => _invoke('requestTracking');

  /// Associate subsequent events with a logged-in user (for better matching).
  Future<void> identify({
    required String externalId,
    String? userName,
    String? phone,
    String? email,
  }) =>
      _invoke('identify', {
        'externalId': externalId,
        if (userName != null) 'userName': userName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      });

  /// Clear the identified user (call on logout).
  Future<void> logout() => _invoke('logout');

  // ===== Generic event =====

  /// Track any event by name. [name] may be a TikTok standard event
  /// (e.g. "Registration", "Login", "Search") or a custom event name.
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? properties,
    String? eventId,
  }) =>
      _invoke('trackEvent', {
        'eventName': name,
        if (properties != null) 'properties': properties,
        if (eventId != null) 'eventId': eventId,
      });

  // ===== Typed helpers for the events that matter to Runly =====
  // Standard TikTok event names are used where one exists so they map to
  // optimization/attribution out of the box; the rest are custom names.

  Future<void> completeRegistration({String method = 'email'}) =>
      logEvent('Registration', properties: {'registration_method': method});

  Future<void> login({String method = 'email'}) =>
      logEvent('Login', properties: {'login_method': method});

  Future<void> search(String query) =>
      logEvent('Search', properties: {'search_string': query});

  Future<void> createGroup({String? groupId}) =>
      logEvent('CreateGroup', properties: {if (groupId != null) 'group_id': groupId});

  Future<void> joinGroup({String? groupId}) =>
      logEvent('JoinGroup', properties: {if (groupId != null) 'group_id': groupId});

  /// User published a post (custom event).
  Future<void> createPost({String? type, int mediaCount = 0}) => logEvent(
        'CreatePost',
        properties: {
          if (type != null) 'post_type': type,
          'media_count': mediaCount,
        },
      );

  /// User created a step contest (custom event).
  Future<void> createContest({String? contestId}) => logEvent(
        'CreateContest',
        properties: {if (contestId != null) 'contest_id': contestId},
      );

  /// User joined / opened a contest (custom event).
  Future<void> joinContest({String? contestId}) => logEvent(
        'JoinContest',
        properties: {if (contestId != null) 'contest_id': contestId},
      );

  /// User reached their daily step goal — maps to standard "AchieveLevel".
  Future<void> achieveDailyGoal({int? steps, int? goal}) => logEvent(
        'AchieveLevel',
        properties: {
          if (steps != null) 'steps': steps,
          if (goal != null) 'goal': goal,
        },
      );
}

/// Model for a leaderboard entry in a contest
class LeaderboardEntryModel {
  final String id;
  final String contestId;
  final String userId;
  final String fullName;
  final String? avatar;
  final int totalSteps;
  final Map<String, int> dailySteps;
  final int rank;
  /// displaySteps: steps to display (either totalSteps or daily steps if filtered)
  final int displaySteps;
  /// filterDate: the date filter applied (null = total)
  final String? filterDate;

  LeaderboardEntryModel({
    required this.id,
    required this.contestId,
    required this.userId,
    required this.fullName,
    this.avatar,
    required this.totalSteps,
    this.dailySteps = const {},
    required this.rank,
    int? displaySteps,
    this.filterDate,
  }) : displaySteps = displaySteps ?? totalSteps;

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    // Parse user info
    String userId;
    String fullName;
    String? avatar;
    if (json['userId'] is Map) {
      final u = json['userId'] as Map<String, dynamic>;
      userId = u['_id'] as String? ?? '';
      fullName = u['fullName'] as String? ?? '';
      avatar = u['avatar'] as String?;
    } else {
      userId = json['userId'] as String? ?? '';
      fullName = '';
    }

    // Parse daily steps
    Map<String, int> dailySteps = {};
    if (json['dailySteps'] is Map) {
      final ds = json['dailySteps'] as Map<String, dynamic>;
      for (final entry in ds.entries) {
        dailySteps[entry.key] = (entry.value as num).toInt();
      }
    }

    final totalSteps = (json['totalSteps'] as num?)?.toInt() ?? 0;
    final displaySteps = (json['displaySteps'] as num?)?.toInt() ?? totalSteps;

    return LeaderboardEntryModel(
      id: json['_id'] as String? ?? '',
      contestId: json['contestId'] as String? ?? '',
      userId: userId,
      fullName: fullName,
      avatar: avatar,
      totalSteps: totalSteps,
      dailySteps: dailySteps,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      displaySteps: displaySteps,
      filterDate: json['filterDate'] as String?,
    );
  }

  /// Get today's steps from dailySteps map
  int get todaySteps {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return dailySteps[today] ?? 0;
  }

  /// Distance in meters
  int get distance => (totalSteps * 0.762).round();

  /// Calories burned
  double get calories => (totalSteps * 0.04 * 100).roundToDouble() / 100;
}

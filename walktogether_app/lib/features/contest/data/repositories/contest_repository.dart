import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/contest_model.dart';
import '../models/leaderboard_entry_model.dart';

class ContestRepository {
  final DioClient _dio;

  ContestRepository({required DioClient dio}) : _dio = dio;

  /// Create a new contest
  Future<ContestModel> createContest({
    required String name,
    String? description,
    required String groupId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.post(ApiEndpoints.contests, data: {
      'name': name,
      'description': description ?? '',
      'groupId': groupId,
      'startDate': startDate,
      'endDate': endDate,
    });
    return ContestModel.fromJson(response.data['data']);
  }

  /// Get contests, optionally filtered by group
  Future<List<ContestModel>> getContests({String? groupId}) async {
    final queryParams = <String, dynamic>{};
    if (groupId != null) queryParams['groupId'] = groupId;

    final response = await _dio.get(
      ApiEndpoints.contests,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data['data'] as List? ?? [];
    return data
        .map((json) => ContestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a contest by ID
  Future<ContestModel> getContestById(String id) async {
    final response = await _dio.get(ApiEndpoints.contestDetail(id));
    return ContestModel.fromJson(response.data['data']);
  }

  /// Update a contest
  Future<ContestModel> updateContest(
    String id, {
    String? name,
    String? description,
    String? startDate,
    String? endDate,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (startDate != null) data['startDate'] = startDate;
    if (endDate != null) data['endDate'] = endDate;

    final response = await _dio.put(ApiEndpoints.contestDetail(id), data: data);
    return ContestModel.fromJson(response.data['data']);
  }

  /// Cancel a contest
  Future<void> cancelContest(String id) async {
    await _dio.delete(ApiEndpoints.contestDetail(id));
  }

  /// Get leaderboard for a contest
  Future<List<LeaderboardEntryModel>> getLeaderboard(String contestId) async {
    final response = await _dio.get(ApiEndpoints.contestLeaderboard(contestId));
    final data = response.data['data'] as List? ?? [];
    return data
        .map((json) =>
            LeaderboardEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get active contest for a group
  Future<ContestModel?> getActiveContestByGroup(String groupId) async {
    final response =
        await _dio.get(ApiEndpoints.contestActiveByGroup(groupId));
    final data = response.data['data'];
    if (data == null) return null;
    return ContestModel.fromJson(data as Map<String, dynamic>);
  }
}

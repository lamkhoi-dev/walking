import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';

class GroupRepository {
  final DioClient _dio;

  GroupRepository({required DioClient dio}) : _dio = dio;

  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? avatar,
    List<String> memberIds = const [],
  }) async {
    final response = await _dio.post(
      ApiEndpoints.groups,
      data: {
        'name': name,
        'description': description,
        'memberIds': memberIds,
        if (avatar != null) 'avatar': avatar,
      },
    );
    return GroupModel.fromJson(response.data['data']);
  }

  /// Get all groups for current user
  Future<List<GroupModel>> getGroups() async {
    final response = await _dio.get(ApiEndpoints.groups);
    final list = response.data['data'] as List;
    return list
        .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  /// Get group detail by ID
  Future<GroupModel> getGroupById(String groupId) async {
    final response = await _dio.get(ApiEndpoints.groupDetail(groupId));
    return GroupModel.fromJson(response.data['data']);
  }

  /// Update group
  Future<GroupModel> updateGroup(String groupId, Map<String, dynamic> data) async {
    final response = await _dio.put(
      ApiEndpoints.groupDetail(groupId),
      data: data,
    );
    return GroupModel.fromJson(response.data['data']);
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    await _dio.delete(ApiEndpoints.groupDetail(groupId));
  }

  /// Add members to group
  Future<GroupModel> addMembers(String groupId, List<String> memberIds) async {
    final response = await _dio.post(
      ApiEndpoints.groupMembers(groupId),
      data: {'memberIds': memberIds},
    );
    return GroupModel.fromJson(response.data['data']);
  }

  /// Remove member from group
  Future<GroupModel> removeMember(String groupId, String userId) async {
    final response = await _dio.delete(
      '${ApiEndpoints.groupMembers(groupId)}/$userId',
    );
    return GroupModel.fromJson(response.data['data']);
  }

  /// Search groups by name
  Future<List<GroupModel>> searchGroups(String query) async {
    final response = await _dio.get(
      '${ApiEndpoints.groups}/search',
      queryParameters: {'q': query},
    );
    final list = response.data['data'] as List;
    return list
        .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  /// Join group by QR code (groupId)
  Future<GroupModel> joinByQR(String groupId) async {
    final response = await _dio.post(ApiEndpoints.groupJoin(groupId));
    return GroupModel.fromJson(response.data['data']);
  }

  /// Get company members (for member selection)
  Future<List<MemberModel>> getCompanyMembers({String? search}) async {
    final Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    final response = await _dio.get(
      ApiEndpoints.companyMembers,
      queryParameters: params,
    );
    final list = response.data['data'] as List;
    return list
        .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}

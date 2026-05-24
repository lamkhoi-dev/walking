/// Friendship status between current user and another user
enum FriendshipStatus {
  none,
  pendingSent,
  pendingReceived,
  friends,
  self,
}

FriendshipStatus friendshipStatusFromString(String? status) {
  switch (status) {
    case 'pending_sent':
      return FriendshipStatus.pendingSent;
    case 'pending_received':
      return FriendshipStatus.pendingReceived;
    case 'friends':
      return FriendshipStatus.friends;
    case 'self':
      return FriendshipStatus.self;
    default:
      return FriendshipStatus.none;
  }
}

/// A user in friend context
class FriendUser {
  final String id;
  final String fullName;
  final String? avatar;
  final String? role;
  final String? companyId;
  final FriendshipStatus friendshipStatus;
  final String? friendshipId;
  final DateTime? friendsSince;

  const FriendUser({
    required this.id,
    required this.fullName,
    this.avatar,
    this.role,
    this.companyId,
    this.friendshipStatus = FriendshipStatus.none,
    this.friendshipId,
    this.friendsSince,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      role: json['role'] as String?,
      companyId: json['companyId']?.toString(),
      friendshipStatus: friendshipStatusFromString(json['friendshipStatus'] as String?),
      friendshipId: json['friendshipId']?.toString(),
      friendsSince: json['friendsSince'] != null
          ? DateTime.tryParse(json['friendsSince'].toString())
          : null,
    );
  }
}

/// Friend request model (incoming/sent)
class FriendRequest {
  final String friendshipId;
  final FriendUser user;
  final DateTime sentAt;

  const FriendRequest({
    required this.friendshipId,
    required this.user,
    required this.sentAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      friendshipId: json['friendshipId']?.toString() ?? '',
      user: FriendUser.fromJson(json['user'] as Map<String, dynamic>),
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// User profile data (for viewing other users' profiles)
class UserProfile {
  final FriendUser user;
  final UserCompanyInfo? company;
  final FriendshipStatus friendshipStatus;
  final String? friendshipId;
  final int friendCount;

  const UserProfile({
    required this.user,
    this.company,
    this.friendshipStatus = FriendshipStatus.none,
    this.friendshipId,
    this.friendCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;
    final friendshipData = json['friendship'] as Map<String, dynamic>?;

    return UserProfile(
      user: FriendUser.fromJson(userData),
      company: userData['company'] != null
          ? UserCompanyInfo.fromJson(userData['company'] as Map<String, dynamic>)
          : null,
      friendshipStatus: friendshipStatusFromString(friendshipData?['status'] as String?),
      friendshipId: friendshipData?['friendshipId']?.toString(),
      friendCount: (json['friendCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserCompanyInfo {
  final String id;
  final String name;
  final String? logo;
  final String status;

  const UserCompanyInfo({
    required this.id,
    required this.name,
    this.logo,
    this.status = 'approved',
  });

  factory UserCompanyInfo.fromJson(Map<String, dynamic> json) {
    return UserCompanyInfo(
      id: json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      status: json['status'] as String? ?? 'approved',
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:urbanharmony/models/comment.dart';
import 'package:urbanharmony/models/post.dart';
import 'package:urbanharmony/models/user.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/database/database_service.dart';

class DatabaseProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _db = DatabaseService();

  //user profile
  Future<UserProfile?> userProfile(String uid) => _db.getUserFromFirebase(uid);

  Future<void> updateBio(String bio) => _db.updateUserBioInFirebase(bio);

  Future<void> updateAvatar(String image) => _db.updateAvatarInFirebase(image);

  //post

  //list of posts

  List<Post> _allPosts = [];
  List<Post> _followingPosts = [];
  List<Post> _reportPosts = [];

  //get posts
  List<Post> get allPosts => _allPosts;
  List<Post> get followingPosts => _followingPosts;
  List<Post> get reportPosts => _reportPosts;


  //post message
  Future<void> postMessage(String message, imageUrl) async {
    await _db.postMessageInFirebase(message, imageUrl);
    await loadAllPosts();
  }

  //fetch all posts
  Future<void> loadAllPosts() async {
    final allPosts = await _db.getAllPostsFromFirebase();

    //get blocked users
    final blockedUserIds = await _db.getBlockedUidsFromFirebase();

    _allPosts =
        allPosts.where((post) => !blockedUserIds.contains(post.uid)).toList();
    loadFollowingPosts();
    loadReportPost();

    initializeLikeMap();

    notifyListeners();
  }

  //post of uid

  List<Post> filterUserPosts(String uid) {
    return _allPosts.where((post) => post.uid == uid).toList();
  }

  Future<void> loadFollowingPosts() async {
    String currentUid = _auth.getCurrentUID();
    final followingUserIds = await _db.getFollowingUidsFromFirebase(currentUid);
    _followingPosts =
        _allPosts.where((post) => followingUserIds.contains(post.uid)).toList();
    notifyListeners();
  }

  //delete post
  Future<void> deletePost(String postId) async {
    await _db.deletePostFromFirebase(postId);
    await loadAllPosts();
  }

  //track like count each post
  Map<String, int> _likeCounts = {};
  //track post like by current user
  List<String> _likedPosts = [];
  //check if like post
  bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);
  //like count
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  void initializeLikeMap() {
    final currentUserID = _auth.getCurrentUID();
    for (var post in _allPosts) {
      _likeCounts[post.id] = post.likes;

      if (post.likedBy.contains(currentUserID)) {
        _likedPosts.add(post.id);
      }
    }
  }

  //toggle like
  Future<void> toggleLike(String postId) async {
    final likedPostOriginal = _likedPosts;
    final likedCountsOriginal = _likeCounts;

    if (_likedPosts.contains(postId)) {
      _likedPosts.remove(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
    } else {
      _likedPosts.add(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    }

    //update local ui
    notifyListeners();

    //update in database
    try {
      await _db.toggleLikeInFirebase(postId);
    } catch (e) {
      _likedPosts = likedPostOriginal;
      _likeCounts = likedCountsOriginal;

      notifyListeners();
    }
  }

  //comment
  //local list comment
  final Map<String, List<Comment>> _comments = {};

  //get comment locally
  List<Comment> getComments(String postId) => _comments[postId] ?? [];

  //fetch comment from database
  Future<void> loadComments(String postId) async {
    //get all comment
    final allComments = await _db.getCommentsFromFirebase(postId);
    //update local data
    _comments[postId] = allComments;
    //update ui
    notifyListeners();
  }

  //add comment
  Future<void> addComment(String postId, message) async {
    //add to firebase
    await _db.addCommentInFirebase(postId, message);
    //reload comment
    await loadComments(postId);
  }

  //delete comment
  Future<void> deleteComment(String commentId, postId) async {
    await _db.deleteCommentInFirebase(commentId);

    await loadComments(postId);
  }

  //Local blocked list

  List<UserProfile> _blockedUsers = [];

  //get list blocked users
  List<UserProfile> get blockedUsers => _blockedUsers;

  //fetch blocked users
  Future<void> loadBlockedUsers() async {
    final blockedUserIds = await _db.getBlockedUidsFromFirebase();

    final blockedUsersData = await Future.wait(blockedUserIds.map(
      (id) => _db.getUserFromFirebase(id),
    ));

    //return list
    _blockedUsers = blockedUsersData.whereType<UserProfile>().toList();

    notifyListeners();
  }


  Future<void> blockUser(String userId) async {
    await _db.blockUserInFirebase(userId);

    //reload block users
    await loadBlockedUsers();

    //reload post

    await loadAllPosts();

    notifyListeners();
  }

  //unlock
  Future<void> unblockUser(String blockedUserId) async {
    await _db.unblockUserInFirebase(blockedUserId);

    //reload block users
    await loadBlockedUsers();

    //reload post

    await loadAllPosts();

    notifyListeners();
  }
  //report

  Future<void> reportUser(String postId, userId) async {
    await _db.reportUserInFirebase(postId, userId);
  }

  Future<void> loadReportPost() async {
    final reportID = await _db.getReportIdsFromFirebase();
    print(reportID);
    _reportPosts =
        _allPosts.where((post) => reportID.contains(post.id)).toList();
    print(_reportPosts);
    notifyListeners();
  }

  //follow

  final Map<String, List<String>> _followers = {};
  final Map<String, List<String>> _following = {};
  final Map<String, int> _followerCount = {};
  final Map<String, int> _followingCount = {};

  int getFollowerCount(String uid) => _followerCount[uid] ?? 0;
  int getFollowingCount(String uid) => _followingCount[uid] ?? 0;

  //load follower
  Future<void> loadUserFollowers(String uid) async {
    //get list follower from firebase

    final listOfFollowerUids = await _db.getFollowerUidsFromFirebase(uid);

    //update local data
    _followers[uid] = listOfFollowerUids;
    _followerCount[uid] = listOfFollowerUids.length;

    notifyListeners();
  }

  //load following
  Future<void> loadUserFollowing(String uid) async {
    //get list following from firebase

    final listOfFollowingUids = await _db.getFollowingUidsFromFirebase(uid);

    //update local data
    _following[uid] = listOfFollowingUids;
    _followingCount[uid] = listOfFollowingUids.length;

    notifyListeners();
  }

//follow user
  Future<void> followUser(String targetUserId) async {
    final currentUserId = _auth.getCurrentUID();
    _following.putIfAbsent(currentUserId, () => []);
    _followers.putIfAbsent(currentUserId, () => []);

    //follower if current is not targer followers

    if (!_followers[targetUserId]!.contains(currentUserId)) {
      //add current user
      _followers[targetUserId]?.add(currentUserId);
      //update follower count
      _followerCount[targetUserId] = (_followerCount[targetUserId] ?? 0) + 1;
      //add user to following
      _following[currentUserId]?.add(targetUserId);
      //update following count
      _followingCount[currentUserId] =
          (_followingCount[currentUserId] ?? 0) + 1;
    }
    notifyListeners();

    try {
      //follow user in firebase
      await _db.followUserInFirebase(targetUserId);
      //reload follower
      await loadUserFollowers(currentUserId);
      //reload following
      await loadUserFollowing(currentUserId);
    } catch (e) {
      //remove current from follower
      _followers[targetUserId]?.remove(currentUserId);
      //update follower count
      _followingCount[targetUserId] = (_followerCount[targetUserId] ?? 0) - 1;
      //remove curent from following
      _following[currentUserId]?.remove(targetUserId);
      //update following count
      _followingCount[currentUserId] =
          (_followingCount[currentUserId] ?? 0) - 1;

      notifyListeners();
    }
  }

//unfollow user

  Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = _auth.getCurrentUID();
    _following.putIfAbsent(currentUserId, () => []);
    _followers.putIfAbsent(currentUserId, () => []);

    if (_followers[targetUserId]!.contains(currentUserId)) {
      //remove current user
      _followers[targetUserId]?.remove(currentUserId);
      //update follower count
      _followerCount[targetUserId] = (_followerCount[targetUserId] ?? 0) - 1;
      //remove user to following
      _following[currentUserId]?.remove(targetUserId);
      //update following count
      _followingCount[currentUserId] =
          (_followingCount[currentUserId] ?? 0) - 1;
    }
    notifyListeners();
    try {
      //unfollow user in firebase
      await _db.unfollowUserInFirebase(targetUserId);
      //reload follower
      await loadUserFollowers(currentUserId);
      //reload following
      await loadUserFollowing(currentUserId);
    } catch (e) {
      //add current from follower
      _followers[targetUserId]?.add(currentUserId);
      //update follower count
      _followingCount[targetUserId] = (_followerCount[targetUserId] ?? 0) + 1;
      //add current from following
      _following[currentUserId]?.add(targetUserId);
      //update following count
      _followingCount[currentUserId] =
          (_followingCount[currentUserId] ?? 0) + 1;

      notifyListeners();
    }
  }

  //check if currently following target
  bool isFollowing(String uid) {
    final currentUserId = _auth.getCurrentUID();
    return _followers[uid]?.contains(currentUserId) ?? false;
  }

  //get list follow
  final Map<String, List<UserProfile>> _followersProfile = {};
  final Map<String, List<UserProfile>> _followingProfile = {};

  List<UserProfile> getListOfFollowersProfile(String uid) =>
      _followersProfile[uid] ?? [];
  List<UserProfile> getListOfFollowingProfile(String uid) =>
      _followingProfile[uid] ?? [];

  Future<void> loadUserFollowerProfiles(String uid) async {
    try {
      final followerIds = await _db.getFollowerUidsFromFirebase(uid);

      List<UserProfile> followerProfiles = [];

      for (String followerId in followerIds) {
        UserProfile? followerProfile =
            await _db.getUserFromFirebase(followerId);

        if (followerProfile != null) {
          followerProfiles.add(followerProfile);
        }
      }
      _followersProfile[uid] = followerProfiles;
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadUserFollowingProfiles(String uid) async {
    try {
      final followingIds = await _db.getFollowingUidsFromFirebase(uid);

      List<UserProfile> followingProfiles = [];

      for (String followingId in followingIds) {
        UserProfile? followingProfile =
            await _db.getUserFromFirebase(followingId);

        if (followingProfile != null) {
          followingProfiles.add(followingProfile);
        }
      }
      _followingProfile[uid] = followingProfiles;
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  //search
  List<UserProfile> _searchResults = [];
  List<UserProfile> get searchResult => _searchResults;
  Future<void> searchUsers(String searchTerm) async {
    try {
      final results = await _db.searchUsersInFirebase(searchTerm);

      _searchResults = results;

      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}

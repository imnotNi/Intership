import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:urbanharmony/models/comment.dart';
import 'package:urbanharmony/models/post.dart';
import 'package:urbanharmony/models/user.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/storage/storage_service.dart';

class DatabaseService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  //user profile
  //save user profile
  Future<void> saveUserInfoInFirebase({
    required String name,
    required String email,
  }) async {
    //get current uid
    String uid = _auth.currentUser!.uid;
    String username = email.split('@')[0];

    UserProfile user = UserProfile(
        email: email, uid: uid, name: name, username: username, bio: '',role: '',imageUrl: '');

    final userMap = user.toMap();

    await _db.collection("Users").doc(uid).set(userMap);
  }
  //get user info

  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection("Users").doc(uid).get();

      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }
  //update bio

  Future<void> updateUserBioInFirebase(String bio) async {
    String uid = AuthService().getCurrentUID();
    try {
      await _db.collection("Users").doc(uid).update({'bio': bio});
    } catch (e) {
      print(e);
      return null;
    }
  }
  Future<void> updateAvatarInFirebase(String imageUrl) async {
    String uid = AuthService().getCurrentUID();
    try {
      await _db.collection("Users").doc(uid).update({'imageUrl': imageUrl});
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _db.collection("Users").doc(uid).update({'role': role});
    } catch (e) {
      print(e);
    }
  }

  //delete user
  Future<void> deleteUserInfoFromFirebase(String uid) async {
    WriteBatch batch = _db.batch();

    DocumentReference userDoc = _db.collection("Users").doc(uid);
    //delete post
    QuerySnapshot userPosts =
        await _db.collection("Posts").where('uid', isEqualTo: uid).get();

    for (var post in userPosts.docs) {
      batch.delete(post.reference);
    }
    //delete report
    QuerySnapshot reportPosts =
    await _db.collection("Reports").where('messageOwnerId', isEqualTo: uid).get();

    for (var report in reportPosts.docs) {
      batch.delete(report.reference);
    }
    //delete comment
    QuerySnapshot userComments =
        await _db.collection("Comments").where('uid', isEqualTo: uid).get();

    for (var comment in userComments.docs) {
      batch.delete(comment.reference);
    }

    //delete like
    QuerySnapshot allPosts = await _db.collection("Posts").get();
    for (QueryDocumentSnapshot post in allPosts.docs) {
      Map<String, dynamic> postData = post.data() as Map<String, dynamic>;
      var likedBy = postData['likedBy'] as List<dynamic>? ?? [];
      if (likedBy.contains(uid)) {
        batch.update(post.reference, {
          'likedBy': FieldValue.arrayRemove([uid]),
          'likes': FieldValue.increment(-1),
        });
      }
    }

    await batch.commit();
  }

  //post

  //post to database
  Future<void> postMessageInFirebase(String message, String imageUrl) async {
    try {
      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserFromFirebase(uid);

      //create new post
      Post newPost = Post(
          id: '',
          uid: uid,
          name: user!.name,
          username: user.username,
          message: message,
          timestamp: Timestamp.now(),
          likes: 0,
          likedBy: [],
          imageUrl: imageUrl);

      //post to map

      Map<String, dynamic> newPostMap = newPost.toMap();
      print(newPostMap);
      await _db.collection("Posts").add(newPostMap);
    } catch (e) {
      print(e);
      throw Exception('Failed to add product: $e');
      return null;
    }
  }

  //get all post
  Future<List<Post>> getAllPostsFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Posts")
          .orderBy("timestamp", descending: true)
          .get();

      return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }
  //delete post

  Future<void> deletePostFromFirebase(String postId) async {
    try {
      WriteBatch batch = _db.batch();
      final snapshot = await _db.collection("Posts").doc(postId).get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('imageUrl')) {
          StorageService().deleteImages( data['imageUrl']);
        }
      }

      await _db.collection("Posts").doc(postId).delete();
      final reportSnapshot = await _db.collection("Reports")
          .where("messageId", isEqualTo: postId)
          .get();

      for (final reportDoc in reportSnapshot.docs) {
        await reportDoc.reference.delete();
      }
           //delete comment
      QuerySnapshot userComments =
      await _db.collection("Comments").where('postId', isEqualTo: postId).get();

      for (var comment in userComments.docs) {
        batch.delete(comment.reference);
      }

      //delete like
      QuerySnapshot allPosts = await _db.collection("Posts").get();
      for (QueryDocumentSnapshot post in allPosts.docs) {
        Map<String, dynamic> postData = post.data() as Map<String, dynamic>;
        var likedBy = postData['likedBy'] as List<dynamic>? ?? [];
        if (likedBy.contains(postId)) {
          batch.update(post.reference, {
            'likedBy': FieldValue.arrayRemove([postId]),
            'likes': FieldValue.increment(-1),
          });
        }
      }

    } catch (e) {
      print(e);
    }
  }

  //like
  //like post
  Future<void> toggleLikeInFirebase(String postId) async {
    try {
      String uid = _auth.currentUser!.uid;

      DocumentReference postDoc = _db.collection("Posts").doc(postId);
      await _db.runTransaction(
        (transaction) async {
          DocumentSnapshot postSnapshot = await transaction.get(postDoc);

          List<String> likedBy =
              List<String>.from(postSnapshot['likedBy'] ?? []);

          int currentLikeCount = postSnapshot['likes'];
          //if not like
          if (!likedBy.contains(uid)) {
            likedBy.add(uid);
            currentLikeCount++;
          }
          //if already like
          else {
            likedBy.remove(uid);

            currentLikeCount--;
          }
          //update in firebase
          transaction.update(postDoc, {
            'likes': currentLikeCount,
            'likedBy': likedBy,
          });
        },
      );
    } catch (e) {
      print(e);
    }
  }

  //comment

  //add comment
  Future<void> addCommentInFirebase(String postId, message) async {
    try {
      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserFromFirebase(uid);

      Comment newComment = Comment(
        id: '',
        postId: postId,
        uid: uid,
        name: user!.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
      );
      Map<String, dynamic> newCommentMap = newComment.toMap();
      await _db.collection("Comments").add(newCommentMap);
    } catch (e) {
      print(e);
    }
  }

  //delete comment
  Future<void> deleteCommentInFirebase(String commentId) async {
    try {
      await _db.collection("Comments").doc(commentId).delete();
    } catch (e) {
      print(e);
    }
  }

  //fetch comment
  Future<List<Comment>> getCommentsFromFirebase(String postId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Comments")
          .where("postId", isEqualTo: postId)
          .get();

      return snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  //report
  Future<void> reportUserInFirebase(String postId, userId) async {
    final currentUserId = _auth.currentUser!.uid;

    final report = {
      'reportedBy': currentUserId,
      'messageId': postId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    //update in firestore
    await _db.collection("Reports").add(report);
  }
  Future<List<String>> getReportIdsFromFirebase() async {
    final snapshot = await _db.collection("Reports").get();
    final messageIds = snapshot.docs.map((doc) => doc['messageId'] as String).toList();

    return messageIds;
  }

  //block user
  Future<void> blockUserInFirebase(String userId) async {
    final currentUserId = _auth.currentUser!.uid;

    //add to block list
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(userId)
        .set({});
  }

  //unblock
  Future<void> unblockUserInFirebase(String blockedUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    //remove from block list
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(blockedUserId)
        .delete();
  }

  //get block list
  Future<List<String>> getBlockedUidsFromFirebase() async {
    final currentUserId = _auth.currentUser!.uid;

    final snapshot = await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  //follow
  Future<void> followUserInFirebase(String uid) async {
    final currentUserId = _auth.currentUser!.uid;

    //add target to following
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Following")
        .doc(uid)
        .set({});

    //add user to follower
    await _db
        .collection("Users")
        .doc(uid)
        .collection("Followers")
        .doc(currentUserId)
        .set({});
  }

  //unfollow
  Future<void> unfollowUserInFirebase(String uid) async {
    final currentUserId = _auth.currentUser!.uid;

    //remove target to folloing
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Following")
        .doc(uid)
        .delete();
    //remove user to follower
    await _db
        .collection("Users")
        .doc(uid)
        .collection("Followers")
        .doc(currentUserId)
        .delete();
  }
  //get follower uid list

  Future<List<String>> getFollowerUidsFromFirebase(String uid) async {
    final snapshot =
        await _db.collection("Users").doc(uid).collection("Followers").get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  //get following uid list

  Future<List<String>> getFollowingUidsFromFirebase(String uid) async {
    final snapshot =
        await _db.collection("Users").doc(uid).collection("Following").get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  //Search

  Future<List<UserProfile>> searchUsersInFirebase(String searchTerm) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Users")
          .where('username', isGreaterThanOrEqualTo: searchTerm)
          .where('username', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      return snapshot.docs.map((doc) => UserProfile.fromDocument(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // USER STATISTICS

  /// Gets count of new users within a specific time period
  Future<int> getNewUsersCount({required Duration period}) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(period);

      QuerySnapshot snapshot = await _db
          .collection("Users")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(startTime))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error in getNewUsersCount: $e');
      return 0;
    }
  }

  /// Gets weekly data for new user signups
  Future<List<Map<String, dynamic>>> getWeeklyNewUsersData() async {
    final List<Map<String, dynamic>> weeklyData = [];
    final now = DateTime.now();

    try {
      for (int i = 0; i < 4; i++) {
        final weekStart = now.subtract(Duration(days: (i + 1) * 7));
        final weekEnd = now.subtract(Duration(days: i * 7));

        QuerySnapshot snapshot = await _db
            .collection("Users")
            .where("timestamp", isGreaterThan: Timestamp.fromDate(weekStart))
            .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
            .get();

        weeklyData.add({
          'week': 'Week ${4 - i}',
          'users': snapshot.docs.length,
        });
      }

      return weeklyData;
    } catch (e) {
      print('Error in getWeeklyNewUsersData: $e');
      return [];
    }
  }

  /// Gets list of recently joined users
  Future<List<UserProfile>> getRecentNewUsers({int limit = 5}) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Users")
          .orderBy("timestamp", descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserProfile.fromDocument(doc)).toList();
    } catch (e) {
      print('Error in getRecentNewUsers: $e');
      return [];
    }
  }

  // ADVANCED STATISTICS AND ANALYTICS

  /// Gets user growth rate compared to previous period
  Future<double> getUserGrowthRate({required Duration period}) async {
    try {
      final now = DateTime.now();
      final periodEnd = now;
      final periodStart = now.subtract(period);
      final previousPeriodEnd = periodStart;
      final previousPeriodStart = periodStart.subtract(period);

      // Current period users
      QuerySnapshot currentPeriodSnapshot = await _db
          .collection("Users")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(periodStart))
          .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
          .get();

      // Previous period users
      QuerySnapshot previousPeriodSnapshot = await _db
          .collection("Users")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(previousPeriodStart))
          .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(previousPeriodEnd))
          .get();

      int currentPeriodUsers = currentPeriodSnapshot.docs.length;
      int previousPeriodUsers = previousPeriodSnapshot.docs.length;

      if (previousPeriodUsers == 0) return double.infinity;

      return ((currentPeriodUsers - previousPeriodUsers) / previousPeriodUsers) * 100;
    } catch (e) {
      print('Error in getUserGrowthRate: $e');
      return 0.0;
    }
  }

  /// Gets user retention rate for a specific time period
  Future<double> getUserRetentionRate({required Duration period}) async {
    try {
      final now = DateTime.now();
      final periodStart = now.subtract(period);

      // Get users who joined during the period
      QuerySnapshot newUsersSnapshot = await _db
          .collection("Users")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(periodStart))
          .get();

      // Get active users (users who have posted or commented)
      List<String> newUserIds = newUsersSnapshot.docs.map((doc) => doc.id).toList();

      QuerySnapshot activePostsSnapshot = await _db
          .collection("Posts")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(periodStart))
          .where("uid", whereIn: newUserIds)
          .get();

      QuerySnapshot activeCommentsSnapshot = await _db
          .collection("Comments")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(periodStart))
          .where("uid", whereIn: newUserIds)
          .get();

      Set<String> activeUserIds = {
        ...activePostsSnapshot.docs.map((doc) => doc['uid'] as String),
        ...activeCommentsSnapshot.docs.map((doc) => doc['uid'] as String),
      };

      if (newUserIds.isEmpty) return 0.0;

      return (activeUserIds.length / newUserIds.length) * 100;
    } catch (e) {
      print('Error in getUserRetentionRate: $e');
      return 0.0;
    }
  }

  /// Gets most active users for a specific time period
  Future<List<Map<String, dynamic>>> getMostActiveUsers({
    required Duration period,
    int limit = 5,
  }) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(period);

      // Get posts count per user
      QuerySnapshot postsSnapshot = await _db
          .collection("Posts")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(startTime))
          .get();

      // Get comments count per user
      QuerySnapshot commentsSnapshot = await _db
          .collection("Comments")
          .where("timestamp", isGreaterThan: Timestamp.fromDate(startTime))
          .get();

      // Combine and calculate activity
      Map<String, int> userActivity = {};

      for (var doc in postsSnapshot.docs) {
        String uid = doc['uid'] as String;
        userActivity[uid] = (userActivity[uid] ?? 0) + 2; // Posts count more
      }

      for (var doc in commentsSnapshot.docs) {
        String uid = doc['uid'] as String;
        userActivity[uid] = (userActivity[uid] ?? 0) + 1;
      }

      // Sort users by activity
      var sortedUsers = userActivity.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Get user details for top active users
      List<Map<String, dynamic>> mostActiveUsers = [];
      for (var i = 0; i < limit && i < sortedUsers.length; i++) {
        var userDoc = await _db.collection("Users").doc(sortedUsers[i].key).get();
        if (userDoc.exists) {
          mostActiveUsers.add({
            'user': UserProfile.fromDocument(userDoc),
            'activityScore': sortedUsers[i].value,
          });
        }
      }

      return mostActiveUsers;
    } catch (e) {
      print('Error in getMostActiveUsers: $e');
      return [];
    }
  }

  // PERFORMANCE OPTIMIZATION METHODS

  /// Caches user data for faster access
  final Map<String, UserProfile> _userCache = {};

  Future<UserProfile?> getCachedUser(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid];
    }

    UserProfile? user = await getUserFromFirebase(uid);
    if (user != null) {
      _userCache[uid] = user;
    }
    return user;
  }

  /// Clears the user cache
  void clearUserCache() {
    _userCache.clear();
  }

  // BATCH OPERATIONS

  /// Performs multiple write operations in a single atomic transaction
  Future<void> batchWriteOperation(List<Map<String, dynamic>> operations) async {
    WriteBatch batch = _db.batch();

    try {
      for (var operation in operations) {
        switch (operation['type']) {
          case 'set':
            batch.set(
              operation['reference'] as DocumentReference,
              operation['data'] as Map<String, dynamic>,
            );
            break;
          case 'update':
            batch.update(
              operation['reference'] as DocumentReference,
              operation['data'] as Map<String, dynamic>,
            );
            break;
          case 'delete':
            batch.delete(operation['reference'] as DocumentReference);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error in batchWriteOperation: $e');
      throw Exception('Batch write operation failed');
    }
  }

  // UTILITY METHODS

  /// Converts a Firestore timestamp to a formatted string
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

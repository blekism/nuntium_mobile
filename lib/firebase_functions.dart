import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nuntium_mobile/models/comment.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nuntium_mobile/models/member.dart';
import 'package:nuntium_mobile/models/notif.dart';
import 'package:nuntium_mobile/models/topic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nuntium_mobile/models/featuredcard.dart';
import 'package:nuntium_mobile/models/normalitem.dart';
import 'package:nuntium_mobile/models/topicmodel.dart';

class FirebaseFunctions {
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, String> userCache = {};

  NormalItem maptoNormalItem(DocumentSnapshot doc) {
    final data = (doc.data() is Function)
        ? (doc.data() as Function)() as Map<String, dynamic>?
        : doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data is null');
    }

    final datePosted = data['datePosted'] ?? 'date unknown' as Timestamp;
    final dateString = datePosted.toDate().toString();

    return NormalItem(
      id: doc.id,
      imageUrl: data['image'] ?? 'no image',
      section: data['section'] ?? 'no section',
      title: data['title'] ?? 'no title',
      datePosted: dateString,
    );
  }

  Stream<List<Topic>> streamTopics(String sectionId) {
    return db
        .collection('tasks')
        .where('section', isEqualTo: sectionId)
        .where('assigned_by', isEqualTo: auth.currentUser!.uid)
        .orderBy('deadline', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      return Future.wait(snapshot.docs.map((topicDoc) async {
        final topicData = topicDoc.data();

        final assignedTaskData =
            await topicDoc.reference.collection('assigned_tasks').get();

        List<Member> members = [];

        if (assignedTaskData.docs.isNotEmpty) {
          members = (await Future.wait(
            assignedTaskData.docs.map((taskDoc) async {
              final memberId = taskDoc['assignee_id'];

              if (memberId != null) {
                final userDoc =
                    await db.collection('users').doc(memberId).get();

                if (userDoc.exists) {
                  return Member(
                    id: userDoc.id,
                    name: userDoc['username'] ?? '',
                    imageUrl: userDoc['photoURL'] ?? '',
                  );
                }
              }
              return null;
            }),
          ))
              .where((member) => member != null)
              .cast<Member>()
              .toList();
        }

        return Topic(
          id: topicDoc.id,
          title: topicData['title'] ?? '',
          section: topicData['section'] ?? '',
          status: topicData['status'] ?? '',
          deadline: topicData['deadline'] ?? '',
          priority: topicData['priority'] ?? '',
          totalSubtask: topicData['totalTasks'] ?? '',
          completedSubtask: topicData['completedTasks'] ?? '',
          members: members,
        );
      }).toList());
    });
  }

  Stream<List<FeaturedItem>> streamFeaturedItems() {
    return db
        .collection('posts')
        .where('isFeatured', isEqualTo: true)
        .orderBy('datePosted', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final datePosted = doc['datePosted'] as Timestamp;
        final dateString = datePosted.toDate().toString();

        return FeaturedItem(
          id: doc.id,
          imageUrl: doc['image'],
          section: doc['section'],
          title: doc['title'],
          datePosted: dateString,
        );
      }).toList();
    });
  }

  Stream<List<NormalItem>> streamNormalItems() {
    return db
        .collection('posts')
        .where('isFeatured', isEqualTo: false)
        .orderBy('datePosted', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final datePosted = doc['datePosted'] as Timestamp;
        final dateString = datePosted.toDate().toString();

        return NormalItem(
          id: doc.id,
          imageUrl: doc['image'],
          section: doc['section'],
          title: doc['title'],
          datePosted: dateString,
        );
      }).toList();
    });
  }

  Stream<List<NormalItem>> streamForDiscover() {
    return db
        .collection('posts')
        .where('isArticle', isEqualTo: true)
        .orderBy('datePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final datePosted = doc['datePosted'] as Timestamp;
        final dateString = datePosted.toDate().toString();

        return NormalItem(
          id: doc.id,
          imageUrl: doc['image'],
          section: doc['section'],
          title: doc['title'],
          datePosted: dateString,
        );
      }).toList();
    });
  }

  Stream<List<NormalItem>> readingHistoryList(String userId) {
    if (userId.isNotEmpty) {
      return db
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .where('isRead', isEqualTo: true)
          .orderBy('readAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        List<NormalItem> posts = [];

        for (var doc in snapshot.docs) {
          String postId = doc['postId'];

          DocumentSnapshot postSnapshot =
              await db.collection('posts').doc(postId).get();

          if (postSnapshot.exists && postSnapshot.data() != null) {
            posts.add(maptoNormalItem(postSnapshot));
          }
        }

        return posts;
      });
    } else {
      return Stream.value([]);
    }
  }

  Stream<List<NormalItem>> readingBookmarkList(String userId) {
    if (userId.isNotEmpty) {
      return db
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .where('isSaved', isEqualTo: true)
          .orderBy('savedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        List<NormalItem> posts = [];

        for (var doc in snapshot.docs) {
          String postId = doc['postId'];

          DocumentSnapshot postSnapshot =
              await db.collection('posts').doc(postId).get();

          if (postSnapshot.exists && postSnapshot.data() != null) {
            posts.add(maptoNormalItem(postSnapshot));
          }
        }

        return posts;
      });
    } else {
      return Stream.value([]);
    }
  }

  Future<void> handlePostClick(String postID, bool isLoading) async {
    if (isLoading) return;

    try {
      if (auth.currentUser == null) {
        print("User not logged in");
        return;
      }

      final userId = auth.currentUser!.uid;

      final savedPostRef = db
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postID);

      final existingPost = await savedPostRef.get();

      if (!existingPost.exists) {
        await savedPostRef.set({
          'postId': postID,
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await db.collection('posts').doc(postID).set(
          {'totalViews': FieldValue.increment(1)}, SetOptions(merge: true));

      print("post saved to history");
    } on FirebaseException catch (e) {
      print("Firebase error: ${e.message}");
    } catch (e) {
      print("Error saving post: $e");
    }
  }

  Stream<Set<String>> readPostsList(String userId) {
    return db
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .where('isRead', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> insertComment(String comment, postId) async {
    try {
      if (auth.currentUser == null) {
        print("user not logged in");
        return;
      }

      final userId = auth.currentUser!.uid;

      await db.collection('comments').add({
        'comment': comment,
        'postID': postId,
        'userID': userId,
        'time': Timestamp.now(),
      });

      await db.collection('posts').doc(postId).set(
          {'totalComments': FieldValue.increment(1)}, SetOptions(merge: true));
    } catch (e) {
      print("Error commenting on post $e");
    }
  }

  Stream<Map<String, dynamic>?> streamPostData(String postId) {
    return db.collection('posts').doc(postId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      } else {
        return null;
      }
    }).handleError((error) {
      print('Error streaming post data: ${error}');
      return null;
    });
  }

  Future<String> getUserName(String userId) async {
    if (userCache.containsKey(userId)) {
      return userCache[userId]!;
    }

    DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();

    String username = userDoc.exists ? userDoc['username'] : 'unknown';
    userCache[userId] = username;
    return username;
  }

  Stream<List<Comment>> streamComments(String postId) {
    return db
        .collection('comments')
        .where('postID', isEqualTo: postId)
        .orderBy('time', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final comments = await Future.wait(snapshot.docs.map((commentDoc) async {
        final data = commentDoc.data();
        final userId = data['userID'];

        DocumentSnapshot userDoc =
            await db.collection('users').doc(userId).get();

        String userName = userDoc.exists ? userDoc['username'] : 'unknown';
        String userPhotoURL = userDoc.exists ? userDoc['photoURL'] : 'unknown';

        final timestamp = data['time'] as Timestamp;
        String dateString = timestamp.toDate().toString();

        return Comment(
          commentId: commentDoc.id,
          imageUrl: userPhotoURL, // Replace with actual user image if available
          commenter: userName,
          comment: data['comment'],
          date: dateString,
          userId: userId,
        );
      }).toList());

      return comments;
    });
  }

  Future<void> createUserDoc(
      String uid, email, displayName, photoUrl, password) async {
    try {
      print('New user detected, creating firestore record...');
      await db.collection('users').doc(uid).set({
        'email': email,
        'password': password ?? 'no-provided-password-google-is-used',
        'uid': uid,
        'username': displayName,
        'photoURL': photoUrl ??
            'https://firebasestorage.googleapis.com/v0/b/nu-publication-system.firebasestorage.app/o/logo.jpg?alt=media&token=fed28218-248d-4ad9-a639-14f072f7e9b9',
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'reader',
      });
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  Future<DocumentSnapshot> getUserDoc(String id) {
    return db.collection('users').doc(id).get();
  }

  Future<DocumentSnapshot> checkIfSaved(String postId) async {
    try {
      DocumentSnapshot postdoc = await db
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('savedPosts')
          .doc(postId)
          .get();

      return postdoc;
    } catch (e) {
      print('error fetching details: $e');
      return Future.error(e);
    }
  }

  Future<void> likeArticle(String postId) async {
    try {
      if (auth.currentUser == null) {
        print("User not logged in");
        return;
      }

      final userId = auth.currentUser!.uid;

      final likedPostRef = db
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId);

      await db.runTransaction((transact) async {
        final doc = await transact.get(likedPostRef);

        if (!doc.exists) {
          transact.set(likedPostRef, {
            'postId': postId,
            'isLiked': true,
            'likedAt': Timestamp.now(),
            'likeClick': FieldValue.increment(1)
          });
          transact.update(db.collection('posts').doc(postId),
              {'totalLikes': FieldValue.increment(1)});
          return;
        }

        final data = doc.data() as Map<String, dynamic>;
        final likeClick = (data['likeClick'] as int?) ?? 0;
        final likeThrottleExpireseAt =
            data['likeThrottleExpiresAt'] as Timestamp?;

        final now = Timestamp.now();

        if (likeThrottleExpireseAt != null &&
            likeThrottleExpireseAt.toDate().isAfter(now.toDate())) {
          print('you are temporarily locked out');
          return;
        }

        if (likeClick < 5) {
          transact.update(likedPostRef, {
            'isLiked': true,
            'likedAt': now,
            'likeClick': likeClick + 1,
          });

          transact.update(db.collection('posts').doc(postId),
              {'totalLikes': FieldValue.increment(1)});
        } else if (likeClick == 5) {
          final lockoutTime =
              Timestamp.fromDate(now.toDate().add(const Duration(hours: 12)));
          transact.update(likedPostRef, {
            'isLiked': true,
            'likedAt': now,
            'likeThrottleExpiresAt': lockoutTime,
          });
          print(
              "You've reached the like limit for this post. Locked out until ${lockoutTime.toDate()}");
        }
      });
    } catch (e) {
      print("Error liking post: $e");
    }
  }

  Future<void> bookmarkArticle(String postId) async {
    try {
      if (auth.currentUser == null) {
        print("User not logged in");
        return;
      }

      final userId = auth.currentUser!.uid;
      final savedPostRef = db
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId);

      await db.runTransaction((transact) async {
        final doc = await transact.get(savedPostRef);

        if (!doc.exists) {
          transact.set(savedPostRef, {
            'postId': postId,
            'isSaved': true,
            'savedAt': Timestamp.now(),
            'bookmarkClick': 1,
          });
          transact.update(db.collection('posts').doc(postId),
              {'totalBookmarks': FieldValue.increment(1)});
          return;
        }

        final data = doc.data() as Map<String, dynamic>;
        final bookmarkClick = (data['bookmarkClick'] as int?) ?? 0;
        final bookmarkThrottleExpiresAt =
            data['bookmarkThrottleExpiresAt'] as Timestamp?;

        final now = Timestamp.now();

        if (bookmarkThrottleExpiresAt != null &&
            bookmarkThrottleExpiresAt.toDate().isAfter(now.toDate())) {
          print('You are temporarily locked out from bookmarking.');
          return;
        }

        if (bookmarkClick < 5) {
          transact.update(savedPostRef, {
            'isSaved': true,
            'savedAt': now,
            'bookmarkClick': bookmarkClick + 1,
          });

          transact.update(db.collection('posts').doc(postId),
              {'totalBookmarks': FieldValue.increment(1)});
        } else if (bookmarkClick == 5) {
          final lockoutTime =
              Timestamp.fromDate(now.toDate().add(const Duration(hours: 12)));
          transact.update(savedPostRef, {
            'isSaved': true,
            'savedAt': now,
            'bookmarkThrottleExpiresAt': lockoutTime,
          });
          print(
              "You've reached the bookmark limit for this post. Locked out until ${lockoutTime.toDate()}");
        }
      });
    } catch (e) {
      print("Error bookmarking post: $e");
    }
  }

  Future<void> removeBokmark(String postId) async {
    try {
      if (auth.currentUser == null) {
        print("User not logged in");
        return;
      }

      final userId = auth.currentUser!.uid;
      final savedPostRef = db
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(savedPostRef);

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final bookmarkClick = (data['bookmarkClick'] as int?) ?? 0;
          final bookmarkThrottleExpiresAt =
              data['bookmarkThrottleExpiresAt'] as Timestamp?;

          final now = Timestamp.now();

          // If the user is currently throttled, we don't want to decrement the bookmarkClick
          if (bookmarkThrottleExpiresAt != null &&
              bookmarkThrottleExpiresAt.toDate().isAfter(now.toDate())) {
            print("Cannot remove bookmark while throttled.");
            return;
          }

          if (bookmarkClick < 5) {
            transaction.update(savedPostRef, {
              'isSaved': false,
              'bookmarkClick': bookmarkClick + 1,
            });

            transaction.update(db.collection('posts').doc(postId),
                {'totalBookmarks': FieldValue.increment(-1)});
          } else if (bookmarkClick == 5) {
            transaction.update(savedPostRef, {
              'isSaved': false,
            });
          }
        }
      });
    } catch (e) {
      print("Error removing bookmark from post: $e");
      // Optionally rethrow the error
    }
  }

  Future<void> removeLike(String postId) async {
    try {
      if (auth.currentUser == null) {
        print("User not logged in");
        return;
      }

      final userId = auth.currentUser!.uid;
      final likedPostRef = db
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(likedPostRef);

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final likeClick = (data['likeClick'] as int?) ?? 0;
          final likeThrottleExpiresAt =
              data['likeThrottleExpiresAt'] as Timestamp?;

          final now = Timestamp.now();

          // If the user is currently throttled, we don't want to decrement the likeClick
          if (likeThrottleExpiresAt != null &&
              likeThrottleExpiresAt.toDate().isAfter(now.toDate())) {
            print("Cannot remove like while throttled.");
            return;
          }

          if (likeClick < 5) {
            transaction.update(likedPostRef, {
              'isLiked': false,
              'likeClick': likeClick + 1,
            });

            transaction.update(db.collection('posts').doc(postId),
                {'totalLikes': FieldValue.increment(-1)});
          } else if (likeClick == 5) {
            transaction.update(likedPostRef, {
              'isLiked': false,
            });
          }
        }
      });
    } catch (e) {
      print("Error removing like from post: $e");
      // Optionally rethrow the error
    }
  }

  Future<void> relatedContent(String section) async {
    try {} catch (e) {
      print('error fetching related content $e');
    }
  }

  Future<void> resetExpiredLikeThrottles() async {
    if (auth.currentUser == null) {
      return;
    }

    final userId = auth.currentUser!.uid;
    final savedPostsCollection =
        db.collection('users').doc(userId).collection('savedPosts');

    final now = Timestamp.now();

    try {
      final querySnapshot = await savedPostsCollection
          .where('likeThrottleExpiresAt', isLessThanOrEqualTo: now)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'likeClick': 0,
            'likeThrottleExpiresAt': FieldValue.delete(),
          });
        }
        await batch.commit();
        print('Expired like throttles reset.');
      }
    } catch (e) {
      print('Error resetting expired like throttles: $e');
    }
  }

  Future<void> resetExpiredBookmarkThrottles() async {
    if (auth.currentUser == null) {
      return;
    }

    final userId = auth.currentUser!.uid;
    final savedPostsCollection =
        db.collection('users').doc(userId).collection('savedPosts');

    final now = Timestamp.now();

    try {
      final querySnapshot = await savedPostsCollection
          .where('bookmarkThrottleExpiresAt', isLessThanOrEqualTo: now)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'bookmarkClick': 0,
            'bookmarkThrottleExpiresAt': FieldValue.delete(),
          });
        }
        await batch.commit();
        print('Expired bookmark throttles reset.');
      }
    } catch (e) {
      print('Error resetting expired bookmark throttles: $e');
    }
  }

  Future<List<NormalItem>> yourWorks() {
    return db
        .collection('posts')
        .where('authors', arrayContains: auth.currentUser!.uid)
        .orderBy('datePosted', descending: true)
        .get()
        .then((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        final datePosted = doc['datePosted'] as Timestamp;
        final dateString = datePosted.toDate().toString();

        return NormalItem(
          id: doc.id,
          imageUrl: doc['image'],
          section: doc['section'],
          title: doc['title'],
          datePosted: dateString,
        );
      }).toList();
    });
  }

  Future<void> submitApplication(String selectedSection) async {
    try {
      await db.collection('applicants').add({
        'username': auth.currentUser!.displayName,
        'email': auth.currentUser!.email,
        'created_at': FieldValue.serverTimestamp(),
        'applied_section': selectedSection,
        'status': 'submitted',
      });
    } catch (e) {
      print('error submitting application $e');
    }
  }

  Future<DocumentSnapshot> getUserInfo(String userId) async {
    try {
      DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();

      return userDoc;
    } catch (e) {
      print('error fetching user info $e');
      return Future.error(e);
    }
  }

  Stream<List<NormalItem>> viewFeaturedTermly() {
    return db
        .collection('posts')
        .where('isTermly', isEqualTo: true)
        .where('termlyFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshots) {
      return snapshots.docs.map((doc) {
        final datePosted = doc['datePosted'] as Timestamp;
        final dateString = datePosted.toDate().toString();

        return NormalItem(
          id: doc.id,
          imageUrl: doc['image'],
          section: doc['section'],
          title: doc['title'],
          datePosted: dateString,
          pdfUrl: doc['pdfUrl'],
        );
      }).toList();
    });
  }

  Stream<List<NormalItem>> viewAllTermly() {
    return db
        .collection('posts')
        .where('isTermly', isEqualTo: true)
        .snapshots()
        .map((snapshots) {
      return snapshots.docs.map((doc) {
        final datePosted = doc['datePosted'] as Timestamp;
        final dateString = datePosted.toDate().toString();

        return NormalItem(
          id: doc.id,
          imageUrl: doc['image'],
          section: doc['section'],
          title: doc['title'],
          datePosted: dateString,
          pdfUrl: doc['pdfUrl'],
        );
      }).toList();
    });
  }

  Future<void> updateComment(String commentId, newComment) async {
    try {
      await db
          .collection('comments')
          .doc(commentId)
          .update({'comment': newComment});
    } catch (e) {
      print('error updating comment: $e');
    }
  }

  Future<void> deleteComment(String commentId, postId) async {
    try {
      await db.collection('comments').doc(commentId).delete();
      // delete din dapat ng 1 sa totalComments
      await db
          .collection('posts')
          .doc(postId)
          .update({'totalComments': FieldValue.increment(-1)});
    } catch (e) {
      print('error updating comment: $e');
    }
  }

  Future<List<Member>> getOrgMembers() async {
    try {
      final snapshot = await db
          .collection('users')
          .where('role', isNotEqualTo: 'reader')
          .orderBy('roleTag', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return Member(
          id: doc.id,
          name: doc['username'],
          imageUrl: doc['photoURL'],
          role: doc['role'],
        );
      }).toList();
    } catch (e) {
      print('error fetching org members $e');
      return [];
    }
  }

  Future<void> markNotificationsAsRead(List<String> notificationIds) async {
    try {
      if (auth.currentUser == null) {
        print("User not logged in");
        return;
      }

      final userId = auth.currentUser!.uid;
      final userDocRef = db.collection('users').doc(userId);

      await userDocRef.update({
        'readNotifications': FieldValue.arrayUnion(notificationIds),
      });
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> saveFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken(); // Get FCM token
    print("FCM Token: $token");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "fcmToken": token,
      });
    }
  }

  Stream<List<NotifItem>> streamPostNotifications() {
    return db
        .collection('posts')
        .where('isAnnouncement', isEqualTo: false)
        .orderBy('datePosted', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final userId = auth.currentUser?.uid;
      Set<String> readNotificationIds = {};

      if (userId != null) {
        final userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists &&
            userDoc.data()?.containsKey('readNotifications') == true) {
          readNotificationIds =
              Set<String>.from(userDoc['readNotifications'] as List<dynamic>);
        }
      }

      return snapshot.docs.map((doc) {
        final datePosted = doc['datePosted'] as Timestamp;
        final dateString = datePosted.toDate().toString();
        final notificationId = doc.id;
        return NotifItem(
          id: notificationId,
          imageUrl: doc['image'],
          section: doc['section'],
          datePosted: dateString,
          headline: doc['title'],
          isRead: readNotificationIds.contains(notificationId),
        );
      }).toList();
    }).handleError((error) {
      print('Error fetching notifications: $error');
      return <NotifItem>[];
    });
  }

  Future<QuerySnapshot> getSections() async {
    try {
      QuerySnapshot sectionSnapshot = await db.collection('sections').get();
      return sectionSnapshot;
    } catch (e) {
      print('error fetching data $e');
      return Future.error(e);
    }
  }

  Future<void> createTopic(
      String assignee, title, deadline, priority, details, section) async {
    try {
      if (auth.currentUser == null) {
        print("user not logged in");
        return;
      }

      DateTime parsedDeadline = DateFormat("d/M/yyyy h:mm a").parse(deadline);
      Timestamp deadlineTimestamp = Timestamp.fromDate(parsedDeadline);

      await db.collection('tasks').add({
        'assigned_by': assignee,
        'title': title,
        'deadline': deadlineTimestamp,
        'priority': priority,
        'details': details,
        'completed_subtask': 0,
        'total_subtask': 0,
        'created_at': Timestamp.now(),
        'isParent': true,
        'section': section,
        'status': 'pendingAPR',
        'otherMembers': 0,
      });

      print('topic created successfully');
    } catch (e) {
      return Future.error(e);
    }
  }

  Stream<List<Topic>> getTopics(String sectionId) {
    return db
        .collection('tasks')
        .where('section', isEqualTo: sectionId)
        .orderBy('deadline', descending: true)
        .snapshots()
        .asyncMap((snapshot) {
      return Future.wait(snapshot.docs.map((topicDoc) async {
        final topicData = topicDoc.data();
        final deadline = topicDoc['deadline'] as Timestamp;
        final dateString =
            DateFormat('dd/MM/yyyy hh:mm a').format(deadline.toDate());

        final assignedTaskData =
            await topicDoc.reference.collection('assigned_tasks').get();

        List<Member> members = [];

        if (assignedTaskData.docs.isNotEmpty) {
          members = (await Future.wait(
            assignedTaskData.docs.map((taskDoc) async {
              final memberId = taskDoc['assignee_id'];

              if (memberId != null) {
                final userDoc =
                    await db.collection('users').doc(memberId).get();

                if (userDoc.exists) {
                  return Member(
                    id: userDoc.id,
                    name: userDoc['username'] ?? '',
                    imageUrl: userDoc['photoURL'] ?? '',
                  );
                }
              }
              return null;
            }),
          ))
              .where((member) => member != null)
              .cast<Member>()
              .toList();
        }

        return Topic(
          id: topicDoc.id,
          title: topicData['title'] ?? '',
          section: topicData['section'] ?? '',
          status: topicData['status'] ?? '',
          deadline: dateString,
          priority: topicData['priority'] ?? '',
          totalSubtask: topicData['total_subtask'] ?? '',
          completedSubtask: topicData['completed_subtask'] ?? '',
          otherMembers: topicData['otherMembers'],
          members: members,
        );
      }).toList());
    });
  }

  // TODO notification for announcements
}

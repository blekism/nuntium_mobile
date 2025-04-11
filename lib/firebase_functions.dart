import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nuntium_mobile/models/comment.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nuntium_mobile/models/eb_section_model.dart';
import 'package:nuntium_mobile/models/member.dart';
import 'package:nuntium_mobile/models/membermodel.dart';
import 'package:nuntium_mobile/models/notif.dart';
import 'package:nuntium_mobile/models/taskmodel.dart';
import 'package:nuntium_mobile/models/timeline_item_model.dart';
import 'package:nuntium_mobile/models/topic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nuntium_mobile/models/featuredcard.dart';
import 'package:nuntium_mobile/models/normalitem.dart';
import 'package:nuntium_mobile/models/viewed_task.dart';

class FirebaseFunctions {
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, String> userCache = {};

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
  }

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
            projectStep: topicData['projectStep']);
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
          });
        } else {
          transact.update(likedPostRef, {
            'isLiked': true,
            'likedAt': Timestamp.now(),
          });
        }

        transact.update(db.collection('posts').doc(postId),
            {'totalLikes': FieldValue.increment(1)});
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
          });
        } else {
          transact.update(savedPostRef, {
            'isSaved': true,
            'savedAt': Timestamp.now(),
          });
        }

        transact.update(db.collection('posts').doc(postId),
            {'totalBookmarks': FieldValue.increment(1)});
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
          transaction.update(savedPostRef, {
            'isSaved': false,
          });

          transaction.update(db.collection('posts').doc(postId),
              {'totalBookmarks': FieldValue.increment(-1)});
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
          transaction.update(likedPostRef, {
            'isLiked': false,
          });

          transaction.update(db.collection('posts').doc(postId),
              {'totalLikes': FieldValue.increment(-1)});
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

//starting here ang need ng logging sa timeline
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
        'projectStep': 1,
      }).then((docRef) async {
        final dateString = formatTimestamp(Timestamp.now());

        await logInTimeline(docRef.id, 'Task Created',
            'Task was created at $dateString', 'Topic Created');
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
          projectStep: topicData['projectStep'],
        );
      }).toList());
    }).handleError((e) {
      print('Error fetching topic for card with user info: $e');
      return Future.error(e);
    });
  }

  Stream<List<TaskModel>> getTasks(String topicId) {
    return db
        .collection('tasks')
        .doc(topicId)
        .collection('assigned_tasks')
        .snapshots()
        .asyncMap((snapshot) async {
      DocumentSnapshot topicDoc =
          await db.collection('tasks').doc(topicId).get();

      if (!topicDoc.exists) {
        return [];
      }

      final topicData = topicDoc.data() as Map<String, dynamic>;
      final parentTitle = topicData['title'] as String? ?? '';
      final parentPriority = topicData['priority'] as String? ?? '';
      final parentSection = topicData['section'] as String? ?? '';

      return Future.wait(snapshot.docs.map((taskDoc) async {
        final taskData = taskDoc.data();
        final memberId = taskData['assignee_id'];
        final tasktype = taskData['task_type'];
        final title = taskData['taskname'];
        final status = taskData['status'];

        final deadline = taskData['deadline'] as Timestamp;
        final dateString =
            DateFormat('dd/MM/yyyy hh:mm a').format(deadline.toDate());

        DocumentSnapshot userDoc =
            await db.collection('users').doc(memberId).get();

        String userName = userDoc.exists ? userDoc['username'] : 'unkown';
        String imageUrl = userDoc.exists ? userDoc['photoURL'] : 'unkown';

        return TaskModel(
          id: taskDoc.id,
          title: title,
          section: parentSection,
          type: tasktype,
          deadline: dateString,
          priority: parentPriority,
          assignee: imageUrl,
          status: status,
        );
      }));
    });
  }

  Stream<Map<String, dynamic>> streamTopicInfo(String topicId) {
    return db
        .collection('tasks')
        .doc(topicId)
        .snapshots()
        .asyncMap((taskDoc) async {
      if (!taskDoc.exists) {
        throw Exception("Task not found");
      }

      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
      String userId = taskData['assigned_by'];

      DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception("User not found");
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      taskData['userName'] = userData['username'];

      return taskData;
    }).handleError((e) {
      print('Error fetching topic with user info: $e');
      return Future.error(e);
    });
  }

  Future<void> approveToCreate(String topicId) async {
    try {
      await db.collection('tasks').doc(topicId).update({
        'status': 'doing',
        'eicApproved': true,
        'createApproved_at': Timestamp.now(),
        'projectStep': FieldValue.increment(1),
      });

      final dateString = formatTimestamp(Timestamp.now());

      await logInTimeline(topicId, 'Topic Approved',
          'Topic was Approved at $dateString', 'Approved');
    } catch (e) {
      print('error approving post $e');
      return Future.error(e);
    }
  }

  Future<void> rejectToCreate(String topicId) async {
    try {
      await db.collection('tasks').doc(topicId).update({
        'status': 'rejected',
        'reason': 'rejected',
        'rejected_at': Timestamp.now(),
      });

      final dateString = formatTimestamp(Timestamp.now());

      await logInTimeline(topicId, 'Topic Rejected',
          'Topic was Rejected at $dateString', 'Rejected');
    } catch (e) {
      print('error rejecting post $e');
      return Future.error(e);
    }
  }

  Future<void> seApprove(
    String topicId,
    taskId,
  ) async {
    // need na sa log starting dito yung mismong content and mismong comments na
    // this is essentially eb returns the task along with the comments for revision
    try {
      final dbref = db.collection('tasks').doc(topicId);

      await dbref.update({
        'completed_subtask': FieldValue.increment(1),
        'projectStep': FieldValue.increment(1),
      });

      await dbref.collection('assigned_tasks').doc(taskId).update({
        'status': 'approved',
        'approved_at': Timestamp.now(),
      });

      await logInTimeline(
          topicId,
          'Task Content Approved',
          'Task Content was Approved at ${Timestamp.now()}',
          'Content Approved');
    } catch (e) {
      print('error approving post $e');
      return Future.error(e);
    }
  }

  Future<void> seReject(String topicId, taskId, comment, content) async {
    // need na sa log starting dito yung mismong content and mismong comments na
    // this is essentially eb returns the task along with the comments for revision
    try {
      await db
          .collection('tasks')
          .doc(topicId)
          .collection('assigned_tasks')
          .doc(taskId)
          .update({
        'status': 'rejected',
        'reason': 'rejected',
        'comment': comment,
        'rejected_at': Timestamp.now(),
      });

      await logInTimeline(topicId, comment, content, 'For Revision');
    } catch (e) {
      print('error rejecting post $e');
      return Future.error(e);
    }
  }

  Future<List<Membermodel>> getUsersInSection(String section) async {
    try {
      final snapshot = await db
          .collection('users')
          .where('section', isEqualTo: section)
          .get();

      return snapshot.docs.map((doc) {
        return Membermodel(
          id: doc.id,
          username: doc['username'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching users in section: $e');
      return [];
    }
  }

  Future<void> createTask(String id, deadline, type, title, member) async {
    try {
      DateTime parsedDeadline = DateFormat("d/M/yyyy h:mm a").parse(deadline);
      Timestamp deadlineTimestamp = Timestamp.fromDate(parsedDeadline);

      await db.collection('tasks').doc(id).collection('assigned_tasks').add({
        'assignee_id': member,
        'created_at': Timestamp.now(),
        'deadline': deadlineTimestamp,
        'status': 'To Do',
        'task_type': type,
        'taskname': title,
        'parent_topic': id,
      });

      await db.collection('tasks').doc(id).update({
        'total_subtask': FieldValue.increment(1),
      });

      final dateString = formatTimestamp(Timestamp.now());

      await logInTimeline(id, 'Task Created', 'Task was Created at $dateString',
          'Task Created');

      //TODO also update users doc sa assignedCount
      print('task created successfully');
    } catch (e) {
      print('error creating a new task lods $e');
      return Future.error(e);
    }
  }

  Future<bool> canUserEdit(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userdoc =
          await db.collection('users').doc(uid).get();

      if (userdoc.exists) {
        final data = userdoc.data();
        if (data != null && data.containsKey('role')) {
          final role = data['role'];
          if (role != 'reader' &&
              role != 'contributor' &&
              role != 'section_member') {
            return true;
          } else {
            return false;
          }
        }
        return false;
      }
      return false;
    } catch (e) {
      print('user cannot edit');
      return false;
    }
  }

  Future<ViewedTask> taskContentWritten(String topicId, String taskId) async {
    // this is for viewing. not necessary to log
    try {
      String? description, priority;

      final parentDocref = db.collection('tasks').doc(topicId);

      final DocumentSnapshot parentSnap = await parentDocref.get();

      final DocumentSnapshot subTaskSnap =
          await parentDocref.collection('assigned_tasks').doc(taskId).get();

      if (parentSnap.exists && parentSnap.data() != null) {
        final parentData = parentSnap.data() as Map<String, dynamic>;

        description = parentData['details'];
        priority = parentData['priority'];

        final username = await getUserInfo(parentSnap['assigned_by']);
        final deadlineTimestamp = subTaskSnap['deadline'] as Timestamp?;
        final deadline = deadlineTimestamp != null
            ? DateFormat('dd/MM/yyyy hh:mm a')
                .format(deadlineTimestamp.toDate())
            : 'No Deadline';

        return ViewedTask(
          title: subTaskSnap['taskname'] ?? '',
          details: description ?? '',
          tasktype: subTaskSnap['task_type'] ?? '',
          deadline: deadline,
          assigner: username['username'],
          assignee: subTaskSnap['assignee_id'],
          priority: priority ?? '',
          content: subTaskSnap.data() != null
              ? (subTaskSnap.data() as Map<String, dynamic>)['content'] ?? ''
              : '',
          taskId: subTaskSnap.id,
        );
      } else {
        print(
            'Error: Task document not found for topicId: $topicId and taskId: $taskId');
        return Future.error('Task not found'); // Or throw an exception
      }
    } catch (e) {
      print('error ka bruh: $e');
      return Future.error(e);
    }
  }

  Future<void> updateContent(
    String topicId,
    subtaskId,
    newTitle,
    newDeadline,
    newType,
    newMember,
  ) async {
    try {
      DateTime parsedDeadline =
          DateFormat("d/M/yyyy h:mm a").parse(newDeadline);
      Timestamp deadlineTimestamp = Timestamp.fromDate(parsedDeadline);

      await db
          .collection('tasks')
          .doc(topicId)
          .collection('assigned_tasks')
          .doc(subtaskId)
          .update({
        'assignee_id': newMember,
        'updated_at': Timestamp.now(),
        'updated_by': auth.currentUser!.uid,
        'deadline': deadlineTimestamp,
        'task_type': newType,
        'taskname': newTitle,
      });

      final dateString = formatTimestamp(Timestamp.now());

      await logInTimeline(topicId, 'Task Updated',
          'Task was Updated at $dateString', 'Task Updated');
      print('task uppydatey suckcessfully');
    } catch (e) {
      print('error yung update bruh: $e');
      return Future.error(e);
    }
  }

  Future<void> updateTopic(
    String topicId,
    newTitle,
    newDetail,
    newDeadline,
    newPriority,
  ) async {
    try {
      DateTime parsedDeadline =
          DateFormat("d/M/yyyy h:mm a").parse(newDeadline);
      Timestamp deadlineTimestamp = Timestamp.fromDate(parsedDeadline);

      await db.collection('tasks').doc(topicId).update({
        'title': newTitle,
        'details': newDetail,
        'updated_at': Timestamp.now(),
        'updated_by': auth.currentUser!.uid,
        'deadline': deadlineTimestamp,
        'priority': newPriority,
        //reason why di included yung section sa pwede iupdate is because it would not make sense to update from one section to another
        //since may assigned members na para jan.
        //much better to just delete the topic if nagkamali rather than changing the section
      });

      final dateString = formatTimestamp(Timestamp.now());

      await logInTimeline(topicId, 'Topic Updated',
          'Topic was Updated at $dateString', 'Topic Updated');
      print('task uppydatey suckcessfully');
    } catch (e) {
      print('error yung update bruh: $e');
      return Future.error(e);
    }
  }

  Stream<List<TimelineItemModel>> getTimelineItems(String topicId) {
    return db
        .collection('tasks')
        .doc(topicId)
        .collection('timeline')
        .orderBy('dateLogged', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final timelineItem =
          await Future.wait(snapshot.docs.map((timelineDoc) async {
        final data = timelineDoc.data();
        final userId = data['userId'];

        final username = await getUserInfo(userId);
        final deadlineTimestamp = data['dateLogged'] as Timestamp?;
        final deadline = deadlineTimestamp != null
            ? DateFormat('dd/MM/yyyy hh:mm a')
                .format(deadlineTimestamp.toDate())
            : 'No Deadline';

        return TimelineItemModel(
          timelineDocId: timelineDoc.id,
          comment: data['comment'],
          content: data['content'],
          logOwner: username['username'],
          dateLogged: deadline,
          status: data['status'],
        );
      }).toList());

      return timelineItem;
    });
  }

  Future<void> logInTimeline(String topicId, comment, content, status) async {
    try {
      await db.collection('tasks').doc(topicId).collection('timeline').add({
        'userId': auth.currentUser!.uid,
        'comment': comment,
        'content': content,
        'status': status,
        'dateLogged': Timestamp.now(),
      });
    } catch (e) {
      print('error logging timeline: $e');
      return Future.error(e);
    }
  }

  Future<EbSectionModel> getEbSection(String uid) async {
    try {
      final String userSectionId, userSectionName;
      final userData = await getUserInfo(uid);

      if (userData.exists) {
        userSectionId = userData['section'];

        DocumentSnapshot sectionSnapshot =
            await db.collection('sections').doc(userSectionId).get();

        if (sectionSnapshot.exists) {
          userSectionName = sectionSnapshot['sectionType'];
          return EbSectionModel(
            sectionId: userSectionId,
            sectionName: userSectionName,
          );
        }
      }
    } catch (e) {
      print('error getting section: $e');
      return Future.error(e);
    }

    throw Exception('Section not found for user: $uid');
  }

  Stream<List<TaskModel>> getMemberTasks(String uid) {
    return db
        .collectionGroup('assigned_tasks')
        .where('assignee_id', isEqualTo: uid)
        .orderBy('deadline', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      return Future.wait(snapshot.docs.map((taskDoc) async {
        final taskData = taskDoc.data();
        final parentId = taskData['parent_topic'];
        final memberId = taskData['assignee_id'];
        final tasktype = taskData['task_type'];
        final title = taskData['taskname'];
        final status = taskData['status'];

        DocumentSnapshot topicDoc =
            await db.collection('tasks').doc(parentId).get();

        if (!topicDoc.exists) {
          return const TaskModel(
            id: '',
            title: 'No Task',
            section: '',
            type: '',
            deadline: '',
            priority: '',
            assignee: '',
            status: '',
            parentId: '',
            sectionName: '',
          );
        }

        final topicData = topicDoc.data() as Map<String, dynamic>;
        final parentPriority = topicData['priority'] as String? ?? '';
        final parentSection = topicData['section'] as String? ?? '';

        final deadline = taskData['deadline'] as Timestamp;
        final dateString =
            DateFormat('dd/MM/yyyy hh:mm a').format(deadline.toDate());

        DocumentSnapshot userDoc =
            await db.collection('users').doc(memberId).get();

        DocumentSnapshot secDoc =
            await db.collection('sections').doc(parentSection).get();

        String imageUrl = userDoc.exists ? userDoc['photoURL'] : 'unkown';
        String userSec = secDoc.exists ? secDoc['sectionType'] : 'unknown';

        return TaskModel(
          id: taskDoc.id,
          title: title,
          section: parentSection,
          type: tasktype,
          deadline: dateString,
          priority: parentPriority,
          assignee: imageUrl,
          status: status,
          parentId: parentId,
          sectionName: userSec,
        );
      }));
    });
  }
  // TODO notification for announcements
}

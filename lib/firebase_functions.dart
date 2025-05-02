import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:nuntium_mobile/models/topic_content_model.dart';
import 'package:nuntium_mobile/models/user_section_model.dart';
import 'package:nuntium_mobile/models/viewed_task.dart';
import 'package:http/http.dart' as http;

class FirebaseFunctions {
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, String> userCache = {};

  Future<String> processData(String content) async {
    final Uri url = Uri.parse(
        'https://us-central1-nu-publication-system.cloudfunctions.net/cleanInput');

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, dynamic> body = {'text': content};
    final String jsonBody = jsonEncode(body);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('text processed successfully');

        if (data.containsKey('cleanedText')) {
          return data['cleanedText'];
        } else {
          print('warning: procssed text not found in response');
          return '';
        }
      } else {
        print('failed to process text ${response.statusCode}');
        print('failed response body ${response.body}');
        throw Exception('Failed to process text: ${response.statusCode}');
      }
    } catch (e) {
      print('error processing text $e');
      return Future.error(e);
    }
  }

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
          imageUrl: (doc['images'] as List<dynamic>?)?.cast<String>() ?? [],
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
          imageUrl: (doc['images'] as List<dynamic>?)?.cast<String>() ?? [],
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
          imageUrl: (doc['images'] as List<dynamic>?)?.cast<String>() ?? [],
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
            final data = postSnapshot.data() as Map<String, dynamic>;
            final datePosted = data['datePosted'] as Timestamp?;
            final dateString = datePosted?.toDate().toString() ?? '';

            posts.add(NormalItem(
              id: postSnapshot.id,
              imageUrl:
                  (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
              section: data['section'] ?? '',
              title: data['title'] ?? '',
              datePosted: dateString,
            ));
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
            final data = postSnapshot.data() as Map<String, dynamic>;
            final datePosted = data['datePosted'] as Timestamp?;
            final dateString = datePosted?.toDate().toString() ?? '';

            posts.add(NormalItem(
              id: postSnapshot.id,
              imageUrl:
                  (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
              section: data['section'] ?? '',
              title: data['title'] ?? '',
              datePosted: dateString,
            ));
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

  Future<List<NormalItem>> yourWorks() async {
    final userId = auth.currentUser!.uid;

    // 1. Fetch posts where the user is the writing author
    final writingAuthorQuery = db
        .collection('posts')
        .where('writingAuthor', isEqualTo: userId)
        .orderBy('datePosted', descending: true)
        .get();

    // 2. Fetch posts where the user is the pubmat author
    final pubmatAuthorQuery = db
        .collection('posts')
        .where('pubmatAuthor', isEqualTo: userId)
        .orderBy('datePosted', descending: true)
        .get();

    // 3. Wait for both
    final results = await Future.wait([writingAuthorQuery, pubmatAuthorQuery]);

    // 4. Merge and dedupe
    final allDocs = [...results[0].docs, ...results[1].docs];
    final uniqueDocs = {
      for (var doc in allDocs) doc.id: doc,
    }.values.toList();

    // 5. Sort (optional but good UX)
    uniqueDocs.sort((a, b) {
      final aDate = (a['datePosted'] as Timestamp).toDate();
      final bDate = (b['datePosted'] as Timestamp).toDate();
      return bDate.compareTo(aDate);
    });

    // 6. Convert to your model
    return uniqueDocs.map((doc) {
      final datePosted = doc['datePosted'] as Timestamp;
      return NormalItem(
        id: doc.id,
        imageUrl: doc['image'],
        section: doc['section'],
        title: doc['title'],
        datePosted: datePosted.toDate().toString(),
      );
    }).toList();
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
          imageUrl: (doc['images'] as List<dynamic>?)?.cast<String>() ?? [],
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
          imageUrl: (doc['images'] as List<dynamic>?)?.cast<String>() ?? [],
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
      QuerySnapshot sectionSnapshot =
          await db.collection('sections').where('sectionType', whereNotIn: [
        'Managing',
        'Associate',
        'eic',
        'Committee',
      ]).get();

      return sectionSnapshot;
    } catch (e) {
      print('error fetching data $e');
      return Future.error(e);
    }
  }

  Future<UserSectionModel> getUserSection(String uid) async {
    try {
      final DocumentSnapshot userDoc = await getUserInfo(uid);

      if (userDoc.exists) {
        final DocumentSnapshot section =
            await db.collection('sections').doc(userDoc['section']).get();

        return UserSectionModel(
            uid: uid,
            sectionId: userDoc['section'],
            sectionName: section['sectionType']);
      } else {
        return UserSectionModel(
          uid: uid,
          sectionId: "",
          sectionName: "",
        );
      }
    } catch (e) {
      print('error gettting user section data $e');
      return Future.error(e);
    }
  }

//starting here ang need ng logging sa timeline
  Future<void> createTopic(
      String assignee, title, deadline, details, section) async {
    try {
      if (auth.currentUser == null) {
        print("user not logged in");
        return;
      }

      final userData = await getUserInfo(assignee);
      String userRole = '';

      if (userData.exists) {
        userRole = userData['role'];
      }

      DateTime parsedDeadline = DateFormat("d/M/yyyy h:mm a").parse(deadline);
      Timestamp deadlineTimestamp = Timestamp.fromDate(parsedDeadline);

      final Map<String, dynamic> topicData = {
        'assigned_by': assignee,
        'title': title,
        'deadline': deadlineTimestamp,
        'details': details,
        'completed_subtask': 0,
        'total_subtask': 0,
        'created_at': Timestamp.now(),
        'isParent': true,
        'section': section,
        'status': 'pendingAPR',
        'otherMembers': 0,
        'projectStep': 1,
      };

      if (userRole == 'Managing' || userRole == 'Associate') {
        topicData['${userRole}Approved'] = true;
      } else if (userRole == 'section_editors') {
        topicData['SEApproved'] = true;
      }

      await db.collection('tasks').add(topicData).then((docRef) async {
        final dateString = formatTimestamp(Timestamp.now());
        await logInTimeline(
          docRef.id,
          'Task Created',
          'Task was created at $dateString',
          'Topic Created',
        );
      });

      print('topic created successfully');
    } catch (e) {
      return Future.error(e);
    }
  }

  Stream<List<Topic>> getTopics(String sectionId) {
    if (sectionId != 'AhIBjLyTec3anoj3mYkz') {
      return db
          .collection('tasks')
          .where('section', isEqualTo: sectionId)
          .where('status', isNotEqualTo: 'Done')
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
    } else {
      return db
          .collection('tasks')
          .where('section', isNotEqualTo: 'XDEPw2VPYdeFdKQRuRpA')
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
  }

  Stream<List<Topic>> getTopicHistory(String sectionId) {
    Query query = db.collection('tasks');

    if (sectionId != 'All') {
      // history view for eic, managing, associate
      query = query.where('section', isEqualTo: sectionId);
    }
    // For 'All', we don't add a section filter, effectively getting all tasks.
    // We always order by deadline.
    query = query.where('status', isEqualTo: 'Done');
    query = query.orderBy('deadline', descending: true);

    return query.snapshots().asyncMap((snapshot) async {
      // Fetch all section names first to minimize reads inside the loop
      final sectionIds = snapshot.docs
          .map((doc) => doc['section'] as String?)
          .where((id) => id != null)
          .toSet();
      final sectionNames = <String, String>{};
      if (sectionIds.isNotEmpty) {
        final sectionDocs = await db
            .collection('sections')
            .where(FieldPath.documentId, whereIn: sectionIds.toList())
            .get();
        for (var doc in sectionDocs.docs) {
          // Assuming the field name for the section name is 'sectionType'
          sectionNames[doc.id] = doc.data()['sectionType'] as String? ?? doc.id;
        }
      }

      return Future.wait(snapshot.docs.map((topicDoc) async {
        final topicData =
            topicDoc.data() as Map<String, dynamic>; // Cast to Map
        final deadline = topicDoc['deadline'] as Timestamp;
        final dateString =
            DateFormat('dd/MM/yyyy hh:mm a').format(deadline.toDate());
        final topicSectionId = topicData['section'] as String? ?? '';

        // Get section name from the pre-fetched map, fallback to ID
        final sectionName = sectionNames[topicSectionId] ?? topicSectionId;

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
          section: topicSectionId, // Keep the original section ID here
          sectionName: sectionName, // Add the fetched section name
          status: topicData['status'] ?? '',
          deadline: dateString,
          // Ensure correct type casting or provide default values
          totalSubtask: (topicData['total_subtask'] as num?)?.toInt() ?? 0,
          completedSubtask:
              (topicData['completed_subtask'] as num?)?.toInt() ?? 0,
          otherMembers: (topicData['otherMembers'] as num?)?.toInt() ?? 0,
          members: members,
          projectStep: (topicData['projectStep'] as num?)?.toInt() ?? 0,
        );
      }).toList());
    }).handleError((e) {
      print('Error fetching topic history: $e');
      // Consider returning an empty list or rethrowing a more specific error
      return <Topic>[]; // Return empty list on error
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
      final parentSection = topicData['section'] as String? ?? '';

      return Future.wait(snapshot.docs.map((taskDoc) async {
        final taskData = taskDoc.data();
        final memberId = taskData['assignee_id'];
        final tasktype = taskData['task_type'];
        final title = taskData['taskname'];
        final status = taskData['status'];
        final canCaption = taskData['forCaption'];

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
          assignee: imageUrl,
          status: status,
          forCaption: canCaption,
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
      DocumentSnapshot currentUser = await getUserInfo(auth.currentUser!.uid);

      if (!userDoc.exists) {
        throw Exception("User not found");
      }

      if (!currentUser.exists) {
        throw Exception("User not found");
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      taskData['userName'] = userData['username'];
      taskData['role'] = currentUser['role'];
      taskData['currentUser'] = currentUser['username'];

      return taskData;
    }).handleError((e) {
      print('Error fetching topic with user info: $e');
      return Future.error(e);
    });
  }

  Stream<TopicContentModel> streamTaskContents(String topicId) {
    final parentRef = db.collection('tasks').doc(topicId);

    return parentRef.snapshots().asyncMap((parentDoc) async {
      if (!parentDoc.exists) {
        print('parent does not exist');
        return TopicContentModel(
          topicId: topicId,
          pubmatUrls: [],
          headline: '',
          writtenContent: '',
          pubmatId: '',
          writingId: '',
          pubmatStatus: '',
          writtenStatus: '',
        );
      }

      if (parentDoc['section'] != 'XDEPw2VPYdeFdKQRuRpA') {
        final childCollection = parentRef.collection('assigned_tasks');

        final childSnapshot = await childCollection.get();

        if (childSnapshot.docs.isEmpty) {
          print('no assigned tasks');
          return TopicContentModel(
            topicId: topicId,
            pubmatUrls: [],
            headline: '',
            writtenContent: '',
            pubmatId: '',
            writingId: '',
            pubmatStatus: '',
            writtenStatus: '',
          );
        }

        final docs = childSnapshot.docs;
        List<String> pubmatUrls = [];
        String writtenContent = '';
        String headline = '';
        String writingId = '';
        String pubmatId = '';
        String pubmatStatus = '';
        String writtenStatus = '';

        for (final doc in docs) {
          final data = doc.data();
          final docId = doc.id;

          final taskType = data['task_type'] as String?;

          if (taskType == 'Pubmat' && data.containsKey('images')) {
            final dynamic imagesData = data['images'];
            if (imagesData is List) {
              pubmatUrls = imagesData.cast<String>().toList();
            }
            pubmatId = docId;
            pubmatStatus = data['status'] ?? '';
          } else if (taskType == 'Writing' &&
              data.containsKey('content') &&
              data.containsKey('headline')) {
            writtenContent = data['content'] as String? ?? '';
            headline = data['headline'] as String? ?? '';
            writingId = docId;
            writtenStatus = data['status'] ?? '';
          }
        }

        return TopicContentModel(
          topicId: topicId,
          pubmatUrls: pubmatUrls,
          headline: headline,
          writtenContent: writtenContent,
          pubmatId: pubmatId,
          writingId: writingId,
          pubmatStatus: pubmatStatus,
          writtenStatus: writtenStatus,
        );
      }

      // section is 'XDEPw2VPYdeFdKQRuRpA', fallback empty content
      return TopicContentModel(
        topicId: topicId,
        pubmatUrls: [],
        headline: '',
        writtenContent: '',
        pubmatId: '',
        writingId: '',
        pubmatStatus: '',
        writtenStatus: '',
      );
    });
  }

  Future<void> approveToCreate(String topicId) async {
    try {
      final userDoc = await getUserInfo(auth.currentUser!.uid);
      String userRole = '';

      if (userDoc.exists) {
        userRole = userDoc['role'];
      } else {
        userRole = 'unknown';
      }

      Map<String, dynamic> updates = {
        '${userRole}Approved': true,
      };

      // Apply updates
      await db.collection('tasks').doc(topicId).update(updates);

      final dateString = formatTimestamp(Timestamp.now());

      await logInTimeline(
        topicId,
        'Topic Approved by $userRole',
        'Topic was Approved at $dateString',
        'Approved',
      );
    } catch (e) {
      print('Error approving topic: $e');
      return Future.error(e);
    }
  }

  Future<void> updateToPost(String topicId) async {
    try {
      final parentRef = db.collection('tasks').doc(topicId);
      final userDoc = await getUserInfo(auth.currentUser!.uid);
      String userRole = '';

      if (userDoc.exists) {
        userRole = userDoc['role'];
      } else {
        userRole = 'unknown';
      }

      if (userRole == 'section_editors') {
        userRole = 'SE';
      }

      await parentRef.update({'${userRole}ApprovedPST': true});

      await logInTimeline(
        topicId,
        'Topic Published',
        'Topic has been published for readers',
        'Published',
      );
    } catch (e) {
      print('error updating for post: $e');
      return Future.error(e);
    }
  }

  Future<void> rejectToCreate(String topicId, reason, role) async {
    try {
      await db.collection('tasks').doc(topicId).update({
        'status': 'rejected',
        '${role}Approved': false,
        '${role}Rejected': reason,
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

  Future<void> seApprove(String topicId, taskId) async {
    // need na sa log starting dito yung mismong content and mismong comments na
    // this is essentially eb returns the task along with the comments for revision
    try {
      final dbref = db.collection('tasks').doc(topicId);

      await dbref.update({
        'completed_subtask': FieldValue.increment(1),
      });

      await dbref.collection('assigned_tasks').doc(taskId).update({
        'status': 'Approved',
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
        'forCaption': false,
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
              role != 'section_writer') {
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
      String? description;

      final parentDocref = db.collection('tasks').doc(topicId);

      final DocumentSnapshot parentSnap = await parentDocref.get();

      final DocumentSnapshot subTaskSnap =
          await parentDocref.collection('assigned_tasks').doc(taskId).get();

      if (parentSnap.exists && parentSnap.data() != null) {
        final parentData = parentSnap.data() as Map<String, dynamic>;

        description = parentData['details'];

        final username = await getUserInfo(parentSnap['assigned_by']);
        final assigneeSec = await getUserInfo(subTaskSnap['assignee_id']);
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
          assigneeName: assigneeSec['username'],
          canCaption: subTaskSnap['forCaption'],
          assigneeSec: assigneeSec['section'],
          hasStarted: subTaskSnap['status'] != 'To Do',
          projectStep: parentData['projectStep'],
          totalSubtask: parentData['total_subtask'],
          status: subTaskSnap['status'],
          comments: subTaskSnap.data() != null
              ? (subTaskSnap.data() as Map<String, dynamic>)['comment'] ??
                  'No Comments yet'
              : '',
          content: subTaskSnap.data() != null
              ? (subTaskSnap.data() as Map<String, dynamic>)['content'] ??
                  'No Content'
              : '',
          headline: subTaskSnap.data() != null
              ? (subTaskSnap.data() as Map<String, dynamic>)['headline'] ??
                  'No Headlien'
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
    // for contrib and section writer
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
        final canCaption = taskData['forCaption'];

        DocumentSnapshot topicDoc =
            await db.collection('tasks').doc(parentId).get();

        if (!topicDoc.exists) {
          return const TaskModel(
            id: '',
            title: 'No Task',
            section: '',
            type: '',
            deadline: '',
            assignee: '',
            status: '',
            parentId: '',
            sectionName: '',
          );
        }

        final topicData = topicDoc.data() as Map<String, dynamic>;
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
          assignee: imageUrl,
          status: status,
          parentId: parentId,
          sectionName: userSec,
          forCaption: canCaption,
        );
      }));
    });
  }

  Future<void> submitSubTaskContent(
      String topicId, taskId, headline, content) async {
    try {
      final dbref = db.collection('tasks').doc(topicId);

      String cleanedData = await processData(content);

      await dbref.collection('assigned_tasks').doc(taskId).update({
        'headline': headline,
        'content': cleanedData,
        'submittedAt': Timestamp.now(),
        'status': 'Submitted',
      });

      await logInTimeline(
        topicId,
        'Task Submitted',
        content,
        'Task Submitted',
      );
    } catch (e) {
      print('error submitting task $e');
      return Future.error(e);
    }
  }

  Future<void> startTask(String topicId, taskId) async {
    //purpose is to signify in the system when a task was started
    try {
      final dbref = db.collection('tasks').doc(topicId);

      await dbref.collection('assigned_tasks').doc(taskId).update({
        'status': 'Doing',
        'started_at': Timestamp.now(),
      });

      await dbref.update({
        'doing_at': Timestamp.now(),
        'status': 'Doing',
      });

      await logInTimeline(
        topicId,
        'Task Started',
        'Task was Started',
        'Task Started',
      );
    } catch (e) {
      print('error starting task $e');
      return Future.error(e);
    }
  }

  Future<void> uploadMultiImage(
    String topicId,
    taskId,
    List<String> imageUrls,
  ) async {
    final dbref = db.collection('tasks').doc(topicId);

    await dbref.update({
      'submittedAt': Timestamp.now(),
      'images': FieldValue.arrayUnion(imageUrls),
      'content': 'Images uploaded',
      'status': 'Submitted',
    });

    await dbref.collection('assigned_tasks').doc(taskId).update({
      'submittedAt': Timestamp.now(),
      'content': 'Images uploaded',
      'status': 'Submitted',
    });

    await logInTimeline(
      topicId,
      'Task Submitted',
      'Images uploaded',
      'Task Submitted',
    );
  }

  Future<void> pubmatImageUpload(String topicId, taskId, imageUrl) async {
    final dbref = db.collection('tasks').doc(topicId);

    await dbref.collection('assigned_tasks').doc(taskId).update({
      'submittedAt': Timestamp.now(),
      'content': imageUrl,
      'status': 'Submitted',
    });

    await logInTimeline(
      topicId,
      'Task Submitted',
      'Images uploaded',
      'Task Submitted',
    );
  }

  Future<void> pubmatMultiUpload(
      String topicId, taskId, List<String> imageUrls) async {
    final dbref = db.collection('tasks').doc(topicId);

    await dbref.collection('assigned_tasks').doc(taskId).update({
      'submittedAt': Timestamp.now(),
      'images': FieldValue.arrayUnion(imageUrls),
      'content': 'Pubmat Images uploaded',
      'status': 'Submitted',
    });

    await logInTimeline(
      topicId,
      'Task Submitted',
      'Images uploaded',
      'Task Submitted',
    );
  }

  Stream<List<String>> retrieveImages(String topicId, taskId) {
    return db
        .collection('tasks')
        .doc(topicId)
        .collection('assigned_tasks')
        .doc(taskId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null && data.containsKey('images')) {
          List<String> images =
              (data['images'] as List<dynamic>).cast<String>();
          return images;
        } else {
          return [];
        }
      }
      return [];
    });
  }

  Stream<List<String>> retrieveAllImages(String topicId) {
    return db.collection('tasks').doc(topicId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null && data.containsKey('images')) {
          List<String> images =
              (data['images'] as List<dynamic>).cast<String>();
          return images;
        } else {
          return [];
        }
      }
      return [];
    });
  }

  Future<void> deleteImages(
      int index, List<String> retrievedImages, String topicId, taskId) async {
    try {
      String imageUrl = retrievedImages[index];

      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      final collection = FirebaseFirestore.instance.collection('image_hashes');

      await storageRef.delete();

      await db.collection('tasks').doc(topicId).update({
        'images': FieldValue.arrayRemove([retrievedImages[index]]),
      });

      final querySnapshot =
          await collection.where('url', isEqualTo: imageUrl).get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        print('Deleted document: ${doc.id}');
      }

      await logInTimeline(
        topicId,
        'None',
        'Deleted Image',
        'Deleted',
      );
    } catch (e) {
      print('error deletingi image $e');
      return Future.error(e);
    }
  }

  Future<void> deleteImageInParent(
      int index, List<String> retrievedImages, String topicId) async {
    try {
      String imageUrl = retrievedImages[index];

      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);

      await storageRef.delete();

      final collection = FirebaseFirestore.instance.collection('image_hashes');

      final querySnapshot =
          await collection.where('url', isEqualTo: imageUrl).get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        print('Deleted document: ${doc.id}');
      }

      await db.collection('tasks').doc(topicId).update({
        'images': FieldValue.arrayRemove([retrievedImages[index]]),
      });

      await logInTimeline(
        topicId,
        'None',
        'Deleted Image',
        'Deleted',
      );
    } catch (e) {
      print('error deletingi image $e');
      return Future.error(e);
    }
  }

  Future<void> deleteImageForPubmat(
      int index, List<String> retrievedImages, String topicId, taskId) async {
    try {
      String imageUrl = retrievedImages[index];

      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);

      await storageRef.delete();

      await db
          .collection('tasks')
          .doc(topicId)
          .collection('assigned_tasks')
          .doc(taskId)
          .update({
        'images': FieldValue.arrayRemove([retrievedImages[index]]),
        'testdeleted': true,
      });

      await logInTimeline(
        topicId,
        'None',
        'Deleted Image',
        'Deleted',
      );
    } catch (e) {
      print('error deletingi image $e');
      return Future.error(e);
    }
  }

  Future<void> massApprove(String topicId, pubmatId, writingId) async {
    try {
      final parentRef = db.collection('tasks').doc(topicId);
      // final userInfo = await getUserInfo(auth.currentUser!.uid);
      final batch = db.batch();

      batch.update(parentRef.collection('assigned_tasks').doc(pubmatId), {
        'status': 'Approved',
        'approvedAt': Timestamp.now(),
        // 'approved_by': auth.currentUser!.uid,
      });

      batch.update(parentRef.collection('assigned_tasks').doc(writingId), {
        'status': 'Approved',
        'approvedAt': Timestamp.now(),
      });

      await logInTimeline(
        topicId,
        'Pubmat task approved',
        'Pubmat approved and ready for management approval',
        'Approved',
      );

      await logInTimeline(
        topicId,
        'Written task approved',
        'Written content approved and ready for management approval',
        'Approved',
      );

      await batch.commit();
    } catch (e) {
      print('error mass approving $e');
      return Future.error(e);
    }
  }

  Future<void> deleteTopic(String topicId) async {
    try {
      final topicRef =
          FirebaseFirestore.instance.collection('tasks').doc(topicId);
      final assignedTasksRef = topicRef.collection('assigned_tasks');
      final timelineTaskRef = topicRef.collection('timeline');

      // Delete all documents inside the 'assigned_tasks' subcollection
      final assignedTasksSnapshot = await assignedTasksRef.get();
      final timelineTaskSnapshot = await timelineTaskRef.get();
      for (var doc in assignedTasksSnapshot.docs) {
        await assignedTasksRef.doc(doc.id).delete();
      }

      for (var doc in timelineTaskSnapshot.docs) {
        await timelineTaskRef.doc(doc.id).delete();
      }

      // Now delete the parent topic document
      await topicRef.delete();

      // system na ang logs nito

      print('Topic and assigned tasks deleted successfully');
    } catch (e) {
      print('Error deleting topic and subcollection: $e');
    }
  }

  Future<void> deleteAssignedTask(String topicId, String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(topicId)
          .collection('assigned_tasks')
          .doc(taskId)
          .delete();

      await logInTimeline(
        taskId,
        'Assigned Task deleted',
        'An assigned task was deleted',
        'Deleted',
      );

      print('Assigned task deleted successfully');
    } catch (e) {
      print('Error deleting assigned task: $e');
    }
  }

  Future<void> writeComment(
    String topicId,
    String taskId,
    String comment,
    String content,
  ) async {
    try {
      final commentData = {
        'comment': comment,
        'userId': auth.currentUser!.uid,
        'comment_at': FieldValue.serverTimestamp(),
        'status': 'Returned'
      };

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(topicId)
          .collection('assigned_tasks')
          .doc(taskId)
          .update(commentData);

      await logInTimeline(topicId, comment, content, 'Commented');

      print('Comment added successfully');
    } catch (e) {
      print('Error writing comment: $e');
    }
  }

  // TODO notification for announcements
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/models/comment.dart';
import 'package:nuntium_mobile/models/member.dart';
import 'package:nuntium_mobile/models/membermodel.dart';
import 'package:nuntium_mobile/models/notif.dart';
import 'package:nuntium_mobile/models/taskmodel.dart';
import 'package:nuntium_mobile/models/timeline_item_model.dart';
import 'package:nuntium_mobile/models/topic.dart';
import 'package:nuntium_mobile/models/featuredcard.dart';
import 'package:nuntium_mobile/models/normalitem.dart';
import 'package:nuntium_mobile/models/viewed_task.dart';

final firebaseFunctions = FirebaseFunctions();

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final topicsProvider =
    StreamProvider.family<List<Topic>, String>((ref, sectionId) {
  return firebaseFunctions.streamTopics(sectionId);
});

final featuredCardProvider = StreamProvider<List<FeaturedItem>>((ref) {
  return firebaseFunctions.streamFeaturedItems();
});

final normalCardProvider = StreamProvider<List<NormalItem>>((ref) {
  return firebaseFunctions.streamNormalItems();
});

final discoverContentProvider = StreamProvider<List<NormalItem>>((ref) {
  return firebaseFunctions.streamForDiscover();
});

final bookmarkContentProvider =
    StreamProvider.family.autoDispose<List<NormalItem>, String>((ref, userId) {
  return firebaseFunctions.readingBookmarkList(userId);
});

final reditContentProvider =
    StreamProvider.family.autoDispose<List<NormalItem>, String>((ref, userId) {
  return firebaseFunctions.readingHistoryList(userId);
});

final commentsContentProvider =
    StreamProvider.family<List<Comment>, String>((ref, postId) {
  return firebaseFunctions.streamComments(postId);
});

final postContentProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, String postId) {
  return firebaseFunctions.streamPostData(postId);
});

final yourWorksProvider = FutureProvider<List<NormalItem>>((ref) {
  return firebaseFunctions.yourWorks();
});

final userDataProfile =
    FutureProvider.family<DocumentSnapshot, String>((ref, String userId) {
  return firebaseFunctions.getUserInfo(userId);
});

final latestTermlyProvider = StreamProvider<List<NormalItem>>((ref) {
  return firebaseFunctions.viewFeaturedTermly();
});

final allTermlyProvider = StreamProvider<List<NormalItem>>((ref) {
  return firebaseFunctions.viewAllTermly();
});

final membersProvider = FutureProvider<List<Member>>((ref) {
  return firebaseFunctions.getOrgMembers();
});

final postNotificationsProvider = StreamProvider<List<NotifItem>>((ref) {
  return firebaseFunctions.streamPostNotifications();
});

final sectionProvider = FutureProvider<QuerySnapshot>((ref) {
  return firebaseFunctions.getSections();
});

final topicProvider =
    StreamProvider.family<List<Topic>, String>((ref, sectionId) {
  return firebaseFunctions.getTopics(sectionId);
});

final topicDataProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, String topicId) {
  return firebaseFunctions.streamTopicInfo(topicId);
});

final taskProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, topicId) {
  return firebaseFunctions.getTasks(topicId);
});

final memberTasksProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, uid) {
  return firebaseFunctions.getMemberTasks(uid);
});

final memberListProvider =
    FutureProvider.family<List<Membermodel>, String>((ref, String sectionId) {
  return firebaseFunctions.getUsersInSection(sectionId);
});

final taskWrittenProvider =
    FutureProvider.family<ViewedTask, (String, String)>((ref, ids) async {
  final topicId = ids.$1;
  final taskId = ids.$2;
  return firebaseFunctions.taskContentWritten(topicId, taskId);
});

final timelineProvider = StreamProvider.family<List<TimelineItemModel>, String>(
    (ref, String topicId) {
  return firebaseFunctions.getTimelineItems(topicId);
});

final allSectionTasksProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, String topicId) {
  return firebaseFunctions.getSectionTasks(topicId);
});

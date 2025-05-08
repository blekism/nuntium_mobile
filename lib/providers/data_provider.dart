import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:nuntium_mobile/models/topic_content_model.dart';
import 'package:nuntium_mobile/models/user_section_model.dart';
import 'package:nuntium_mobile/models/viewed_task.dart';

final firebaseFunctions = FirebaseFunctions();

final topicsProvider =
    StreamProvider.family.autoDispose<List<Topic>, String>((ref, sectionId) {
  return firebaseFunctions.streamTopics(sectionId);
});

final featuredCardProvider =
    StreamProvider.autoDispose<List<FeaturedItem>>((ref) {
  return firebaseFunctions.streamFeaturedItems();
});

final normalCardProvider = StreamProvider.autoDispose<List<NormalItem>>((ref) {
  return firebaseFunctions.streamNormalItems();
});

final discoverContentProvider =
    StreamProvider.autoDispose<List<NormalItem>>((ref) {
  return firebaseFunctions.streamForDiscover();
});

final postsForApprovalProvider =
    StreamProvider.autoDispose<List<NormalItem>>((ref) {
  return firebaseFunctions.streamForPostApprovals();
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
    StreamProvider.family.autoDispose<List<Comment>, String>((ref, postId) {
  return firebaseFunctions.streamComments(postId);
});

final postContentProvider = StreamProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, String postId) {
  return firebaseFunctions.streamPostData(postId);
});

final yourWorksProvider = FutureProvider.autoDispose<List<NormalItem>>((ref) {
  return firebaseFunctions.yourWorks();
});

final userDataProfile = FutureProvider.family
    .autoDispose<DocumentSnapshot, String>((ref, String userId) {
  return firebaseFunctions.getUserInfo(userId);
});

final latestTermlyProvider =
    StreamProvider.autoDispose<List<NormalItem>>((ref) {
  return firebaseFunctions.viewFeaturedTermly();
});

final allTermlyProvider = StreamProvider.autoDispose<List<NormalItem>>((ref) {
  return firebaseFunctions.viewAllTermly();
});

final membersProvider = FutureProvider.autoDispose<List<Member>>((ref) {
  return firebaseFunctions.getOrgMembers();
});

final postNotificationsProvider =
    StreamProvider.autoDispose<List<NotifItem>>((ref) {
  return firebaseFunctions.streamPostNotifications();
});

final sectionProvider = FutureProvider.autoDispose<QuerySnapshot>((ref) {
  return firebaseFunctions.getSections();
});

final topicProvider =
    StreamProvider.family.autoDispose<List<Topic>, String>((ref, sectionId) {
  return firebaseFunctions.getTopics(sectionId);
});

final topicDataProvider = StreamProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, String topicId) {
  return firebaseFunctions.streamTopicInfo(topicId);
});

final taskProvider =
    StreamProvider.family.autoDispose<List<TaskModel>, String>((ref, topicId) {
  return firebaseFunctions.getTasks(topicId);
});

final memberTasksProvider =
    StreamProvider.family.autoDispose<List<TaskModel>, String>((ref, uid) {
  return firebaseFunctions.getMemberTasks(uid);
});

final memberListProvider = FutureProvider.family
    .autoDispose<List<Membermodel>, String>((ref, String sectionId) {
  return firebaseFunctions.getUsersInSection(sectionId);
});

final taskWrittenProvider = FutureProvider.family
    .autoDispose<ViewedTask, (String, String)>((ref, ids) async {
  final topicId = ids.$1;
  final taskId = ids.$2;
  return firebaseFunctions.taskContentWritten(topicId, taskId);
});

final timelineProvider = StreamProvider.family
    .autoDispose<List<TimelineItemModel>, String>((ref, String topicId) {
  return firebaseFunctions.getTimelineItems(topicId);
});

final retImagesProvider = StreamProvider.family
    .autoDispose<List<String>, (String, String)>((ref, ids) {
  final topicId = ids.$1;
  final taskId = ids.$2;
  return firebaseFunctions.retrieveImages(topicId, taskId);
});

final singleViewTopicContent = StreamProvider.family
    .autoDispose<TopicContentModel, String>((ref, String topicId) {
  return firebaseFunctions.streamTaskContents(topicId);
});

final viewAllImageInParent = StreamProvider.family
    .autoDispose<List<String>, String>((ref, String topicId) {
  return firebaseFunctions.retrieveAllImages(topicId);
});

final userSectionProvider = FutureProvider.family
    .autoDispose<UserSectionModel, String>((ref, String uid) {
  return firebaseFunctions.getUserSection(uid);
});

final historyProvider = StreamProvider.family
    .autoDispose<List<Topic>, String>((ref, String sectionId) {
  return firebaseFunctions.getTopicHistory(sectionId);
});

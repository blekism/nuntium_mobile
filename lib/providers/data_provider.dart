import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/models/comment.dart';
import 'package:nuntium_mobile/models/member.dart';
import 'package:nuntium_mobile/models/notif.dart';
import 'package:nuntium_mobile/models/topic.dart';
import 'package:nuntium_mobile/models/featuredcard.dart';
import 'package:nuntium_mobile/models/normalitem.dart';

final firebaseFunctions = FirebaseFunctions();

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

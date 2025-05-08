import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/articlepage.dart';
import 'package:nuntium_mobile/Pages/Homepage/aaaapdf.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:nuntium_mobile/providers/read_provider.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  final firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context) {
    final postNotifications = ref.watch(postNotificationsProvider);

    // Side effect: Mark notifications as read when the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (postNotifications is AsyncData) {
        final unreadNotifications = postNotifications.value
            ?.where((notification) => !notification.isRead)
            .toList();

        if (unreadNotifications != null && unreadNotifications.isNotEmpty) {
          final notificationIds = unreadNotifications.map((e) => e.id).toList();
          firebaseFunctions.markNotificationsAsRead(notificationIds);

          ref.invalidate(postNotificationsProvider);
        }
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Notifications',
        hasNavigated: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            postNotifications.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const Center(child: Text('No notifications for now!'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return GestureDetector(
                      onTap: !item.isTermly
                          ? () {
                              print('Navigating to content page from normal');
                              final notifier =
                                  ref.read(savedPostsProvider.notifier);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ArticlePage(
                                            postId: item.postId,
                                          )));

                              FirebaseAuth.instance.currentUser != null
                                  ? notifier.markAsRead(item.postId, false)
                                  : null;
                            }
                          : () {
                              print('Navigating to content page from normal');
                              final notifier =
                                  ref.read(savedPostsProvider.notifier);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PdfViewerScreen(
                                            pdfUrl: item.pdfUrl,
                                            isPosted: true,
                                            postId: item.postId,
                                          )));

                              FirebaseAuth.instance.currentUser != null
                                  ? notifier.markAsRead(item.postId, false)
                                  : null;
                            },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(item.imageUrl[0]),
                        ),
                        title: Text(
                          'New ${item.section} \nArticle: ${item.headline}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0XFF020B40),
                            overflow: TextOverflow.ellipsis,
                            fontStyle: item.isRead
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        subtitle: Text(
                          item.datePosted,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0XFF020B40),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              error: (error, stack) => Center(child: Text('Error: $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

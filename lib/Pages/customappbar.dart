import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Homepage/notificationpage.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? appbarTitle;
  final bool? hasNavigated;

  const CustomAppBar({
    super.key,
    this.appbarTitle,
    this.hasNavigated,
  });
  //TODO YUNG DI NA DAPAT OPENABLE YUNG NOTIFS PAG ANDUN NA SI USER

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final postNotifications = ref.watch(postNotificationsProvider);
      bool hasUnreadNotifications = false;

      if (postNotifications is AsyncData) {
        hasUnreadNotifications =
            postNotifications.value?.any((item) => !item.isRead) ?? false;
      }

      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(90), // Shadow color
              spreadRadius: 5, // How far the shadow spreads
              blurRadius: 7, // The blur intensity of the shadow
              offset: const Offset(0,
                  3), // Changes the position of the shadow (horizontal, vertical)
            ),
          ],
          gradient: const LinearGradient(
            colors: [
              Color(0xFF020B40),
              Color(0xFF203E83),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          title: Text(
            appbarTitle ?? 'Custom App Bar',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            hasNavigated == false
                ? IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications),
                        if (hasUnreadNotifications)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      // Navigate to notification page
                      hasNavigated == true
                          ? null
                          : Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationPage()),
                            );
                      print('navigated to notif page');
                    },
                  )
                : const SizedBox.shrink(),
          ],
        ),
      );
    });
  }
}

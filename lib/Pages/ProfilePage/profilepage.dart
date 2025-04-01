import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Homepage/CardsTemplate/normalpost.dart';
import 'package:nuntium_mobile/Pages/ProfilePage/passwordreset.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final VoidCallback? onLogout;

  const ProfilePage({
    super.key,
    this.onLogout,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _refreshData() async {
    ref.invalidate(yourWorksProvider);

    await ref.read(yourWorksProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    final yourWorks = ref.watch(yourWorksProvider);
    final userProfile = ref.watch(userDataProfile(currentUser!.uid));

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: _profileAppbar(),
      body: CustomRefreshIndicator(
        onRefresh: _refreshData,
        builder: (
          BuildContext context,
          Widget child,
          IndicatorController controller,
        ) {
          return AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, _) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                        top: controller.value *
                            MediaQuery.of(context).size.height *
                            0.1),
                    child: child,
                  ),
                  if (controller.isArmed)
                    const Text(
                      "Release to Refresh",
                      style: TextStyle(
                          color: Color(0XFF020B40),
                          fontWeight: FontWeight.w700,
                          fontSize: 17),
                    ),
                  if (controller.isLoading || controller.isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0XFF020B40),
                      ), // Change color
                      strokeWidth: 4.0,
                    ),
                ],
              );
            },
          );
        },
        child: userProfile.when(
          data: (userProfile) {
            if (!userProfile.exists) {
              return const Center(
                child: Text('Error: No User Found'),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: screenHeight * .20,
                          width: screenWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0XFFB8CFED),
                                  Color(0XFFFFF3CD),
                                  Color(0XFFCB82AE),
                                  Color(0XFF746DA9),
                                  Color(0XFF1D57A3),
                                ]),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.10),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: MediaQuery.of(context).size.height * 0.20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withAlpha(130),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    userProfile['photoURL'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0XFFE4BD3D).withAlpha(166),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userProfile['role'],
                        style: const TextStyle(
                            color: Color(0XFF020B40),
                            fontWeight: FontWeight.w700,
                            fontSize: 17),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userProfile['username'],
                      style: const TextStyle(
                          color: Color(0XFF020B40),
                          fontWeight: FontWeight.w800,
                          fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Editor In Chief 2024-2025',
                      style: const TextStyle(
                        color: Color(0XFF020B40),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const Divider(
                      indent: 80,
                      endIndent: 80,
                    ),
                    Text(
                      userProfile['email'],
                      style: const TextStyle(
                        color: Color(0XFF929292),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .5,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return PasswordResetModal(
                              onLogout: widget.onLogout,
                            );
                          }));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFF020B40),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Password Reset',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Published Works',
                        style: TextStyle(
                            color: Color(0XFF020B40),
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      indent: 20,
                      endIndent: 20,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      child: yourWorks.when(
                        data: (yourWorks) {
                          if (yourWorks.isEmpty) {
                            return const Center(
                                child: Text('Start Contributing now!'));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: yourWorks.length,
                            itemBuilder: (context, index) {
                              final item = yourWorks[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, right: 16.0, bottom: 16),
                                child: NormalPostCard(
                                  imageAsset: item.imageUrl,
                                  sectionType: item.section,
                                  articleTitle: item.title,
                                  postID: item.id,
                                  isAuthenticated: currentUser != null,
                                  datePosted: item.datePosted,
                                  isLoading: false,
                                  isTermly: false,
                                ),
                              );
                            },
                          );
                        },
                        loading: () => SizedBox(
                            height: MediaQuery.of(context).size.height * .15,
                            child: NormalPostCard(
                              isLoading: true,
                              isTermly: false,
                            )),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (error, stack) => Center(child: Text('Error: $error')),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  AppBar _profileAppbar() {
    return AppBar(
      title: const Text(
        'Profile',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    );
  }
}

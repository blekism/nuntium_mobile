import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TaskContentPage extends StatefulWidget {
  final String? taskid;
  const TaskContentPage({super.key, this.taskid});

  @override
  State<TaskContentPage> createState() => _TaskContentPage();
}

class _TaskContentPage extends State<TaskContentPage> {
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String? title;
  String? section;
  List<String> timelineAuthors = [];
  List<String> taskAssignees = [];
  String? writingContent;
  String? pubmatImageUrl;

  Future<void> fetchData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('tasks')
          .doc(widget.taskid)
          .get();

      if (snapshot.exists) {
        setState(() {
          title = snapshot.data()?['title'];
          String? sectionId = snapshot.data()?['section'];
          if (sectionId != null) {
            fetchSectionType(sectionId);
          } else {
            section = 'Unknown Section';
          }
        });

        await fetchAssignedTasks(widget.taskid!);

        await fetchTimeline(widget.taskid!);
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAssignedTasks(String taskId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> assignedTasksSnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .collection('assigned_tasks')
              .get();

      print(assignedTasksSnapshot.docs.length);

      Set<String> assignees = {};

      for (var doc in assignedTasksSnapshot.docs) {
        var data = doc.data();
        print('Fetched data: $data');
        String taskType = data['task_type'];

        if (taskType == 'writing') {
          print('Writing Task Content: ${data['content']}');
          writingContent = data['content'];
        } else if (taskType == 'pubmat') {
          List<dynamic> images = data['images'] ?? [];
          if (images.isNotEmpty) {
            print('Pubmat Image URL: ${images[0]}');
            pubmatImageUrl = images[0];
          }
        }

        assignees.add(data['assignee_id'] as String);
      }

      List<String> usernames = [];
      for (String assigneeId in assignees) {
        String username = await fetchUsername(assigneeId) ?? 'Unknown User';
        usernames.add(username);
      }

      setState(() {
        taskAssignees = usernames;
      });
      print('Fetched assignees: $taskAssignees');
    } catch (e) {
      print('Error fetching assigned tasks: $e');
    }
  }

  Future<void> fetchTimeline(String taskId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> timelineSnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .collection('timeline')
              .where('timelinestatus', isEqualTo: 'approved')
              .get();

      List<String> authors = timelineSnapshot.docs
          .map((doc) => doc.data()['author'] as String)
          .toSet() // Convert to Set to remove duplicates
          .toList();

      setState(() {
        timelineAuthors = authors;
      });
      print('Fetched authors: $timelineAuthors');
    } catch (e) {
      print('Error fetching timeline: $e');
    }
  }

  Future<void> fetchSectionType(String sectionId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> sectionSnapshot =
          await FirebaseFirestore.instance
              .collection('sections')
              .doc(sectionId)
              .get();

      if (sectionSnapshot.exists) {
        setState(() {
          section = sectionSnapshot.data()?['sectionType'];
        });
      } else {
        print('Section document does not exist');
        section = 'Unknown Section';
      }
    } catch (e) {
      print('Error fetching section type: $e');
      section = 'Error Section';
    }
  }

  Future<String?> fetchUsername(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        return userSnapshot.data()?['username'];
      } else {
        print('User document does not exist');
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching username: $e');
      return 'Error User';
    }
  }

  Future<void> submitContent() async {
    try {
      CollectionReference posts =
          FirebaseFirestore.instance.collection('posts');

      String formattedTime =
          DateFormat('h:mm a').format(DateTime.now().toLocal());

      Map<String, dynamic> postData = {
        'appearIn': "general",
        'title': title,
        'content': writingContent,
        'section': section,
        'image': pubmatImageUrl,
        'isFeatured': true,
        'isNormal': true,
        'time': formattedTime,
        'datePosted': FieldValue.serverTimestamp(),
      };

      await posts.add(postData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content posted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post content: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    pubmatImageUrl != null
                        ? pubmatImageUrl!
                        : 'https://firebasestorage.googleapis.com/v0/b/nu-publication-system.firebasestorage.app/o/burge.jpg?alt=media&token=e301878c-4317-4517-b9eb-91279f82aca9',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: 412,
                    height: 70,
                    decoration: const ShapeDecoration(
                      color: Color(0xFF008117),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    alignment: Alignment.bottomCenter,
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Ready For Posting',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                _topButtons(context),
                _textOverlay(
                  context,
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.4, // 40% of screen upon opening
                  minChildSize: 0.4, // 40% of screen
                  maxChildSize: 0.83, // 90% of screen
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(20),
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // _textContent(widget.postdata?['content']),
                                    _textContent(context),

                                    const SizedBox(height: 15),
                                    _divider(context),
                                    const SizedBox(height: 15),
                                    Wrap(
                                      children: [
                                        const Text(
                                          'Approved By:',
                                          style: TextStyle(
                                            color: Color(0XFF020B40),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          timelineAuthors.join(', '),
                                          style: const TextStyle(
                                            color: Color(0XFF020B40),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          submitContent();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xff020B40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Post Content',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Container _divider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width * .85,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Positioned _topButtons(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.1 - 1,
      left: 20,
      right: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * .18,
            height: MediaQuery.of(context).size.width * .12,
            child: ElevatedButton(
              onPressed: () {
                print('pabalik na ko from content');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFFF5F5F5),
                elevation: 8,
              ),
              child: Image.asset(
                'assets/images/back.png',
                width: 36,
                height: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Positioned _textOverlay(BuildContext context) {
    return Positioned(
      left: 20,
      top: MediaQuery.of(context).size.height * 0.38, // Adjust to align
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0XFF020B40),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 5.0,
                  spreadRadius: 0.0,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
            child: Text(
              section ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto Slab'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'By:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                taskAssignees.join(', '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            DateTime.now().toLocal().toString().split(' ')[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Text _textContent(context) {
    return Text(
      writingContent != null ? writingContent! : "No content available",
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

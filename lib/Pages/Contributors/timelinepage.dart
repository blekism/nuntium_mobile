import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/timelinecardtemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TimelinePage extends StatefulWidget {
  final String? taskId;

  const TimelinePage({
    super.key,
    required this.taskId,
  });

  @override
  State<TimelinePage> createState() => _TimelinePage();
}

class _TimelinePage extends State<TimelinePage> {
  final List<Map<String, String>> timelineData = [
    {
      "timelinestatus": "Reviewing",
      "date": "Sep 10, 2002 10:00",
      "revision": "awaiting revision",
    },
    {
      "timelinestatus": "Reviewed",
      "date": "Aug 27, 2002 13:04",
      "revision": "Revision 2",
    },
    {
      "timelinestatus": "Reviewed",
      "date": "Aug 4, 2002 13:04",
      "revision": "Revision 1",
    },
  ];

  List<Map<String, dynamic>> timelineHistory = [];

  late final Stream<QuerySnapshot> _timelineStream;

  @override
  void initState() {
    super.initState();
    _timelineStream = FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('timeline')
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: StreamBuilder(
          stream: _timelineStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('An error occurred'),
              );
            }
            timelineHistory = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // Convert Firestore Timestamp to a formatted string
              String formattedDate = "No Date";
              if (data["date"] != null && data["date"] is Timestamp) {
                DateTime dateTime = (data["date"] as Timestamp).toDate();
                formattedDate =
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
              }

              return {
                ...data,
                "formattedDate": formattedDate,
              };
            }).toList();

            return ListView.builder(
              itemCount: timelineHistory.length,
              itemBuilder: (context, index) {
                final item = timelineHistory[index];

                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: index == 0, // Mark the first item
                  isLast:
                      index == timelineHistory.length - 1, // Mark the last item
                  indicatorStyle: IndicatorStyle(
                    width: 25,
                    color: index == 0
                        ? const Color(0xffD4AF37)
                        : const Color(0xff020B40),
                  ),
                  beforeLineStyle: index == 0
                      ? const LineStyle(
                          color:
                              Colors.transparent) // No line before first item
                      : const LineStyle(color: Color(0xff020B40), thickness: 3),
                  afterLineStyle: index == timelineHistory.length - 1
                      ? const LineStyle(
                          color: Colors.transparent) // No line after last item
                      : const LineStyle(color: Color(0xff020B40), thickness: 3),
                  endChild: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TimelineCard(
                      timelinestatus: item["timelinestatus"],
                      date: item["formattedDate"],
                      revision: item["revision"],
                      comments: item["comment"],
                      content: item["content"],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'Timeline',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }
}

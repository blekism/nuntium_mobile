import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineCard extends StatefulWidget {
  final String? timelinestatus;
  final String? date;
  final String? revision;
  final String? content;
  final String? comments;

  const TimelineCard({
    super.key,
    this.timelinestatus,
    this.date,
    this.revision,
    this.content,
    this.comments,
  });

  @override
  State<TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  bool _showDetails = false;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.content ?? '';
    _commentsController.text = widget.comments ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showDetails
          ? _timelineDetailsCard(
              _contentController,
              _commentsController,
            )
          : _timelineCard(),
    );
  }

  Widget _timelineCard() {
    return GestureDetector(
      key: const ValueKey(1),
      onTap: _toggleDetails,
      child: Stack(
        children: [
          SizedBox(
            height: 100,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              color: const Color(0xfff5f5f5),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xff020B40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.timelinestatus ?? 'No Status',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          widget.date ?? 'No Date',
                          style: const TextStyle(color: Color(0xff020B40)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.revision ?? 'No Revision',
                    style: const TextStyle(color: Color(0xffD4AF37)),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8, right: 8),
              child: Icon(Icons.arrow_drop_down, color: Colors.grey, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineDetailsCard(TextEditingController contentController,
      TextEditingController commentsController) {
    return GestureDetector(
      onTap: _toggleDetails,
      child: Card(
        key: const ValueKey(2),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: const Color(0xfff5f5f5),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Content",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: contentController,
                maxLines: 3,
                readOnly: true,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: 'Enter content...',
                ),
              ),
              const SizedBox(height: 10),
              const Text("Comments",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: commentsController,
                maxLines: 2,
                readOnly: true,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: 'Enter comments...',
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 0, right: 0),
                  child:
                      Icon(Icons.arrow_drop_up, color: Colors.grey, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

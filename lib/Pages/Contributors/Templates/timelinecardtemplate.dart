import 'package:flutter/material.dart';

class TimelineCard extends StatefulWidget {
  final String? timelinestatus;
  final String? date;
  final String? revision;

  const TimelineCard({
    super.key,
    this.timelinestatus,
    this.date,
    this.revision,
  });

  @override
  State<TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  bool _showDetails = false;

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
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
      child: _showDetails ? _timelineDetailsCard() : _timelineCard(),
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

  Widget _timelineDetailsCard() {
    return GestureDetector(
      onTap: _toggleDetails,
      child: Card(
        key: const ValueKey(2),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: const Color(0xfff5f5f5),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Content", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: 'Enter content...',
                ),
              ),
              SizedBox(height: 10),
              Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: 'Enter comments...',
                ),
              ),
              SizedBox(height: 10),
              Align(
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

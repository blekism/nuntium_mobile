import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/timelinecardtemplate.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimelineV2Page extends ConsumerStatefulWidget {
  final String topicId, title, sectionName, deadline;
  final int projectStep, totalSubtask;

  const TimelineV2Page({
    super.key,
    required this.topicId,
    required this.title,
    required this.sectionName,
    required this.deadline,
    required this.totalSubtask,
    required this.projectStep,
  });

  @override
  ConsumerState<TimelineV2Page> createState() => _TimelineV2PageState();
}

class _TimelineV2PageState extends ConsumerState<TimelineV2Page> {
  @override
  Widget build(BuildContext context) {
    final timelineView = ref.watch(timelineProvider(widget.topicId));

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Timeline',
        hasNavigated: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF020B40),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ' ${widget.sectionName} | Due on ${widget.deadline} | ${widget.totalSubtask} Tasks ',
                    style: const TextStyle(
                      color: Color(0xFF505050),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const SizedBox(height: 10),
                StepProgressIndicator(
                  totalSteps: 6,
                  currentStep: widget.projectStep,
                  selectedColor: const Color(0XFF020B40),
                  unselectedColor: const Color(0XFF0E0E0E).withAlpha(90),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const ShapeDecoration(
                color: Color(0xFFECEEF5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: timelineView.when(
                  data: (timelineData) {
                    if (timelineData.isEmpty) {
                      return const Center(
                        child: Text('No Timeline data'),
                      );
                    }

                    return ListView.builder(
                      itemCount: timelineData.length,
                      itemBuilder: (context, index) {
                        final item = timelineData[index];

                        return TimelineTile(
                          alignment: TimelineAlign.start,
                          isFirst: index == 0,
                          isLast: index == timelineData.length - 1,
                          indicatorStyle: IndicatorStyle(
                            width: 25,
                            color: index == 0
                                ? const Color(0xffD4AF37)
                                : const Color(0xff020B40),
                          ),
                          beforeLineStyle: index == 0
                              ? const LineStyle(
                                  color: Colors
                                      .transparent) // No line before first item
                              : const LineStyle(
                                  color: Color(0xff020B40), thickness: 3),
                          afterLineStyle: index == timelineData.length - 1
                              ? const LineStyle(
                                  color: Colors
                                      .transparent) // No line after last item
                              : const LineStyle(
                                  color: Color(0xff020B40), thickness: 3),
                          endChild: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TimelineCard(
                              timelinestatus: item.status,
                              date: item.dateLogged,
                              comments: item.comment,
                              content: item.content,
                              author: item.logOwner,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

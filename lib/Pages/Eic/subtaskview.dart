import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/subtask_card.dart';
import 'package:nuntium_mobile/Pages/Eic/assign_task_page.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SubTaskView extends ConsumerStatefulWidget {
  final String topicId;
  final String section;

  const SubTaskView({
    super.key,
    required this.topicId,
    required this.section,
  });

  @override
  ConsumerState<SubTaskView> createState() => _SubTaskViewState();
}

class _SubTaskViewState extends ConsumerState<SubTaskView> {
  @override
  Widget build(BuildContext context) {
    final tasksView = ref.watch(taskProvider(widget.topicId));

    return FractionallySizedBox(
      heightFactor: .85,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 100,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    '${widget.section} Tasks',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width * .9,
                    height: MediaQuery.of(context).size.height * .1,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (tasksView.value!.length >= 2) {
                          Fluttertoast.showToast(
                              msg: "Cannot assign more than 2 tasks in a topic",
                              toastLength: Toast.LENGTH_SHORT,
                              backgroundColor: const Color(0XFFD23737));
                          print('no more tasks allowed to create');
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignTaskPage(
                                topicId: widget.topicId,
                                section: widget.section,
                              ),
                            ),
                          );
                        }
                      },
                      child: DottedBorder(
                        color: Colors.black,
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(10),
                        strokeWidth: 2,
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Create New Task',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.black,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        child: tasksView.when(
                          data: (tasksView) {
                            if (tasksView.isEmpty) {
                              return const Center(
                                child:
                                    Text('No tasks found. Start Creating now!'),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tasksView.length,
                              itemBuilder: (context, index) {
                                final item = tasksView[index];

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: SubtaskCard(
                                    id: item.id,
                                    title: item.title,
                                    imageurl: item.assignee,
                                    section: widget.section,
                                    type: item.type,
                                    deadline: item.deadline,
                                    status: item.status,
                                    topicId: widget.topicId,
                                  ),
                                );
                              },
                            );
                          },
                          error: (error, stack) =>
                              Center(child: Text('Error: $error')),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

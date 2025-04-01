import 'package:flutter/material.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class ContribHuntPage extends StatefulWidget {
  const ContribHuntPage({super.key});

  @override
  State<ContribHuntPage> createState() => _ContribHuntPage();
}

class _ContribHuntPage extends State<ContribHuntPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedSection;
  bool _isChecked = false;
  bool _isCheckboxerror = false;
  FocusNode dropdownFocusNode = FocusNode();
  Future<void> submitApplication() async {
    if (_formKey.currentState!.validate() && _isChecked) {
      // setState(() {
      //   _isLoading = true;
      // });

      try {
        // DocumentReference taskRef =
        await firebaseFunctions.submitApplication(selectedSection!);

        // Clear the form
        _formKey.currentState!.reset();
        setState(() {
          _isChecked = false;
          selectedSection = null;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
      } catch (e) {
        print("Error submitting application: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          '',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 4,
                        height: 30,
                        color: const Color(0xff929292),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      const Text(
                        'Contributors Hunt',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF020B40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFF020B40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 50,
                          color: Color(0xffD4AF37),
                        ),
                        Text(
                          'The NUntium',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        Text(
                          'JOIN NOW!',
                          style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 229, 113)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terms and Conditions*',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF020B40),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                            'Lorem ipsum dolor sit etal amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF020B40)),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  title: const Text(
                                      'I Agree to terms and conditions.',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 14)),
                                  value: _isChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isChecked = value!;
                                      _isCheckboxerror = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_isCheckboxerror)
                            const Text(
                              'Please agree to the terms and conditions',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 192, 43, 33)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select a Section',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF020B40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    focusNode: dropdownFocusNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      filled: true,
                      fillColor: Color(0xFff5f5f5),
                      labelText: "Section",
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    items: [
                      'News',
                      'Sports',
                      'Feature',
                      'Literary',
                      'Opinion',
                      'Photojournalism',
                      'Layout',
                      'Committee',
                    ].map((sectionType) {
                      return DropdownMenuItem(
                        value: sectionType,
                        child: Text(sectionType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedSection = value;
                    },
                    validator: (value) =>
                        value == null ? 'Please select a section' : null,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_isChecked) {
                          setState(() {
                            _isCheckboxerror = true;
                          });
                        }
                        if (_formKey.currentState!.validate()) {
                          dropdownFocusNode.unfocus();
                          submitApplication();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff020B40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Apply Now',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

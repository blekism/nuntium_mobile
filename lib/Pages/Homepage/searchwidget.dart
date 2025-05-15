import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  final TextEditingController searchController;
  final String usedInPage;
  final Function(String)? onSearch; // Callback for search action

  const SearchWidget({
    super.key,
    required this.searchController,
    this.usedInPage = 'reader',
    this.onSearch,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: const Color(0xff1D1617).withOpacity(0.11),
              blurRadius: 40,
              spreadRadius: 0.0,
            ),
          ]),
          child: TextField(
            controller: widget.searchController,
            textInputAction: TextInputAction.search,
            onTapOutside: (PointerDownEvent event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onSearch!(value); // Notify parent widget
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(15),
              hintText: 'What are you looking for?',
              hintStyle: const TextStyle(
                color: Color(0xffDDDADA),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/searchicon.png',
                  height: 25,
                  width: 25,
                ),
              ),
              suffixIcon: SizedBox(
                width: 100,
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const VerticalDivider(
                        color: Colors.black,
                        thickness: 0.2,
                        indent: 10,
                        endIndent: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/felter.png',
                          height: 25,
                          width: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

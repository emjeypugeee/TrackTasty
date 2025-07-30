import 'package:flutter/material.dart';

class BottomSheetModel extends StatefulWidget {
  const BottomSheetModel({super.key});

  @override
  BottomSheetModelState createState() => BottomSheetModelState();
}

class BottomSheetModelState extends State<BottomSheetModel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text("Tap button \nbelow", textAlign: TextAlign.center),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "fab",
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 3,
        child: const Icon(
          Icons.arrow_upward,
          color: Colors.white,
        ),
        onPressed: () {
          showSheet(context);
        },
      ),
    );
  }
}

void showSheet(context) {
  // Show a modal bottom sheet with the specified context and builder method.
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          // Define padding for the container.
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          // Create a Wrap widget to display the sheet contents.
          child: Wrap(
            spacing: 60, // Add spacing between the child widgets.
            children: <Widget>[
              // Add a container with height to create some space.
              Container(height: 10),
              // Add a text widget with a title for the sheet.
              const Text(
                "Flutter Material 3",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              Container(height: 10), // Add some more space.
              // Add a text widget with a long description for the sheet.
              Text(
                'Flutter is an open-source UI software development kit created by Google. It is used to develop cross-platform applications for Android, iOS, Linux, macOS, Windows, Google Fuchsia, and the web from a single codebase.',
                style: TextStyle(
                    color: Colors.grey[600], // Set the text color.
                    fontSize: 18 // Set the text size.
                    ),
              ),
              Container(height: 10), // Add some more space.
              // Add a row widget to display buttons for closing and reading more.
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Align the buttons to the right.
                children: <Widget>[
                  // Add a text button to close the sheet.
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.transparent,
                    ), // Make the button text transparent.
                    onPressed: () {
                      Navigator.pop(context); // Close the sheet.
                    },
                    child: Text("CLOSE",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .primary)), // Add the button text.
                  ),
                  // Add an elevated button to read more.
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ), // Set the button background color.
                    onPressed: () {}, // Add the button onPressed function.
                    child: Text("Read More",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .inversePrimary)), // Add the button text.
                  )
                ],
              )
            ],
          ),
        );
      });
}

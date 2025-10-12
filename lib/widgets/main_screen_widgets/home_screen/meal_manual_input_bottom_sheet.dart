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
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Wrap(
            spacing: 60,
            children: <Widget>[
              Container(height: 10),
              const Text(
                "Flutter Material 3",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              Container(height: 10),
              Text(
                'Flutter is an open-source UI software development kit created by Google. It is used to develop cross-platform applications for Android, iOS, Linux, macOS, Windows, Google Fuchsia, and the web from a single codebase.',
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
              Container(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("CLOSE",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {},
                    child: Text("Read More",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.inversePrimary)),
                  )
                ],
              )
            ],
          ),
        );
      });
}

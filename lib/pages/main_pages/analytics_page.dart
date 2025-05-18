import 'package:fitness/components/linegraph_statistics.dart';
import 'package:fitness/theme/app_color.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Analytics',
          style: TextStyle(color: AppColors.titleText),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight',
              style: TextStyle(color: AppColors.primaryText, fontSize: 20),
            ),
            LinegraphStatistics()
          ],
        ),
      ),
    );
  }
}

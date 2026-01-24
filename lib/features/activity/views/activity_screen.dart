import 'package:flutter/material.dart';
import '../widgets/activity_header.dart';
import '../widgets/goal_percentage_widget.dart';
import '../widgets/metrics_list_widget.dart';
import '../widgets/recommendation_card_widget.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActivityHeader(),
              const SizedBox(height: 30),
              GoalPercentageWidget(percentage: 87),
              const SizedBox(height: 50),
              MetricsListWidget(),
              const SizedBox(height: 30),
              RecommendationCardWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
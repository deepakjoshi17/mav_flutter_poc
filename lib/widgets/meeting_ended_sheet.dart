import 'package:flutter/material.dart';
import 'package:mav_flutter/widgets/blue_rounded_button.dart';
import 'package:mav_flutter/widgets/custom_app_bar.dart';

class MeetingEndedSheet extends StatelessWidget {
  final String moduleName;
  final DateTime nextSessionDateTime;
  final VoidCallback? onGoBack;

  const MeetingEndedSheet({
    Key? key,
    required this.moduleName,
    required this.nextSessionDateTime,
    this.onGoBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final day = _getWeekday(nextSessionDateTime);
    final date = _getDateString(nextSessionDateTime);
    final time = _getTimeString(nextSessionDateTime);
    return Container(
      padding: EdgeInsets.only(top: MediaQueryData.fromView(View.of(context)).padding.top),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: CustomAppBar(moduleName: moduleName, showGuideMe: false),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF2FF), Color(0xFFD6F2E7)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/ic_vid_call.png',
                height: 80,
                width: 80,
              ),
              const SizedBox(height: 12),
              const Text(
                'Meeting Ended!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '"Thanks for joining!"',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Upcoming session',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF413930)),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF534C44),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFF15D22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Your next session is scheduled for $date at $time. See you then!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: BlueRoundedButton(
                    text: 'Go Back To Dashboard',
                    onTap: () {
                      if (onGoBack != null) {
                        onGoBack!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWeekday(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[dt.weekday - 1];
  }

  String _getDateString(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
  }

  String _getTimeString(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}

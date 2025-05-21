import 'package:flutter/material.dart';
import 'package:mav_flutter/widgets/blue_rounded_button.dart';
import 'package:mav_flutter/widgets/custom_app_bar.dart';

class SessionFeedbackSheet extends StatefulWidget {
  final VoidCallback? onSubmit;
  const SessionFeedbackSheet({Key? key, this.onSubmit}) : super(key: key);

  @override
  State<SessionFeedbackSheet> createState() => _SessionFeedbackSheetState();
}

class _SessionFeedbackSheetState extends State<SessionFeedbackSheet> {
  int? sessionRating;
  int? teacherRating;
  bool submitted = false;

  final List<String> emojis = [
    'assets/emoji_bad.png',
    'assets/emoji_neutral.png',
    'assets/emoji_smile.png',
    'assets/emoji_party.png',
  ];
  final List<String> emojiLabels = [
    'Bad', 'Okay', 'Good', 'Great'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(top: MediaQueryData.fromView(View.of(context)).padding.top),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2FF), Color(0xFFD6F2E7)],
          ),
        ),
        child: submitted
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text('Thank you for your feedback!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : Column(
              children: [
                CustomAppBar(moduleName: "Module 3", showGuideMe: false),
                Column(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Session Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "How was today's session?",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please rate your in class experience with us',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(emojis.length, (i) => _buildEmoji(i, sessionRating, (val) {
                        setState(() => sessionRating = val);
                      })),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How would you rate your teacher?',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please rate your in class experience with us',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(emojis.length, (i) => _buildEmoji(i, teacherRating, (val) {
                        setState(() => teacherRating = val);
                      })),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: BlueRoundedButton(text: 'Submit Feedback', onTap:
                      (sessionRating != null && teacherRating != null) ? () {
                        if(!mounted) return;
                        setState(() => submitted = true);
                        if (widget.onSubmit != null) widget.onSubmit!();
                        Future.delayed(Duration(seconds: 2), () {
                          Navigator.of(context).maybePop();
                        });
                      }
                      : null),
                    )
                  ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildEmoji(int index, int? selected, ValueChanged<int> onTap) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected == index ? Color(0xFF4B7BFF) : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(8),
              child: Image.asset(
                emojis[index],
                height: 40,
                width: 40,
              ),
            ),
            SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              padding: EdgeInsets.all(4),
              child: Checkbox(
                side: BorderSide(
                  color: Colors.transparent,
                  width: 1,
                ),
                value: selected == index,
                onChanged: (_) => onTap(index),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                fillColor: MaterialStateProperty.all(Colors.transparent),
                checkColor: Color(0xFF4B7BFF),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget {
  final String moduleName;
  final String screenName;
  final VoidCallback? onGuideMe;
  final VoidCallback? onSettings;
  final bool showGuideMe;

  const CustomAppBar({
    super.key,
    required this.moduleName,
    this.screenName = '',
    this.onGuideMe,
    this.onSettings,
    this.showGuideMe = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Warning bar
        Visibility(
          visible: showGuideMe,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFFF6B6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'To enable camera & microphone access.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onGuideMe,
                  child: const Text(
                    'Guide Me',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Main app bar row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // SVG Logo
              SvgPicture.asset(
                'assets/bhanzu_mav_logo.svg', // Update path if needed
                height: 24,
              ),
              Spacer(),
              // Module/session name
              Visibility(
                visible: screenName != 'Meeting ended',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Color(0xFFF15D22), size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          moduleName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Visibility(
                visible: screenName != 'Meeting ended',
                child: GestureDetector(
                  onTap: () {

                    if(screenName == 'Live Class') {
                      onSettings?.call();
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EFED),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: screenName == 'Live Class' ? SvgPicture.asset("assets/ic_setting_outline.svg") : Icon(Icons.close, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 
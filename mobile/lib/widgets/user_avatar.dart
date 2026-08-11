import 'package:flutter/material.dart';

import '../models/chat_models.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar(
      {super.key,
      required this.user,
      this.radius = 26,
      this.showOnline = true});
  final ChatUser user;
  final double radius;
  final bool showOnline;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Color(0xFFFFB21A),
                    Color(0xFFFF5A1F),
                    Color(0xFF0C4CF5)
                  ])),
              child: CircleAvatar(
                  radius: radius - 2.5,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Text(user.initials,
                      style: TextStyle(
                          color: const Color(0xFF0C4CF5),
                          fontWeight: FontWeight.w900,
                          fontSize: radius * .6)))),
          if (showOnline && user.isOnline)
            Positioned(
              right: -1,
              bottom: 1,
              child: Container(
                width: radius * .42,
                height: radius * .42,
                decoration: BoxDecoration(
                    color: const Color(0xFF2EB67D),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2.5)),
              ),
            ),
        ],
      );
}

import 'package:flutter/material.dart';
import '../core/app_services.dart';
import '../models/chat_models.dart';
import '../widgets/user_avatar.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final current = AppServices.instance.session.user!;
    final user = ChatUser(
        id: current.id,
        name: current.name,
        handle: '@${current.username}',
        initials: _initials(current.name),
        colorValue: 0xFF5B4FDB);
    return SafeArea(
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(padding: const EdgeInsets.all(22), children: [
                  const Text('Profile',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 22),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 28),
                          child: Column(children: [
                            UserAvatar(
                                user: user, radius: 52, showOnline: false),
                            const SizedBox(height: 18),
                            Text(current.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text('@${current.username}',
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Color(0xFF77758A)))
                          ]))),
                  const SizedBox(height: 30),
                  const Card(
                      elevation: 0,
                      child: ListTile(
                          leading: Icon(Icons.security_rounded),
                          title: Text('Authenticated session'),
                          subtitle:
                              Text('JWT stored securely on this device'))),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: () async {
                        await AppServices.instance.session.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                  builder: (_) => const AuthScreen()),
                              (_) => false);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out')),
                ]))));
  }

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

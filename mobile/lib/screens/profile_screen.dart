import 'package:flutter/material.dart';
import '../core/app_services.dart';
import '../models/chat_models.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final current = AppServices.instance.session.user!;
    final user = ChatUser(id: current.id, name: current.name, handle: '@${current.username}', initials: _initials(current.name), colorValue: 0xFFFFB300);
    final options = <(IconData, String, String)>[
      (Icons.key_rounded, 'Account', 'Security notifications and account info'),
      (Icons.lock_outline_rounded, 'Privacy', 'Blocked contacts and disappearing messages'),
      (Icons.face_retouching_natural_rounded, 'Avatar', 'Create and edit your avatar'),
      (Icons.chat_outlined, 'Chats', 'Theme, wallpaper and chat history'),
      (Icons.notifications_none_rounded, 'Notifications', 'Message, group and call tones'),
      (Icons.storage_rounded, 'Storage and data', 'Network usage and auto-download'),
      (Icons.language_rounded, 'App language', 'English'),
      (Icons.help_outline_rounded, 'Help', 'Help centre and privacy policy'),
    ];
    return Scaffold(backgroundColor: Colors.white, appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(children: [
        Padding(padding: const EdgeInsets.all(18), child: Row(children: [
          UserAvatar(user: user, radius: 32, showOnline: false), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(current.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('Hey there! I am using Looply', style: TextStyle(color: AppTheme.muted))])),
          IconButton(tooltip: 'Profile code', onPressed: () => showDialog<void>(context: context, builder: (_) => const AlertDialog(title: Text('Looply profile code'), content: Icon(Icons.qr_code_2_rounded, size: 160))), icon: const Icon(Icons.qr_code_2_rounded, color: AppTheme.amber))
        ])), const Divider(height: 1),
        ...options.map((o) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5), leading: Icon(o.$1, color: AppTheme.muted), title: Text(o.$2, style: const TextStyle(color: AppTheme.ink)), subtitle: Text(o.$3, style: const TextStyle(color: AppTheme.muted)), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${o.$2} settings selected'))))),
        ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5), leading: const Icon(Icons.logout_rounded, color: AppTheme.amber), title: const Text('Sign out'), onTap: () async { await AppServices.instance.session.signOut(); if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const AuthScreen()), (_) => false); }),
        const SizedBox(height: 24), const Center(child: Column(children: [Text('from', style: TextStyle(color: AppTheme.muted, fontSize: 12)), SizedBox(height: 3), Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.all_inclusive_rounded, color: AppTheme.amber), SizedBox(width: 6), Text('Looply', style: TextStyle(fontWeight: FontWeight.w700))])])), const SizedBox(height: 28)
      ])))));
  }
  static String _initials(String name) => name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();
}

import 'package:flutter/material.dart';
import '../core/app_services.dart';
import '../models/chat_models.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _loading = true;
  String? _error;
  List<ChatUser> _users = [];
  List<ConversationModel> _conversations = [];
  String get _currentUserId => AppServices.instance.session.user!.id;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AppServices.instance.api.users(),
        AppServices.instance.api.conversations()
      ]);
      if (!mounted) return;
      setState(() {
        _users = results[0] as List<ChatUser>;
        _conversations = results[1] as List<ConversationModel>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load conversations. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openUser(ChatUser user) async {
    try {
      final conversation = await AppServices.instance.api.openDirect(user.id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) =>
              ChatScreen(user: user, conversationId: conversation.id)));
      _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open this conversation.')));
      }
    }
  }

  void _openConversation(ConversationModel conversation) {
    final user = conversation.otherThan(_currentUserId);
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
            builder: (_) =>
                ChatScreen(user: user, conversationId: conversation.id)))
        .then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: .07),
              Theme.of(context).scaffoldBackgroundColor
            ], begin: Alignment.topLeft, end: Alignment.center)),
            child: IndexedStack(index: _index, children: [
              _DirectoryPage(
                  title: 'Messages',
                  subtitle: 'Your conversations',
                  loading: _loading,
                  error: _error,
                  onRetry: _refresh,
                  child: _conversations.isEmpty
                      ? const _EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No conversations yet',
                          text: 'Open People and start a chat.')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: _conversations.length,
                          itemBuilder: (_, index) {
                            final conversation = _conversations[index];
                            final user = conversation.otherThan(_currentUserId);
                            return _UserTile(
                                user: user,
                                preview: 'Open conversation',
                                onTap: () => _openConversation(conversation));
                          })),
              _DirectoryPage(
                  title: 'People',
                  subtitle: 'Available Looply users',
                  loading: _loading,
                  error: _error,
                  onRetry: _refresh,
                  child: _users.isEmpty
                      ? const _EmptyState(
                          icon: Icons.people_outline,
                          title: 'No other users',
                          text: 'Ask someone to register first.')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: _users.length,
                          itemBuilder: (_, index) => _UserTile(
                              user: _users[index],
                              preview: _users[index].handle,
                              onTap: () => _openUser(_users[index])))),
              const ProfileScreen(),
            ])),
        bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chats'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'People'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile')
            ]),
      );
}

class _DirectoryPage extends StatelessWidget {
  const _DirectoryPage(
      {required this.title,
      required this.subtitle,
      required this.loading,
      required this.error,
      required this.onRetry,
      required this.child});
  final String title, subtitle;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
      child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF1463FF), Color(0xFF073BD8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x300C4CF5),
                                  blurRadius: 24,
                                  offset: Offset(0, 10))
                            ]),
                        child: Row(children: [
                          Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .16),
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.forum_rounded,
                                  color: Colors.white, size: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.7)),
                                const SizedBox(height: 2),
                                Text(subtitle,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: .76)))
                              ])),
                          IconButton(
                              tooltip: 'Refresh',
                              onPressed: onRetry,
                              style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: .14)),
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white))
                        ]))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : error != null
                                ? Center(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                        const Icon(Icons.cloud_off_rounded,
                                            size: 38),
                                        const SizedBox(height: 12),
                                        Text(error!,
                                            textAlign: TextAlign.center),
                                        TextButton(
                                            onPressed: onRetry,
                                            child: const Text('Try again'))
                                      ]))
                                : RefreshIndicator(
                                    onRefresh: () async => onRetry(),
                                    child: child)))
              ]))));
}

class _UserTile extends StatelessWidget {
  const _UserTile(
      {required this.user, required this.preview, required this.onTap});
  final ChatUser user;
  final String preview;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
          minTileHeight: 76,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          leading: UserAvatar(user: user),
          title: Text(user.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child:
                  Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis)),
          trailing: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFFFB21A), Color(0xFFFF5A1F)]),
                  shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white)),
          onTap: onTap));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .09),
                shape: BoxShape.circle),
            child: Icon(icon,
                size: 34, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Color(0xFF77758A)))
      ]));
}

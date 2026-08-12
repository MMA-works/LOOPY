import 'package:flutter/material.dart';
import '../core/app_services.dart';
import '../models/chat_models.dart';
import '../theme/app_theme.dart';
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
  bool _loading = true, _searching = false;
  String? _error;
  String _query = '';
  List<ChatUser> _users = [];
  List<ConversationModel> _conversations = [];
  String get _currentUserId => AppServices.instance.session.user!.id;

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait([AppServices.instance.api.users(), AppServices.instance.api.conversations()]);
      if (!mounted) return;
      setState(() { _users = values[0] as List<ChatUser>; _conversations = values[1] as List<ConversationModel>; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load conversations. Check your connection.'; _loading = false; });
    }
  }

  Route<void> _slide(Widget page) => PageRouteBuilder<void>(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)), child: child),
    transitionDuration: const Duration(milliseconds: 320));

  Future<void> _openUser(ChatUser user) async {
    try {
      final conversation = await AppServices.instance.api.openDirect(user.id);
      if (!mounted) return;
      await Navigator.of(context).push(_slide(ChatScreen(user: user, conversationId: conversation.id)));
      _refresh();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this conversation.'))); }
  }

  void _openConversation(ConversationModel conversation) {
    final user = conversation.otherThan(_currentUserId);
    Navigator.of(context).push(_slide(ChatScreen(user: user, conversationId: conversation.id))).then((_) => _refresh());
  }

  void _showPeople() => showModalBottomSheet<void>(
    context: context, showDragHandle: true, isScrollControlled: true,
    builder: (_) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .65,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('New message', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        Expanded(child: ListView.builder(itemCount: _users.length, itemBuilder: (_, i) => ListTile(
          leading: UserAvatar(user: _users[i]), title: Text(_users[i].name), subtitle: Text(_users[i].handle),
          onTap: () { Navigator.pop(context); _openUser(_users[i]); })))
      ]))));

  @override
  Widget build(BuildContext context) {
    final chats = _conversations.where((c) => c.otherThan(_currentUserId).name.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(child: Column(children: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 240), child: _searching
          ? Container(key: const ValueKey('search'), color: AppTheme.primary, padding: const EdgeInsets.all(10), child: TextField(
              autofocus: true, onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(fillColor: Colors.white, hintText: 'Search chats', prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(onPressed: () => setState(() { _searching = false; _query = ''; }), icon: const Icon(Icons.close)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10))))
          : Container(key: const ValueKey('header'), height: 64, color: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Expanded(child: Text('Looply', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.ink))),
                IconButton(tooltip: 'Camera', onPressed: _showPeople, icon: const Icon(Icons.camera_alt_outlined)),
                IconButton(tooltip: 'Search', onPressed: () => setState(() => _searching = true), icon: const Icon(Icons.search)),
                IconButton(tooltip: 'Settings', onPressed: () => Navigator.of(context).push(_slide(const ProfileScreen())), icon: const Icon(Icons.more_vert))
              ]))),
        Expanded(child: _body(chats)),
      ])),
      floatingActionButton: _index == 0 ? FloatingActionButton(onPressed: _showPeople, backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.ink, elevation: 8, tooltip: 'New message', child: const Icon(Icons.chat_rounded)) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: (i) => setState(() => _index = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
        NavigationDestination(icon: Icon(Icons.update_outlined), selectedIcon: Icon(Icons.update), label: 'Updates'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Communities'),
        NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Calls'),
      ]));
  }

  Widget _body(List<ConversationModel> chats) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _refresh, child: const Text('Try again'))]));
    if (_index != 0) {
      const labels = ['Chats', 'Updates', 'Communities', 'Calls'];
      const icons = [Icons.chat_bubble_outline, Icons.update, Icons.groups_outlined, Icons.call_outlined];
      return _EmptyState(icon: icons[_index], title: labels[_index], text: 'Nothing here yet.');
    }
    if (chats.isEmpty) return const _EmptyState(icon: Icons.forum_outlined, title: 'No conversations yet', text: 'Tap the yellow button to start a chat.');
    return RefreshIndicator(onRefresh: _refresh, child: ListView.builder(padding: const EdgeInsets.only(top: 8, bottom: 92), itemCount: chats.length,
      itemBuilder: (_, i) { final c = chats[i]; return _AnimatedChatTile(index: i, user: c.otherThan(_currentUserId), updatedAt: c.updatedAt, onTap: () => _openConversation(c)); }));
  }
}

class _AnimatedChatTile extends StatefulWidget {
  const _AnimatedChatTile({required this.index, required this.user, required this.updatedAt, required this.onTap});
  final int index; final ChatUser user; final DateTime updatedAt; final VoidCallback onTap;
  @override State<_AnimatedChatTile> createState() => _AnimatedChatTileState();
}

class _AnimatedChatTileState extends State<_AnimatedChatTile> {
  bool _visible = false, _hover = false;
  @override void initState() { super.initState(); Future.delayed(Duration(milliseconds: 90 * (widget.index.clamp(0, 5) + 1)), () { if (mounted) setState(() => _visible = true); }); }
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, .25),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          child: MouseRegion(
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  transform: Matrix4.translationValues(_hover ? 8 : 0, 0, 0),
                  decoration: BoxDecoration(
                      color: _hover ? AppTheme.hover : Colors.white,
                      border: Border(left: BorderSide(color: _hover ? AppTheme.accent : Colors.transparent, width: 4))),
                  child: ListTile(
                      minTileHeight: 74,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      onTap: widget.onTap,
                      leading: UserAvatar(user: widget.user, radius: 25),
                      title: Text(widget.user.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                      subtitle: const Text('Tap to open conversation', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.muted)),
                      trailing: Text(TimeOfDay.fromDateTime(widget.updatedAt.toLocal()).format(context), style: const TextStyle(fontSize: 12, color: AppTheme.muted)))))));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.text});
  final IconData icon; final String title, text;
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    CircleAvatar(radius: 38, backgroundColor: AppTheme.hover, child: Icon(icon, size: 34, color: AppTheme.amber)), const SizedBox(height: 12),
    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(text, style: const TextStyle(color: AppTheme.muted))]));
}

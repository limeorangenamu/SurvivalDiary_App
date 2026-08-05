import 'package:flutter/material.dart';

import 'auth_session.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('계정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '사용자',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (user?.email.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(user!.email),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('계정 관리'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('프로필 정보'),
                  subtitle: Text(
                    user?.birthDate.isNotEmpty == true
                        ? '생년월일 ${user!.birthDate}'
                        : '등록된 프로필 정보가 없습니다.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('로그아웃'),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await AuthSession.instance.logout();
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';
import '../auth/auth_session.dart';
import 'data/profile_api_client.dart';
import 'widgets/profile_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _session = AuthSession.instance;
  final _apiClient = ProfileApiClient();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_handleSessionChanged);
    unawaited(_refreshProfile());
  }

  @override
  void dispose() {
    _session.removeListener(_handleSessionChanged);
    super.dispose();
  }

  void _handleSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshProfile() async {
    final token = _session.accessToken;
    if (token == null || _isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final user = await _apiClient.getMe(accessToken: token);
      _session.updateCurrentUser(user);
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _openEditProfile() async {
    final changed = await Navigator.pushNamed(context, AppRoutes.profileEdit);
    if (changed == true && mounted) {
      await _refreshProfile();
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('현재 계정에서 로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await _session.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요해요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              _ProfileHeader(
                name: user.name,
                email: user.email,
                bio: user.bio,
                imageUrl: user.profileImageUrl,
                isRefreshing: _isRefreshing,
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: '계정 관리'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.manage_accounts_outlined,
                      title: '회원 정보 수정',
                      subtitle: '이름, 연락처, 프로필 사진을 관리해요',
                      onTap: _openEditProfile,
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.logout_rounded,
                      title: '로그아웃',
                      foregroundColor: AppColors.danger,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: '내 정보'),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(label: '이메일', value: user.email),
                    const Divider(height: 22),
                    _InfoRow(
                      label: '휴대폰',
                      value: user.phone.isEmpty ? '미등록' : user.phone,
                    ),
                    const Divider(height: 22),
                    _InfoRow(
                      label: '지역',
                      value: user.region.isEmpty ? '미등록' : user.region,
                    ),
                    const Divider(height: 22),
                    _InfoRow(
                      label: '가입일',
                      value: _joinedDate(user.createdAt),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _joinedDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? '확인 불가' : '${date.year}.${date.month}.${date.day}';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.bio,
    required this.imageUrl,
    required this.isRefreshing,
  });

  final String name;
  final String email;
  final String bio;
  final String? imageUrl;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ProfileAvatar(imageUrl: imageUrl, name: name, size: 96),
              if (isRefreshing)
                const SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    color: AppColors.surface,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: AppTextStyles.title.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.surface.withValues(alpha: 0.82),
            ),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.surface.withValues(alpha: 0.92),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.foregroundColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: foregroundColor.withValues(alpha: 0.1),
        foregroundColor: foregroundColor,
        child: Icon(icon, size: 21),
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppTextStyles.caption),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: AppTextStyles.bodyMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_session.dart';
import 'data/profile_api_client.dart';
import 'widgets/profile_avatar.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ProfileApiClient();
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  DateTime? _birthDate;
  String _gender = '';
  bool _isSaving = false;
  bool _isUpdatingImage = false;
  final _interests = <String>[];
  static const _interestOptions = <String>[
    '생활비 절약',
    '주거·주택비',
    '정부 정책',
    '지원금·복지',
    '가계부 관리',
    '식비 관리',
    '저축·투자',
    '부수입',
  ];

  @override
  void initState() {
    super.initState();
    final user = AuthSession.instance.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _passwordController = TextEditingController();
    _birthDate = DateTime.tryParse(user.birthDate);
    _gender = user.gender;
    _interests.addAll(user.interests);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoActions() async {
    if (_isUpdatingImage) return;
    final hasPhoto = AuthSession.instance.currentUser?.profileImageUrl != null;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(hasPhoto ? '새 사진으로 변경' : '프로필 사진 등록'),
                subtitle: const Text('갤러리에서 이미지를 선택해요'),
                onTap: () => Navigator.pop(context, _PhotoAction.pick),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    '현재 사진 삭제',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () => Navigator.pop(context, _PhotoAction.delete),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _PhotoAction.pick:
        await _pickAndUploadImage();
        return;
      case _PhotoAction.delete:
        await _deleteImage();
        return;
      case null:
        return;
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;
      final token = AuthSession.instance.accessToken;
      if (token == null) return;

      setState(() => _isUpdatingImage = true);
      final user = await _apiClient.uploadProfileImage(
        accessToken: token,
        bytes: await image.readAsBytes(),
        filename: image.name,
      );
      AuthSession.instance.updateCurrentUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 사진을 저장했어요.')),
      );
    } on ProfileApiException catch (error) {
      _showError(error.message);
    } on PlatformException {
      _showError('사진을 불러오지 못했어요. 사진 접근 권한을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  Future<void> _deleteImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 사진 삭제'),
        content: const Text('현재 프로필 사진을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    setState(() => _isUpdatingImage = true);
    try {
      final user = await _apiClient.deleteProfileImage(accessToken: token);
      AuthSession.instance.updateCurrentUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 사진을 삭제했어요.')),
      );
    } on ProfileApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final latest = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final defaultDate = DateTime(now.year - 20, now.month, now.day);
    final initialDate = _birthDate == null || _birthDate!.isAfter(latest)
        ? defaultDate
        : _birthDate!;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: latest,
      helpText: '생년월일 선택',
    );
    if (selected != null && mounted) {
      setState(() => _birthDate = selected);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final token = AuthSession.instance.accessToken;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      final user = await _apiClient.updateProfile(
        accessToken: token,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        birthDate: _dateValue(_birthDate),
        gender: _gender,
        region: AuthSession.instance.currentUser?.region ?? '',
        bio: AuthSession.instance.currentUser?.bio ?? '',
        password: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
        interests: _interests,
      );
      AuthSession.instance.updateCurrentUser(user);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ProfileApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _dateValue(DateTime? value) {
    if (value == null) return '';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('회원 정보 수정')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(
                      imageUrl: user.profileImageUrl,
                      name: user.name,
                      size: 112,
                    ),
                    if (_isUpdatingImage)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: IconButton.filled(
                        tooltip: '프로필 사진 관리',
                        onPressed: _isUpdatingImage ? null : _showPhotoActions,
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '사진 버튼을 눌러 등록·변경·삭제할 수 있어요.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return '이름을 입력해 주세요.';
                  if (name.length > 50) return '이름은 50자 이하로 입력해 주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: user.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  helperText: '로그인 이메일은 변경할 수 없어요.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  hintText: '변경할 때만 입력해 주세요',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: const InputDecoration(labelText: '휴대폰 번호'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '생년월일',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _birthDate == null ? '선택 안 함' : _dateValue(_birthDate),
                    style: _birthDate == null
                        ? AppTextStyles.bodyMuted
                        : AppTextStyles.body,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: '성별'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('선택 안 함')),
                  DropdownMenuItem(value: 'MALE', child: Text('남성')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? ''),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: '관심사'),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final interest in _interestOptions)
                      FilterChip(
                        label: Text(interest),
                        selected: _interests.contains(interest),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _interests.add(interest);
                          } else {
                            _interests.remove(interest);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? '저장 중...' : '회원 정보 저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PhotoAction { pick, delete }

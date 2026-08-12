import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../auth/auth_session.dart';
import 'data/community_api_client.dart';

class PostWritePage extends StatefulWidget {
  const PostWritePage({super.key, this.post, this.initialCategory});

  final CommunityPost? post;
  final String? initialCategory;

  @override
  State<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends State<PostWritePage> {
  static const categories = ['자유게시판', '정보 공유', '절약 인증', '질문'];
  final _titleController = TextEditingController();
  final _hashtagInputController = TextEditingController();
  final _editorController = QuillController.basic();
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _apiClient = CommunityApiClient();
  final _hashtags = <String>[];
  String? _category;
  String? _error;
  String? _hashtagError;
  bool _commentsDisabled = false;
  bool _commentsHidden = false;

  bool get _isQna => (widget.post?.category ?? widget.initialCategory) == '질문';

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _category = post?.category ?? widget.initialCategory ?? categories.first;
    if (post == null) return;
    _titleController.text = post.title;
    if (!_isQna) {
      _hashtags.addAll(post.hashtags);
    }
    _commentsDisabled = post.commentsDisabled;
    _commentsHidden = post.commentsHidden;
    try {
      _editorController.document =
          Document.fromJson(jsonDecode(post.contentJson ?? post.body));
    } catch (_) {
      _editorController.document.insert(0, post.body);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hashtagInputController.dispose();
    _editorController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<String?> _pickImage(BuildContext context) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final extension = file.name.split('.').last.toLowerCase();
    return 'data:image/$extension;base64,${base64Encode(bytes)}';
  }

  void _addHashtag([String? rawValue]) {
    final value =
        (rawValue ?? _hashtagInputController.text).trim().replaceFirst('#', '');
    if (value.isEmpty) {
      return;
    }
    if (value.contains(RegExp(r'\s'))) {
      setState(() => _hashtagError = '해시태그에는 띄어쓰기를 사용할 수 없어요.');
      return;
    }
    if (value.length > 7) {
      setState(() => _hashtagError = '해시태그는 7글자 이내로 입력해 주세요.');
      return;
    }
    if (_hashtags.contains(value)) {
      setState(() => _hashtagError = '중복된 태그입니다.');
      return;
    }
    if (_hashtags.length >= 5) {
      setState(() => _hashtagError = '해시태그는 5개까지 입력할 수 있어요.');
      return;
    }
    setState(() {
      _hashtags.add(value);
      _hashtagInputController.clear();
      _hashtagError = null;
    });
  }

  Future<void> _submit() async {
    if (_category == null ||
        _titleController.text.trim().isEmpty ||
        _editorController.document.toPlainText().trim().isEmpty) {
      setState(() => _error = '카테고리, 제목, 내용을 모두 입력해 주세요.');
      return;
    }
    final token = AuthSession.instance.accessToken;
    if (token == null) {
      setState(() => _error = '로그인이 필요해요.');
      return;
    }
    final request = CreateCommunityPostRequest(
      category: _category!,
      title: _titleController.text.trim(),
      content: jsonEncode(_editorController.document.toDelta().toJson()),
      hashtags: _isQna ? const [] : _hashtags,
      commentsDisabled: _commentsDisabled,
      commentsHidden: _commentsHidden,
    );
    try {
      if (widget.post == null) {
        await _apiClient.create(accessToken: token, request: request);
      } else {
        await _apiClient.update(
          accessToken: token,
          postId: widget.post!.id,
          request: request,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on CommunityApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Widget _formSection({
    required String label,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorStyles = DefaultStyles.getInstance(context).merge(
      const DefaultStyles(
        paragraph: DefaultTextBlockStyle(
          AppTextStyles.body,
          HorizontalSpacing(0, 0),
          VerticalSpacing(6, 0),
          VerticalSpacing.zero,
          null,
        ),
        placeHolder: DefaultTextBlockStyle(
          AppTextStyles.bodyMuted,
          HorizontalSpacing(0, 0),
          VerticalSpacing(6, 0),
          VerticalSpacing.zero,
          null,
        ),
      ),
    );
    final imageButton = QuillToolbarImageButtonOptions(
      imageButtonConfig: QuillToolbarImageConfig(
        onRequestPickImage: _pickImage,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? '글쓰기' : '게시글 수정'),
        actions: [
          TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: AppTextStyles.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(widget.post == null ? '등록' : '수정완료'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _formSection(
            label: '제목',
            child: TextField(
              controller: _titleController,
              maxLength: 60,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                counterText: '',
              ),
              style: AppTextStyles.body,
            ),
          ),
          if (!_isQna) ...[
            const SizedBox(height: 12),
            _formSection(
              label: '해시태그',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final hashtag in _hashtags)
                        InputChip(
                          label: Text('#$hashtag'),
                          backgroundColor: AppColors.surfaceAlt,
                          side: const BorderSide(color: AppColors.border),
                          shape: const StadiumBorder(),
                          onDeleted: () => setState(() {
                            _hashtags.remove(hashtag);
                            _hashtagError = null;
                          }),
                        ),
                      SizedBox(
                        width: 180,
                        height: 32,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _hashtagInputController,
                                style: AppTextStyles.caption,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                      RegExp(r'\s')),
                                  LengthLimitingTextInputFormatter(7),
                                ],
                                onSubmitted: _addHashtag,
                                onChanged: (_) {
                                  if (_hashtagError != null) {
                                    setState(() => _hashtagError = null);
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: '태그 입력',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                  hintStyle: AppTextStyles.caption,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _addHashtag,
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('추가'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_hashtagError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _hashtagError!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (AuthSession.instance.currentUser?.isAdmin == true) ...[
            const SizedBox(height: 12),
            _formSection(
              label: '댓글 관리',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('댓글 정지'),
                    subtitle: const Text('새 댓글을 등록할 수 없게 합니다.'),
                    value: _commentsDisabled,
                    onChanged: (value) =>
                        setState(() => _commentsDisabled = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('댓글 숨김'),
                    subtitle: const Text('기존 댓글도 상세 화면에서 숨깁니다.'),
                    value: _commentsHidden,
                    onChanged: (value) =>
                        setState(() => _commentsHidden = value),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _formSection(
            label: '내용',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: AppColors.surfaceAlt,
                    child: QuillSimpleToolbar(
                      controller: _editorController,
                      config: QuillSimpleToolbarConfig(
                        multiRowsDisplay: false,
                        showDividers: false,
                        showFontFamily: false,
                        showFontSize: false,
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: false,
                        showStrikeThrough: false,
                        showInlineCode: false,
                        showColorButton: false,
                        showBackgroundColorButton: false,
                        showClearFormat: false,
                        showAlignmentButtons: false,
                        showHeaderStyle: false,
                        showListNumbers: false,
                        showListBullets: false,
                        showListCheck: false,
                        showCodeBlock: false,
                        showQuote: false,
                        showIndent: false,
                        showLink: false,
                        showUndo: true,
                        showRedo: true,
                        showSubscript: false,
                        showSuperscript: false,
                        showSearchButton: false,
                        embedButtons: FlutterQuillEmbeds.toolbarButtons(
                          imageButtonOptions: imageButton,
                          videoButtonOptions: null,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: AppColors.surface,
                    constraints: const BoxConstraints(minHeight: 300),
                    child: QuillEditor(
                      controller: _editorController,
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      config: QuillEditorConfig(
                        placeholder: '내용을 입력해 주세요.',
                        padding: const EdgeInsets.all(16),
                        customStyles: editorStyles,
                        embedBuilders: FlutterQuillEmbeds.editorBuilders(
                          imageEmbedConfig: QuillEditorImageEmbedConfig(
                            imageProviderBuilder: (context, imageUrl) {
                              if (!imageUrl.startsWith('data:image/')) {
                                return null;
                              }
                              return MemoryImage(
                                base64Decode(imageUrl.split(',').last),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

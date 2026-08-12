import 'package:flutter/material.dart';

const defaultHomeWidgetOrder = <String>[
  'today_spent',
  'daily_usage',
  'top_category',
  'daily_remaining',
  'monthly_usage',
  'monthly_remaining',
];

const homeWidgetLabels = <String, String>{
  'today_spent': '오늘 지출',
  'daily_usage': '일일 예산 사용률',
  'top_category': '카테고리 1위',
  'daily_remaining': '일일 잔여 예산',
  'monthly_usage': '월간 예산 사용률',
  'monthly_remaining': '월간 잔여 예산',
};

class HomeWidgetEditorArguments {
  const HomeWidgetEditorArguments({required this.order, required this.hidden});

  final List<String> order;
  final List<String> hidden;
}

class HomeWidgetEditorPage extends StatefulWidget {
  const HomeWidgetEditorPage({
    super.key,
    required this.initialOrder,
    required this.initialHidden,
  });

  final List<String> initialOrder;
  final List<String> initialHidden;

  @override
  State<HomeWidgetEditorPage> createState() => _HomeWidgetEditorPageState();
}

class _HomeWidgetEditorPageState extends State<HomeWidgetEditorPage> {
  late List<String> _visible;
  late List<String> _hidden;

  @override
  void initState() {
    super.initState();
    _visible = [...widget.initialOrder];
    _hidden = [...widget.initialHidden];
  }

  void _hide(String id) {
    setState(() {
      _visible.remove(id);
      if (!_hidden.contains(id)) _hidden.add(id);
    });
  }

  void _show(String id) {
    setState(() {
      _hidden.remove(id);
      _visible.add(id);
    });
  }

  void _swapWidget(String draggedId, String targetId) {
    if (draggedId == targetId) return;
    setState(() {
      final draggedIndex = _visible.indexOf(draggedId);
      final targetIndex = _visible.indexOf(targetId);
      if (draggedIndex < 0 || targetIndex < 0) return;
      final target = _visible[targetIndex];
      _visible[targetIndex] = _visible[draggedIndex];
      _visible[draggedIndex] = target;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('화면 편집')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              const Text(
                '순서를 바꾸거나\n목록에서 숨길 수 있어요',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _visible.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 150,
                  ),
                  itemBuilder: (context, index) {
                    final id = _visible[index];
                    return DragTarget<String>(
                      onWillAcceptWithDetails: (details) => details.data != id,
                      onAcceptWithDetails: (details) =>
                          _swapWidget(details.data, id),
                      builder: (context, candidateData, rejectedData) =>
                          LongPressDraggable<String>(
                        data: id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: (constraints.maxWidth - 10) / 2,
                            height: 150,
                            child: _EditorWidgetCard(
                              id: id,
                              onHide: () {},
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _EditorWidgetCard(
                            id: id,
                            onHide: () => _hide(id),
                          ),
                        ),
                        child: _EditorWidgetCard(
                          id: id,
                          onHide: () => _hide(id),
                          highlighted: candidateData.isNotEmpty,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_hidden.isNotEmpty) ...[
                const Divider(height: 40),
                const Text(
                  '숨긴 항목',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final id in _hidden)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(id == 'today_spent'
                        ? '오늘 지출'
                        : homeWidgetLabels[id] ?? id),
                    trailing: IconButton(
                      onPressed: () => _show(id),
                      icon: const Icon(Icons.add_circle,
                          color: Colors.deepPurple),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  HomeWidgetEditorArguments(
                    order: [..._visible],
                    hidden: [..._hidden],
                  ),
                ),
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      );
}

class _EditorWidgetCard extends StatelessWidget {
  const _EditorWidgetCard({
    required this.id,
    required this.onHide,
    this.highlighted = false,
  });

  final String id;
  final VoidCallback onHide;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: highlighted ? Colors.deepPurple.withValues(alpha: 0.08) : null,
        child: SizedBox(
          height: 150,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: IconButton(
                  onPressed: onHide,
                  icon: const Icon(Icons.remove_circle, color: Colors.blueGrey),
                ),
              ),
              const Positioned(
                right: 12,
                top: 14,
                child: Icon(Icons.drag_handle, color: Colors.blueGrey),
              ),
              Center(
                child: Text(
                  homeWidgetLabels[id] ?? id,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

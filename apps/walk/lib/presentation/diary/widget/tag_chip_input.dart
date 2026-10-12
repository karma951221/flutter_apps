import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/named_count.dart';

/// 입력 글자로 추천 목록을 찾는다(`DiaryRepository.watchTagCounts` · `watchPlaceCounts`).
typedef SuggestionSource = Stream<List<NamedCount>> Function(String query);

/// 해시태그 칩 입력(스펙 §6.2). 완료 · 띄어쓰기 · 쉼표로 칩을 만들고, 입력칸에 있는 동안
/// 기존 태그를 추천한다. 정규화 · 중복 무시는 부모(cubit)가 한다 — 여기서는 원문을 넘긴다.
///
/// 저장 직전에 부모가 `GlobalKey<TagChipInputState>` 로 [TagChipInputState.commitPending] 을
/// 불러 아직 칩이 되지 않은 글자를 칩으로 만든다.
class TagChipInput extends StatefulWidget {
  const TagChipInput({
    required this.tags,
    required this.onAdd,
    required this.onRemove,
    required this.suggestionsFor,
    super.key,
  });

  /// 정규화된 이름, 입력 순.
  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final SuggestionSource suggestionsFor;

  @override
  State<TagChipInput> createState() => TagChipInputState();
}

class TagChipInputState extends State<TagChipInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late Stream<List<NamedCount>> _suggestions = widget.suggestionsFor('');
  String _query = '';

  static final _separator = RegExp(r'[\s,]$');

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (_separator.hasMatch(text)) {
      _commit(text.replaceFirst(RegExp(r'[\s,]+$'), ''));
      return;
    }
    _search(text);
  }

  /// 입력칸에 남은 글자(칩으로 만들지 않은 것)를 칩으로 만든다. 비었으면 아무것도 하지 않는다.
  void commitPending() {
    if (_controller.text.trim().isEmpty) return;
    _commit(_controller.text);
  }

  void _commit(String raw) {
    if (raw.trim().isNotEmpty) widget.onAdd(raw);
    _controller.clear();
    _search('');
  }

  void _search(String query) {
    if (query == _query) return;
    setState(() {
      _query = query;
      _suggestions = widget.suggestionsFor(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in widget.tags)
                InputChip(
                  label: Text(l10n.walkDiaryTag(tag)),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => widget.onRemove(tag),
                ),
            ],
          ),
        TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.tag),
            hintText: l10n.walkDiaryEditorTagHint,
          ),
          onChanged: _onChanged,
          onSubmitted: (text) {
            _commit(text);
            _focus.requestFocus();
          },
        ),
        if (_focus.hasFocus)
          SuggestionChips(
            stream: _suggestions,
            exclude: widget.tags.toSet(),
            label: (s) => l10n.walkDiaryEditorTagSuggestion(s.name, s.count),
            onTap: (name) => _commit(name),
          ),
      ],
    );
  }
}

/// 추천 칩 한 줄(가로 스크롤). [exclude] 에 든 이름은 빼고, 비면 아무것도 그리지 않는다.
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    required this.stream,
    required this.label,
    required this.onTap,
    this.exclude = const {},
    super.key,
  });

  final Stream<List<NamedCount>> stream;
  final String Function(NamedCount suggestion) label;
  final ValueChanged<String> onTap;
  final Set<String> exclude;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<NamedCount>>(
    stream: stream,
    builder: (context, snapshot) {
      final items = [
        for (final s in snapshot.data ?? const <NamedCount>[])
          if (!exclude.contains(s.name)) s,
      ];
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in items)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ActionChip(
                    label: Text(label(s)),
                    onPressed: () => onTap(s.name),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

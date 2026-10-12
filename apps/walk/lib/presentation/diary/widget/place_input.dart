import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_location.dart';
import '../../../domain/diary/entity/named_count.dart';
import 'tag_chip_input.dart';

/// 작성 화면의 위치 행(스펙 §6.2).
///
/// - 지금 위치를 찾는 중이면 안내.
/// - 지금 위치가 붙어 있으면 이름(없으면 '이름 없는 위치') + ✕.
/// - [manualPlace] 면 장소 이름 직접 입력칸 + 기존 장소 추천(좌표 없음).
class PlaceInput extends StatefulWidget {
  const PlaceInput({
    required this.location,
    required this.locating,
    required this.manualPlace,
    required this.onClear,
    required this.onName,
    required this.suggestionsFor,
    super.key,
  });

  final EntryLocation? location;
  final bool locating;
  final bool manualPlace;
  final VoidCallback onClear;

  /// 직접 입력한 이름. 비우면 위치 없음.
  final ValueChanged<String> onName;
  final SuggestionSource suggestionsFor;

  @override
  State<PlaceInput> createState() => _PlaceInputState();
}

class _PlaceInputState extends State<PlaceInput> {
  late final _controller = TextEditingController(
    text: widget.manualPlace ? widget.location?.placeName ?? '' : '',
  );
  final _focus = FocusNode();
  late Stream<List<NamedCount>> _suggestions = _search(_controller.text);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(PlaceInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 직접 입력으로 바뀌면 그때의 이름(지금 위치를 뺐으면 빈칸)에서 시작한다.
    if (!oldWidget.manualPlace && widget.manualPlace) {
      _controller.text = widget.location?.placeName ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Stream<List<NamedCount>> _search(String query) =>
      widget.suggestionsFor(query.trim());

  void _onChanged(String text) {
    widget.onName(text);
    setState(() => _suggestions = _search(text));
  }

  void _pickSuggestion(String name) {
    _controller.text = name;
    _onChanged(name);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.locating) {
      return AppListTile(
        leading: const Icon(Icons.place_outlined),
        title: Text(l10n.walkDiaryEditorLocating),
      );
    }
    final location = widget.location;
    if (!widget.manualPlace && location != null) {
      return AppListTile(
        leading: const Icon(Icons.place_outlined),
        title: Text(location.placeName ?? l10n.walkDiaryEditorUnnamedPlace),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.walkDiaryEditorRemoveLocation,
          onPressed: widget.onClear,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.place_outlined),
              hintText: l10n.walkDiaryEditorPlaceHint,
            ),
            onChanged: _onChanged,
          ),
          if (_focus.hasFocus)
            SuggestionChips(
              stream: _suggestions,
              exclude: {_controller.text.trim()},
              label: (s) =>
                  l10n.walkDiaryEditorPlaceSuggestion(s.name, s.count),
              onTap: _pickSuggestion,
            ),
        ],
      ),
    );
  }
}

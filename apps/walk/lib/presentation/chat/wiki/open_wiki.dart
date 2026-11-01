import 'package:flutter/widgets.dart';

import '../../diary/page/diary_route.dart';
import 'page/wiki_note_page.dart';
import 'page/wiki_page.dart';

/// 위키 화면을 잠금 아래로 연다. [대화 보기]를 고르면 그 대화 id 로 끝난다 —
/// 여는 쪽(ChatTab)이 cubit.open 한다.
Future<String?> openWikiPage(BuildContext context) =>
    pushDiaryRoute<String>(context, page: (_) => const WikiPage());

/// 메모 하나를 잠금 아래로 연다. [대화 보기]를 고르면 그 대화 id 로 끝난다 —
/// 여는 쪽이 그 id 를 그대로 위로 넘긴다.
Future<String?> openWikiNote(BuildContext context, int id) =>
    pushDiaryRoute<String>(context, page: (_) => WikiNotePage(id: id));

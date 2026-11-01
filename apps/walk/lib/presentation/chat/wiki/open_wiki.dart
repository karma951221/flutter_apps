import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/repository/wiki_repository.dart';
import '../../diary/page/diary_route.dart';
import 'cubit/wiki_edit_cubit.dart';
import 'cubit/wiki_edit_state.dart';
import 'page/wiki_note_edit_page.dart';
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

/// 메모 편집 화면을 잠금 아래로 연다. 저장하면 메모 id, 취소면 null.
/// cubit 은 게이트 바깥(scope)에 둬 잠겼다 풀려도 쓰던 글이 남는다.
Future<int?> openWikiEditor(BuildContext context, WikiEditSeed seed) =>
    pushDiaryRoute<int>(
      context,
      page: (_) => const WikiNoteEditPage(),
      scope: (_, gated) => BlocProvider(
        create: (_) => WikiEditCubit(getIt<WikiRepository>(), seed: seed),
        child: gated,
      ),
    );

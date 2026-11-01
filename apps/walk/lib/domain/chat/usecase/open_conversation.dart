import 'package:injectable/injectable.dart';

/// 지금 탭에 열린 저장 대화 id. ChatCubit 이 쓰고 ChatHistoryPruner 가 읽는다.
@lazySingleton
class OpenConversation {
  String? id;
}

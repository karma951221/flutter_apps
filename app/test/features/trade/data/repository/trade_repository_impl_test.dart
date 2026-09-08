import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/trade/data/cursor/trade_cursor.dart';
import 'package:daylog/features/trade/data/datasource/trade_data_source.dart';
import 'package:daylog/features/trade/data/dto/trade_session_dto.dart';
import 'package:daylog/features/trade/data/dto/trade_session_summary_dto.dart';
import 'package:daylog/features/trade/data/repository/trade_repository_impl.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeDataSource extends Mock implements TradeDataSource {}

TradeSessionSummaryDto _summary(int index) => TradeSessionSummaryDto(
  id: 'session-$index',
  createdAt: DateTime.utc(2026, 8, 30, 9).subtract(Duration(minutes: index)),
  finishedAt: DateTime.utc(2026, 8, 30, 9),
  step: 60,
);

const _session = TradeSessionDto(
  id: 's1',
  userId: 'u1',
  step: 3,
  cash: 9000,
  quantity: 1.5,
  isFinished: false,
);

void main() {
  late _MockTradeDataSource dataSource;
  late TradeRepositoryImpl repository;

  setUp(() {
    dataSource = _MockTradeDataSource();
    repository = TradeRepositoryImpl(dataSource);
  });

  group('getPastSessions', () {
    test('다음 페이지 유무를 알려고 한 개를 더 요청한다', () async {
      when(
        () => dataSource.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => []);

      await repository.getPastSessions(limit: 20);

      verify(() => dataSource.getPastSessions(limit: 21, cursor: null)).called(1);
    });

    test('요청한 개수보다 많이 오면 잘라내고 다음 커서를 만든다', () async {
      when(
        () => dataSource.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => [for (var i = 0; i < 3; i++) _summary(i)]);

      final result = await repository.getPastSessions(limit: 2);

      final page = (result as Ok).value;
      expect(page.items.length, 2);
      expect(page.hasMore, isTrue);
      // 커서는 잘라낸 뒤의 마지막 항목이다.
      expect(TradeCursor.decode(page.nextCursor)!.id, 'session-1');
    });

    test('요청한 개수 이하로 오면 마지막 페이지다', () async {
      when(
        () => dataSource.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => [_summary(0)]);

      final result = await repository.getPastSessions(limit: 20);

      expect((result as Ok).value.hasMore, isFalse);
    });

    test('받은 커서를 해석해 데이터 원천에 넘긴다', () async {
      final cursor = TradeCursor(createdAt: DateTime.utc(2026, 8, 30, 9), id: 'session-9');
      when(
        () => dataSource.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => []);

      await repository.getPastSessions(limit: 20, cursor: cursor.encode());

      verify(() => dataSource.getPastSessions(limit: 21, cursor: cursor)).called(1);
    });

    test('깨진 커서는 Err 로 돌려주고 데이터 원천을 부르지 않는다', () async {
      final result = await repository.getPastSessions(limit: 20, cursor: 'not-a-cursor');

      expect((result as Err).failure, isA<ValidationFailure>());
      verifyNever(
        () => dataSource.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      );
    });
  });

  group('getActiveSession', () {
    test('진행 중인 판이 없으면 Ok(null) 이고 getSession 을 부르지 않는다', () async {
      when(() => dataSource.getActiveSessionId()).thenAnswer((_) async => null);

      final result = await repository.getActiveSession();

      expect((result as Ok).value, isNull);
      verifyNever(() => dataSource.getSession(any()));
    });

    test('진행 중인 판이 있으면 그 id 로 getSession 을 불러 돌려준다', () async {
      when(() => dataSource.getActiveSessionId()).thenAnswer((_) async => 's1');
      when(() => dataSource.getSession('s1')).thenAnswer((_) async => _session);

      final result = await repository.getActiveSession();

      expect((result as Ok).value!.id, 's1');
      verify(() => dataSource.getSession('s1')).called(1);
    });
  });

  test('시작 실패는 Err 로 옮긴다', () async {
    when(
      () => dataSource.startSession(),
    ).thenThrow(const Failure.validation(message: '진행 중인 판이 있습니다'));

    final result = await repository.startSession();

    expect((result as Err).failure, isA<ValidationFailure>());
  });

  test('주문 성공은 Ok 로 돌려준다', () async {
    when(
      () => dataSource.placeOrder(
        sessionId: 's1',
        side: TradeSide.buy,
        quantity: 1,
      ),
    ).thenAnswer((_) async => _session);

    final result = await repository.placeOrder(sessionId: 's1', side: TradeSide.buy, quantity: 1);

    expect((result as Ok).value.id, 's1');
  });
}

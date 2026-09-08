import '../../../trade/domain/entity/trade_result_summary.dart';
import '../../domain/entity/post.dart';
import '../../domain/entity/post_image.dart';
import '../dto/post_dto.dart';
import '../dto/post_trade_result_dto.dart';

/// data/domain 경계의 게시물 변환.
extension PostDtoMapper on PostDto {
  Post toEntity() => Post(
    id: id,
    authorId: authorId,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
    images: images
        .map(
          (image) => PostImage(
            id: image.id,
            url: image.url,
            width: image.width,
            height: image.height,
            sortOrder: image.sortOrder,
          ),
        )
        .toList(),
    tradeResult: tradeResult?.toEntity(),
  );
}

extension PostTradeResultDtoMapper on PostTradeResultDto {
  TradeResultSummary toEntity() => TradeResultSummary(
    sessionId: sessionId,
    symbol: symbol,
    startDay: startDay,
    endDay: endDay,
    returnPct: returnPct,
    buyHoldReturnPct: buyHoldReturnPct,
    maxDrawdownPct: maxDrawdownPct,
    tradeCount: tradeCount,
  );
}

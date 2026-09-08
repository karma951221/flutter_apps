#!/usr/bin/env python3
"""Binance의 과거 일봉을 받아 로컬 Supabase seed SQL을 생성한다.

프로젝트 루트에서 `python3 supabase/scripts/fetch_candles.py`로 실행한다.
부분 확인은 `--symbols BTC,ETH`, 출력 경로 변경은 `--out <path>`를 쓴다.
시세는 월 1회 수동으로 전체 재수집하며, 생성된 SQL은 직접 수정하지 않는다.
"""
import argparse
import datetime
import decimal
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


BASE_SYMBOLS = (
    "BTC", "ETH", "BNB", "XRP", "ADA", "LTC", "TRX", "XLM", "ETC", "BCH",
    "LINK", "MATIC", "ATOM", "DOGE", "DOT", "SOL", "AVAX", "UNI", "NEAR", "FIL",
)
PRIMARY_ENDPOINT = "https://api.binance.com/api/v3/klines"
FALLBACK_ENDPOINT = "https://data-api.binance.vision/api/v3/klines"
START_TIME_MS = 1483228800000  # 2017-01-01T00:00:00Z
DAY_MS = 86_400_000
PAGE_SIZE = 1000
REQUEST_INTERVAL_SECONDS = 0.2
MAX_RATE_LIMIT_RETRIES = 3


class KlineClient:
    def __init__(self):
        self.endpoint = PRIMARY_ENDPOINT

    def fetch(self, symbol, start_time):
        params = urllib.parse.urlencode({
            "symbol": symbol,
            "interval": "1d",
            "startTime": start_time,
            "limit": PAGE_SIZE,
        })
        try:
            return self._request(f"{self.endpoint}?{params}")
        except urllib.error.HTTPError as error:
            if self.endpoint != PRIMARY_ENDPOINT or error.code not in (403, 451):
                raise RuntimeError(
                    f"{self.endpoint} 요청 실패: HTTP {error.code}"
                ) from error
            primary_error = f"HTTP {error.code}"
        except urllib.error.URLError as error:
            if self.endpoint != PRIMARY_ENDPOINT:
                raise RuntimeError(
                    f"{self.endpoint} 연결 실패: {error.reason}"
                ) from error
            primary_error = str(error.reason)

        print(
            f"WARN  기본 Binance API 실패({primary_error}); data-api.binance.vision으로 재시도",
            file=sys.stderr,
        )
        self.endpoint = FALLBACK_ENDPOINT
        try:
            return self._request(f"{self.endpoint}?{params}")
        except urllib.error.HTTPError as error:
            raise RuntimeError(
                "Binance 기본/대체 API가 모두 실패했습니다: "
                f"기본={primary_error}, 대체=HTTP {error.code}"
            ) from error
        except urllib.error.URLError as error:
            raise RuntimeError(
                "Binance 기본/대체 API가 모두 실패했습니다: "
                f"기본={primary_error}, 대체={error.reason}"
            ) from error

    @staticmethod
    def _request(url):
        retries = 0
        while True:
            request = urllib.request.Request(url, headers={"User-Agent": "daylog-candle-seeder/1.0"})
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    return json.loads(response.read().decode("utf-8"))
            except urllib.error.HTTPError as error:
                if error.code != 429 or retries >= MAX_RATE_LIMIT_RETRIES:
                    raise
                retry_after = error.headers.get("Retry-After", "1")
                try:
                    wait_seconds = max(0.0, float(retry_after))
                except ValueError:
                    wait_seconds = 1.0
                retries += 1
                print(
                    f"WARN  HTTP 429; {wait_seconds:g}초 후 재시도 "
                    f"({retries}/{MAX_RATE_LIMIT_RETRIES})",
                    file=sys.stderr,
                )
                time.sleep(wait_seconds)
            finally:
                time.sleep(REQUEST_INTERVAL_SECONDS)


def utc_day(milliseconds):
    epoch = datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)
    return (epoch + datetime.timedelta(milliseconds=milliseconds)).date()


def parse_candle(symbol, raw, now_ms):
    if not isinstance(raw, list) or len(raw) < 7:
        raise ValueError(f"올바르지 않은 kline 배열: {raw!r}")
    open_time = int(raw[0])
    close_time = int(raw[6])
    if close_time > now_ms:
        return None
    try:
        values = tuple(decimal.Decimal(str(raw[index])) for index in range(1, 6))
    except decimal.InvalidOperation as error:
        raise ValueError(f"숫자로 읽을 수 없는 kline: {raw!r}") from error
    return (symbol, utc_day(open_time), *values)


def collect_symbol(client, symbol, now_ms):
    candles = []
    start_time = START_TIME_MS
    while True:
        page = client.fetch(symbol, start_time)
        if not isinstance(page, list):
            raise RuntimeError(f"{symbol}: Binance 응답이 배열이 아닙니다: {page!r}")
        for raw in page:
            candle = parse_candle(symbol, raw, now_ms)
            if candle is not None:
                candles.append(candle)
        if len(page) < PAGE_SIZE:
            break
        if not page:
            break
        next_start = int(page[-1][0]) + DAY_MS
        if next_start <= start_time:
            raise RuntimeError(f"{symbol}: 페이지의 open_time이 증가하지 않습니다")
        start_time = next_start
    return candles


def validation_error(candles):
    if len(candles) < 120:
        return f"최소 120봉 미달({len(candles)}봉)"
    for previous, current in zip(candles, candles[1:]):
        if current[1] - previous[1] != datetime.timedelta(days=1):
            return f"날짜 불연속({previous[1]} 다음이 {current[1]})"
    for symbol, day, open_price, high, low, close, volume in candles:
        if high < max(open_price, close):
            return f"{day}: high가 open/close보다 낮음"
        if low > min(open_price, close):
            return f"{day}: low가 open/close보다 높음"
        if volume < 0:
            return f"{day}: volume이 음수"
    return None


def sql_number(value):
    text = format(value, "f")
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return "0" if text in ("", "-0") else text


def write_seed(path, candles_by_symbol):
    rows = [candle for candles in candles_by_symbol for candle in candles]
    generated_at = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0)
    timestamp = generated_at.isoformat().replace("+00:00", "Z")
    with open(path, "w", encoding="utf-8", newline="\n") as output:
        output.write(f"-- generated by supabase/scripts/fetch_candles.py at {timestamp}\n")
        output.write(
            f"-- {len(candles_by_symbol)} symbols, {len(rows)} rows. do not edit by hand.\n"
        )
        for offset in range(0, len(rows), 1000):
            chunk = rows[offset:offset + 1000]
            output.write(
                "insert into public.market_candles "
                "(symbol, day, open, high, low, close, volume) values\n"
            )
            values = []
            for symbol, day, open_price, high, low, close, volume in chunk:
                values.append(
                    f"('{symbol}', '{day.isoformat()}', {sql_number(open_price)}, "
                    f"{sql_number(high)}, {sql_number(low)}, {sql_number(close)}, "
                    f"{sql_number(volume)})"
                )
            output.write(",\n".join(values))
            output.write("\non conflict (symbol, day) do nothing;\n")


def parse_symbols(value, parser):
    requested = [symbol.strip().upper() for symbol in value.split(",") if symbol.strip()]
    if not requested:
        parser.error("--symbols에는 종목을 하나 이상 지정해야 합니다")
    unknown = [symbol for symbol in requested if symbol not in BASE_SYMBOLS]
    if unknown:
        parser.error(f"지원하지 않는 종목: {', '.join(unknown)}")
    return list(dict.fromkeys(requested))


def main():
    parser = argparse.ArgumentParser(description="Binance 일봉 seed SQL 생성")
    parser.add_argument("--symbols", default=",".join(BASE_SYMBOLS), help="수집할 base symbol 목록")
    parser.add_argument(
        "--out", default="supabase/seeds/market_candles.sql", help="생성할 SQL 경로"
    )
    args = parser.parse_args()
    symbols = parse_symbols(args.symbols, parser)

    now = datetime.datetime.now(datetime.timezone.utc)
    now_ms = int(now.timestamp() * 1000)
    client = KlineClient()
    valid = []
    for base_symbol in symbols:
        symbol = f"{base_symbol}USDT"
        candles = collect_symbol(client, symbol, now_ms)
        error = validation_error(candles)
        if error:
            print(f"WARN  {symbol} 제외: {error}", file=sys.stderr)
            continue
        valid.append(candles)
        print(f"OK    {symbol}: {len(candles)}봉", file=sys.stderr)

    write_seed(args.out, valid)
    row_count = sum(len(candles) for candles in valid)
    print(f"{args.out}: {len(valid)} symbols, {row_count} rows")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, OSError, json.JSONDecodeError) as error:
        print(f"ERROR {error}", file=sys.stderr)
        raise SystemExit(1) from error

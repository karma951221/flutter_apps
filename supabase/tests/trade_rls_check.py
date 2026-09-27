#!/usr/bin/env python3
"""F10 모의투자(trade_sessions · trade_orders)의 권한 경계와 채점을 실제 JWT + REST 로 확인한다.

apps/trader/docs/schema.md §17 이 약속한 것 두 가지를 훑는다.

1. **판이 끝나기 전엔 종목 · 날짜 · 미래 봉이 어떤 경로로도 내려가지 않는다** —
   컬럼 GRANT(`symbol` · `start_day`)와 RPC 의 거절 문구가 그 경계다.
2. **채점은 서버가 한다** — 스크립트가 내려받은 정규화 봉만으로 지표 넷을 다시
   계산해 RPC 가 채운 값과 맞춰 본다.

로컬 Supabase 를 띄우고 `python3 supabase/tests/trade_rls_check.py` 로 실행한다.
"""
import json
import re
import urllib.error
import urllib.request
import uuid
from decimal import Decimal, ROUND_HALF_UP

BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

WARMUP_CANDLES = 60
TOTAL_CANDLES = 120
INITIAL_CASH = Decimal(10000)
FEE_RATE = Decimal("0.001")

results = []


def call(method, path, token, body=None, headers=None, base=BASE):
    url = f"{base}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("apikey", ANON)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read().decode()
            # 지표를 소수로 다시 계산하므로 float 이 아니라 Decimal 로 받는다.
            return r.status, (json.loads(raw, parse_float=Decimal) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw, parse_float=Decimal)
        except json.JSONDecodeError:
            return e.code, raw


def signup(nickname):
    email = f"{nickname}-{uuid.uuid4().hex[:8]}@example.test"
    status, body = call(
        "POST", "/auth/v1/admin/users", SERVICE,
        {"email": email, "password": "password123", "email_confirm": True,
         "user_metadata": {"nickname": nickname}},
    )
    assert status == 200, (status, body)
    uid = body["id"]
    status, body = call(
        "POST", "/auth/v1/token?grant_type=password", ANON,
        {"email": email, "password": "password123"},
    )
    assert status == 200, (status, body)
    return uid, body["access_token"]


def check(name, ok, detail=""):
    results.append((ok, name, detail))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  — {detail}" if detail else ""))


def rpc(name, token, params=None):
    return call("POST", f"/rest/v1/rpc/{name}", token, params if params is not None else {})


def message_of(body):
    return body.get("message") if isinstance(body, dict) else None


def code_of(body):
    return body.get("code") if isinstance(body, dict) else None


def rejected(status, body, text):
    """RPC 의 `raise exception` 은 400(P0001) 또는 지정한 errcode 로 온다."""
    return status in (400, 401, 403) and message_of(body) == text


def dec(x):
    return x if isinstance(x, Decimal) else Decimal(str(x))


def q2(x):
    return dec(x).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


DAY_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def replay(closes, orders, end_index):
    """정규화 봉과 주문만으로 종료 시 현금과 지표 넷을 다시 계산한다.

    apps/trader/docs/schema.md §17 의 정의를 그대로 옮긴 것이다 — 종료 봉 종가로 청산하고,
    step 0..end 의 평가액 곡선에서 최대 낙폭을 잡는다. 청산은 주문이 아니다.
    """
    end_step = end_index - WARMUP_CANDLES + 1
    by_step = {}
    for o in orders:
        by_step.setdefault(int(o["step"]), []).append(o)

    def apply(cash, quantity, order):
        amount = dec(order["quantity"]) * dec(order["price"])
        fee = dec(order["fee"])
        if order["side"] == "buy":
            return cash - amount - fee, quantity + dec(order["quantity"])
        return cash + amount - fee, quantity - dec(order["quantity"])

    # (1) 주문을 모두 반영한 뒤 종료 봉 종가로 청산한 최종 현금.
    cash, quantity = INITIAL_CASH, Decimal(0)
    for step in range(0, end_step + 1):
        for order in by_step.get(step, []):
            cash, quantity = apply(cash, quantity, order)
    if quantity > 0:
        proceeds = quantity * closes[end_index]
        cash = cash + proceeds - proceeds * FEE_RATE
    final_cash = cash

    # (2) 평가액 곡선. 각 step 의 평가액은 그 step 의 주문을 반영한 뒤 cash + qty × close.
    cash, quantity = INITIAL_CASH, Decimal(0)
    peak, drawdown = INITIAL_CASH, Decimal(0)
    for step in range(0, end_step + 1):
        for order in by_step.get(step, []):
            cash, quantity = apply(cash, quantity, order)
        equity = final_cash if step == end_step else cash + quantity * closes[WARMUP_CANDLES - 1 + step]
        peak = max(peak, equity)
        if peak > 0:
            drawdown = max(drawdown, (peak - equity) / peak)

    return {
        "final_equity": q2(final_cash),
        "return_pct": q2((final_cash / INITIAL_CASH - 1) * 100),
        "buy_hold_return_pct": q2(
            ((1 - FEE_RATE) * (1 - FEE_RATE) * closes[end_index] / closes[WARMUP_CANDLES - 1] - 1) * 100
        ),
        "max_drawdown_pct": q2(drawdown * 100),
        "trade_count": len(orders),
    }


def closes_of(state):
    return [dec(c["c"]) for c in state["candles"]]


suffix = uuid.uuid4().hex[:6]
a_id, A = signup(f"A{suffix}")
b_id, B = signup(f"B{suffix}")

# --- 판을 시작한다 -----------------------------------------------------------
st, a_session = rpc("start_trade_session", A)
ok = st == 200 and isinstance(a_session, str)
check("판을 시작하면 id 만 내려온다", ok, f"{st} {str(a_session)[:40]}")
assert ok, (st, a_session)

st, body = rpc("start_trade_session", A)
check("진행 중인 판이 있으면 두 번째는 거부된다",
      rejected(st, body, "진행 중인 판이 있습니다"), f"{st} {message_of(body)}")

# --- 숨김 컬럼은 GRANT 가 막는다 ---------------------------------------------
st, body = call("GET", "/rest/v1/trade_sessions?select=symbol", A)
check("본인도 symbol 컬럼은 읽지 못한다 (42501)",
      st in (401, 403) and code_of(body) == "42501", f"{st} {code_of(body)}")

st, body = call("GET", "/rest/v1/trade_sessions?select=start_day", A)
check("본인도 start_day 컬럼은 읽지 못한다 (42501)",
      st in (401, 403) and code_of(body) == "42501", f"{st} {code_of(body)}")

st, body = call("GET", "/rest/v1/trade_sessions?select=*", A)
check("본인도 * 로는 못 읽는다 — 숨김 컬럼이 섞여 컬럼 단위 GRANT 에 걸린다 (42501)",
      st in (401, 403) and code_of(body) == "42501", f"{st} {code_of(body)}")

st, rows = call("GET", f"/rest/v1/trade_sessions?select=id,step,cash&id=eq.{a_session}", A)
check("GRANT 된 컬럼만 고르면 내 판이 보인다 (컬럼 단위 경계다)",
      st == 200 and len(rows or []) == 1, f"{st} {str(rows)[:60]}")

# --- 남의 진행 중 판은 존재 여부도 밝히지 않는다 -----------------------------
for name, params in (
    ("get_trade_session", {"session_id": a_session}),
    ("place_trade_order", {"session_id": a_session, "side": "buy", "quantity": 1}),
    ("advance_trade_session", {"session_id": a_session}),
    ("finish_trade_session", {"session_id": a_session}),
):
    st, body = rpc(name, B, params)
    check(f"B 는 A 의 진행 중 판에 {name} 할 수 없다",
          rejected(st, body, "판을 찾을 수 없습니다"), f"{st} {message_of(body)}")

st, body = rpc("get_trade_session", ANON, {"session_id": a_session})
check("게스트도 진행 중 판은 열지 못한다",
      rejected(st, body, "판을 찾을 수 없습니다"), f"{st} {message_of(body)}")

# --- 진행 중 상태 — 보이는 봉은 60 + step 개 --------------------------------
st, state = rpc("get_trade_session", A, {"session_id": a_session})
check("A 는 자기 판을 연다", st == 200 and isinstance(state, dict), f"{st}")
check("진행 중이면 finished 가 false 다", state.get("finished") is False)
check("user_id 가 본인이다", state.get("user_id") == a_id)
check("step 0 이면 봉이 정확히 60개다", len(state["candles"]) == WARMUP_CANDLES,
      str(len(state["candles"])))
keys = {frozenset(c.keys()) for c in state["candles"]}
check("봉에는 i,o,h,l,c 만 있다 (day · volume · symbol 없음)",
      keys == {frozenset({"i", "o", "h", "l", "c"})}, str(sorted(next(iter(keys)))))
check("index 59 의 종가가 100 으로 정규화된다",
      dec(state["candles"][59]["c"]) == Decimal(100), str(state["candles"][59]["c"]))
check("주문이 없으면 orders 가 빈 배열이다", state["orders"] == [])
check("진행 중이면 result 가 null 이다", state["result"] is None)

# --- 주문 검증 ---------------------------------------------------------------
price0 = dec(state["candles"][59]["c"])
st, body = rpc("place_trade_order", A,
               {"session_id": a_session, "side": "buy",
                "quantity": float(INITIAL_CASH / price0 + 1)})
check("현금을 넘는 매수는 거부된다",
      rejected(st, body, "잔고가 부족합니다"), f"{st} {message_of(body)}")

st, body = rpc("place_trade_order", A,
               {"session_id": a_session, "side": "sell", "quantity": 1})
check("보유가 없으면 매도는 거부된다",
      rejected(st, body, "보유 수량이 부족합니다"), f"{st} {message_of(body)}")

st, body = rpc("place_trade_order", A,
               {"session_id": a_session, "side": "buy", "quantity": 0})
check("수량 0 은 거부된다",
      rejected(st, body, "수량은 0보다 커야 합니다"), f"{st} {message_of(body)}")

# JSON 표준에는 NaN 숫자가 없지만 PostgREST 는 문자열 "NaN" 을 PostgreSQL
# numeric 으로 변환한다. numeric NaN 은 0 이하 비교도 CHECK 도 통과하므로 RPC 가
# 직접 막아야 판의 cash · quantity · fee 가 NaN 으로 오염되지 않는다.
st, body = rpc("place_trade_order", A,
               {"session_id": a_session, "side": "buy", "quantity": "NaN"})
check("NaN 수량은 0과 같은 문구로 거부된다",
      rejected(st, body, "수량은 0보다 커야 합니다"), f"{st} {message_of(body)}")

st, state_after_nan = rpc("get_trade_session", A, {"session_id": a_session})
check("NaN 거부 뒤 판 상태와 주문이 오염되지 않는다",
      st == 200 and dec(state_after_nan["cash"]) == INITIAL_CASH
      and dec(state_after_nan["quantity"]) == 0 and state_after_nan["orders"] == [],
      f"{st} cash={state_after_nan.get('cash')} quantity={state_after_nan.get('quantity')}")

# --- 손계산 1건: step 0 에서 10주 매수 ---------------------------------------
st, state = rpc("place_trade_order", A,
                {"session_id": a_session, "side": "buy", "quantity": 10})
check("step 0 매수가 체결된다", st == 200, f"{st} {str(state)[:60]}")
check("현금이 10000 − 10×100 − 1 = 8999 다",
      dec(state["cash"]) == Decimal("8999"), str(state["cash"]))
check("보유 수량이 10 이다", dec(state["quantity"]) == Decimal(10), str(state["quantity"]))
order = (state["orders"] or [None])[0]
check("주문 1건이 step 0 · buy · 10 · price 100 · fee 1 로 남는다",
      len(state["orders"]) == 1 and order["step"] == 0 and order["side"] == "buy"
      and dec(order["quantity"]) == Decimal(10) and dec(order["price"]) == Decimal(100)
      and dec(order["fee"]) == Decimal(1), str(order))

st, rows = call("GET", f"/rest/v1/trade_orders?session_id=eq.{a_session}", B)
check("진행 중 판의 주문은 남에게 0행이다", st == 200 and rows == [], f"{st} {str(rows)[:60]}")

# --- 59번 advance 하면 step 59, 봉 119개 -------------------------------------
for _ in range(59):
    st, state = rpc("advance_trade_session", A, {"session_id": a_session})
    assert st == 200, (st, state)
check("59번 advance 하면 step 59 다", state["step"] == 59, str(state["step"]))
check("step 59 에서도 아직 끝나지 않았다", state["finished"] is False)
check("step 59 의 봉은 119개다 (미래 봉은 안 보인다)",
      len(state["candles"]) == 119, str(len(state["candles"])))

# --- 60번째 advance 는 마지막 봉을 공개하고 자동 종료한다 --------------------
st, state = rpc("advance_trade_session", A, {"session_id": a_session})
check("60번째 advance 로 판이 끝난다", st == 200 and state["finished"] is True, f"{st}")
check("종료 step 은 60 이다", state["step"] == 60, str(state["step"]))
check("끝나면 봉 120개가 모두 공개된다", len(state["candles"]) == TOTAL_CANDLES,
      str(len(state["candles"])))
result = state["result"] or {}
check("결과의 end_index 가 119 다", result.get("end_index") == 119, str(result.get("end_index")))

closes = closes_of(state)
expected = replay(closes, state["orders"], 119)
check("final_equity 가 손계산과 같다",
      q2(result["final_equity"]) == expected["final_equity"],
      f"rpc={result['final_equity']} 계산={expected['final_equity']}")
check("return_pct 가 손계산과 같다",
      q2(result["return_pct"]) == expected["return_pct"],
      f"rpc={result['return_pct']} 계산={expected['return_pct']}")
check("buy_hold_return_pct 가 (1−수수료)² × c119/c59 와 같다",
      q2(result["buy_hold_return_pct"]) == expected["buy_hold_return_pct"],
      f"rpc={result['buy_hold_return_pct']} 계산={expected['buy_hold_return_pct']}")
check("max_drawdown_pct 가 평가액 곡선과 같다",
      q2(result["max_drawdown_pct"]) == expected["max_drawdown_pct"],
      f"rpc={result['max_drawdown_pct']} 계산={expected['max_drawdown_pct']}")
check("trade_count 는 주문 수 1 이다 (청산은 세지 않는다)",
      result["trade_count"] == 1, str(result["trade_count"]))

# --- 끝난 판은 더 이상 움직이지 않는다 ---------------------------------------
for name, params in (
    ("place_trade_order", {"session_id": a_session, "side": "sell", "quantity": 1}),
    ("advance_trade_session", {"session_id": a_session}),
    ("finish_trade_session", {"session_id": a_session}),
):
    st, body = rpc(name, A, params)
    check(f"끝난 판에는 {name} 가 통하지 않는다",
          rejected(st, body, "이미 끝난 판입니다"), f"{st} {message_of(body)}")

# --- 끝난 판은 게스트에게도 열린다 -------------------------------------------
st, rows = call("GET", f"/rest/v1/trade_orders?session_id=eq.{a_session}", ANON)
check("끝난 판의 주문은 게스트도 1행 읽는다 (42P17 아님)",
      st == 200 and len(rows or []) == 1, f"{st} {str(rows)[:80]}")

st, guest_state = rpc("get_trade_session", ANON, {"session_id": a_session})
check("게스트가 끝난 판을 연다", st == 200 and guest_state.get("finished") is True, f"{st}")
guest_result = (guest_state or {}).get("result") or {}
check("끝나야 심볼이 공개된다",
      isinstance(guest_result.get("symbol"), str) and guest_result["symbol"].endswith("USDT"),
      str(guest_result.get("symbol")))
check("start_day · end_day 가 YYYY-MM-DD 다",
      bool(DAY_RE.match(guest_result.get("start_day") or ""))
      and bool(DAY_RE.match(guest_result.get("end_day") or "")),
      f"{guest_result.get('start_day')} ~ {guest_result.get('end_day')}")

# --- finish 는 아무 step 에서나 현재 종가로 청산한다 -------------------------
st, b_session = rpc("start_trade_session", B)
assert st == 200, (st, b_session)
for _ in range(3):
    st, b_state = rpc("advance_trade_session", B, {"session_id": b_session})
    assert st == 200, (st, b_state)
st, b_state = rpc("finish_trade_session", B, {"session_id": b_session})
check("finish 로 판이 끝난다", st == 200 and b_state["finished"] is True, f"{st}")
check("finish 는 step 을 올리지 않는다 (step 3)", b_state["step"] == 3, str(b_state["step"]))
b_result = b_state["result"] or {}
check("finish 의 end_index 는 59 + step = 62 다",
      b_result.get("end_index") == 62, str(b_result.get("end_index")))
check("주문이 없으면 trade_count 가 0 이다", b_result["trade_count"] == 0,
      str(b_result["trade_count"]))
check("주문이 없으면 return_pct 가 0 이다 (현금 그대로)",
      q2(b_result["return_pct"]) == Decimal("0.00"), str(b_result["return_pct"]))
b_expected = replay(closes_of(b_state), b_state["orders"], 62)
check("finish 의 buy_hold_return_pct 는 c62/c59 로 계산한 값과 같다",
      q2(b_result["buy_hold_return_pct"]) == b_expected["buy_hold_return_pct"],
      f"rpc={b_result['buy_hold_return_pct']} 계산={b_expected['buy_hold_return_pct']}")
check("finish 의 max_drawdown_pct 도 곡선과 같다",
      q2(b_result["max_drawdown_pct"]) == b_expected["max_drawdown_pct"],
      f"rpc={b_result['max_drawdown_pct']} 계산={b_expected['max_drawdown_pct']}")

# --- 게시물에 붙일 수 있는 것은 끝난 내 판뿐이다 -----------------------------
st, post_id = rpc("create_post_with_images", A,
                  {"content": "내 판 결과", "images": [], "trade_session_id": a_session})
check("끝난 내 판을 붙여 게시물을 만든다",
      st in (200, 201) and isinstance(post_id, str), f"{st} {str(post_id)[:40]}")

st, plain_post_id = rpc("create_post_with_images", A, {"content": "판 없는 글", "images": []})
check("기존 2-인자 시그니처도 그대로 동작한다",
      st in (200, 201) and isinstance(plain_post_id, str), f"{st} {str(plain_post_id)[:40]}")

st, body = rpc("create_post_with_images", B,
               {"content": "남의 판", "images": [], "trade_session_id": a_session})
check("남의 끝난 판은 붙일 수 없다",
      rejected(st, body, "끝난 판만 공유할 수 있습니다"), f"{st} {message_of(body)}")

st, a_active = rpc("start_trade_session", A)
assert st == 200, (st, a_active)
st, body = rpc("create_post_with_images", A,
               {"content": "진행 중인 판", "images": [], "trade_session_id": a_active})
check("진행 중인 내 판도 붙일 수 없다",
      rejected(st, body, "끝난 판만 공유할 수 있습니다"), f"{st} {message_of(body)}")

# --- 피드 뷰의 trade_result --------------------------------------------------
st, rows = call("GET", f"/rest/v1/posts_with_author?select=id,trade_result&id=eq.{post_id}", ANON)
trade_result = (rows or [{}])[0].get("trade_result") or {}
check("게스트의 피드에도 결과가 붙는다",
      st == 200 and trade_result.get("session_id") == a_session
      and str(trade_result.get("symbol", "")).endswith("USDT")
      and trade_result.get("return_pct") is not None,
      f"{st} {str(trade_result)[:100]}")

st, rows = call("GET",
                f"/rest/v1/posts_with_author?select=id,trade_result&id=eq.{plain_post_id}", ANON)
check("판 없는 게시물의 trade_result 는 null 이다",
      st == 200 and (rows or [{}])[0].get("trade_result") is None, f"{st} {str(rows)[:60]}")

st, b_post_id = rpc("create_post_with_images", B,
                    {"content": "B 의 판 결과", "images": [], "trade_session_id": b_session})
assert st in (200, 201), (st, b_post_id)
st, _ = call("POST", "/rest/v1/follows", A, {"followee_id": b_id},
             {"Prefer": "return=representation"})
assert st == 201, st
st, rows = call("GET", "/rest/v1/following_posts_with_author?select=id,trade_result", A)
with_trade = [r for r in (rows or []) if r.get("trade_result")]
check("팔로잉 피드도 trade_result 를 그대로 넘긴다",
      st == 200 and len(with_trade) == 1
      and with_trade[0]["trade_result"].get("session_id") == b_session,
      f"{st} {str(with_trade)[:100]}")

# --- 탈퇴 cascade ------------------------------------------------------------
st, rows = call("GET", f"/rest/v1/trade_sessions?user_id=eq.{b_id}&select=id", ANON)
check("탈퇴 전에는 B 의 끝난 판이 보인다", st == 200 and len(rows or []) == 1,
      f"{st} {len(rows or [])}")

st, _ = call("DELETE", f"/auth/v1/admin/users/{b_id}", SERVICE)
st, rows = call("GET", f"/rest/v1/trade_sessions?user_id=eq.{b_id}&select=id", ANON)
check("탈퇴하면 그 사람의 판이 함께 사라진다", st == 200 and rows == [], f"{st} {str(rows)[:60]}")

print()
failed = [r for r in results if not r[0]]
print(f"{len(results) - len(failed)}/{len(results)} 통과")
for _, name, detail in failed:
    print(f"  FAILED: {name} — {detail}")
raise SystemExit(1 if failed else 0)

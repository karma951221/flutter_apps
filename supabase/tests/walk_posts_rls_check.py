#!/usr/bin/env python3
"""pawlog W5 social 스키마(walk_posts · walk_post_likes)의 권한 경계를 실제 JWT + REST 로 확인한다.

apps/pawlog/docs/features/social/plan.md 의 스키마 절이 말하는 것 — 둘러보기는 로그인 없이,
쓰기는 RPC 로만, 같은 산책은 한 행, 공유 취소한 글엔 좋아요 못 함 — 을 DB 로 판정한다.
"""
import json
import urllib.error
import urllib.request
import uuid

BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

# 앱이 모두의 산책에서 읽을 컬럼. anon 에게 막힌 컬럼이 섞이면 여기서 드러난다.
COLUMNS = (
    "id,author_id,local_walk_id,started_at,duration_seconds,distance_meters,"
    "dog_names,memo,route_preview,created_at,"
    "author_nickname,author_avatar_url,like_count,liked_by_me"
)

results = []


def call(method, path, token, body=None, headers=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"{BASE}{path}", data=data, method=method)
    req.add_header("apikey", ANON)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, raw


def signup(nickname):
    """service key 로 사용자를 만들고 그 사용자의 JWT 를 받는다."""
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


def walk(local_walk_id, **overrides):
    body = {
        "p_local_walk_id": local_walk_id,
        "p_started_at": "2026-10-17T07:30:00Z",
        "p_duration_seconds": 1800,
        "p_distance_meters": 2100.5,
        "p_dog_names": ["콩이"],
        "p_memo": "아침 산책",
        "p_route_preview": [{"lat": 37.5, "lng": 127.0}, {"lat": 37.501, "lng": 127.001}],
    }
    body.update(overrides)
    return body


def publish(token, body):
    return call("POST", "/rest/v1/rpc/publish_walk_post", token, body)


def update(token, local_walk_id, **overrides):
    body = {
        "p_local_walk_id": local_walk_id,
        "p_dog_names": ["콩이", "보리"],
        "p_memo": "고친 메모",
        "p_route_preview": [{"lat": 37.5, "lng": 127.0}, {"lat": 37.502, "lng": 127.002}],
    }
    body.update(overrides)
    return call("POST", "/rest/v1/rpc/update_walk_post", token, body)


def unpublish(token, local_walk_id):
    return call("POST", "/rest/v1/rpc/unpublish_walk_post", token,
                {"p_local_walk_id": local_walk_id})


def view_row(token, post_id):
    st, rows = call("GET", f"/rest/v1/walk_posts_with_author?select={COLUMNS}&id=eq.{post_id}", token)
    return st, (rows[0] if isinstance(rows, list) and rows else None)


suffix = uuid.uuid4().hex[:6]
a_id, A = signup(f"A{suffix}")
b_id, B = signup(f"B{suffix}")
walk_a = str(uuid.uuid4())

# --- anon --------------------------------------------------------------------
st, rows = call("GET", f"/rest/v1/walk_posts_with_author?select={COLUMNS}&limit=1", ANON)
check("anon 은 보기를 읽는다", st == 200 and isinstance(rows, list), f"{st} {str(rows)[:80]}")

st, body = call("POST", "/rest/v1/walk_posts", ANON,
                {"local_walk_id": str(uuid.uuid4()), "started_at": "2026-10-17T00:00:00Z",
                 "duration_seconds": 1, "distance_meters": 1, "dog_names": ["x"]})
check("anon 은 walk_posts 에 insert 못 한다", st in (401, 403), f"{st} {str(body)[:60]}")

st, body = publish(ANON, walk(str(uuid.uuid4())))
check("anon 은 publish RPC 를 못 부른다", st in (401, 403, 404), f"{st} {str(body)[:60]}")

# --- 공유 · 조회 ---------------------------------------------------------------
st, post_id = publish(A, walk(walk_a))
check("A 가 산책을 공유한다", st == 200 and isinstance(post_id, str), f"{st} {post_id}")

st, row = view_row(B, post_id)
check("B 가 보기로 A 의 글을 본다 (작성자 닉네임 포함)",
      row is not None and row["author_nickname"] == f"A{suffix}" and row["author_id"] == a_id,
      f"{st} {str(row)[:80]}")

st, row = view_row(ANON, post_id)
check("anon 도 A 의 글을 본다", row is not None, f"{st}")

st, body = call("PATCH", f"/rest/v1/walk_posts?id=eq.{post_id}", ANON, {"memo": "x"},
                {"Prefer": "return=representation"})
check("anon 은 update 못 한다", st in (401, 403), f"{st} {str(body)[:60]}")

st, body = call("DELETE", f"/rest/v1/walk_posts?id=eq.{post_id}", ANON, None,
                {"Prefer": "return=representation"})
check("anon 은 delete 못 한다", st in (401, 403), f"{st} {str(body)[:60]}")

# --- 같은 산책 두 번 공유 ---------------------------------------------------------
st, again = publish(A, walk(walk_a, p_memo="고친 메모", p_dog_names=["콩이", "보리"]))
check("같은 local_walk_id 로 다시 공유하면 같은 id 다", again == post_id, f"{st} {again}")

st, rows = call("GET", f"/rest/v1/walk_posts_with_author?select=id,memo,dog_names&author_id=eq.{a_id}", A)
check("여전히 한 행이고 내용이 갱신된다",
      st == 200 and len(rows) == 1 and rows[0]["memo"] == "고친 메모"
      and rows[0]["dog_names"] == ["콩이", "보리"],
      f"{st} {str(rows)[:80]}")

# --- 공유 글 고치기(update_walk_post) — created_at 은 그대로 ----------------------------
st, rows = call("GET", f"/rest/v1/walk_posts?select=created_at&id=eq.{post_id}", A)
created_before = rows[0]["created_at"] if st == 200 and rows else None

st, ok = update(A, walk_a, p_memo="산책을 고쳤다", p_dog_names=["콩이", "보리", "쿠키"])
st2, row = view_row(B, post_id)
check("작성자가 update RPC 로 공유 글을 고친다",
      st == 200 and ok is True and row is not None and row["memo"] == "산책을 고쳤다"
      and row["dog_names"] == ["콩이", "보리", "쿠키"]
      and row["route_preview"][1] == {"lat": 37.502, "lng": 127.002},
      f"{st} {ok} {str(row)[:80]}")
check("고쳐도 created_at 은 그대로다 (목록 위치 유지)",
      created_before is not None and row is not None and row["created_at"] == created_before,
      f"{created_before} → {row and row['created_at']}")

st, ok = update(A, walk_a, p_memo="산책을 고쳤다", p_route_preview=None)
st2, row = view_row(B, post_id)
check("경로 없이 고칠 수 있다", ok is True and row and row["route_preview"] is None, f"{st} {ok}")

st, ok = update(B, walk_a, p_memo="남이 고침")
st2, row = view_row(B, post_id)
check("B 는 A 의 글을 못 고친다 (false · 그대로)",
      st == 200 and ok is False and row and row["memo"] == "산책을 고쳤다", f"{st} {ok}")

st, body = update(ANON, walk_a, p_memo="anon")
st2, row = view_row(B, post_id)
check("anon 은 update RPC 를 못 부른다",
      st in (401, 403, 404) and row and row["memo"] == "산책을 고쳤다", f"{st} {str(body)[:60]}")

st, ok = update(A, str(uuid.uuid4()))
check("공유하지 않은 산책을 고치면 false", st == 200 and ok is False, f"{st} {ok}")

for label, bad in (("배열이 아닌", {"lat": 1, "lng": 2}),
                   ("lat 이 문자열인", [{"lat": "37.5", "lng": 127.0}])):
    st, body = update(A, walk_a, p_route_preview=bad)
    check(f"update: {label} route_preview 는 거부된다 (22023)",
          st == 400 and isinstance(body, dict) and body.get("code") == "22023",
          f"{st} {str(body)[:80]}")

too_long = [{"lat": 37.5 + i * 1e-4, "lng": 127.0} for i in range(65)]
for label, overrides in (("64점 넘는 경로", {"p_route_preview": too_long}),
                         ("빈 반려견", {"p_dog_names": []}),
                         ("공백 반려견 이름", {"p_dog_names": ["  "]}),
                         ("501자 메모", {"p_memo": "가" * 501})):
    st, body = update(A, walk_a, **overrides)
    check(f"update: {label} 는 CHECK 로 거부된다", st == 400, f"{st} {str(body)[:80]}")

st2, row = view_row(B, post_id)
check("거부된 update 뒤에도 글은 그대로다", row and row["memo"] == "산책을 고쳤다", str(row)[:60])

# --- 남의 글은 공유 취소 못 함 ----------------------------------------------------
st, ok = unpublish(B, walk_a)
st2, row = view_row(B, post_id)
check("B 는 A 의 글을 공유 취소 못 한다", ok is False and row is not None, f"{st} {ok}")

# --- 직접 쓰기 금지 ---------------------------------------------------------------
st, body = call("PATCH", f"/rest/v1/walk_posts?id=eq.{post_id}", A, {"memo": "직접"},
                {"Prefer": "return=representation"})
check("작성자라도 PATCH walk_posts 는 거부된다", st in (401, 403), f"{st} {str(body)[:60]}")

st, body = call("DELETE", f"/rest/v1/walk_posts?id=eq.{post_id}", A, None,
                {"Prefer": "return=representation"})
check("작성자라도 DELETE walk_posts 는 거부된다", st in (401, 403), f"{st} {str(body)[:60]}")

st, body = call("POST", "/rest/v1/walk_posts", A,
                {"local_walk_id": str(uuid.uuid4()), "started_at": "2026-10-17T00:00:00Z",
                 "duration_seconds": 1, "distance_meters": 1, "dog_names": ["x"]})
check("로그인해도 직접 INSERT walk_posts 는 거부된다 (RPC 로만)", st in (401, 403),
      f"{st} {str(body)[:60]}")

st, body = call("POST", "/rest/v1/walk_posts", B,
                {"author_id": a_id, "local_walk_id": str(uuid.uuid4()),
                 "started_at": "2026-10-17T00:00:00Z", "duration_seconds": 1,
                 "distance_meters": 1, "dog_names": ["x"]})
check("author_id 위조 insert 는 거부된다 (GRANT 없음)", st in (401, 403), f"{st} {str(body)[:60]}")

st, body = call("POST", "/rest/v1/walk_posts?on_conflict=author_id,local_walk_id", A,
                {"local_walk_id": walk_a, "started_at": "2026-10-17T00:00:00Z",
                 "duration_seconds": 1, "distance_meters": 1, "dog_names": ["x"]},
                {"Prefer": "resolution=merge-duplicates,return=representation"})
check("PostgREST upsert(merge-duplicates) 는 거부된다", st in (401, 403), f"{st} {str(body)[:60]}")

# --- 좋아요 -----------------------------------------------------------------------
st, _ = call("POST", "/rest/v1/walk_post_likes", B, {"post_id": post_id})
check("B 가 좋아요를 누른다", st == 201, f"{st}")

st, row = view_row(B, post_id)
check("B 에게 like_count 1 · liked_by_me true",
      row and row["like_count"] == 1 and row["liked_by_me"] is True, str(row)[:120])
st, row = view_row(A, post_id)
check("A 에게 like_count 1 · liked_by_me false",
      row and row["like_count"] == 1 and row["liked_by_me"] is False, str(row)[:120])
st, row = view_row(ANON, post_id)
check("anon 에게 liked_by_me false",
      row and row["like_count"] == 1 and row["liked_by_me"] is False, str(row)[:120])

st, body = call("POST", "/rest/v1/walk_post_likes", B, {"post_id": post_id})
check("두 번 좋아요는 PK 충돌로 거부된다", st == 409, f"{st}")

st, _ = call("POST", "/rest/v1/walk_post_likes", A, {"post_id": post_id})
st, body = call("DELETE", f"/rest/v1/walk_post_likes?post_id=eq.{post_id}&user_id=eq.{a_id}", B,
                None, {"Prefer": "return=representation"})
st2, row = view_row(A, post_id)
check("B 는 A 의 좋아요를 못 지운다",
      body == [] and row["liked_by_me"] is True and row["like_count"] == 2,
      f"{st} {str(body)[:60]} {row and row['like_count']}")

st, body = call("POST", "/rest/v1/walk_post_likes", B,
                {"post_id": post_id, "user_id": a_id})
check("user_id 위조 좋아요는 거부된다", st in (401, 403), f"{st}")

# --- 공유 취소 · 다시 공유 ---------------------------------------------------------
st, ok = unpublish(A, walk_a)
check("A 가 공유 취소한다", st == 200 and ok is True, f"{st} {ok}")

st, row = view_row(B, post_id)
check("공유 취소한 글은 보기에서 사라진다", row is None, f"{st} {str(row)[:60]}")

for who, token in (("anon", ANON), ("B", B), ("작성자 A", A)):
    st, rows = call("GET", f"/rest/v1/walk_posts?select=id&id=eq.{post_id}", token)
    check(f"공유 취소한 행은 {who} 가 기반 테이블에서도 못 읽는다", st == 200 and rows == [],
          f"{st} {str(rows)[:60]}")

for who, token in (("anon", ANON), ("B", B)):
    st, rows = call("GET", f"/rest/v1/walk_post_likes?post_id=eq.{post_id}", token)
    check(f"공유 취소한 글의 좋아요는 {who} 에게 안 보인다", st == 200 and rows == [],
          f"{st} {str(rows)[:60]}")

c_id, C = signup(f"C{suffix}")
st, body = call("POST", "/rest/v1/walk_post_likes", C, {"post_id": post_id})
check("공유 취소한 글엔 좋아요가 거부된다", st in (401, 403), f"{st} {str(body)[:60]}")

st, ok = unpublish(A, walk_a)
check("이미 취소한 글을 다시 취소하면 false", ok is False, f"{st} {ok}")

st, ok = update(A, walk_a, p_memo="되살리지 마")
st2, row = view_row(B, post_id)
check("공유 취소한 글은 update 로 되살아나지 않는다 (false · 안 보임)",
      st == 200 and ok is False and row is None, f"{st} {ok} {str(row)[:60]}")

st, again = publish(A, walk(walk_a))
check("다시 공유하면 같은 id 로 되살아난다", again == post_id, f"{st} {again}")
st, row = view_row(B, post_id)
check("되살린 글이 보기에 다시 보인다", row is not None, f"{st}")
check("되살리면 좋아요도 돌아온다", row and row["like_count"] == 2, str(row and row["like_count"]))

st, rows = call("GET", "/rest/v1/walk_posts_with_author?select=id&order=created_at.desc,id.desc&limit=1", B)
check("다시 공유한 글이 목록 맨 위에 온다", rows and rows[0]["id"] == post_id, str(rows)[:80])

# --- CHECK 제약 --------------------------------------------------------------------
too_long = [{"lat": 37.5 + i * 1e-4, "lng": 127.0} for i in range(65)]
st, body = publish(A, walk(str(uuid.uuid4()), p_route_preview=too_long))
check("route_preview 가 64점을 넘으면 거부된다", st == 400, f"{st} {str(body)[:80]}")

exact = [{"lat": 37.5 + i * 1e-4, "lng": 127.0} for i in range(64)]
st, body = publish(A, walk(str(uuid.uuid4()), p_route_preview=exact))
check("route_preview 64점은 허용된다", st == 200, f"{st} {str(body)[:80]}")

st, body = publish(A, walk(str(uuid.uuid4()), p_route_preview=None))
check("route_preview 없이도 공유된다", st == 200, f"{st} {str(body)[:80]}")

st, body = publish(A, walk(str(uuid.uuid4()), p_dog_names=[]))
check("dog_names 가 비면 거부된다", st == 400, f"{st} {str(body)[:80]}")

st, body = publish(A, walk(str(uuid.uuid4()), p_dog_names=["콩이", "가" * 31]))
check("31자 반려견 이름은 거부된다", st == 400, f"{st} {str(body)[:80]}")

st, body = publish(A, walk(str(uuid.uuid4()), p_dog_names=["  "]))
check("공백뿐인 반려견 이름은 거부된다", st == 400, f"{st} {str(body)[:80]}")

st, body = publish(A, walk(str(uuid.uuid4()), p_dog_names=["가" * 30]))
check("30자 반려견 이름은 허용된다", st == 200, f"{st} {str(body)[:80]}")

fat = [{"lat": 37.5, "lng": 127.0, "pad": "x" * 200} for _ in range(60)]
st, body = publish(A, walk(str(uuid.uuid4()), p_route_preview=fat))
check("8KB 를 넘는 route_preview 는 거부된다", st == 400, f"{st} {str(body)[:80]}")

for label, bad in (("배열이 아닌", {"lat": 1, "lng": 2}),
                   ("lat 이 문자열인", [{"lat": "37.5", "lng": 127.0}]),
                   ("lng 가 빠진", [{"lat": 37.5}]),
                   ("원소가 숫자인", [1, 2])):
    st, body = publish(A, walk(str(uuid.uuid4()), p_route_preview=bad))
    check(f"{label} route_preview 는 거부된다 (22023)",
          st == 400 and isinstance(body, dict) and body.get("code") == "22023",
          f"{st} {str(body)[:80]}")

st, body = publish(A, walk(str(uuid.uuid4()), p_memo="가" * 501))
check("memo 500자 초과는 거부된다", st == 400, f"{st} {str(body)[:80]}")

# --- 탈퇴 cascade ------------------------------------------------------------------
st, _ = call("DELETE", f"/auth/v1/admin/users/{b_id}", SERVICE)
st, row = view_row(A, post_id)
check("탈퇴하면 그 사람의 좋아요가 함께 사라진다",
      row and row["like_count"] == 1, str(row and row["like_count"]))

# --- 정리 -------------------------------------------------------------------------
for uid in (a_id, c_id):
    st, _ = call("DELETE", f"/auth/v1/admin/users/{uid}", SERVICE)
    check("테스트 사용자를 지운다", st == 200, f"{st}")
st, rows = call("GET", f"/rest/v1/walk_posts_with_author?select=id&author_id=eq.{a_id}", ANON)
check("작성자를 지우면 공유 산책도 사라진다", rows == [], str(rows)[:60])

print()
failed = [r for r in results if not r[0]]
print(f"{len(results) - len(failed)}/{len(results)} 통과")
for _, name, detail in failed:
    print(f"  FAILED: {name} — {detail}")
raise SystemExit(1 if failed else 0)

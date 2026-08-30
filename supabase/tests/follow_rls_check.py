#!/usr/bin/env python3
"""F8 follow 스키마의 권한 경계를 실제 JWT + REST 로 확인한다.

docs/features/follow/plan.md 의 완료 조건 중 DB 로 판정되는 것들을 훑는다.
차단(F7)과의 상호작용 — 엣지 삭제 트리거와 삽입 거부 — 이 이 스크립트의 중심이다.
"""
import json
import urllib.request
import urllib.error
import uuid

BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

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
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
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


def follow(token, followee_id):
    return call("POST", "/rest/v1/follows", token, {"followee_id": followee_id},
                {"Prefer": "return=representation"})


suffix = uuid.uuid4().hex[:6]
a_id, A = signup(f"A{suffix}")
b_id, B = signup(f"B{suffix}")
c_id, C = signup(f"C{suffix}")

# --- 기본 동작 ---------------------------------------------------------------
st, row = follow(A, b_id)
check("팔로우할 수 있다", st == 201, f"{st} {str(row)[:80]}")
check("follower_id 가 auth.uid() 로 채워진다", (row or [{}])[0].get("follower_id") == a_id)

st, body = follow(A, b_id)
check("중복 팔로우는 PK 충돌로 거부된다", st == 409, f"{st}")

st, body = follow(A, a_id)
check("자기 자신은 팔로우할 수 없다 (CHECK)", st in (400, 403, 409),
      f"{st} {str(body)[:60]}")

st, body = call("POST", "/rest/v1/follows", A,
                {"follower_id": b_id, "followee_id": c_id},
                {"Prefer": "return=representation"})
check("follower_id 위조는 거부된다 (GRANT 없음)", st in (400, 401, 403),
      f"{st} {str(body)[:60]}")

# --- 조회는 공개다 -----------------------------------------------------------
st, rows = call("GET", f"/rest/v1/follows?followee_id=eq.{b_id}", C)
check("제3자도 팔로우 그래프를 읽는다", st == 200 and len(rows) == 1, f"{st} {len(rows or [])}")

st, rows = call("GET", f"/rest/v1/follows?followee_id=eq.{b_id}", ANON)
check("비로그인도 팔로우 그래프를 읽는다", st == 200 and len(rows) == 1, f"{st}")

# --- 남의 엣지는 못 지운다 ---------------------------------------------------
st, body = call("DELETE",
                f"/rest/v1/follows?follower_id=eq.{a_id}&followee_id=eq.{b_id}", C,
                None, {"Prefer": "return=representation"})
check("남의 팔로우 행은 지워지지 않는다", st == 200 and body == [], f"{st} {str(body)[:60]}")

# --- profile_details ---------------------------------------------------------
st, rows = call("GET", f"/rest/v1/profile_details?id=eq.{b_id}", A)
row = (rows or [{}])[0]
check("팔로워 수가 집계된다", row.get("follower_count") == 1, str(row.get("follower_count")))
check("is_following 이 조회자 기준이다", row.get("is_following") is True)
check("맞팔이 아니면 is_followed_by 가 false", row.get("is_followed_by") is False)

st, rows = call("GET", f"/rest/v1/profile_details?id=eq.{b_id}", C)
row = (rows or [{}])[0]
check("남이 보면 is_following 이 false 다", row.get("is_following") is False)
check("팔로워 수는 조회자와 무관하다", row.get("follower_count") == 1)

follow(B, a_id)
st, rows = call("GET", f"/rest/v1/profile_details?id=eq.{b_id}", A)
row = (rows or [{}])[0]
check("맞팔이면 양쪽 다 true 다",
      row.get("is_following") is True and row.get("is_followed_by") is True)

st, rows = call("GET", f"/rest/v1/profile_details?id=eq.{b_id}", ANON)
row = (rows or [{}])[0]
check("비로그인은 수만 보고 관계는 false 다",
      row.get("follower_count") == 1 and row.get("is_following") is False)

# --- 목록 뷰 -----------------------------------------------------------------
follow(C, b_id)
st, rows = call("GET", f"/rest/v1/user_followers?user_id=eq.{b_id}"
                       "&select=id,nickname,created_at&order=created_at.desc", A)
check("팔로워 목록에 두 명이 보인다", st == 200 and len(rows) == 2, f"{st} {len(rows or [])}")

st, rows = call("GET", f"/rest/v1/user_followings?user_id=eq.{a_id}", A)
check("팔로잉 목록은 반대 방향이다",
      len(rows) == 1 and rows[0]["id"] == b_id, str(rows)[:80])

# --- 팔로잉 피드 -------------------------------------------------------------
st, post = call("POST", "/rest/v1/posts", B, {"content": "B 의 글"},
                {"Prefer": "return=representation"})
assert st == 201, (st, post)
st, post_c = call("POST", "/rest/v1/posts", C, {"content": "C 의 글"},
                  {"Prefer": "return=representation"})
assert st == 201, (st, post_c)

st, rows = call("GET", "/rest/v1/following_posts_with_author?select=id,author_id", A)
authors = {r["author_id"] for r in (rows or [])}
check("팔로잉 피드는 팔로우한 사람의 글만 보여준다",
      st == 200 and authors == {b_id}, f"{st} {authors}")

st, rows = call("GET", "/rest/v1/posts_with_author?select=id,author_id", A)
authors = {r["author_id"] for r in (rows or [])}
check("전체 피드에는 둘 다 보인다", {b_id, c_id} <= authors, str(authors)[:80])

# --- 차단과의 상호작용 -------------------------------------------------------
# A 와 B 는 서로 팔로우 중이고, C 도 B 를 팔로우한다.
st, _ = call("POST", "/rest/v1/blocks", A, {"blocked_id": b_id},
             {"Prefer": "return=representation"})
check("차단이 걸린다", st == 201, f"{st}")

st, rows = call("GET",
                f"/rest/v1/follows?or=(and(follower_id.eq.{a_id},followee_id.eq.{b_id}),"
                f"and(follower_id.eq.{b_id},followee_id.eq.{a_id}))", C)
check("차단하면 양방향 팔로우 행이 사라진다", rows == [], str(rows)[:80])

st, body = follow(A, b_id)
check("차단 상태에서는 팔로우가 거부된다", st in (401, 403), f"{st} {str(body)[:60]}")

st, body = follow(B, a_id)
check("차단당한 쪽의 팔로우도 거부된다 (양방향 판정)", st in (401, 403), f"{st}")

# C 의 눈으로 B 의 팔로워 목록을 본다 — C 는 아무도 차단하지 않았다.
st, rows = call("GET", f"/rest/v1/user_followers?user_id=eq.{b_id}", C)
check("제3자의 목록에는 차단과 무관한 팔로워가 남는다",
      {r["id"] for r in (rows or [])} == {c_id}, str(rows)[:80])

# A 가 C 를 차단하면, A 의 눈에는 B 의 팔로워 목록에서 C 가 사라져야 한다.
follow(C, a_id)
st, _ = call("POST", "/rest/v1/blocks", A, {"blocked_id": c_id},
             {"Prefer": "return=representation"})
st, rows = call("GET", f"/rest/v1/user_followers?user_id=eq.{b_id}", A)
check("차단한 상대는 제3자의 팔로워 목록에서도 가려진다",
      rows == [], str(rows)[:80])
st, rows = call("GET", f"/rest/v1/user_followers?user_id=eq.{b_id}", C)
check("같은 목록이 다른 사람 눈에는 그대로다",
      {r["id"] for r in (rows or [])} == {c_id}, str(rows)[:80])

# 수는 조회자에 따라 달라지지 않는다 — 필터는 목록 뷰에만 있다.
st, rows_a = call("GET", f"/rest/v1/profile_details?id=eq.{b_id}", A)
st, rows_c = call("GET", f"/rest/v1/profile_details?id=eq.{b_id}", C)
check("팔로워 수는 차단 여부와 무관하게 같다",
      rows_a[0]["follower_count"] == rows_c[0]["follower_count"],
      f"A={rows_a[0]['follower_count']} C={rows_c[0]['follower_count']}")

# --- 탈퇴 cascade ------------------------------------------------------------
st, _ = call("DELETE", f"/auth/v1/admin/users/{c_id}", SERVICE)
st, rows = call("GET", f"/rest/v1/follows?follower_id=eq.{c_id}", A)
check("탈퇴하면 그 사람의 팔로우 행이 함께 사라진다", rows == [], str(rows)[:80])

print()
failed = [r for r in results if not r[0]]
print(f"{len(results) - len(failed)}/{len(results)} 통과")
for _, name, detail in failed:
    print(f"  FAILED: {name} — {detail}")
raise SystemExit(1 if failed else 0)

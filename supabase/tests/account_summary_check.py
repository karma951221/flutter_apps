#!/usr/bin/env python3
"""탈퇴 확인 화면이 보여주는 개수의 경계를 실제 JWT + REST 로 확인한다.

apps/trader/docs/features/settings/testing.md 의 "로컬 Supabase 로만 확인되는 것". 앱은
`Prefer: count=exact` HEAD 두 번으로 내 게시물 수와 댓글 수를 센다.

댓글은 `post_comments` 가 아니라 `post_comments_visible` 뷰로 센다. 원본 테이블은
`content` 가 SELECT 컬럼 GRANT 에서 빠져 있어(apps/trader/docs/schema.md §8) `select=*` 로
도는 count HEAD 가 42501 로 거부된다 — 이 스크립트의 마지막 검사가 그 이유를
붙잡아 둔다. 뷰를 테이블로 되돌리면 여기서 깨진다.
"""
import json
import urllib.error
import urllib.request
import uuid

BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

results = []


def call(method, path, token, body=None, headers=None, base=BASE):
    """HEAD 는 (status, headers) 를, 나머지는 (status, body) 를 돌려준다.

    count=exact 의 답은 본문이 아니라 `Content-Range` 헤더에 온다.
    """
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
            if method == "HEAD":
                return r.status, dict(r.headers)
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        if method == "HEAD":
            return e.code, dict(e.headers)
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


def count_head(path, token):
    return call("HEAD", path, token, None, {"Prefer": "count=exact"})


uid, TOKEN = signup(f"acct{uuid.uuid4().hex[:6]}")

# --- 셀 것을 심는다 (게시물 2 · 댓글 3) --------------------------------------
post_ids = []
for i in range(2):
    st, rows = call("POST", "/rest/v1/posts", TOKEN, {"content": f"내 글 {i + 1}"},
                    {"Prefer": "return=representation"})
    assert st == 201, (st, rows)
    post_ids.append(rows[0]["id"])

# `content` 는 SELECT 컬럼 GRANT 에 없으므로 returning 목록을 좁혀야 한다 (§8).
for i in range(3):
    st, rows = call("POST", "/rest/v1/post_comments?select=id,created_at", TOKEN,
                    {"post_id": post_ids[i % 2], "content": f"내 댓글 {i + 1}"},
                    {"Prefer": "return=representation"})
    assert st == 201, (st, rows)

# --- 앱이 실제로 보내는 두 요청 ----------------------------------------------
st, headers = count_head(f"/rest/v1/posts?author_id=eq.{uid}&deleted_at=is.null", TOKEN)
rng = headers.get("Content-Range", "")
check("내 게시물 수를 count HEAD 로 센다", st == 200 and rng.endswith("/2"),
      f"status={st} Content-Range={rng}")

st, headers = count_head(
    f"/rest/v1/post_comments_visible?author_id=eq.{uid}&deleted_at=is.null", TOKEN)
rng = headers.get("Content-Range", "")
check("내 댓글 수를 post_comments_visible 로 센다", st == 200 and rng.endswith("/3"),
      f"status={st} Content-Range={rng}")

# --- 뷰를 쓰는 이유 -----------------------------------------------------------
st, headers = count_head(
    f"/rest/v1/post_comments?author_id=eq.{uid}&deleted_at=is.null", TOKEN)
check("같은 요청을 원본 테이블에 보내면 컬럼 GRANT 가 막는다", st == 403,
      f"status={st}")

print()
failed = [r for r in results if not r[0]]
print(f"{len(results) - len(failed)}/{len(results)} 통과")
for _, name, detail in failed:
    print(f"  FAILED: {name} — {detail}")
raise SystemExit(1 if failed else 0)

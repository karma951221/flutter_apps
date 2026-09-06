#!/usr/bin/env python3
"""비로그인(anon) 이 게스트 피드를 읽을 수 있고, 쓰기는 전부 막히는지 REST 로 확인한다.

docs/features/feed/plan.md 의 완료 조건 중 게스트 피드 두 줄을 DB 로 판정한다.
스키마 변경 없이 기존 GRANT/RLS 만으로 성립해야 한다 — 이 스크립트가 깨지면
누군가 anon 권한을 걷어낸 것이다.

조회 컬럼은 앱이 실제로 요청하는 목록(`SupabaseFeedDataSource._columns`)을 그대로
쓴다. `select=id` 만 물으면 anon 에게 막힌 컬럼이 섞여 있어도 드러나지 않는다.
"""
import json
import urllib.error
import urllib.request
import uuid

BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

# app/lib/features/feed/data/datasource/supabase_feed_data_source.dart 의 _columns
# 와 같아야 한다. 공백만 없앤 형태다.
COLUMNS = (
    "id,author_id,content,created_at,updated_at,"
    "author_nickname,author_avatar_url,images,"
    "reaction_counts,my_reaction,comment_count"
)

results = []


def call(method, path, body=None, token=ANON, headers=None):
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
        "POST", "/auth/v1/admin/users",
        {"email": email, "password": "password123", "email_confirm": True,
         "user_metadata": {"nickname": nickname}},
        token=SERVICE,
    )
    assert status == 200, (status, body)
    uid = body["id"]
    status, body = call(
        "POST", "/auth/v1/token?grant_type=password",
        {"email": email, "password": "password123"},
    )
    assert status == 200, (status, body)
    return uid, body["access_token"]


def check(name, ok, detail=""):
    results.append((ok, name, detail))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  — {detail}" if detail else ""))


def seed_post_if_empty():
    """행 모양 검사가 헛돌지 않게, 로컬에 글이 하나도 없으면 하나 심는다.

    지우지는 않는다 — 로컬 스택은 `supabase db reset` 이 비우는 곳이다.
    """
    status, rows = call("GET", "/rest/v1/posts_with_author?select=id&limit=1")
    if status == 200 and rows:
        return
    _, token = signup("guestseed")
    status, row = call("POST", "/rest/v1/posts", {"content": "게스트 읽기 검사용 글"},
                       token=token, headers={"Prefer": "return=representation"})
    assert status == 201, (status, row)


seed_post_if_empty()

status, rows = call("GET", f"/rest/v1/posts_with_author?select={COLUMNS}&limit=3")
check("anon 이 앱과 같은 컬럼으로 posts_with_author 를 읽는다", status == 200,
      f"status={status} {str(rows)[:80] if status != 200 else ''}")
check("행 모양이 앱이 기대하는 그대로다 (images 는 목록, my_reaction 은 없음)",
      status == 200 and bool(rows)
      and all(isinstance(r.get("images"), list) and r.get("my_reaction") is None
              for r in rows),
      f"rows={len(rows or [])}")

status, _ = call("GET", "/rest/v1/profiles?select=id,nickname&limit=1")
check("anon 이 profiles 를 읽는다", status == 200, f"status={status}")

status, _ = call("POST", "/rest/v1/posts", {"content": "guest"})
check("anon 은 게시물을 쓰지 못한다", status in (401, 403), f"status={status}")

status, _ = call("POST", "/rest/v1/post_reactions",
                 {"post_id": "00000000-0000-0000-0000-000000000000", "type": "like"})
check("anon 은 반응을 남기지 못한다", status in (401, 403), f"status={status}")

status, body = call("GET", "/rest/v1/following_posts_with_author?select=id&limit=1")
check("anon 의 팔로잉 피드는 비어 있거나 거부된다",
      status in (200, 401, 403) and (status != 200 or body == []),
      f"status={status} body={body}")

failed = [r for r in results if not r[0]]
print(f"\n{len(results) - len(failed)}/{len(results)} passed")
for _, name, detail in failed:
    print(f"  FAILED: {name} — {detail}")
raise SystemExit(1 if failed else 0)

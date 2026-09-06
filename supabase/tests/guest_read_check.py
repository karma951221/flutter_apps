#!/usr/bin/env python3
"""비로그인(anon) 이 게스트 피드를 읽을 수 있고, 쓰기는 전부 막히는지 REST 로 확인한다.

docs/features/feed/plan.md 의 게스트 피드 완료 조건. 스키마 변경 없이 기존
GRANT/RLS 만으로 성립해야 한다 — 이 스크립트가 깨지면 누군가 anon 권한을 걷어낸 것이다.
"""
import json
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

results = []


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"{BASE}{path}", data=data, method=method)
    req.add_header("apikey", ANON)
    req.add_header("Authorization", f"Bearer {ANON}")
    req.add_header("Content-Type", "application/json")
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


def check(name, ok, detail=""):
    results.append((ok, name, detail))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  — {detail}" if detail else ""))


status, body = call("GET", "/rest/v1/posts_with_author?select=id,author_nickname&limit=3")
check("anon 이 posts_with_author 를 읽는다", status == 200, f"status={status}")

status, body = call("GET", "/rest/v1/profiles?select=id,nickname&limit=1")
check("anon 이 profiles 를 읽는다", status == 200, f"status={status}")

status, body = call("POST", "/rest/v1/posts", {"content": "guest"})
check("anon 은 게시물을 쓰지 못한다", status in (401, 403), f"status={status}")

status, body = call("POST", "/rest/v1/post_reactions", {"post_id": "00000000-0000-0000-0000-000000000000", "type": "like"})
check("anon 은 반응을 남기지 못한다", status in (400, 401, 403), f"status={status}")

status, body = call("GET", "/rest/v1/following_posts_with_author?select=id&limit=1")
check("anon 의 팔로잉 피드는 비어 있거나 거부된다", status in (200, 401, 403) and (status != 200 or body == []), f"status={status} body={body}")

failed = [r for r in results if not r[0]]
print(f"\n{len(results) - len(failed)}/{len(results)} passed")
raise SystemExit(1 if failed else 0)

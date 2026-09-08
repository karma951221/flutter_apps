#!/usr/bin/env python3
"""market_candles를 anon과 authenticated가 직접 읽지 못하는지 REST로 확인한다.

로컬 Supabase를 시작하고 `python3 supabase/tests/market_candles_grant_check.py`로
실행한다. 두 역할 모두 테이블 GRANT가 없어 42501을 받아야 하며, 이는 나중에
security definer RPC만 시세를 읽게 하는 권한 경계다.
"""
import json
import urllib.error
import urllib.request
import uuid


BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"


def call(method, path, body=None, token=ANON):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(f"{BASE}{path}", data=data, method=method)
    request.add_header("apikey", ANON)
    request.add_header("Authorization", f"Bearer {token}")
    request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read().decode()
            return response.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as error:
        raw = error.read().decode()
        try:
            return error.code, json.loads(raw)
        except json.JSONDecodeError:
            return error.code, raw


def signup():
    email = f"market-candles-{uuid.uuid4().hex[:8]}@example.test"
    status, body = call(
        "POST",
        "/auth/v1/admin/users",
        {"email": email, "password": "password123", "email_confirm": True},
        token=SERVICE,
    )
    assert status == 200, (status, body)
    status, body = call(
        "POST",
        "/auth/v1/token?grant_type=password",
        {"email": email, "password": "password123"},
    )
    assert status == 200, (status, body)
    return body["access_token"]


def is_permission_denied(status, body):
    return status in (401, 403) and isinstance(body, dict) and body.get("code") == "42501"


results = []
authenticated = signup()
for role, token in (("anon", ANON), ("authenticated", authenticated)):
    status, body = call(
        "GET", "/rest/v1/market_candles?select=symbol&limit=1", token=token
    )
    passed = is_permission_denied(status, body)
    results.append((passed, role, status, body))
    print(
        f"{'PASS' if passed else 'FAIL'}  {role} 직접 조회는 42501 permission denied"
        f"  — status={status} code={body.get('code') if isinstance(body, dict) else None}"
    )

failed = [result for result in results if not result[0]]
print(f"\n{len(results) - len(failed)}/{len(results)} passed")
raise SystemExit(1 if failed else 0)

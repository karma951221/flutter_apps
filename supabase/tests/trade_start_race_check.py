#!/usr/bin/env python3
"""같은 사용자의 동시 판 시작이 한 판과 한 사용자 문구로 끝나는지 확인한다."""
import json
import subprocess
import time
import urllib.error
import urllib.request
import uuid

BASE = "http://127.0.0.1:54321"
PSQL = ["docker", "exec", "-i", "supabase_db_socialapp",
        "psql", "-U", "postgres", "-d", "postgres", "-v", "ON_ERROR_STOP=1"]
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"


def call(method, path, token, body=None):
    request = urllib.request.Request(
        BASE + path,
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
    )
    request.add_header("apikey", ANON)
    request.add_header("Authorization", f"Bearer {token}")
    request.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(request) as response:
        return response.status, json.loads(response.read().decode() or "null")


def sql(statement):
    done = subprocess.run(
        PSQL + ["-tAc", statement], capture_output=True, text=True
    )
    return done.returncode, (done.stdout or "").strip(), (done.stderr or "").strip()


suffix = uuid.uuid4().hex[:8]
status, user = call(
    "POST",
    "/auth/v1/admin/users",
    SERVICE,
    {
        "email": f"trade-race-{suffix}@example.test",
        "password": "password123",
        "email_confirm": True,
        "user_metadata": {"nickname": f"TR{suffix}"},
    },
)
assert status == 200, (status, user)
user_id = user["id"]
claims = json.dumps({"sub": user_id, "role": "authenticated"}).replace("'", "''")
as_user = (
    "set local role authenticated; "
    f"set local request.jwt.claims = '{claims}'; "
)

try:
    holder = subprocess.Popen(
        PSQL + [
            "-tAc",
            "begin; " + as_user +
            "select public.start_trade_session(); "
            "select pg_sleep(2); commit;",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    time.sleep(0.7)

    second_code, _, second_error = sql(
        "begin; " + as_user + "select public.start_trade_session(); commit;"
    )
    holder_stdout, holder_error = holder.communicate(timeout=30)
    holder_ok = holder.returncode == 0
    message_ok = (
        second_code != 0
        and "진행 중인 판이 있습니다" in second_error
        and "duplicate key" not in second_error
        and "23505" not in second_error
    )
    _, active_count, count_error = sql(
        "select count(*) from public.trade_sessions "
        f"where user_id = '{user_id}' and finished_at is null"
    )

    print(f"{'PASS' if holder_ok else 'FAIL'}  첫 호출은 판을 만든다")
    print(f"{'PASS' if message_ok else 'FAIL'}  겹친 호출은 사용자 문구로 거부된다")
    print(f"{'PASS' if active_count == '1' else 'FAIL'}  진행 중인 판은 하나만 남는다")

    if not holder_ok:
        print(holder_error or holder_stdout)
    if not message_ok:
        print(second_error)
    if active_count != "1":
        print(count_error or active_count)

    passed = sum((holder_ok, message_ok, active_count == "1"))
    print(f"\n{passed}/3 통과")
    exit_code = 0 if passed == 3 else 1
finally:
    try:
        call("DELETE", f"/auth/v1/admin/users/{user_id}", SERVICE)
    except urllib.error.HTTPError:
        pass

raise SystemExit(exit_code)

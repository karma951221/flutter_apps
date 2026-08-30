#!/usr/bin/env python3
"""팔로우 삽입과 차단이 겹쳐도 엣지가 남지 않는지 확인한다.

`follow_rls_check.py` 는 순차 호출만 본다 — 이 결함은 두 트랜잭션이 시간적으로
겹칠 때만 나타나므로 REST 로는 재현되지 않는다. psql 세션 둘로 직접 겹친다.

배경은 `20260830150000_harden_follows.sql` 과
`docs/features/follow/history.md` 에 있다. 요약하면, 락이 없을 때는

  A: begin; insert into follows ...   (아직 커밋 안 함)
  B: insert into blocks ...           (트리거가 0행 삭제하고 커밋)
  A: commit;                          (엣지 확정)

순서로 양쪽이 다 성공해 엣지가 살아남았다.
"""
import json
import subprocess
import urllib.error
import urllib.request
import uuid

BASE = "http://127.0.0.1:54321"
# psql 은 호스트에 없을 수 있으므로 DB 컨테이너 안의 것을 쓴다.
PSQL = ["docker", "exec", "-i", "supabase_db_socialapp",
        "psql", "-U", "postgres", "-d", "postgres"]
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

results = []


def check(name, ok, detail=""):
    results.append((ok, name, detail))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  — {detail}" if detail else ""))


def signup(nickname):
    email = f"{nickname}-{uuid.uuid4().hex[:8]}@example.test"
    req = urllib.request.Request(
        f"{BASE}/auth/v1/admin/users",
        data=json.dumps(
            {"email": email, "password": "password123", "email_confirm": True,
             "user_metadata": {"nickname": nickname}}
        ).encode(),
        method="POST",
    )
    req.add_header("apikey", ANON)
    req.add_header("Authorization", f"Bearer {SERVICE}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode())["id"]


def sql(statement):
    """한 문장을 자기 트랜잭션으로 실행하고 stdout 을 돌려준다."""
    done = subprocess.run(
        PSQL + ["-tAc", statement], capture_output=True, text=True
    )
    return done.returncode, (done.stdout or "").strip(), (done.stderr or "").strip()


def race(first, second, hold_seconds=2):
    """`first` 를 트랜잭션 안에서 열어 둔 채 `second` 를 끼워 넣는다.

    락이 없으면 둘 다 그대로 통과한다. 락이 있으면 뒤에 온 쪽이 기다린다.
    """
    holder = subprocess.Popen(
        PSQL + ["-tAc",
                f"begin; {first}; select pg_sleep({hold_seconds}); commit;"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    # holder 가 문장을 실행하고 잠들 때까지 기다린다.
    subprocess.run(["sleep", "0.7"], check=True)
    code, out, err = sql(second)
    holder.wait(timeout=30)
    return code, out, err, holder.returncode, (holder.stderr.read() or "").strip()


suffix = uuid.uuid4().hex[:6]
a_id = signup(f"RA{suffix}")
b_id = signup(f"RB{suffix}")

code, out, _ = sql("select 1")
if code != 0:
    print("DB 컨테이너의 psql 에 붙지 못했다. supabase start 를 먼저 한다.")
    raise SystemExit(2)

# --- 순서 1: 팔로우가 먼저 열리고 차단이 끼어든다 ------------------------------
_, _, err, holder_code, holder_err = race(
    f"insert into public.follows (follower_id, followee_id) "
    f"values ('{a_id}', '{b_id}')",
    f"insert into public.blocks (blocker_id, blocked_id) "
    f"values ('{b_id}', '{a_id}')",
)
_, remaining, _ = sql(
    f"select count(*) from public.follows "
    f"where (follower_id = '{a_id}' and followee_id = '{b_id}') "
    f"   or (follower_id = '{b_id}' and followee_id = '{a_id}')"
)
check("팔로우가 열려 있는 중에 차단해도 엣지가 남지 않는다",
      remaining == "0", f"남은 엣지 {remaining}")

sql(f"delete from public.blocks where blocker_id = '{b_id}'")
sql(f"delete from public.follows where follower_id in ('{a_id}', '{b_id}')")

# --- 순서 2: 차단이 먼저 열리고 팔로우가 끼어든다 ------------------------------
code, _, err, _, _ = race(
    f"insert into public.blocks (blocker_id, blocked_id) "
    f"values ('{b_id}', '{a_id}')",
    f"insert into public.follows (follower_id, followee_id) "
    f"values ('{a_id}', '{b_id}')",
)
check("차단이 열려 있는 중에 건 팔로우는 거부된다",
      code != 0 and '지금은 팔로우할 수 없습니다' in err,
      err.splitlines()[0][:80] if err else f"code={code}")

_, remaining, _ = sql(
    f"select count(*) from public.follows "
    f"where follower_id = '{a_id}' and followee_id = '{b_id}'"
)
check("거부된 뒤에도 엣지가 남지 않는다", remaining == "0", f"남은 엣지 {remaining}")

# --- 가드가 정상 팔로우를 막지는 않는다 ----------------------------------------
sql(f"delete from public.blocks where blocker_id = '{b_id}'")
code, _, err = sql(
    f"insert into public.follows (follower_id, followee_id) "
    f"values ('{a_id}', '{b_id}')"
)
check("차단이 없으면 팔로우는 그대로 된다", code == 0, err[:80])

# --- 정리 ---------------------------------------------------------------------
sql(f"delete from public.follows where follower_id in ('{a_id}', '{b_id}')")
for uid in (a_id, b_id):
    req = urllib.request.Request(
        f"{BASE}/auth/v1/admin/users/{uid}", method="DELETE"
    )
    req.add_header("apikey", ANON)
    req.add_header("Authorization", f"Bearer {SERVICE}")
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError:
        pass

print()
failed = [r for r in results if not r[0]]
print(f"{len(results) - len(failed)}/{len(results)} 통과")
for _, name, detail in failed:
    print(f"  FAILED: {name} — {detail}")
raise SystemExit(1 if failed else 0)

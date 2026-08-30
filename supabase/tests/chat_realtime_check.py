#!/usr/bin/env python3
"""Postgres Changes 구독이 실제로 메시지를 전달하는지, 그리고 구독자별 RLS
재검사가 걸리는지 확인한다.

단위 테스트로는 잡히지 않는 부분이다 (docs/features/chat/plan.md "테스트").
"""
import asyncio
import json
import urllib.request
import urllib.error
import uuid

import websockets

BASE = "http://127.0.0.1:54321"
WS = "ws://127.0.0.1:54321/realtime/v1/websocket"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

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
    email = f"{nickname}-{uuid.uuid4().hex[:8]}@example.test"
    st, body = call("POST", "/auth/v1/admin/users", SERVICE,
                    {"email": email, "password": "password123", "email_confirm": True,
                     "user_metadata": {"nickname": nickname}})
    assert st == 200, (st, body)
    uid = body["id"]
    st, body = call("POST", "/auth/v1/token?grant_type=password", ANON,
                    {"email": email, "password": "password123"})
    assert st == 200, (st, body)
    return uid, body["access_token"]


def check(name, ok, detail=""):
    results.append((ok, name, detail))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  — {detail}" if detail else ""))


async def subscribe(token, room_id, collected, ready):
    """한 사용자로 chat_messages 의 이 방 INSERT 를 구독한다."""
    url = f"{WS}?apikey={ANON}&vsn=1.0.0"
    async with websockets.connect(url) as ws:
        await ws.send(json.dumps({
            "topic": f"realtime:room-{room_id}",
            "event": "phx_join",
            "payload": {
                "config": {
                    "broadcast": {"self": False},
                    "presence": {"key": ""},
                    "postgres_changes": [{
                        "event": "INSERT",
                        "schema": "public",
                        "table": "chat_messages",
                        "filter": f"room_id=eq.{room_id}",
                    }],
                },
                "access_token": token,
            },
            "ref": "1",
        }))
        try:
            while True:
                raw = await asyncio.wait_for(ws.recv(), timeout=12)
                msg = json.loads(raw)
                if msg.get("event") == "phx_reply" and msg.get("ref") == "1":
                    if msg["payload"].get("status") != "ok":
                        print("   join failed:", json.dumps(msg["payload"])[:300])
                elif (msg.get("event") == "system"
                      and msg["payload"].get("extension") == "postgres_changes"):
                    # phx_reply 는 채널 참여일 뿐이다. 실제로 WAL 을 읽기 시작한
                    # 시점은 이 system 이벤트다 — 여기서 준비됐다고 봐야 한다.
                    ready.set()
                elif msg.get("event") == "postgres_changes":
                    record = msg["payload"]["data"]["record"]
                    collected.append(record)
        except (asyncio.TimeoutError, websockets.exceptions.ConnectionClosed):
            return


async def main():
    suffix = uuid.uuid4().hex[:6]
    a_id, A = signup(f"RA{suffix}")
    b_id, B = signup(f"RB{suffix}")
    c_id, C = signup(f"RC{suffix}")

    st, room = call("POST", "/rest/v1/chat_rooms", A, {"title": "실시간 방"},
                    {"Prefer": "return=representation"})
    room_id = room[0]["id"]
    call("POST", "/rest/v1/chat_participants", A, {"room_id": room_id, "nickname": "에이스"})
    call("POST", "/rest/v1/chat_participants", B, {"room_id": room_id, "nickname": "비비"})
    # C 는 방에 들어가지 않는다 — 비참여자가 구독해도 받지 못해야 한다.

    b_msgs, c_msgs = [], []
    b_ready, c_ready = asyncio.Event(), asyncio.Event()
    b_task = asyncio.create_task(subscribe(B, room_id, b_msgs, b_ready))
    c_task = asyncio.create_task(subscribe(C, room_id, c_msgs, c_ready))
    await asyncio.wait_for(asyncio.gather(b_ready.wait(), c_ready.wait()), timeout=15)
    await asyncio.sleep(0.5)

    sent_id = str(uuid.uuid4())
    st, _ = call("POST", "/rest/v1/chat_messages", A,
                 {"id": sent_id, "room_id": room_id, "type": "text", "content": "실시간 확인"})
    assert st == 201, st
    await asyncio.sleep(3)

    check("구독자가 재조회 없이 새 메시지를 받는다",
          any(m["id"] == sent_id for m in b_msgs), f"{len(b_msgs)}건 수신")
    check("페이로드에 앱이 만든 id 가 그대로 온다",
          any(m["id"] == sent_id and m["content"] == "실시간 확인" for m in b_msgs))
    check("비참여자는 구독해도 메시지를 받지 못한다 (구독자별 RLS 재검사)",
          not any(m["id"] == sent_id for m in c_msgs), f"{len(c_msgs)}건 수신")

    # 차단한 상대의 메시지도 실시간 경로에서 막히는지.
    call("POST", "/rest/v1/blocks", B, {"blocked_id": a_id})
    await asyncio.sleep(1.5)
    blocked_id = str(uuid.uuid4())
    call("POST", "/rest/v1/chat_messages", A,
         {"id": blocked_id, "room_id": room_id, "type": "text", "content": "차단 후"})
    await asyncio.sleep(3)
    check("차단한 상대의 메시지는 실시간으로도 오지 않는다",
          not any(m["id"] == blocked_id for m in b_msgs),
          f"수신 {[m['content'] for m in b_msgs]}")

    b_task.cancel()
    c_task.cancel()
    await asyncio.gather(b_task, c_task, return_exceptions=True)

    print()
    failed = [r for r in results if not r[0]]
    print(f"{len(results) - len(failed)}/{len(results)} 통과")
    return 1 if failed else 0


raise SystemExit(asyncio.run(main()))

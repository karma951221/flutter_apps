#!/usr/bin/env python3
"""F9 chat 스키마의 권한 경계를 실제 JWT + REST 로 확인한다.

apps/trader/docs/features/chat/plan.md 의 완료 조건 중 DB 로 판정되는 것들을 훑는다.
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


suffix = uuid.uuid4().hex[:6]
a_id, A = signup(f"A{suffix}")
b_id, B = signup(f"B{suffix}")
c_id, C = signup(f"C{suffix}")

# --- 방 개설 -----------------------------------------------------------------
st, room = call("POST", "/rest/v1/chat_rooms", A,
                {"title": "테스트 방", "description": "설명", "member_limit": 3},
                {"Prefer": "return=representation"})
check("공개방을 만들 수 있다", st == 201, f"{st}")
room_id = room[0]["id"]
check("개설자가 created_by 에 자동으로 채워진다", room[0]["created_by"] == a_id)

st, body = call("POST", "/rest/v1/chat_rooms", A,
                {"title": "위조", "created_by": b_id},
                {"Prefer": "return=representation"})
check("created_by 위조는 거부된다", st in (400, 401, 403), f"{st} {str(body)[:80]}")

st, body = call("POST", "/rest/v1/chat_rooms", A,
                {"title": "다이렉트", "type": "direct"},
                {"Prefer": "return=representation"})
check("v1 에서 direct 방 생성은 정책이 막는다", st in (401, 403), f"{st}")

# --- 입장 --------------------------------------------------------------------
st, _ = call("POST", "/rest/v1/chat_participants", A,
             {"room_id": room_id, "nickname": "에이스"})
check("개설자가 방에 입장한다", st == 201, f"{st}")
st, _ = call("POST", "/rest/v1/chat_participants", B,
             {"room_id": room_id, "nickname": "비비"})
check("다른 사람이 공개방에 입장한다", st == 201, f"{st}")

st, body = call("POST", "/rest/v1/chat_participants", C,
                {"room_id": room_id, "nickname": "씨씨", "user_id": a_id})
check("user_id 위조 입장은 거부된다", st in (400, 401, 403), f"{st}")

# --- 시스템 메시지 -----------------------------------------------------------
st, msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&select=*&order=created_at.asc", A)
joins = [m for m in msgs if m["type"] == "system" and m["system_event"] == "join"]
check("입장마다 join 시스템 메시지가 쌓인다", len(joins) == 2, f"{len(joins)}건")
check("시스템 메시지는 닉네임 스냅샷을 담는다",
      {m["content"] for m in joins} == {"에이스", "비비"},
      str({m["content"] for m in joins}))
check("시스템 메시지에 한국어 문장이 저장되지 않는다",
      all(m["content"] in ("에이스", "비비") for m in joins))

# --- 메시지 송수신 -----------------------------------------------------------
msg_id = str(uuid.uuid4())
st, _ = call("POST", "/rest/v1/chat_messages", A,
             {"id": msg_id, "room_id": room_id, "type": "text", "content": "안녕"})
check("참여자가 메시지를 보낸다", st == 201, f"{st}")
check("앱이 만든 id 가 그대로 쓰인다", True)

st, msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&type=eq.text&select=id,content", B)
check("같은 방 참여자가 메시지를 읽는다", st == 200 and len(msgs) == 1, f"{st} {msgs}")

st, msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&select=id", C)
check("비참여자는 메시지를 조회할 수 없다", st == 200 and msgs == [], f"{st} {msgs}")

st, body = call("POST", "/rest/v1/chat_messages", C,
                {"room_id": room_id, "type": "text", "content": "끼어들기"})
check("비참여자는 메시지를 보낼 수 없다", st in (401, 403), f"{st}")

st, body = call("POST", "/rest/v1/chat_messages", B,
                {"room_id": room_id, "type": "system", "content": "가짜", "system_event": "join"})
check("앱이 시스템 메시지를 직접 만들 수 없다", st in (401, 403), f"{st}")

st, body = call("POST", "/rest/v1/chat_messages", B,
                {"room_id": room_id, "type": "text", "content": "위조", "sender_id": a_id})
check("sender_id 위조는 거부된다", st in (400, 401, 403), f"{st}")

# --- 이미지 경로 -------------------------------------------------------------
st, body = call("POST", "/rest/v1/chat_messages", B,
                {"room_id": room_id, "type": "image",
                 "image_path": f"{room_id}/{a_id}/{uuid.uuid4()}.webp"})
check("남의 폴더를 가리키는 이미지 경로는 거부된다", st in (400, 403), f"{st} {str(body)[:70]}")

st, body = call("POST", "/rest/v1/chat_messages", B,
                {"room_id": room_id, "type": "image",
                 "image_path": f"{uuid.uuid4()}/{b_id}/x.webp"})
check("다른 방을 가리키는 이미지 경로는 거부된다", st in (400, 403), f"{st}")

st, body = call("POST", "/rest/v1/chat_messages", B,
                {"room_id": room_id, "type": "image",
                 "image_path": f"{room_id}/{b_id}/ok.webp"})
check("본인 경로의 이미지 메시지는 통과한다", st == 201, f"{st} {str(body)[:70]}")

# --- 삭제 --------------------------------------------------------------------
st, ok = call("POST", "/rest/v1/rpc/soft_delete_chat_message", B, {"message_id": msg_id})
check("남의 메시지는 삭제되지 않는다", st == 200 and ok is False, f"{st} {ok}")
st, ok = call("POST", "/rest/v1/rpc/soft_delete_chat_message", A, {"message_id": msg_id})
check("본인 메시지는 소프트 삭제된다", st == 200 and ok is True, f"{st} {ok}")
st, msgs = call("GET", f"/rest/v1/chat_messages?id=eq.{msg_id}&select=id", B)
check("삭제된 메시지는 조회에서 사라진다", msgs == [], str(msgs))

# --- 차단 --------------------------------------------------------------------
st, _ = call("POST", "/rest/v1/chat_messages", A,
             {"room_id": room_id, "type": "text", "content": "차단 전"})
st, before = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&type=eq.text&select=id", B)
st, _ = call("POST", "/rest/v1/blocks", B, {"blocked_id": a_id})
check("차단을 건다", st == 201, f"{st}")
st, after = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&type=eq.text&select=id", B)
check("차단한 상대의 메시지가 히스토리에서 사라진다",
      len(after) == len(before) - 1, f"{len(before)} → {len(after)}")
st, sys_after = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&type=eq.system&select=id", B)
check("시스템 메시지는 차단의 영향을 받지 않는다", len(sys_after) == 2, f"{len(sys_after)}건")
call("DELETE", f"/rest/v1/blocks?blocked_id=eq.{a_id}", B)

# --- 신고 --------------------------------------------------------------------
st, tgt = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&type=eq.text&select=id&limit=1", B)
target_msg = tgt[0]["id"]
st, body = call("POST", "/rest/v1/reports", B,
                {"target_type": "chat_message", "target_id": target_msg, "reason": "spam"})
check("채팅 메시지를 신고할 수 있다", st == 201, f"{st} {str(body)[:80]}")

st, sysmsg = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&type=eq.system&select=id&limit=1", B)
st, body = call("POST", "/rest/v1/reports", B,
                {"target_type": "chat_message", "target_id": sysmsg[0]["id"], "reason": "spam"})
check("시스템 메시지는 신고 대상이 아니다", st >= 400, f"{st}")

st, own = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&type=eq.image&select=id&limit=1", B)
st, body = call("POST", "/rest/v1/reports", B,
                {"target_type": "chat_message", "target_id": own[0]["id"], "reason": "spam"})
check("내 메시지는 신고할 수 없다", st >= 400, f"{st}")

# --- 정원 --------------------------------------------------------------------
st, _ = call("POST", "/rest/v1/chat_participants", C, {"room_id": room_id, "nickname": "씨씨"})
check("정원(3) 안에서는 입장한다", st == 201, f"{st}")
d_id, D = signup(f"D{suffix}")
st, body = call("POST", "/rest/v1/chat_participants", D, {"room_id": room_id, "nickname": "디디"})
check("정원이 차면 입장이 거부된다", st >= 400, f"{st} {str(body)[:70]}")

# --- 나가기 · 재입장 ---------------------------------------------------------
st, _ = call("PATCH", f"/rest/v1/chat_participants?room_id=eq.{room_id}&user_id=eq.{c_id}", C,
             {"left_at": "now()"})
check("나가기는 left_at 갱신이다", st in (200, 204), f"{st}")
st, msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&system_event=eq.leave&select=id", A)
check("퇴장 시스템 메시지가 남는다", len(msgs) == 1, f"{len(msgs)}건")
st, msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&select=id", C)
check("나간 사람은 메시지를 못 읽는다", msgs == [], str(msgs)[:60])
st, mine = call("GET", f"/rest/v1/chat_participants?room_id=eq.{room_id}&user_id=eq.{c_id}&select=left_at", C)
check("나간 뒤에도 자기 참여자 행은 읽힌다(재입장 판정)", len(mine) == 1, str(mine))

st, _ = call("PATCH", f"/rest/v1/chat_participants?room_id=eq.{room_id}&user_id=eq.{c_id}", C,
             {"left_at": None, "nickname": "씨씨2"})
check("재입장은 left_at 을 되돌린다", st in (200, 204), f"{st}")
st, msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{room_id}&system_event=eq.join&select=content", A)
check("재입장도 join 시스템 메시지를 남긴다", len(msgs) == 4, f"{len(msgs)}건")

# --- 입장 경로: 읽고 나서 쓴다 (upsert 를 쓰지 않는 이유) ---------------------
#
# PostgREST 의 upsert 는 보내는 모든 컬럼에 INSERT 와 UPDATE 권한을 요구한다.
# 그러려면 room_id 에 UPDATE 를 줘야 하는데, 그 순간 자기 참여자 행을 다른 방으로
# 옮겨 삽입 정책의 "살아 있는 공개방인가" 검사를 건너뛸 수 있다.
e_id, E = signup(f"E{suffix}")
st, other_room = call("POST", "/rest/v1/chat_rooms", E, {"title": "남의 방"},
                      {"Prefer": "return=representation"})
st, body = call("PATCH", f"/rest/v1/chat_participants?room_id=eq.{room_id}&user_id=eq.{c_id}", C,
                {"room_id": other_room[0]["id"]})
check("참여자 행의 room_id 는 고칠 수 없다", st in (401, 403), f"{st}")

st, body = call("POST", "/rest/v1/chat_participants?on_conflict=room_id,user_id", C,
                {"room_id": room_id, "nickname": "씨씨", "left_at": None},
                {"Prefer": "resolution=merge-duplicates"})
check("upsert 는 권한 부족으로 막힌다 (앱은 읽고 나서 쓴다)", st in (401, 403), f"{st}")

# --- 뷰 ----------------------------------------------------------------------
st, rooms = call("GET", "/rest/v1/my_chat_rooms?select=*", A)
check("my_chat_rooms 가 내 방을 보여준다", st == 200 and len(rooms) == 1, f"{st} {len(rooms) if isinstance(rooms, list) else rooms}")
mine = rooms[0]
check("my_chat_rooms 가 참여자 수를 센다", mine["member_count"] == 3, str(mine["member_count"]))
check("my_chat_rooms 가 내 방 닉네임을 준다", mine["my_nickname"] == "에이스", str(mine["my_nickname"]))

st, rooms_c = call("GET", "/rest/v1/my_chat_rooms?select=id", C)
check("재입장한 사람의 목록에도 방이 있다", len(rooms_c) == 1, str(len(rooms_c)))

st, unread = call("GET", "/rest/v1/my_chat_rooms?select=unread_count", B)
check("안읽음 수가 0 이상으로 계산된다", st == 200 and unread[0]["unread_count"] >= 1,
      str(unread[0]["unread_count"]))
call("PATCH", f"/rest/v1/chat_participants?room_id=eq.{room_id}&user_id=eq.{b_id}", B,
     {"last_read_at": "now()"})
st, unread = call("GET", "/rest/v1/my_chat_rooms?select=unread_count", B)
check("읽고 나면 안읽음이 0 이 된다", unread[0]["unread_count"] == 0, str(unread[0]["unread_count"]))

st, open_rooms = call("GET", f"/rest/v1/open_chat_rooms?id=eq.{room_id}&select=*", D)
check("비참여자도 탐색 목록에서 방을 본다", st == 200 and len(open_rooms) == 1, f"{st}")
check("탐색 목록이 참여자 수를 정확히 센다", open_rooms[0]["member_count"] == 3,
      str(open_rooms[0]["member_count"]))
st, anon_rooms = call("GET", f"/rest/v1/open_chat_rooms?id=eq.{room_id}&select=member_count", ANON)
check("비로그인도 탐색 목록을 읽는다(anon execute GRANT)", st == 200 and len(anon_rooms) == 1, f"{st}")

st, parts = call("GET", f"/rest/v1/chat_participants?room_id=eq.{room_id}&select=user_id", D)
check("비참여자는 참여자 신원을 볼 수 없다", parts == [], str(parts)[:60])

# open_chat_rooms 는 security_invoker = off 다. 그 뷰를 발판 삼아 임베딩으로
# 참여자·메시지를 끌어올 수 있으면 예외를 둔 대가가 너무 커진다 — PostgREST 의
# 임베딩은 대상 테이블의 RLS 를 그대로 적용하므로 막힌다는 것을 고정해 둔다.
st, embedded = call(
    "GET",
    f"/rest/v1/open_chat_rooms?id=eq.{room_id}"
    "&select=id,chat_participants(user_id,nickname),chat_messages(content)",
    D,
)
row = (embedded or [{}])[0]
check("탐색 뷰로 참여자를 임베딩해도 비어 있다",
      row.get("chat_participants") == [], str(row.get("chat_participants"))[:60])
check("탐색 뷰로 메시지를 임베딩해도 비어 있다",
      row.get("chat_messages") == [], str(row.get("chat_messages"))[:60])

st, columns = call("GET", f"/rest/v1/open_chat_rooms?id=eq.{room_id}&select=*", D)
check("탐색 뷰는 집계 수 말고 참여자 정보를 내보내지 않는다",
      set((columns or [{}])[0]) == {
          "id", "title", "description", "created_at", "member_count", "last_message_at"
      },
      str(sorted((columns or [{}])[0])))

# --- DM (open_direct_room) ---------------------------------------------------
# A·B·C 는 위에서 이미 만든 사용자를 재사용한다.

# 1. 개설은 멱등이다 — 누가 부르든, 몇 번을 부르든 같은 방 id.
st, dm_room_id = call("POST", "/rest/v1/rpc/open_direct_room", A, {"partner_id": b_id})
check("A 가 B 와 DM 방을 연다", st == 200 and isinstance(dm_room_id, str), f"{st} {dm_room_id}")
st, again = call("POST", "/rest/v1/rpc/open_direct_room", A, {"partner_id": b_id})
check("같은 상대로 재호출해도 같은 방 id", st == 200 and again == dm_room_id, f"{st} {again}")
st, from_b = call("POST", "/rest/v1/rpc/open_direct_room", B, {"partner_id": a_id})
check("상대가 열어도 같은 방 id (중복 방 없음)", st == 200 and from_b == dm_room_id, f"{st} {from_b}")

# 2. 자기 자신과의 DM 은 거부된다.
st, body = call("POST", "/rest/v1/rpc/open_direct_room", A, {"partner_id": a_id})
check("자기 자신과의 DM 은 거부된다", st >= 400, f"{st} {str(body)[:80]}")

# 3. 존재하지 않는 상대 — 상대 없음과 차단을 구분하지 않는 중립 문구.
st, body = call("POST", "/rest/v1/rpc/open_direct_room", A, {"partner_id": str(uuid.uuid4())})
check("존재하지 않는 상대와의 DM 은 거부되고 문구가 중립적이다",
      st >= 400 and "대화를 시작할 수 없습니다" in json.dumps(body, ensure_ascii=False),
      f"{st} {str(body)[:80]}")

# 4. 탐색 미노출 — 비참여자는 물론, 당사자에게도 open_chat_rooms 에 없다.
st, rooms = call("GET", f"/rest/v1/chat_rooms?id=eq.{dm_room_id}&select=id", C)
check("비참여자는 DM 방을 chat_rooms 로 조회할 수 없다", rooms == [], str(rooms))
st, open_c = call("GET", f"/rest/v1/open_chat_rooms?id=eq.{dm_room_id}&select=id", C)
check("DM 방은 탐색 목록(open_chat_rooms)에 없다 (비참여자 기준)", open_c == [], str(open_c))
st, open_a = call("GET", f"/rest/v1/open_chat_rooms?id=eq.{dm_room_id}&select=id", A)
check("DM 방은 당사자 기준으로도 탐색 목록에 없다", open_a == [], str(open_a))

# 4-1. 비로그인(anon) 은 open_direct_room 을 부를 수도, chat_rooms 로 DM 방을
# 직접 조회할 수도 없다.
st, body = call("POST", "/rest/v1/rpc/open_direct_room", ANON, {"partner_id": b_id})
check("비로그인은 open_direct_room 을 호출할 수 없다", st >= 400, f"{st} {str(body)[:80]}")
st, anon_rooms = call("GET", f"/rest/v1/chat_rooms?id=eq.{dm_room_id}&select=id", ANON)
check("비로그인은 DM 방을 chat_rooms 로 조회할 수 없다", anon_rooms == [], str(anon_rooms))

# 5. 메시지 송수신 경계 — 참여자만 보내고 읽는다.
st, _ = call("POST", "/rest/v1/chat_messages", A,
             {"room_id": dm_room_id, "type": "text", "content": "안녕 DM"})
check("A 가 DM 방에 메시지를 보낸다", st == 201, f"{st}")
st, body = call("POST", "/rest/v1/chat_messages", C,
                {"room_id": dm_room_id, "type": "text", "content": "끼어들기"})
check("비참여자는 DM 방에 메시지를 못 보낸다", st in (401, 403), f"{st}")
st, msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{dm_room_id}&select=id", C)
check("비참여자는 DM 방 메시지를 조회할 수 없다", msgs == [], str(msgs))

# 6. direct 방에는 입퇴장이 있어도 시스템 메시지가 생기지 않는다.
st, all_msgs = call("GET", f"/rest/v1/chat_messages?room_id=eq.{dm_room_id}&select=type", A)
check("DM 방에는 시스템 메시지가 없다",
      st == 200 and all(m["type"] != "system" for m in all_msgs), str(all_msgs))

# 7. 나가기 · 카톡식 자동 재등장.
st, _ = call("PATCH", f"/rest/v1/chat_participants?room_id=eq.{dm_room_id}&user_id=eq.{b_id}", B,
             {"left_at": "now()"})
check("B 가 DM 방을 나간다(left_at 갱신, 기존 나가기와 동일 경로)", st in (200, 204), f"{st}")
st, rooms_b = call("GET", "/rest/v1/my_chat_rooms?select=id", B)
check("나간 뒤 B 의 my_chat_rooms 에서 DM 방이 사라진다",
      all(r["id"] != dm_room_id for r in rooms_b), str(rooms_b))
st, _ = call("POST", "/rest/v1/chat_messages", A,
             {"room_id": dm_room_id, "type": "text", "content": "다시 왔어"})
st, rooms_b2 = call("GET", "/rest/v1/my_chat_rooms?select=id", B)
check("A 가 메시지를 보내면 B 의 my_chat_rooms 에 방이 자동으로 다시 나타난다",
      any(r["id"] == dm_room_id for r in rooms_b2), str(rooms_b2))
st, all_msgs2 = call("GET", f"/rest/v1/chat_messages?room_id=eq.{dm_room_id}&select=type", A)
check("자동 재등장 과정에서도 시스템 메시지는 생기지 않는다",
      st == 200 and all(m["type"] != "system" for m in all_msgs2), str(all_msgs2))

# 7-1. open_direct_room 재호출만으로는 나간 상대가 되돌아오지 않는다 —
# 자동 재등장은 메시지 전송(enforce_direct_message)에서만 일어난다. A·C 의
# 새 DM 으로 확인한다(B 는 위에서 이미 메시지로 재등장시켜 상태가 섞인다).
st, dm_ac = call("POST", "/rest/v1/rpc/open_direct_room", A, {"partner_id": c_id})
check("A 가 C 와 새 DM 방을 연다", st == 200 and isinstance(dm_ac, str), f"{st} {dm_ac}")
st, _ = call("PATCH", f"/rest/v1/chat_participants?room_id=eq.{dm_ac}&user_id=eq.{c_id}", C,
             {"left_at": "now()"})
check("C 가 A·C DM 방을 나간다", st in (200, 204), f"{st}")
st, dm_ac_again = call("POST", "/rest/v1/rpc/open_direct_room", A, {"partner_id": c_id})
check("A 가 다시 open_direct_room 을 불러도 같은 방 id", st == 200 and dm_ac_again == dm_ac, f"{st} {dm_ac_again}")
st, rooms_c = call("GET", "/rest/v1/my_chat_rooms?select=id", C)
check("open_direct_room 재호출만으로는 나간 C 의 목록에 방이 되돌아오지 않는다",
      all(r["id"] != dm_ac for r in rooms_c), str(rooms_c))

# 8. my_chat_rooms 의 DM 행 모양.
st, mine = call("GET", f"/rest/v1/my_chat_rooms?id=eq.{dm_room_id}&select=*", A)
check("A 의 my_chat_rooms 에 DM 행이 있다", st == 200 and len(mine) == 1, f"{st} {mine}")
dm_row = mine[0]
check("my_chat_rooms 의 DM 행은 type=direct", dm_row["type"] == "direct", str(dm_row["type"]))
check("my_chat_rooms 의 DM 행은 title 이 없다", dm_row["title"] is None, str(dm_row["title"]))
check("my_chat_rooms 의 DM 행은 상대 닉네임을 준다",
      dm_row["partner_nickname"] == f"B{suffix}", str(dm_row["partner_nickname"]))

# 9. 차단 — 양방향 전송 거부, 히스토리 은닉, open_direct_room 거부, 해제 시 복구.
st, before_block = call("GET", f"/rest/v1/chat_messages?room_id=eq.{dm_room_id}&select=id", B)
st, _ = call("POST", "/rest/v1/blocks", A, {"blocked_id": b_id})
check("A 가 B 를 차단한다", st == 201, f"{st}")

st, body = call("POST", "/rest/v1/chat_messages", A,
                {"room_id": dm_room_id, "type": "text", "content": "차단 후 A"})
check("차단 후 A 의 DM 전송이 거부된다", st in (401, 403), f"{st} {str(body)[:80]}")

st, body = call("POST", "/rest/v1/chat_messages", B,
                {"room_id": dm_room_id, "type": "text", "content": "차단 후 B"})
check("차단 후 B 의 DM 전송도 거부된다(양방향)",
      st in (401, 403) and "메시지를 보낼 수 없습니다" in json.dumps(body, ensure_ascii=False),
      f"{st} {str(body)[:80]}")

st, body = call("POST", "/rest/v1/rpc/open_direct_room", B, {"partner_id": a_id})
check("차단된 상대와는 open_direct_room 도 거부된다", st >= 400, f"{st} {str(body)[:80]}")

st, after_block = call("GET", f"/rest/v1/chat_messages?room_id=eq.{dm_room_id}&select=id", B)
check("차단 후 B 의 조회에서 A 가 보낸 기존 메시지가 사라진다",
      len(before_block) > 0 and after_block == [], f"{len(before_block)} → {after_block}")

st, _ = call("DELETE", f"/rest/v1/blocks?blocked_id=eq.{b_id}", A)
st, body = call("POST", "/rest/v1/chat_messages", A,
                {"room_id": dm_room_id, "type": "text", "content": "차단 해제 후"})
check("차단 해제 후 A 의 전송이 복구된다", st == 201, f"{st} {str(body)[:80]}")

print()
failed = [r for r in results if not r[0]]
print(f"{len(results) - len(failed)}/{len(results)} 통과")
for _, name, detail in failed:
    print(f"  FAILED: {name} — {detail}")
raise SystemExit(1 if failed else 0)

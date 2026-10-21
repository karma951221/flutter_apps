// 대한민국 관공서 공휴일 2026 · 2027 (확인 2026-10-06).
//
// 기준: 「관공서의 공휴일에 관한 규정」(대통령령 제36290호, 2026. 4. 30. 개정 — 노동절 · 제헌절 공휴일,
// 둘 다 대체공휴일 대상) · 「공휴일에 관한 법률」(법률 제21543호).
// 출처:
// - 규정 https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=285779&efYd=20260511
// - 공휴일법 https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=283311&efYd=20260511
// - 2026년 월력요항(우주항공청, 관보 우주항공청공고 제2025-0044호)
//   https://www.kasi.re.kr/kor/publication/post/newsMaterial/32031
// - 2027년 월력요항(우주항공청, 관보 우주항공청공고 제2026-0078호)
//   https://www.kasa.go.kr/prog/plcyBrf/brief/kor/sub01_01_04/view.do?plcyBrfNo=431
// - 노동절 · 제헌절 공휴일(인사혁신처 2026-04-29)
//   https://mpm.go.kr/mpm/comm/newsPress/newsPressRelease/?boardId=bbs_0000000000000029&cntId=4250&mode=view
// - 제9회 전국동시지방선거 2026-06-03(중앙선거관리위원회)
//   https://www.nec.go.kr/site/nec/ex/bbs/View.do?cbIdx=1104&bcIdx=289351
// - 음력 날짜: 한국천문연구원 음양력 대조표 https://astro.kasi.re.kr/life/pageView/5
//
// 일요일은 따로 적지 않는다. 주말과 겹친 공휴일은 그대로 적는다(그날 울릴 알람도 알려 준다).
// 2027년에는 법정 선거일이 없다. 임시공휴일은 2026-10-06 기준 지정된 것이 없고, 새로 지정되면
// 폰 캘린더가 먼저 따라가거나 앱 업데이트로 고친다.

import 'holiday_calendar.dart';

/// 날짜(`yyyymmdd`) → 공휴일 이름.
const koreanHolidays = <int, String>{
  // 2026
  20260101: '신정',
  20260216: '설날 전날',
  20260217: '설날',
  20260218: '설날 다음 날',
  20260301: '삼일절',
  20260302: '삼일절 대체공휴일',
  20260501: '노동절',
  20260505: '어린이날',
  20260524: '부처님 오신 날',
  20260525: '부처님 오신 날 대체공휴일',
  20260603: '지방선거',
  20260606: '현충일',
  20260717: '제헌절',
  20260815: '광복절',
  20260817: '광복절 대체공휴일',
  20260924: '추석 전날',
  20260925: '추석',
  20260926: '추석 다음 날',
  20261003: '개천절',
  20261005: '개천절 대체공휴일',
  20261009: '한글날',
  20261225: '성탄절',
  // 2027
  20270101: '신정',
  20270206: '설날 전날',
  20270207: '설날',
  20270208: '설날 다음 날',
  20270209: '설날 대체공휴일',
  20270301: '삼일절',
  20270501: '노동절',
  20270503: '노동절 대체공휴일',
  20270505: '어린이날',
  20270513: '부처님 오신 날',
  20270606: '현충일',
  20270717: '제헌절',
  20270719: '제헌절 대체공휴일',
  20270815: '광복절',
  20270816: '광복절 대체공휴일',
  20270914: '추석 전날',
  20270915: '추석',
  20270916: '추석 다음 날',
  20271003: '개천절',
  20271004: '개천절 대체공휴일',
  20271009: '한글날',
  20271011: '한글날 대체공휴일',
  20271225: '성탄절',
  20271227: '성탄절 대체공휴일',
};

/// [koreanHolidays] 로 답하는 [HolidayCalendar]. 폰 캘린더가 없을 때의 바닥선.
class KoreanHolidayCalendar implements HolidayCalendar {
  const KoreanHolidayCalendar();

  static const firstYear = 2026;
  static const lastYear = 2027;

  @override
  String? nameOf(DateTime date) =>
      koreanHolidays[date.year * 10000 + date.month * 100 + date.day];

  @override
  HolidaySource get source =>
      const HolidaySource.bundled(firstYear: firstYear, lastYear: lastYear);
}

/// Health Connect 를 읽을 수 있는가. 실패가 아니라 정상 분기라 `FailureCode` 로 만들지 않는다.
enum HealthAccess { notInstalled, updateRequired, permissionDenied, granted }

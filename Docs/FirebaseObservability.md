# Firebase 관측성

CCRecorder는 Firebase Crashlytics와 Google Analytics의 기본 관측성만 사용한다.

## 적용 범위

- Firebase Apple SDK `13.1.1`
- `FirebaseCrashlytics`, `FirebaseAnalyticsCore`
- Firebase 초기화와 Analytics·CrashReporting 서비스 경계
- Debug·Release dSYM 생성과 Crashlytics 심볼 업로드

커스텀 Analytics 이벤트·사용자 속성, Crashlytics 커스텀 키·로그·사용자 ID, Remote Config와 Performance Monitoring은 사용하지 않는다.

## 수집 정책

Analytics와 Crashlytics의 자동 수집은 기본 비활성화하고 앱 시작 시 실행 환경에 맞게 적용한다.

| 환경 | Analytics | Crashlytics |
| --- | --- | --- |
| Xcode Debug | `-FIRDebugEnabled` 사용 시에만 활성화 | 자동 수집 비활성화, `-FIRDebugEnabled` 사용 시 대기 보고서 전송 |
| TestFlight | 비활성화 | 활성화 |
| App Store | 활성화 | 활성화 |
| 환경 확인 실패·Ad Hoc | 비활성화 | Release 빌드에서 활성화 |

Release 환경은 검증된 StoreKit `AppTransaction`으로 구분한다. `.production`은 App Store, `.sandbox`는 TestFlight, `.xcode`는 StoreKit Testing으로 판단한다.

Tuist App 스킴에는 `-FIRDebugEnabled`와 `-FIRDebugDisabled`를 체크 해제 상태로 생성한다. TestFlight와 App Store의 Crashlytics 보고서를 구분할 수 있도록 빌드 번호를 다르게 관리한다.

## 개인정보 원칙

- 녹음 오디오·내용, 파일명·경로, 대화 제목·노트, 이름·전화번호·이메일을 Firebase로 전송하지 않는다.
- Analytics는 IDFA가 없는 `FirebaseAnalyticsCore`를 사용하고 광고 개인화 신호를 비활성화한다.
- Firebase 설정 파일과 클라이언트 API 키는 앱 식별 정보로 저장소에 포함하되, Google Cloud에서 Bundle ID와 허용 API를 제한한다.
- 서비스 계정, Admin SDK 자격증명과 인증서 개인 키는 앱과 저장소에 포함하지 않는다.

## 빌드와 출시

- Debug와 Release 모두 `DWARF with dSYM File`을 생성한다.
- 앱 타깃의 마지막 build phase에서 Firebase 공식 스크립트로 dSYM을 업로드한다.
- App Store Connect에는 대략적인 위치, 기기 ID, 제품 상호 작용, 충돌 데이터와 기타 진단 데이터를 공개한다.
- 외부 개인정보처리방침에는 Google Analytics for Firebase와 Firebase Crashlytics의 수집 항목, 목적, 보유 기간과 국외 이전을 명시한다.

## 참고

- [Firebase Apple SDK 설정](https://firebase.google.com/docs/ios/setup)
- [Firebase API 키 관리](https://firebase.google.com/docs/projects/api-keys)
- [Crashlytics Apple 플랫폼 시작](https://firebase.google.com/docs/crashlytics/ios/get-started)
- [Firebase의 App Store 데이터 공개 안내](https://firebase.google.com/docs/ios/app-store-data-collection)

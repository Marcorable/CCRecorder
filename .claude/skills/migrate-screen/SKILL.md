---
name: migrate-screen
description: 레거시 폴더의 화면을 레이어 모듈(Presentation)로 옮기고 Screen 패턴을 적용한다. "화면 모듈 이동", "MVVMC 적용", "Screen 패턴으로 바꿔줘" 같은 요청에 사용.
---

# 레거시 화면 마이그레이션

Partners #473 #476 #478 #480 에서 반복한 흐름이다. **커밋을 단계별로 나눈다** — 이동과 구조 변경을 한 커밋에 섞지 않는다.

먼저 `agent-common/marcorable-swift/rules/architecture/screen-pattern.md` 와 `section-subview.md` 를 읽는다.

## 0. 범위 확인

- 대상 화면, 이 화면이 의존하는 Usecase, 화면 진입 경로를 찾는다
- 옮길 위치와 화면 등록 위치를 이미 옮긴 화면에서 확인한다
- 같이 쓰이는 하위 컴포넌트 중 다른 화면과 중복된 것이 있는지 본다
- 계획을 사용자에게 보여주고 진행한다

## 1. 모듈 이동 — 커밋: `refactor: <화면명> 화면 모듈 이동`

동작을 바꾸지 않고 위치만 옮긴다.

1. 레거시 폴더의 `<Usecase>/<Name>/` 를 레이어 모듈의 같은 구조로 `git mv`
2. 모듈이 바뀌어 생긴 import 를 정리한다
3. 새 위치에서 아직 쓸 수 없는 의존성은 임시 코드로 바꾼다 (아래 "임시 코드")
4. 화면을 등록한다 (아래 "화면 등록")
5. 빌드

### 임시 코드

최종 코드는 주석으로 남기고, 임시 코드 줄 끝에 `// 임시` 와 바꿀 형태를 적는다.

```swift
//    @Environment(MainNavigationStackModel.self) private var mainStack
@Environment(\.popAction) private var popAction // 임시
...
popAction(1) // 임시 -> mainStack.pop()
```

### 화면 등록

등록 위치는 이미 옮긴 화면을 따라간다. 보통 네 곳이다.

1. 화면 목록 enum — case 를 추가하고 줄 끝에 한글 화면명 주석을 단다. 주석 열을 맞춘다
2. 화면 key — 문자열 key 를 추가한다. AOS 와 맞춘 key 에는 `/// AOS confirmed` 를 붙인다
3. 화면 팩토리 — 의존성을 DI 컨테이너에서 `resolve` 로 꺼내 조립한다
4. 레거시 진입점이 남아 있으면 새 화면 팩토리로 위임한다

```swift
case login                                  // 로그인 화면
case notification                           // 알림 화면

case .notification:     "notification"      /// AOS confirmed
```

## 2. 구조 개선 — 커밋: `refactor: <화면명> 화면 MVVMC 적용` / `구조 정리`

1. `<Name>View` + `ViewModel` 을 `<Name>Screen`(네임스페이스) / `.Model` / `.ViewModel` / `.Context` (UIKit 이면 `.ViewController` 도) 로 나눈다
2. 뷰에 있던 로직(`Task { await viewModel.x() }`)을 `Intent` case 로 바꾸고 `viewModel.reduce(by:)` 로 보낸다. 서버 호출과 에러 변환은 `Model` 로 옮긴다
3. 화면 전용 enum 이 Domain 개념이면 Domain 레이어의 Entity 로 옮기고, 문구는 Presentation 레이어의 extension 에 둔다
4. 프리뷰 추가 (`agent-common/marcorable-swift/rules/architecture/preview.md`)
5. 빌드

## 3. 중복 정리 (필요할 때) — 커밋: `refactor: <컴포넌트> 중복 컴포넌트 구성`

두 화면 이상에서 같은 모양이 보이면 공용 컴포넌트로 뺀다 (예: `BottomButtonSection`, `TextFieldSection`).

## 4. 마무리

- `Localized Key` 대상 문자열이 있으면 별도 `chore` 커밋
- 남은 `// 임시` 주석 목록을 PR 설명에 적는다
- 각 커밋은 `/commit` 스킬로 만든다

## 하지 않는 것

- 이동 커밋에서 로직 수정
- 이번 화면과 상관없는 레거시 화면 정리
- 스킴·타겟 이름 변경

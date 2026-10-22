---
name: new-section
description: 화면에 들어갈 섹션 서브뷰(View + 중첩 ViewModel + Model + Preview)를 Marco 의 패턴으로 한 파일에 생성한다. "섹션 추가", "서브뷰 만들어줘", "영역 분리" 요청에 사용.
---

# 섹션 서브뷰 생성

`agent-common/marcorable-swift/rules/architecture/section-subview.md` 의 구조를 따른다.

## 1. 입력 확인

다음이 정해지지 않았으면 묻는다.

- 부모 타입 — `MartInfoScreen`, `BarcodeRegisterScreen` 등
- 섹션 이름 — `BusinessInfoSection`, `Board` 등
- 표시할 필드 — 디자인(Figma) 또는 Entity 에서
- 디자인시스템 모듈 — 이미 쓰는 화면의 import 를 따른다
- 원본 데이터 필드 — Optional 과 원본 값 타입을 변형하지 않고 확인한다
- 화면 단위 상태 또는 Intent 사용 여부 — 필요하면 `Screen.ViewModel`을 Environment 로 사용한다
- 하위 View 가 독립적인 변경 상태를 소유하는지 — 없으면 값 타입 ViewModel 을 만든다

## 2. 파일 생성

입력 데이터가 없는 정적 View 면 Model/ViewModel 없이 View 만 만든다. 아래 템플릿의 Model · ViewModel extension 은 생략한다.

위치: `<부모 화면 폴더>/<섹션>/` — 섹션 이름의 폴더를 만든다. `Subview/` 폴더는 두지 않는다.
파일: `<부모>.<섹션>.swift`, 파일 헤더 없음.

```swift
import SwiftUI

extension <Parent> {

    struct <Section>: View {
        let viewModel: ViewModel

        var body: some View {
            // 프로젝트 디자인시스템 컴포넌트 사용
        }
    }

}

extension <Parent>.<Section> {

    struct Model {
        // 원본 값을 변형하지 않고 보관
    }

    struct ViewModel {
        let model: Model
    }

}

extension <Parent>.<Section>.ViewModel {

    // 포맷, Optional 기본값, 파생 상태와 액션 결과

}

#Preview {
    Color.black.overlay {
        <Parent>.<Section>(
            viewModel: .init(
                model: .init(
                    // 실제와 비슷한 샘플 값
                )
            )
        )
        .background(.white)
    }
}
```

## 3. 부모 연결

- 불변 `struct` 하위 ViewModel 은 부모 Screen.ViewModel 에 `<section>: <Section>.ViewModel` 연산 프로퍼티로 추가한다
- 독립적인 변경 상태가 있는 `@MainActor @Observable final class` 하위 ViewModel 은 부모의 저장 프로퍼티로 한 번 생성한다. 연산 프로퍼티에서 새 인스턴스를 반환하지 않는다
- 이름이 길면 `typealias <Section>ViewModel = <Parent>.<Section>.ViewModel`
- 값 타입은 연산 프로퍼티에서 원본 데이터 → 하위 `Model` → 하위 `ViewModel` 순서로 조립한다
- 부모 레이아웃에 섹션 배치

화면 전용 Intent 는 클로저로 전달하지 않고 하위 View 에서 Environment 의 Screen.ViewModel 로 보낸다. 표시 데이터는 Environment 에서 찾지 않고 하위 ViewModel 로 받는다.
Environment 를 사용하는 하위 View 의 `#Preview` 에는 `.environment(<Parent>.ViewModel.mock)`을 붙인다.

## 4. 확인

- 원본 Optional 의 기본 표시가 하위 ViewModel 에 있는지 확인한다
- 데이터·액션에 따라 바뀌는 값은 ViewModel, 고정 문구와 컴포넌트 구성은 View 에 있는지 확인한다
- 입력 데이터가 전혀 없는 정적 View 에 빈 Model/ViewModel 을 만들지 않았는지 확인한다
- 상태를 가진 참조 타입 ViewModel 을 연산 프로퍼티에서 재생성하지 않는지 확인한다
- Environment 를 사용하는 프리뷰에 부모 ViewModel 을 주입했는지 확인한다
- 빌드

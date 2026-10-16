---
name: new-section
description: 화면에 들어갈 섹션 서브뷰(View + 중첩 ViewModel + Model + Preview)를 Marco 의 패턴으로 한 파일에 생성한다. "섹션 추가", "서브뷰 만들어줘", "영역 분리" 요청에 사용.
---

# 섹션 서브뷰 생성

`.claude/rules/marcorable-swift/architecture/section-subview.md` 의 구조를 따른다.

## 1. 입력 확인

다음이 정해지지 않았으면 묻는다.

- 부모 타입 — `MartInfoView`, `BarcodeRegisterScreen` 등
- 섹션 이름 — `BusinessInfoSection`, `Board` 등
- 표시할 필드 — 디자인(Figma) 또는 Entity 에서
- 디자인시스템 모듈 — 이미 쓰는 화면의 import 를 따른다
- ViewModel 전달 방식 — `let viewModel` 주입 / `@Environment(ViewModel.self)`

## 2. 파일 생성

위치: `<부모 폴더>/Subview/` (섹션이 여럿이면 `Subview/Section/`)
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

    @Observable
    @MainActor
    final class ViewModel {
        var model: Model?

        init(model: Model? = nil) {
            self.model = model
        }
    }

    struct Model {
        // 표시에 필요한 필드만
    }

}

extension <Parent>.<Section>.ViewModel {

    // 값 표시는 `model?.x ?? ""`, 문구가 갈리면 case 만 돌려준다

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

- 부모 Model/ViewModel 에 `let <section>ViewModel: <Section>.ViewModel = .init()` 추가
- 이름이 길면 `typealias <Section>ViewModel = <Parent>.<Section>.ViewModel`
- 데이터를 받는 곳에서 Entity → `Model` 변환해 대입
- 부모 레이아웃에 섹션 배치

## 4. 확인

- 프리뷰가 `model == nil` 일 때도 깨지지 않는지 본다
- 빌드

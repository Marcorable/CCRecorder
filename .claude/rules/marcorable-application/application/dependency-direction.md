---
paths:
  - "**/Domain/**/*.swift"
  - "**/Data/**/*.swift"
  - "**/Presentation/**/*.swift"
  - "**/UserInterface/**/*.swift"
  - "**/*App.swift"
  - "**/Project.swift"
---

# 애플리케이션 의존 방향

업무 규칙을 외부 기술보다 안쪽에 두고, 구체 구현은 앱의 Composition Root에서 연결한다.

```text
App(Composition Root) ──▶ Presentation ──▶ Domain
          │                                  ▲
          └────────────────▶ Data ───────────┘
```

- Domain은 Presentation, Data, UI·저장 프레임워크와 네트워크 라이브러리를 알지 않는다
- Presentation은 Domain이 공개한 모델과 동작을 사용한다
- Data는 Domain이 정의한 경계를 구현한다
- App은 구현과 실행 환경을 조립하지만 업무 규칙을 소유하지 않는다
- 레이어를 별도 모듈로 만들지는 규모, 교체 가능성, 빌드 경계에 따라 결정한다

기존 프로젝트의 폴더 이름은 존중한다. 이름보다 실제 의존 방향과 책임을 기준으로 판단한다.

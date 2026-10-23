---
paths:
  - "**/*.swift"
---

# 모듈 배치

**새 코드는 레이어 모듈에 쓴다.** 레거시 폴더에는 새 타입을 만들지 않는다.
레거시 화면을 고칠 때는 화면 파일은 그대로 두고, 그 화면이 쓸 Usecase 를 새 레이어에 만들어 주입한다.

## 어디에 두나

| 무엇 | 레이어 |
|---|---|
| API 엔드포인트 | API 모듈 — 엔드포인트 하나당 파일 하나 |
| Repository 프로토콜 | Domain (DataInterface) |
| Repository 구현 | Data — `<Name>RepositoryConcrete` |
| Usecase | Domain — 프로토콜과 Concrete 를 파일 두 개로 |
| Entity | Domain |
| 공용 UI · Manager | Presentation — 화면·컴포넌트 폴더 원칙은 `agent-common/marcorable-swiftui/rules/swiftui/ui-layout.md` |

## 등록

새 API 부터 화면 주입까지 이어지면 각 레이어의 등록 위치(API 목록, DI 컨테이너, 화면 팩토리)를 함께 고친다.
등록 위치는 프로젝트마다 다르다. 같은 종류의 기존 타입이 등록된 곳을 찾아 따른다.

## 레이어 모듈이 없는 앱

모듈을 나누지 않은 단일 타깃 앱은 화면 밖 타입을 `Model/` 아래에 성격별로 둔다. 화면·컴포넌트 폴더는 `agent-common/marcorable-swiftui/rules/swiftui/ui-layout.md`의 단일 타깃 예시를 따른다.

```
Model/
├── Entity/     # 저장소·서버에서 온 데이터 (SwiftData @Model, DTO 를 옮긴 값) — Domain Entity
└── Enum/       # 여러 화면이 함께 쓰는 열거형 — 사용자 설정값, 저장 키
```

- 한 화면에서만 쓰는 열거형은 `Model/Enum/`에 두지 않고 그 화면에 중첩한다 (`agent-common/marcorable-swiftui/rules/swiftui/ui-layout.md`)
- `Types/` 처럼 성격이 드러나지 않는 폴더 이름은 쓰지 않는다

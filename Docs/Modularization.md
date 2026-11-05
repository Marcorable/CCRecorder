# Modularization

v2 앱은 Tuist가 생성하는 단일 App 프로젝트 안에서 Clean Architecture의 레이어를 동적 프레임워크 타깃으로 구분한다.

## 생성과 검증

```sh
tuist generate
xcodebuild -workspace CCRecorder.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
```

생성되는 workspace와 project, `Derived/` 소스는 커밋하지 않는다.

## Xcode Cloud

Xcode Cloud는 저장소 루트의 `ci_scripts/ci_post_clone.sh`에서 `.mise.toml`에 고정된 Tuist를 설치하고 `tuist generate --no-open`을 실행한다. Cloud 워크플로의 프로젝트 또는 workspace는 `CCRecorder.xcworkspace`, 스킴은 `App`을 사용한다.

## 프로젝트 구조

```text
Project/
└── App/
    ├── Project.swift
    ├── App/
    │   ├── Sources/
    │   └── Resources/
    ├── Presentation/
    │   └── Sources/
    ├── Domain/
    │   └── Sources/
    ├── Data/
    │   └── Sources/
    └── Tests/
        ├── Plans/
        ├── Unit/
        └── UI/
```

`App`은 Debug나 Release 같은 빌드 설정명이 아니라, 실행·배포되는 앱과 그 조립 지점을 뜻한다. 추후 앱 확장이 생기면 `Project/App/Extensions/Widget`, `Project/App/Extensions/Share`처럼 같은 출시 앱의 구성 요소로 둔다.

## 의존 방향

```text
App ───────────▶ Presentation
 │                    │
 ├─────────────▶ Data │
 │                │   │
 └─────────────▶ Domain ◀──┘
```

- `App`: 앱 실행 타깃과 실제 구현 조립
- `Presentation`: SwiftUI, TCA Feature, 화면 표시 모델
- `Domain`: Entity, Usecase, Repository 계약
- `Data`: SwiftData 모델, Repository 구현, 파일 저장 구현

`Presentation`과 `Data`는 서로 의존하지 않고 모두 `Domain`을 바라본다. `Domain`은 다른 앱 레이어에 의존하지 않는다.

## 현재 범위

현재는 `App.xcodeproj` 안에 `Presentation`, `Domain`, `Data`의 동적 프레임워크 타깃과 의존 방향만 준비한다. 기존 App 코드는 기능 단위 리팩터링이 필요한 시점에 각 레이어로 옮기며, 구조를 만들기 위해 미리 잘게 분리하지 않는다.

각 타깃의 소스와 리소스는 Tuist의 `buildableFolders`로 선언한다. 따라서 `tuist generate` 후 Xcode에는 전통적인 Group이 아니라 파일시스템과 동기화되는 Folder로 표시된다.

이관이 끝나기 전까지 App은 기존 코드와 새 레이어 구현을 함께 조립하는 전환 지점 역할을 한다.

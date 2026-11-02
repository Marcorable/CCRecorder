
# 로컬 SwiftPM 패키지

새로 만드는 단일 타깃 로컬 패키지는 `Sources/<타깃명>/`, `Tests/<테스트 타깃명>/`처럼 이름만 반복하는 중첩을 줄인다.

```swift
.target(
    name: "SharedKit",
    path: "Sources"
),
.testTarget(
    name: "SharedKitTests",
    dependencies: ["SharedKit"],
    path: "Tests"
)
```

```text
SharedKit/
├── Package.swift
├── Sources/
└── Tests/
```

- 여러 타깃이 같은 패키지에 있으면 SwiftPM의 타깃별 디렉터리로 구분한다
- 기존 패키지의 폴더 구조를 이 규칙만으로 재배치하지 않는다
- 생성 도구가 경로를 관리하면 도구의 정본을 따른다

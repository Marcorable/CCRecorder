---
paths:
  - "**/*Service*.swift"
  - "**/*Client*.swift"
---

# 프레임워크 기반 Service의 Source of Truth

AVFoundation처럼 상태를 가진 프레임워크 객체를 감싼 Service는 프레임워크 객체를 정본으로 삼는다. 같은 값을 Service 저장 프로퍼티에 복제하지 않는다.

- `currentTime`, `duration`, `rate`, 준비 여부처럼 실제 객체에서 즉시 알 수 있는 값은 computed property나 조회 메서드로 제공한다
- 외부에서 값이 필요할 때마다 정본을 조회할 수 있다면 바인딩을 위해 별도 상태를 만들지 않는다
- ticker는 시간 값을 저장하는 상태가 아니라 정본을 주기적으로 읽어 전달하는 생명주기다
- `isPrepared`처럼 객체의 존재 여부로 표현 가능한 상태는 객체에서 파생한다
- `Phase`, `State`, `pausedTime`은 화면 표현이나 프레임워크가 제공하지 않는 업무 전환을 보존할 때만 저장한다
- 프레임워크 콜백 사이에서만 알 수 있는 누적값처럼 다시 계산할 수 없는 값은 저장할 수 있다

```swift
var currentTime: TimeInterval {
    player?.currentTime ?? 0
}

var isPrepared: Bool {
    player != nil
}
```

## 외부 계약

- 공개 계약에는 AVFoundation 같은 프레임워크 타입을 노출하지 않는다
- 호출자가 처리해야 하는 실패는 concrete 구현의 비공개 `ServiceError`에 숨기지 않고 Domain의 공개 오류 계약으로 표현한다
- delegate 객체가 프레임워크 콜백의 수명과 동시성 경계를 담당해야 하면 concrete Service와 분리한 private bridge로 둔다
- `@unchecked Sendable`은 bridge가 캡처하는 값과 콜백의 안전성을 직접 보장할 수 있을 때만 좁은 범위에 적용한다

상태를 추가하기 전에는 “정본에서 다시 읽을 수 있는가”, “화면이나 업무 전환이 이 값을 독립적으로 사용하는가”를 먼저 확인한다.

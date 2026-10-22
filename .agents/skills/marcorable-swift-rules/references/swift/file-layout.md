
# 파일 구성

## 첫 줄은 비운다

파일의 **첫 줄은 빈 줄**로 두고 둘째 줄부터 쓴다. 파일 헤더 주석은 넣지 않는다 (`agent-common/marcorable-swift/rules/comment/file-header.md`).

## import 그룹

import 는 세 그룹으로 나누고 그룹 사이에 빈 줄을 하나 둔다. import 가 끝나면 빈 줄 하나 뒤에 코드를 쓴다.

1. Apple SDK — `Foundation`, `SwiftUI`, `UIKit`, `Combine`, `Observation`, `XCTest` 등
2. 서드파티 · 로컬 패키지
3. `@testable import`

그룹 안에서는 **이름이 짧은 순서**로, 길이가 같으면 알파벳순으로 쓴다.

```swift

import UIKit
import Combine
import SwiftUI
import Foundation

import SharedKit
import CommonScene

@testable import SwiftUIObservable

final class SearchScreenModelTests: XCTestCase {
```

import 가 없으면 첫 빈 줄 다음에 바로 코드를 쓴다.

## 파일 하나에 주 타입 하나

파일 하나에는 주 타입 하나를 둔다. 그 타입의 extension 과 중첩 타입은 같은 파일에 둘 수 있다.

## 예외

`Package.swift` 는 `// swift-tools-version:` 이 반드시 첫 줄이어야 하므로 이 룰에서 뺀다.

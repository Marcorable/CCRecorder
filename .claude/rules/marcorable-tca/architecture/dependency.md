---
paths:
  - "**/*.swift"
---

# TCA Dependency

Feature는 화면 상태와 사용자 시나리오의 정책을 결정하고, Dependency는 재사용 가능한 기본 동작을 수행한다.

- 화면 밖에서도 의미가 있는 동작은 Screen에 중첩하지 않는다
- 행동 단위 이름은 `<동사><목적어>Usecase`를 기본으로 하되 앱의 핵심 행위는 `RecordUsecase`처럼 간결하게 쓸 수 있다
- Usecase의 live 구현은 Service 또는 Repository를 주입받는다
- Feature는 입력 정규화, 표시 상태, Alert, navigation 같은 화면 시나리오를 결정한다
- Usecase는 녹음 완료, 저장 같은 기본 동작과 실패 시 자원 정리 등 동작의 원자성을 책임진다
- closure 기반 client의 interface와 endpoint 기본값은 `@DependencyClient`로 선언할 수 있다
- client type은 `TestDependencyKey`를 채택해 test·preview 값을 제공하고, 자체 live 값도 제공한다면 `DependencyKey`를 채택한다. live 구현을 앱 진입점에서 주입하는 구조라면 `TestDependencyKey`만 채택할 수 있다
- client를 `DependencyValues`에 노출하고 Feature에서는 `@Dependency`로 사용한다

Usecase는 화면 이름이 아니라 수행하는 동작으로 이름 짓는다. 화면에서 정한 기본 문구나 입력 보정 정책을 Usecase에서 다시 결정하지 않는다.

## 하위 Feature 의존성

`Scope`, `ifLet`, `forEach`로 조합한 하위 Feature는 부모 Store가 생성될 때 캡처한 Dependency를 상속한다.

- View에서 scoped Store를 꺼내는 시점에는 Reducer Dependency를 새로 주입할 수 없다
- 하위 Feature가 쓰는 live Dependency는 그 Feature를 조합한 조상 Store의 생성 지점에 등록한다
- 화면을 닫을 때 실제 객체도 해제해야 한다면 부모 Store에 객체를 직접 주입하지 않는다. 지연 생성 Client 또는 독립 Store 경계를 선택한다
- Dependency 등록 위치와 실제 객체 수명은 별개다. closure Client가 객체를 캡처하면 Client를 가진 Store만큼 객체가 유지된다

화면 단위 수명이 요구되는데 TCA 상태 트리를 유지할지, 독립 Store로 끊을지는 구현 전에 사용자와 결정한다.

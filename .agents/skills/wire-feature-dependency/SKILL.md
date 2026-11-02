---
name: wire-feature-dependency
description: 이미 구현된 Usecase·Repository·Service를 앱의 Composition Root와 소비 지점에 연결한다. DI 등록, Factory 연결, Preview·테스트 대체 구현 연결 요청에 사용한다. 의존 대상 자체를 새로 구현하는 요청에는 사용하지 않는다.
---

# 기능 의존성 조립

먼저 `../../rules/application/composition-root.md`를 읽는다.

## 입력

- 연결할 계약과 구체 구현
- 런타임 소비 지점
- Preview와 테스트에서 사용할 대체 구현

## 수행

1. 기존 Composition Root, Factory와 같은 종류의 등록 사례를 찾는다.
2. 구체 인프라의 생성 시점과 수명을 결정한다.
3. 소비 지점에는 가능한 한 계약만 전달한다.
4. 런타임, Preview와 테스트 구성을 각각 연결한다.
5. 실제 소비 경로에서 누락된 의존성이 없는지 실행해 확인한다.

## 제외

- 새 DI 프레임워크를 도입하지 않는다.
- 화면 상태가 Container나 Client의 수명을 소유하게 하지 않는다.
- 계약과 구체 구현의 내부 동작을 함께 바꾸지 않는다.

## 결과와 검증

- 앱 실행 시 구현이 한 조립 지점에서 생성되고 소비 지점까지 전달된다.
- Preview와 테스트가 live 인프라 없이 같은 계약을 사용할 수 있다.

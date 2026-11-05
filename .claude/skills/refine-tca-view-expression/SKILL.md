---
name: refine-tca-view-expression
description: 기존 SwiftUI·TCA 표현 계층을 전반적으로 정리할 때 상태와 리소스 경계, 중복 View 분기, 컴포넌트 입력을 진단하고 필요한 원자 스킬만 조합한다. 둘 이상의 경계를 함께 다루는 리팩터링에 사용한다. 단일 문제, 새 화면 구현, Child Feature 추출과 Domain 변경에는 사용하지 않는다.
---

# TCA·SwiftUI 표현 경계 조합

이 스킬은 `marcorable-tca`와 `marcorable-swiftui` 팩이 함께 설치된 프로젝트에서만 사용한다.

## 원자 스킬

- 상태 조건과 UI 리소스가 섞였으면 `agent-common/marcorable-tca/skills/separate-tca-view-resources/SKILL.md`
- 같은 View 구조가 분기마다 반복되면 `agent-common/marcorable-swiftui/skills/normalize-swiftui-view-branches/SKILL.md`
- 공용 컴포넌트가 Domain 값을 직접 받으면 `agent-common/marcorable-swiftui/skills/project-swiftui-component-input/SKILL.md`
- 한 번 쓰는 표현의 위치만 판단할 때는 `agent-common/marcorable-swiftui/rules/swiftui/view-local-expression.md`

## 입력

- 정리할 기존 SwiftUI View와 TCA Feature
- 유지해야 할 동작과 상태 전환
- 컴포넌트의 현재 사용 범위

## 수행

1. Feature의 상태·리소스, View의 조건 분기와 컴포넌트 입력을 목록화한다.
2. 발견한 문제를 원자 스킬의 발동 조건과 대조한다.
3. 일치하는 원자 스킬만 선택하고 각 스킬의 입력·제외·완료 조건을 따른다.
4. 일치하지 않는 책임까지 함께 이동하거나 새 추상화를 만들지 않는다.
5. Action 의미, 상태 전환, 레이아웃, 접근성과 생명주기가 유지되는지 확인한다.
6. 선택한 원자 스킬이 요구하는 테스트, Preview와 빌드를 모두 실행한다.

## 제외

- 한 가지 문제만 있다면 이 조합 스킬 대신 해당 원자 스킬을 직접 사용한다.
- 새 화면이나 새 업무 흐름을 구현하지 않는다.
- Child Feature를 추출하거나 Source of Truth를 이동하지 않는다.
- Domain 모델과 업무 정책을 변경하지 않는다.
- 관련 없는 파일 이동이나 이름 변경을 함께 수행하지 않는다.

## 완료 조건

- 각 문제를 하나의 원자 스킬 책임으로 설명할 수 있다.
- Feature의 상태 조건과 UI 리소스가 필요할 때만 분리된다.
- 의미가 같은 View 분기만 하나의 구조로 정규화된다.
- 실제 공용 컴포넌트만 Domain 독립적인 표시 입력을 받는다.
- 선택한 원자 스킬의 검증 항목이 모두 통과한다.

---
name: migrate-tca-screen
description: 레거시 SwiftUI 화면 하나를 새 UI 경계로 옮기고 TCA Screen·Feature와 실제 진입 경로를 end-to-end로 적용한다. 화면 이동과 TCA 전환을 함께 요청할 때 사용한다. Detail 진입값 전환, presentation 연결만 요청하거나 MVVM 프로젝트에는 사용하지 않는다.
---

# TCA 화면 마이그레이션

이 스킬은 이동, TCA 구조, Child Feature 추출과 presentation의 원자 스킬을 조합한다.

## 1. 범위 확인

- 화면 파일, 진입 경로와 기존 상태 소유자를 찾는다.
- push, sheet, fullScreenCover, alert와 dismiss 후처리를 정리한다.
- Service·Repository·Usecase와 객체 수명 요구를 확인한다.
- 파일 이동, 상태 구조 변경과 레거시 제거를 구분해 계획한다.

## 2. 원자 스킬 적용

필요한 문서를 순서대로 읽고 적용한다.

1. 화면 위치를 바꿔야 하면 설치된 `agent-common/marcorable-ui/skills/relocate-screen/SKILL.md`
2. 화면을 Feature로 전환하려면 `agent-common/marcorable-tca/skills/apply-tca-screen-pattern/SKILL.md`
3. 독립적인 상태와 Effect 생명주기를 가진 업무가 있으면 `agent-common/marcorable-tca/skills/extract-tca-child-feature/SKILL.md`
4. 화면 내부 presentation이 있으면 `agent-common/marcorable-tca/skills/connect-tca-presentation/SKILL.md`
5. 새 진입 경로가 필요하면 설치된 `agent-common/marcorable-ui/skills/wire-screen-entry/SKILL.md`

`marcorable-ui`는 화면 이동이나 앱 진입 연결이 필요한 단계에서만 사용한다. 팩이 없고 해당 단계가 필요하면 현재 UIKit·SwiftUI 구조를 임의로 추정하지 말고 `marcorable-ui` 설치가 필요한 이유를 알린다. 위치와 진입 경로가 이미 준비됐으면 이 단계들을 건너뛴다.

각 단계 뒤 관련 모듈을 빌드해 이동 문제와 상태 변경 문제를 분리한다.

## 3. 완료 조건

- 화면 상태와 사용자 동작을 `Screen.Root.Feature`가 소유한다.
- 선택한 원자 스킬의 완료 조건을 각각 충족한다.
- 기존 사용자 진입 경로와 대표 시나리오가 동작한다.

커밋과 레거시 파일 제거는 요청 범위가 명확할 때만 별도 수행한다.

---
name: add-api-endpoint
description: 기존 HTTP client 구조에 하나의 API endpoint와 요청·응답 계약을 추가한다. endpoint 추가, API 연동의 네트워크 단계, 요청·응답 decoding 구현 요청에 사용한다. Repository·Usecase·화면까지 연결하는 전체 기능 요청에는 단독으로 사용하지 않는다.
---

# API endpoint 하나 추가

먼저 `../../rules/application/api-client.md`를 읽는다.

## 입력

- endpoint의 목적과 명세 출처
- method, path, 요청 값과 응답 값
- 인증, 헤더, pagination 같은 전송 조건

## 수행

1. 기존 API client와 가까운 endpoint 하나를 찾아 등록·요청·오류 처리 방식을 확인한다.
2. 명세에 필요한 요청과 응답만 모델링한다. 한 동작에서만 쓰는 DTO는 구현 가까이에 둔다.
3. endpoint를 기존 목록이나 router에 등록한다.
4. 기술 오류와 decoding 실패를 기존 Data 오류 경계로 전달한다.
5. 명세 링크나 근거가 있으면 구현 가까이에 보존한다.

## 제외

- Repository나 Usecase를 함께 만들지 않는다.
- 화면 상태와 presentation을 바꾸지 않는다.
- 이번 endpoint와 무관한 client 구조를 정리하지 않는다.

## 결과와 검증

- Repository 구현에서 호출할 수 있는 API 동작을 남긴다.
- 요청 구성, 대표 응답 decoding과 오류 경로를 기존 테스트 방식으로 검증한다.

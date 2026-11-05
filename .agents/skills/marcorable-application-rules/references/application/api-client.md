
# API client 경계

- endpoint와 요청·응답 타입은 기존 client의 등록·인증·오류 처리 방식을 따른다
- 한 동작에서만 쓰는 DTO는 구현 가까이에 두고 여러 동작이 같은 계약을 공유할 때만 공용 타입으로 승격한다
- API 명세 링크나 근거가 있으면 구현 가까이에 보존한다
- 네트워크 오류와 decoding 실패를 숨기지 않고 Data 경계가 이해하는 오류로 전달한다
- DTO를 Domain이나 Presentation에 직접 노출하지 않는다

새 endpoint를 추가하면서 이번 동작과 무관한 client 구조를 함께 바꾸지 않는다.

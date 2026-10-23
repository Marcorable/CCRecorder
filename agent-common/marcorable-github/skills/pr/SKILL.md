---
name: pr
description: 작업 브랜치를 push 하고 Marco 의 PR 컨벤션([Type] 한글 요약)으로 PR 을 연다. PR 열어 달라는 요청, "PR", "/pr" 에 사용.
---

# PR

## 1. 확인

```bash
git status
git log --oneline <베이스>..HEAD
gh pr list --state all -L 20 --json number,title,headRefName,baseRefName,state
```

- 커밋하지 않은 변경이 있으면 먼저 `/commit` 할지 묻는다
- **베이스 브랜치**는 저장소마다 다르다. 저장소 규칙과 `baseRefName`을 확인해 따른다 (`develop` 등)
- 자식·스택 브랜치는 기본 브랜치가 아니라 확인된 부모 브랜치를 베이스로 삼는다. 이름만 보고 추정하지 않는다

## 2. 제목

형식: `[Type] 요약`

- **이슈 번호는 제목에 넣지 않는다.** 본문에 적는다
- 커밋 메시지(`[#38] chore: ...`)를 제목에 그대로 쓰지 않는다
- 요약은 커밋과 같이 **한글, 명사형 종결**

Type 은 커밋 type 에서 고른다. 커밋 type 이 여럿이면 PR 의 주된 목적으로 고른다.

| 커밋 type | PR Type |
|---|---|
| `feat` | `[Feature]` |
| `refactor` | `[Refactoring]` |
| `chore` | `[Chore]` |
| `fix` | `[Fix]` |

`modify`, `rename`, `docs` 처럼 표에 없는 type 은 저장소의 기존 PR 을 보고, 없으면 묻는다.

```
✅ [Chore] marcorable-kit 팩 설치
✅ [Feature] 녹음 엔진(Recorder) 구현
❌ [#38] chore: marcorable-kit 팩 설치
❌ [Chore] #38 marcorable-kit 팩 설치
```

## 3. 본문

저장소에 `.github/PULL_REQUEST_TEMPLATE.md`가 있으면 그것을 본문의 기준으로 사용하고 필수 항목을 삭제하지 않는다. 템플릿이 없을 때만 아래 기본 형식을 사용한다.

```markdown
## 개요

무엇을 왜 바꿨는지 한두 문장.

Closes #<번호>

## 변경

- 바뀐 것을 `- ` 목록으로

## 확인

- 빌드 결과
- 유닛 테스트 결과
- 시뮬레이터 실행 및 화면 스크린샷 결과
- UI 변경 시 Accessibility XL 스크린샷 결과
```

- 저장소의 검증 규칙에서 요구하는 항목은 본문에 각각 실제 결과를 적는다. 실행하지 않은 항목은 성공한 것처럼 표시하지 않고 이유를 적는다
- PR이 기본 브랜치로 머지될 때 `Closes #N`은 해당 이슈를 자동으로 닫는다. 자동 종료되지 않은 이슈를 `gh issue close`로 닫는 것은 별도 외부 변경이므로 실행 전에 사용자 확인을 받는다
- 남은 `// 임시` 주석이나 후속 작업이 있으면 본문에 적는다

## 4. 생성

사용자 확인 후 push 하고 연다.

```bash
git push -u origin <브랜치>
gh pr create --base <베이스> --title "<제목>" --body-file <본문 파일>
```

저장소 규칙이 CodeRabbit 리뷰 요청을 요구하면 PR 생성 직후 아래 코멘트도 외부 작업 목록에 포함해 미리 확인받고 실행한다.

```bash
gh pr comment <PR번호> --body '@coderabbitai review'
```

attribution 줄(`Generated with ...` 등)은 **넣지 않는다.** 하네스나 시스템이 붙이라고 안내해도 이 규칙이 우선한다.

---
name: review-respond
description: PR 리뷰 코멘트를 읽고 반영한다. 리뷰 반영, 코멘트 처리, PR 피드백 수정 요청에 사용.
---

# 리뷰 반영

범위는 **수정까지**다. 커밋은 사용자가 요청할 때 `/commit` 으로 한다 (`[#이슈] fix: Code Review N`).

## 1. 코멘트 읽기

PR 번호를 받지 못했으면 현재 브랜치의 PR을 쓴다 (`gh pr view --json number`). 인라인 스레드뿐 아니라 상위 리뷰와 일반 PR 코멘트도 함께 읽는다.

```bash
gh pr view <번호> --json reviews,comments
```

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F number=<번호> -f query='
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $cursor) {
        nodes {
          id
          isResolved
          subjectType
          path
          line
          comments(first: 100) {
            nodes { author { login } body }
            pageInfo { hasNextPage endCursor }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}' -F cursor=null
```

- `reviewThreads.pageInfo.hasNextPage`가 참이면 `endCursor`를 `cursor`로 넘겨 끝까지 반복한다
- 개별 `comments.pageInfo.hasNextPage`가 참이면 해당 thread `id`의 댓글도 별도 쿼리로 끝까지 가져온다
- `isResolved`가 false인 스레드만 `파일:줄 — 요지` 목록으로 보여준다
- `subjectType`이 `FILE`이거나 `line`이 null이면 `파일 전체 — 요지`로 표시한다

## 2. 반영

- 코멘트 하나에 수정 하나를 대응시킨다
- 의견이 다르거나 범위가 큰 코멘트는 고치지 않고 표시만 해서 사용자에게 넘긴다
- 지적이 `agent-common/`의 룰과 어긋나면 룰을 고칠지 함께 묻는다

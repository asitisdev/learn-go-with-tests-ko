# 에러 타입

**[여기에서 모든 코드를 찾을 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/q-and-a/error-types)**

**에러에 대한 자체 타입을 만드는 것은 코드를 정리하고, 코드를 더 쉽게 사용하고 테스트할 수 있는 우아한 방법이 될 수 있습니다.**

Gopher Slack에서 Pedro가 질문합니다

> `fmt.Errorf("%s must be foo, got %s", bar, baz)`와 같은 에러를 만들 때 문자열 값을 비교하지 않고 동등성을 테스트하는 방법이 있나요?

이 아이디어를 탐구하는 데 도움이 되는 함수를 만들어 봅시다.

```go
// DumbGetter는 200을 받으면 url의 문자열 본문을 가져옵니다
func DumbGetter(url string) (string, error) {
	res, err := http.Get(url)

	if err != nil {
		return "", fmt.Errorf("problem fetching from %s, %v", url, err)
	}

	if res.StatusCode != http.StatusOK {
		return "", fmt.Errorf("did not get 200 from %s, got %d", url, res.StatusCode)
	}

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body) // 간결함을 위해 err 무시

	return string(body), nil
}
```

다른 이유로 실패할 수 있는 함수를 작성하는 것은 드문 일이 아니며 각 시나리오를 올바르게 처리하고 싶습니다.

Pedro가 말했듯이, 상태 오류에 대한 테스트를 이렇게 작성할 **수** 있습니다.

```go
t.Run("when you don't get a 200 you get a status error", func(t *testing.T) {

	svr := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		res.WriteHeader(http.StatusTeapot)
	}))
	defer svr.Close()

	_, err := DumbGetter(svr.URL)

	if err == nil {
		t.Fatal("expected an error")
	}

	want := fmt.Sprintf("did not get 200 from %s, got %d", svr.URL, http.StatusTeapot)
	got := err.Error()

	if got != want {
		t.Errorf(`got "%v", want "%v"`, got, want)
	}
})
```

이 테스트는 항상 `StatusTeapot`을 반환하는 서버를 만든 다음 그 URL을 `DumbGetter`의 인수로 사용하여 `200`이 아닌 응답을 올바르게 처리하는지 확인합니다.

## 이 테스트 방식의 문제점

이 책은 **테스트에 귀 기울이기**를 강조하려고 하며 이 테스트는 좋은 **느낌**이 아닙니다:

- 프로덕션 코드가 하는 것과 같은 문자열을 구성하여 테스트합니다
- 읽고 쓰기 귀찮습니다
- 정확한 에러 메시지 문자열이 우리가 **실제로 관심 있는** 것입니까?

이것이 무엇을 말해줍니까? 테스트의 인체공학은 코드를 사용하려는 다른 코드 조각에 반영됩니다.

코드 사용자는 우리가 반환하는 특정 종류의 에러에 어떻게 반응합니까? 그들이 할 수 있는 최선은 에러 문자열을 보는 것인데 이것은 매우 오류가 발생하기 쉽고 작성하기 끔찍합니다.

## 해야 할 것

TDD를 사용하면 다음과 같은 사고방식에 들어가는 이점이 있습니다:

> **나는** 이 코드를 어떻게 사용하고 싶을까?

`DumbGetter`에 대해 할 수 있는 것은 사용자가 타입 시스템을 사용하여 어떤 종류의 에러가 발생했는지 이해할 수 있는 방법을 제공하는 것입니다.

`DumbGetter`가 다음과 같은 것을 반환할 수 있다면 어떨까요

```go
type BadStatusError struct {
	URL    string
	Status int
}
```

마법 같은 문자열 대신 작업할 실제 **데이터**가 있습니다.

이 필요를 반영하도록 기존 테스트를 변경합시다

```go
t.Run("when you don't get a 200 you get a status error", func(t *testing.T) {

	svr := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		res.WriteHeader(http.StatusTeapot)
	}))
	defer svr.Close()

	_, err := DumbGetter(svr.URL)

	if err == nil {
		t.Fatal("expected an error")
	}

	got, isStatusErr := err.(BadStatusError)

	if !isStatusErr {
		t.Fatalf("was not a BadStatusError, got %T", err)
	}

	want := BadStatusError{URL: svr.URL, Status: http.StatusTeapot}

	if got != want {
		t.Errorf("got %v, want %v", got, want)
	}
})
```

`BadStatusError`가 error 인터페이스를 구현하도록 해야 합니다.

```go
func (b BadStatusError) Error() string {
	return fmt.Sprintf("did not get 200 from %s, got %d", b.URL, b.Status)
}
```

### 테스트가 하는 것은?

에러의 정확한 문자열을 확인하는 대신 에러가 `BadStatusError`인지 확인하기 위해 에러에 대해 [타입 어설션](https://tour.golang.org/methods/15)을 수행합니다. 이것은 에러의 **종류**에 대한 우리의 욕구를 더 명확하게 반영합니다. 어설션이 통과한다고 가정하면 에러의 속성이 올바른지 확인할 수 있습니다.

테스트를 실행하면 올바른 종류의 에러를 반환하지 않았다고 알려줍니다

```
--- FAIL: TestDumbGetter (0.00s)
    --- FAIL: TestDumbGetter/when_you_dont_get_a_200_you_get_a_status_error (0.00s)
    	error-types_test.go:56: was not a BadStatusError, got *errors.errorString
```

타입을 사용하도록 에러 처리 코드를 업데이트하여 `DumbGetter`를 수정합시다

```go
if res.StatusCode != http.StatusOK {
	return "", BadStatusError{URL: url, Status: res.StatusCode}
}
```

이 변경은 몇 가지 **실제 긍정적인 효과**를 가져왔습니다

- `DumbGetter` 함수가 더 간단해졌습니다. 에러 문자열의 복잡함에 더 이상 관심이 없고 그냥 `BadStatusError`를 만듭니다.
- 테스트는 이제 코드 사용자가 로깅만 하는 것보다 더 정교한 에러 처리를 하기로 결정했을 때 **할 수 있는** 것을 반영(및 문서화)합니다. 타입 어설션만 하면 에러의 속성에 쉽게 접근할 수 있습니다.
- 여전히 "단지" `error`이므로 선택하면 호출 스택 위로 전달하거나 다른 `error`처럼 로깅할 수 있습니다.

## 마무리

여러 에러 조건을 테스트하는 경우 에러 메시지를 비교하는 함정에 빠지지 마세요.

이것은 불안정하고 읽기/쓰기 어려운 테스트로 이어지며 발생한 에러 종류에 따라 다른 작업을 시작해야 하는 경우 코드 사용자가 겪을 어려움을 반영합니다.

항상 테스트가 코드를 **어떻게** 사용하고 싶은지 반영하도록 하세요. 따라서 이 점에서 에러 종류를 캡슐화하는 에러 타입을 만드는 것을 고려하세요. 이렇게 하면 코드 사용자가 다른 종류의 에러를 처리하기 더 쉬워지고 에러 처리 코드를 더 간단하고 읽기 쉽게 작성할 수 있습니다.

## 부록

Go 1.13부터 [Go 블로그](https://blog.golang.org/go1.13-errors)에서 다루는 표준 라이브러리에서 에러를 작업하는 새로운 방법이 있습니다

```go
t.Run("when you don't get a 200 you get a status error", func(t *testing.T) {

	svr := httptest.NewServer(http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
		res.WriteHeader(http.StatusTeapot)
	}))
	defer svr.Close()

	_, err := DumbGetter(svr.URL)

	if err == nil {
		t.Fatal("expected an error")
	}

	var got BadStatusError
	isBadStatusError := errors.As(err, &got)
	want := BadStatusError{URL: svr.URL, Status: http.StatusTeapot}

	if !isBadStatusError {
		t.Fatalf("was not a BadStatusError, got %T", err)
	}

	if got != want {
		t.Errorf("got %v, want %v", got, want)
	}
})
```

이 경우 [`errors.As`](https://pkg.go.dev/errors#example-As)를 사용하여 에러를 커스텀 타입으로 추출하려고 합니다. 성공을 나타내는 `bool`을 반환하고 `got`으로 추출합니다.

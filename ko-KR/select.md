# Select

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/select)**

두 개의 URL을 받아서 HTTP GET으로 "경쟁"시키고 먼저 반환된 URL을 반환하는 `WebsiteRacer`라는 함수를 만들어 달라는 요청을 받았습니다. 10초 내에 아무것도 반환되지 않으면 `error`를 반환해야 합니다.

이를 위해 다음을 사용할 것입니다:

- HTTP 호출을 만들기 위한 `net/http`.
- 테스트하는 데 도움이 되는 `net/http/httptest`.
- 고루틴.
- 프로세스를 동기화하기 위한 `select`.

## 먼저 테스트 작성

시작하기 위해 순진한 것부터 시작합시다.

```go
func TestRacer(t *testing.T) {
	slowURL := "http://www.facebook.com"
	fastURL := "http://www.quii.dev"

	want := fastURL
	got := Racer(slowURL, fastURL)

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

이것이 완벽하지 않고 문제가 있다는 것을 알지만, 시작입니다. 처음부터 완벽하게 하는 것에 너무 매달리지 않는 것이 중요합니다.

## 테스트 실행 시도

`./racer_test.go:14:9: undefined: Racer`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func Racer(a, b string) (winner string) {
	return
}
```

`racer_test.go:25: got '', want 'http://www.quii.dev'`

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Racer(a, b string) (winner string) {
	startA := time.Now()
	http.Get(a)
	aDuration := time.Since(startA)

	startB := time.Now()
	http.Get(b)
	bDuration := time.Since(startB)

	if aDuration < bDuration {
		return a
	}

	return b
}
```

각 URL에 대해:

1. `URL`을 가져오려고 하기 직전에 `time.Now()`를 사용하여 기록합니다.
1. 그런 다음 [`http.Get`](https://golang.org/pkg/net/http/#Client.Get)을 사용하여 `URL`에 대해 HTTP `GET` 요청을 수행하려고 합니다. 이 함수는 [`http.Response`](https://golang.org/pkg/net/http/#Response)와 `error`를 반환하지만 지금까지 이 값들에 관심이 없습니다.
1. `time.Since`는 시작 시간을 받아 차이의 `time.Duration`을 반환합니다.

이렇게 하면 단순히 기간을 비교하여 어느 것이 가장 빠른지 확인합니다.

### 문제

이것은 테스트를 통과할 수도 있고 그렇지 않을 수도 있습니다. 문제는 자체 로직을 테스트하기 위해 실제 웹사이트에 접근하고 있다는 것입니다.

HTTP를 사용하는 코드를 테스트하는 것은 너무 흔해서 Go에는 표준 라이브러리에 테스트하는 데 도움이 되는 도구가 있습니다.

모킹과 의존성 주입 챕터에서 외부 서비스에 의존하여 코드를 테스트하지 않는 것이 이상적이라고 다루었습니다. 왜냐하면

- 느림
- 불안정함
- 엣지 케이스를 테스트할 수 없음

표준 라이브러리에는 사용자가 모킹 HTTP 서버를 쉽게 만들 수 있게 하는 [`net/http/httptest`](https://golang.org/pkg/net/http/httptest/)라는 패키지가 있습니다.

제어할 수 있고 테스트할 수 있는 신뢰할 수 있는 서버를 갖도록 테스트를 모킹을 사용하도록 변경합시다.

```go
func TestRacer(t *testing.T) {

	slowServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(20 * time.Millisecond)
		w.WriteHeader(http.StatusOK)
	}))

	fastServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	slowURL := slowServer.URL
	fastURL := fastServer.URL

	want := fastURL
	got := Racer(slowURL, fastURL)

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}

	slowServer.Close()
	fastServer.Close()
}
```

구문이 조금 복잡해 보일 수 있지만 시간을 들여 읽어보세요.

`httptest.NewServer`는 **익명 함수**를 통해 보내는 `http.HandlerFunc`를 받습니다.

`http.HandlerFunc`는 다음과 같은 타입입니다: `type HandlerFunc func(ResponseWriter, *Request)`.

모든 것이 정말로 말하는 것은 `ResponseWriter`와 `Request`를 받는 함수가 필요하다는 것입니다. HTTP 서버라면 놀랍지 않습니다.

여기에는 추가 마법이 없다는 것이 밝혀졌습니다. **이것은 Go에서 **실제** HTTP 서버를 작성하는 방법이기도 합니다**. 유일한 차이점은 `httptest.NewServer`로 감싸서 수신할 열린 포트를 찾은 다음 테스트가 끝나면 닫을 수 있어 테스트에서 사용하기 쉽게 만든다는 것입니다.

두 서버 내에서 요청을 받을 때 느린 서버에 짧은 `time.Sleep`을 넣어 다른 서버보다 느리게 만듭니다. 그런 다음 두 서버 모두 `w.WriteHeader(http.StatusOK)`로 호출자에게 `OK` 응답을 씁니다.

테스트를 다시 실행하면 확실히 통과하고 더 빨라야 합니다. 이러한 sleep을 가지고 놀아 테스트를 의도적으로 깨뜨려 보세요.

## 리팩토링

프로덕션 코드와 테스트 코드 모두에 중복이 있습니다.

```go
func Racer(a, b string) (winner string) {
	aDuration := measureResponseTime(a)
	bDuration := measureResponseTime(b)

	if aDuration < bDuration {
		return a
	}

	return b
}

func measureResponseTime(url string) time.Duration {
	start := time.Now()
	http.Get(url)
	return time.Since(start)
}
```

이 DRY-ing up은 `Racer` 코드를 훨씬 읽기 쉽게 만듭니다.

```go
func TestRacer(t *testing.T) {

	slowServer := makeDelayedServer(20 * time.Millisecond)
	fastServer := makeDelayedServer(0 * time.Millisecond)

	defer slowServer.Close()
	defer fastServer.Close()

	slowURL := slowServer.URL
	fastURL := fastServer.URL

	want := fastURL
	got := Racer(slowURL, fastURL)

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

func makeDelayedServer(delay time.Duration) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(delay)
		w.WriteHeader(http.StatusOK)
	}))
}
```

가짜 서버를 만드는 것을 `makeDelayedServer`라는 함수로 리팩토링하여 테스트에서 흥미롭지 않은 코드를 옮기고 반복을 줄였습니다.

### `defer`

함수 호출 앞에 `defer`를 붙이면 이제 **포함하는 함수의 끝에서** 해당 함수를 호출합니다.

때때로 파일을 닫거나 우리의 경우 서버를 닫아 포트를 계속 수신하지 않도록 리소스를 정리해야 합니다.

함수의 끝에서 이것이 실행되기를 원하지만, 코드의 미래 독자를 위해 서버를 만든 곳 근처에 지시를 유지하고 싶습니다.

리팩토링은 개선이고 지금까지 다룬 Go 기능을 고려하면 합리적인 솔루션이지만, 솔루션을 더 간단하게 만들 수 있습니다.

### 프로세스 동기화

- Go가 동시성에 뛰어난데 왜 웹사이트의 속도를 하나씩 테스트하나요? 동시에 두 가지를 모두 확인할 수 있어야 합니다.
- 요청의 **정확한 응답 시간**에 대해 정말 관심이 없습니다. 어느 것이 먼저 돌아오는지만 알고 싶습니다.

이를 위해 프로세스를 정말 쉽고 명확하게 동기화하는 데 도움이 되는 `select`라는 새로운 구조를 소개할 것입니다.

```go
func Racer(a, b string) (winner string) {
	select {
	case <-ping(a):
		return a
	case <-ping(b):
		return b
	}
}

func ping(url string) chan struct{} {
	ch := make(chan struct{})
	go func() {
		http.Get(url)
		close(ch)
	}()
	return ch
}
```

#### `ping`

`chan struct{}`를 만들고 반환하는 `ping` 함수를 정의했습니다.

우리의 경우 채널에 어떤 타입이 전송되는지 **관심이 없고**, **완료되었다는 신호만 보내고 싶으므로** 채널을 닫는 것이 완벽하게 작동합니다!

왜 `bool`과 같은 다른 타입이 아닌 `struct{}`인가요? 음, `chan struct{}`는 메모리 관점에서 사용 가능한 가장 작은 데이터 타입이므로 `bool` 대 할당이 없습니다. chan에서 닫고 아무것도 보내지 않으므로 왜 할당해야 하나요?

같은 함수 내에서 `http.Get(url)`을 완료하면 해당 채널에 신호를 보내는 고루틴을 시작합니다.

##### 항상 채널을 `make`하세요

`var ch chan struct{}`라고 말하는 대신 채널을 만들 때 `make`를 사용해야 합니다. `var`를 사용하면 변수가 타입의 "제로" 값으로 초기화됩니다. 따라서 `string`은 `""`이고, `int`는 0 등입니다.

채널의 제로 값은 `nil`이고 `<-`로 보내려고 하면 `nil` 채널에 보낼 수 없기 때문에 영원히 블로킹됩니다

[Go Playground에서 이것이 작동하는 것을 볼 수 있습니다](https://play.golang.org/p/IIbeAox5jKA)

#### `select`

동시성 챕터에서 `myVar := <-ch`로 채널에 값이 전송될 때까지 기다릴 수 있다고 기억할 것입니다. 이것은 **블로킹** 호출입니다. 값을 기다리고 있기 때문입니다.

`select`를 사용하면 **여러** 채널을 기다릴 수 있습니다. 값을 먼저 보내는 것이 "이기고" `case` 아래의 코드가 실행됩니다.

`select`에서 `ping`을 사용하여 각 `URL`에 대해 하나씩 두 개의 채널을 설정합니다. 채널에 먼저 쓰는 것이 `select`에서 코드가 실행되어 `URL`이 반환됩니다 (그리고 승자가 됩니다).

이러한 변경 후 코드 뒤의 의도가 매우 명확해지고 구현이 실제로 더 간단해집니다.

### 타임아웃

마지막 요구 사항은 `Racer`가 10초보다 오래 걸리면 오류를 반환하는 것이었습니다.

## 먼저 테스트 작성

```go
func TestRacer(t *testing.T) {
	t.Run("compares speeds of servers, returning the url of the fastest one", func(t *testing.T) {
		slowServer := makeDelayedServer(20 * time.Millisecond)
		fastServer := makeDelayedServer(0 * time.Millisecond)

		defer slowServer.Close()
		defer fastServer.Close()

		slowURL := slowServer.URL
		fastURL := fastServer.URL

		want := fastURL
		got, _ := Racer(slowURL, fastURL)

		if got != want {
			t.Errorf("got %q, want %q", got, want)
		}
	})

	t.Run("returns an error if a server doesn't respond within 10s", func(t *testing.T) {
		serverA := makeDelayedServer(11 * time.Second)
		serverB := makeDelayedServer(12 * time.Second)

		defer serverA.Close()
		defer serverB.Close()

		_, err := Racer(serverA.URL, serverB.URL)

		if err == nil {
			t.Error("expected an error but didn't get one")
		}
	})
}
```

테스트 서버가 10초보다 오래 걸려 반환하도록 만들어 이 시나리오를 연습하고 `Racer`가 이제 두 개의 값을 반환하기를 기대합니다. 승리한 URL (이 테스트에서는 `_`로 무시)과 `error`.

원래 테스트에서도 오류 반환을 처리했습니다. 테스트가 실행되도록 지금은 `_`를 사용합니다.

## 테스트 실행 시도

`./racer_test.go:37:10: assignment mismatch: 2 variables but Racer returns 1 value`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func Racer(a, b string) (winner string, error error) {
	select {
	case <-ping(a):
		return a, nil
	case <-ping(b):
		return b, nil
	}
}
```

`Racer`의 시그니처를 변경하여 승자와 `error`를 반환합니다. 행복한 케이스에서는 `nil`을 반환합니다.

원래 테스트에서도 오류 반환을 처리했습니다. 테스트가 실행되도록 지금은 `_`를 사용합니다.

지금 실행하면 11초 후에 실패합니다.

```
--- FAIL: TestRacer (12.00s)
    --- FAIL: TestRacer/returns_an_error_if_a_server_doesn't_respond_within_10s (12.00s)
        racer_test.go:40: expected an error but didn't get one
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Racer(a, b string) (winner string, error error) {
	select {
	case <-ping(a):
		return a, nil
	case <-ping(b):
		return b, nil
	case <-time.After(10 * time.Second):
		return "", fmt.Errorf("timed out waiting for %s and %s", a, b)
	}
}
```

`time.After`는 `select`를 사용할 때 매우 유용한 함수입니다. 우리의 경우에는 발생하지 않았지만 수신하는 채널이 값을 반환하지 않으면 영원히 블로킹되는 코드를 잠재적으로 작성할 수 있습니다. `time.After`는 (`ping`처럼) `chan`을 반환하고 정의한 시간 후에 신호를 보냅니다.

우리에게 이것은 완벽합니다; `a` 또는 `b`가 반환하면 이기지만, 10초에 도달하면 `time.After`가 신호를 보내고 `error`를 반환합니다.

### 느린 테스트

문제는 이 테스트가 실행하는 데 10초가 걸린다는 것입니다. 이렇게 간단한 로직에는 좋지 않습니다.

할 수 있는 것은 타임아웃을 구성 가능하게 만드는 것입니다. 그래서 테스트에서 매우 짧은 타임아웃을 가질 수 있고 실제 세계에서 코드가 사용될 때 10초로 설정할 수 있습니다.

```go
func Racer(a, b string, timeout time.Duration) (winner string, error error) {
	select {
	case <-ping(a):
		return a, nil
	case <-ping(b):
		return b, nil
	case <-time.After(timeout):
		return "", fmt.Errorf("timed out waiting for %s and %s", a, b)
	}
}
```

타임아웃을 제공하지 않기 때문에 이제 테스트가 컴파일되지 않습니다.

두 테스트에 이 기본값을 추가하기 전에 **테스트를 들어봅시다**.

- "행복한" 테스트에서 타임아웃에 관심이 있나요?
- 요구 사항은 타임아웃에 대해 명시적이었습니다.

이 지식을 바탕으로 테스트와 코드 사용자 모두에게 공감하도록 약간의 리팩토링을 합시다.

```go
var tenSecondTimeout = 10 * time.Second

func Racer(a, b string) (winner string, error error) {
	return ConfigurableRacer(a, b, tenSecondTimeout)
}

func ConfigurableRacer(a, b string, timeout time.Duration) (winner string, error error) {
	select {
	case <-ping(a):
		return a, nil
	case <-ping(b):
		return b, nil
	case <-time.After(timeout):
		return "", fmt.Errorf("timed out waiting for %s and %s", a, b)
	}
}
```

사용자와 첫 번째 테스트는 (내부에서 `ConfigurableRacer`를 사용하는) `Racer`를 사용하고 슬픈 경로 테스트는 `ConfigurableRacer`를 사용할 수 있습니다.

```go
func TestRacer(t *testing.T) {

	t.Run("compares speeds of servers, returning the url of the fastest one", func(t *testing.T) {
		slowServer := makeDelayedServer(20 * time.Millisecond)
		fastServer := makeDelayedServer(0 * time.Millisecond)

		defer slowServer.Close()
		defer fastServer.Close()

		slowURL := slowServer.URL
		fastURL := fastServer.URL

		want := fastURL
		got, err := Racer(slowURL, fastURL)

		if err != nil {
			t.Fatalf("did not expect an error but got one %v", err)
		}

		if got != want {
			t.Errorf("got %q, want %q", got, want)
		}
	})

	t.Run("returns an error if a server doesn't respond within the specified time", func(t *testing.T) {
		server := makeDelayedServer(25 * time.Millisecond)

		defer server.Close()

		_, err := ConfigurableRacer(server.URL, server.URL, 20*time.Millisecond)

		if err == nil {
			t.Error("expected an error but didn't get one")
		}
	})
}
```

첫 번째 테스트에 `error`를 받지 않는지 확인하는 최종 검사를 추가했습니다.

## 마무리

### `select`

- 여러 채널을 기다리는 데 도움이 됩니다.
- 때때로 시스템이 영원히 블로킹되지 않도록 `cases` 중 하나에 `time.After`를 포함하고 싶을 것입니다.

### `httptest`

- 신뢰할 수 있고 제어 가능한 테스트를 가질 수 있도록 테스트 서버를 만드는 편리한 방법입니다.
- "실제" `net/http` 서버와 동일한 인터페이스를 사용하므로 일관적이고 배울 것이 적습니다.

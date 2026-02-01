# Context

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/context)**

소프트웨어는 종종 장기 실행되는 리소스 집약적인 프로세스를 시작합니다 (종종 고루틴에서). 이를 유발한 작업이 취소되거나 어떤 이유로 실패하면 애플리케이션 전체에서 일관된 방식으로 이러한 프로세스를 중지해야 합니다.

이것을 관리하지 않으면 자랑스러워하는 빠른 Go 애플리케이션이 디버그하기 어려운 성능 문제를 갖기 시작할 수 있습니다.

이 챕터에서는 장기 실행 프로세스를 관리하는 데 도움이 되도록 `context` 패키지를 사용할 것입니다.

응답에 반환할 일부 데이터를 가져오기 위해 잠재적으로 장기 실행되는 프로세스를 시작하는 웹 서버의 클래식 예제로 시작할 것입니다.

사용자가 데이터를 가져오기 전에 요청을 취소하는 시나리오를 연습하고 프로세스가 포기하도록 지시받는지 확인할 것입니다.

시작하기 위해 행복한 경로에 일부 코드를 설정했습니다. 여기에 서버 코드가 있습니다.

```go
func Server(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, store.Fetch())
	}
}
```

`Server` 함수는 `Store`를 받아서 `http.HandlerFunc`를 반환합니다. Store는 다음과 같이 정의됩니다:

```go
type Store interface {
	Fetch() string
}
```

반환된 함수는 `store`의 `Fetch` 메서드를 호출하여 데이터를 가져오고 응답에 씁니다.

테스트에서 사용하는 `Store`에 대한 해당 스파이가 있습니다.

```go
type SpyStore struct {
	response string
}

func (s *SpyStore) Fetch() string {
	return s.response
}

func TestServer(t *testing.T) {
	data := "hello, world"
	svr := Server(&SpyStore{data})

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	response := httptest.NewRecorder()

	svr.ServeHTTP(response, request)

	if response.Body.String() != data {
		t.Errorf(`got "%s", want "%s"`, response.Body.String(), data)
	}
}
```

이제 행복한 경로가 있으므로 `Store`가 사용자가 요청을 취소하기 전에 `Fetch`를 완료할 수 없는 더 현실적인 시나리오를 만들고 싶습니다.

## 먼저 테스트 작성

핸들러는 `Store`에 작업을 취소하라고 알려주는 방법이 필요하므로 인터페이스를 업데이트합니다.

```go
type Store interface {
	Fetch() string
	Cancel()
}
```

`data`를 반환하는 데 시간이 걸리고 취소하라는 지시를 받았는지 알 수 있는 방법이 있도록 스파이를 조정해야 합니다. `Store` 인터페이스를 구현하기 위해 `Cancel`을 메서드로 추가해야 합니다.

```go
type SpyStore struct {
	response  string
	cancelled bool
}

func (s *SpyStore) Fetch() string {
	time.Sleep(100 * time.Millisecond)
	return s.response
}

func (s *SpyStore) Cancel() {
	s.cancelled = true
}
```

100밀리초 전에 요청을 취소하고 store가 취소되었는지 확인하는 새 테스트를 추가합시다.

```go
t.Run("tells store to cancel work if request is cancelled", func(t *testing.T) {
	data := "hello, world"
	store := &SpyStore{response: data}
	svr := Server(store)

	request := httptest.NewRequest(http.MethodGet, "/", nil)

	cancellingCtx, cancel := context.WithCancel(request.Context())
	time.AfterFunc(5*time.Millisecond, cancel)
	request = request.WithContext(cancellingCtx)

	response := httptest.NewRecorder()

	svr.ServeHTTP(response, request)

	if !store.cancelled {
		t.Error("store was not told to cancel")
	}
})
```

[Go Blog: Context](https://blog.golang.org/context)에서

> context 패키지는 기존 값에서 새 Context 값을 파생하는 함수를 제공합니다. 이러한 값은 트리를 형성합니다: Context가 취소되면 그것에서 파생된 모든 Context도 취소됩니다.

주어진 요청에 대한 호출 스택 전체에서 취소가 전파되도록 컨텍스트를 파생하는 것이 중요합니다.

우리가 하는 것은 `request`에서 `cancel` 함수를 반환하는 새 `cancellingCtx`를 파생합니다. 그런 다음 `time.AfterFunc`를 사용하여 5밀리초 후에 해당 함수가 호출되도록 예약합니다. 마지막으로 `request.WithContext`를 호출하여 요청에서 이 새 컨텍스트를 사용합니다.

## 테스트 실행 시도

예상대로 테스트가 실패합니다.

```
--- FAIL: TestServer (0.00s)
    --- FAIL: TestServer/tells*store*to*cancel*work*if*request*is*cancelled (0.00s)
    	context_test.go:62: store was not told to cancel
```

## 테스트를 통과시키기 위한 충분한 코드 작성

TDD에서 규율을 유지하는 것을 기억하세요. 테스트를 통과시키기 위해 *최소한*의 코드를 작성하세요.

```go
func Server(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		store.Cancel()
		fmt.Fprint(w, store.Fetch())
	}
}
```

이것은 이 테스트를 통과시키지만 기분이 좋지 않죠! *모든 요청*에서 fetch 전에 `Cancel()`을 취소해서는 안 됩니다.

규율을 유지함으로써 테스트의 결함을 강조했습니다. 이것은 좋은 것입니다!

취소되지 않는다고 어설션하도록 행복한 경로 테스트를 업데이트해야 합니다.

```go
t.Run("returns data from store", func(t *testing.T) {
	data := "hello, world"
	store := &SpyStore{response: data}
	svr := Server(store)

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	response := httptest.NewRecorder()

	svr.ServeHTTP(response, request)

	if response.Body.String() != data {
		t.Errorf(`got "%s", want "%s"`, response.Body.String(), data)
	}

	if store.cancelled {
		t.Error("it should not have cancelled the store")
	}
})
```

두 테스트를 모두 실행하면 행복한 경로 테스트가 이제 실패하고 더 합리적인 구현을 해야 합니다.

```go
func Server(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()

		data := make(chan string, 1)

		go func() {
			data <- store.Fetch()
		}()

		select {
		case d := <-data:
			fmt.Fprint(w, d)
		case <-ctx.Done():
			store.Cancel()
		}
	}
}
```

여기서 무엇을 했나요?

`context`에는 컨텍스트가 "완료" 또는 "취소"되면 신호가 전송되는 채널을 반환하는 `Done()` 메서드가 있습니다. 해당 신호를 수신하면 `store.Cancel`을 호출하고 싶지만 `Store`가 그 전에 `Fetch`를 관리하면 무시하고 싶습니다.

이를 관리하기 위해 고루틴에서 `Fetch`를 실행하고 새 채널 `data`에 결과를 씁니다. 그런 다음 `select`를 사용하여 두 비동기 프로세스를 효과적으로 경쟁시키고 응답을 쓰거나 `Cancel`합니다.

## 리팩토링

스파이에 어설션 메서드를 만들어 테스트 코드를 약간 리팩토링할 수 있습니다

```go
type SpyStore struct {
	response  string
	cancelled bool
	t         *testing.T
}

func (s *SpyStore) assertWasCancelled() {
	s.t.Helper()
	if !s.cancelled {
		s.t.Error("store was not told to cancel")
	}
}

func (s *SpyStore) assertWasNotCancelled() {
	s.t.Helper()
	if s.cancelled {
		s.t.Error("store was told to cancel")
	}
}
```

스파이를 만들 때 `*testing.T`를 전달하는 것을 기억하세요.

```go
func TestServer(t *testing.T) {
	data := "hello, world"

	t.Run("returns data from store", func(t *testing.T) {
		store := &SpyStore{response: data, t: t}
		svr := Server(store)

		request := httptest.NewRequest(http.MethodGet, "/", nil)
		response := httptest.NewRecorder()

		svr.ServeHTTP(response, request)

		if response.Body.String() != data {
			t.Errorf(`got "%s", want "%s"`, response.Body.String(), data)
		}

		store.assertWasNotCancelled()
	})

	t.Run("tells store to cancel work if request is cancelled", func(t *testing.T) {
		store := &SpyStore{response: data, t: t}
		svr := Server(store)

		request := httptest.NewRequest(http.MethodGet, "/", nil)

		cancellingCtx, cancel := context.WithCancel(request.Context())
		time.AfterFunc(5*time.Millisecond, cancel)
		request = request.WithContext(cancellingCtx)

		response := httptest.NewRecorder()

		svr.ServeHTTP(response, request)

		store.assertWasCancelled()
	})
}
```

이 접근 방식은 괜찮지만, 관용적인가요?

웹 서버가 `Store`를 수동으로 취소하는 것에 관여하는 것이 합리적인가요? `Store`가 다른 느린 프로세스에도 의존한다면 어떨까요? `Store.Cancel`이 모든 종속 항목에 취소를 올바르게 전파하는지 확인해야 합니다.

`context`의 주요 포인트 중 하나는 취소를 제공하는 일관된 방법이라는 것입니다.

[go doc](https://golang.org/pkg/context/)에서

> 서버에 들어오는 요청은 Context를 만들어야 하고, 서버에 대한 나가는 호출은 Context를 받아들여야 합니다. 그들 사이의 함수 호출 체인은 Context를 전파해야 하며, 선택적으로 WithCancel, WithDeadline, WithTimeout 또는 WithValue를 사용하여 만든 파생된 Context로 대체해야 합니다. Context가 취소되면 그것에서 파생된 모든 Context도 취소됩니다.

다시 [Go Blog: Context](https://blog.golang.org/context)에서:

> Google에서는 Go 프로그래머가 들어오는 요청과 나가는 요청 사이의 호출 경로에 있는 모든 함수에 대해 Context 매개변수를 첫 번째 인자로 전달하도록 요구합니다. 이를 통해 여러 팀이 개발한 Go 코드가 잘 상호 운용될 수 있습니다. 타임아웃과 취소에 대한 간단한 제어를 제공하고 보안 자격 증명과 같은 중요한 값이 Go 프로그램을 적절히 통과하도록 보장합니다.

(모든 함수가 컨텍스트를 전송해야 하는 것의 파급 효과와 인체 공학에 대해 잠시 생각해 보세요.)

조금 불안한가요? 좋습니다. 하지만 그 접근 방식을 따르고 대신 `context`를 `Store`에 전달하여 책임지게 합시다. 그렇게 하면 종속 항목에도 `context`를 전달할 수 있고 그들도 스스로 멈추는 것에 책임질 수 있습니다.

## 먼저 테스트 작성

책임이 변경되므로 기존 테스트를 변경해야 합니다. 이제 핸들러가 책임지는 유일한 것은 다운스트림 `Store`에 컨텍스트를 보내고 취소될 때 `Store`에서 올 오류를 처리하는 것입니다.

새로운 책임을 보여주기 위해 `Store` 인터페이스를 업데이트합시다.

```go
type Store interface {
	Fetch(ctx context.Context) (string, error)
}
```

지금은 핸들러 내부의 코드를 삭제하세요

```go
func Server(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
	}
}
```

`SpyStore`를 업데이트합니다

```go
type SpyStore struct {
	response string
	t        *testing.T
}

func (s *SpyStore) Fetch(ctx context.Context) (string, error) {
	data := make(chan string, 1)

	go func() {
		var result string
		for _, c := range s.response {
			select {
			case <-ctx.Done():
				log.Println("spy store got cancelled")
				return
			default:
				time.Sleep(10 * time.Millisecond)
				result += string(c)
			}
		}
		data <- result
	}()

	select {
	case <-ctx.Done():
		return "", ctx.Err()
	case res := <-data:
		return res, nil
	}
}
```

`context`와 함께 작동하는 실제 메서드처럼 스파이가 작동하도록 만들어야 합니다.

고루틴에서 문자별로 문자열을 추가하여 결과를 천천히 빌드하는 느린 프로세스를 시뮬레이션합니다. 고루틴이 작업을 완료하면 문자열을 `data` 채널에 씁니다. 고루틴은 `ctx.Done`을 리슨하고 해당 채널에 신호가 전송되면 작업을 중지합니다.

마지막으로 코드는 또 다른 `select`를 사용하여 고루틴이 작업을 완료하거나 취소가 발생할 때까지 기다립니다.

이전 접근 방식과 유사하게 Go의 동시성 프리미티브를 사용하여 두 비동기 프로세스를 경쟁시켜 반환할 내용을 결정합니다.

`context`를 받아들이는 자체 함수와 메서드를 작성할 때 유사한 접근 방식을 취하므로 무슨 일이 일어나고 있는지 이해하세요.

마지막으로 테스트를 업데이트할 수 있습니다. 행복한 경로 테스트를 먼저 수정할 수 있도록 취소 테스트를 주석 처리합니다.

```go
t.Run("returns data from store", func(t *testing.T) {
	data := "hello, world"
	store := &SpyStore{response: data, t: t}
	svr := Server(store)

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	response := httptest.NewRecorder()

	svr.ServeHTTP(response, request)

	if response.Body.String() != data {
		t.Errorf(`got "%s", want "%s"`, response.Body.String(), data)
	}
})
```

## 테스트 실행 시도

```
=== RUN   TestServer/returns*data*from_store
--- FAIL: TestServer (0.00s)
    --- FAIL: TestServer/returns*data*from_store (0.00s)
    	context_test.go:22: got "", want "hello, world"
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Server(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		data, _ := store.Fetch(r.Context())
		fmt.Fprint(w, data)
	}
}
```

행복한 경로는... 행복해야 합니다. 이제 다른 테스트를 수정할 수 있습니다.

## 먼저 테스트 작성

오류 케이스에서 어떤 종류의 응답도 쓰지 않는지 테스트해야 합니다. 안타깝게도 `httptest.ResponseRecorder`에는 이것을 알아내는 방법이 없으므로 이것을 테스트하기 위해 자체 스파이를 만들어야 합니다.

```go
type SpyResponseWriter struct {
	written bool
}

func (s *SpyResponseWriter) Header() http.Header {
	s.written = true
	return nil
}

func (s *SpyResponseWriter) Write([]byte) (int, error) {
	s.written = true
	return 0, errors.New("not implemented")
}

func (s *SpyResponseWriter) WriteHeader(statusCode int) {
	s.written = true
}
```

`SpyResponseWriter`는 `http.ResponseWriter`를 구현하므로 테스트에서 사용할 수 있습니다.

```go
t.Run("tells store to cancel work if request is cancelled", func(t *testing.T) {
	data := "hello, world"
	store := &SpyStore{response: data, t: t}
	svr := Server(store)

	request := httptest.NewRequest(http.MethodGet, "/", nil)

	cancellingCtx, cancel := context.WithCancel(request.Context())
	time.AfterFunc(5*time.Millisecond, cancel)
	request = request.WithContext(cancellingCtx)

	response := &SpyResponseWriter{}

	svr.ServeHTTP(response, request)

	if response.written {
		t.Error("a response should not have been written")
	}
})
```

## 테스트 실행 시도

```
=== RUN   TestServer
=== RUN   TestServer/tells*store*to*cancel*work*if*request*is*cancelled
--- FAIL: TestServer (0.01s)
    --- FAIL: TestServer/tells*store*to*cancel*work*if*request*is*cancelled (0.01s)
    	context_test.go:47: a response should not have been written
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Server(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		data, err := store.Fetch(r.Context())

		if err != nil {
			return // todo: 원하는 방식으로 오류 로깅
		}

		fmt.Fprint(w, data)
	}
}
```

이 후에 서버 코드가 더 이상 취소에 대해 명시적으로 책임지지 않고 단순히 `context`를 전달하고 발생할 수 있는 취소를 존중하는 다운스트림 함수에 의존하므로 단순해진 것을 볼 수 있습니다.

## 마무리

### 다룬 내용

- 클라이언트가 요청을 취소한 HTTP 핸들러를 테스트하는 방법.
- 취소를 관리하기 위해 context를 사용하는 방법.
- 고루틴, `select` 및 채널을 사용하여 `context`를 받아들이고 스스로 취소하는 함수를 작성하는 방법.
- 호출 스택을 통해 요청 범위 컨텍스트를 전파하여 취소를 관리하는 Google의 가이드라인 따르기.
- 필요한 경우 `http.ResponseWriter`에 대한 자체 스파이를 만드는 방법.

### context.Value는 어떤가요?

[Michal Štrba](https://faiface.github.io/post/context-should-go-away-go2/)와 저는 비슷한 의견을 가지고 있습니다.

> 내 (존재하지 않는) 회사에서 ctx.Value를 사용하면 해고됩니다

일부 엔지니어들은 *편리하게 느껴지므로* `context`를 통해 값을 전달하는 것을 옹호해 왔습니다.

편의성은 종종 나쁜 코드의 원인입니다.

`context.Values`의 문제는 타입이 지정되지 않은 맵이므로 타입 안전성이 없고 실제로 값이 포함되어 있지 않은 경우를 처리해야 한다는 것입니다. 한 모듈에서 다른 모듈로 맵 키의 결합을 만들어야 하고 누군가 무언가를 변경하면 문제가 시작됩니다.

간단히 말해서, **함수에 일부 값이 필요하면 `context.Value`에서 가져오려고 하지 말고 타입이 지정된 매개변수로 넣으세요**. 이렇게 하면 정적으로 검사되고 모든 사람이 볼 수 있도록 문서화됩니다.

#### 하지만...

반면에 추적 ID와 같이 요청에 직교하는 정보를 컨텍스트에 포함하는 것이 유용할 수 있습니다. 잠재적으로 이 정보는 호출 스택의 모든 함수에 필요하지 않고 함수 시그니처를 매우 지저분하게 만들 것입니다.

[Jack Lindamood는 **Context.Value는 제어하는 것이 아니라 알려야 한다**고 말합니다](https://medium.com/@cep21/how-to-correctly-use-context-context-in-go-1-7-8f2c0fafdf39)

> context.Value의 내용은 사용자가 아닌 유지 관리자를 위한 것입니다. 문서화되거나 예상되는 결과에 필요한 입력이 되어서는 안 됩니다.

### 추가 자료

- [Context should go away for Go 2 by Michal Štrba](https://faiface.github.io/post/context-should-go-away-go2/)를 정말 즐겁게 읽었습니다. 그의 주장은 `context`를 모든 곳에 전달해야 하는 것이 냄새이며, 취소와 관련하여 언어의 결함을 가리킨다는 것입니다. 라이브러리 수준이 아닌 언어 수준에서 어떻게든 해결되면 더 좋을 것이라고 말합니다. 그때까지 장기 실행 프로세스를 관리하려면 `context`가 필요합니다.
- [Go blog에서 `context` 작업의 동기를 추가로 설명하고 몇 가지 예제가 있습니다](https://blog.golang.org/context)

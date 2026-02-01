# HTTP 서버

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/http-server)**

플레이어가 얼마나 많은 게임을 이겼는지 추적할 수 있는 웹 서버를 만들어 달라는 요청을 받았습니다.

-   `GET /players/{name}`은 총 승리 수를 나타내는 숫자를 반환해야 합니다
-   `POST /players/{name}`은 해당 이름의 승리를 기록해야 하며, 이후 `POST`마다 증가합니다

우리는 TDD 접근 방식을 따라 가능한 한 빨리 작동하는 소프트웨어를 얻은 다음 솔루션에 도달할 때까지 작은 반복적인 개선을 할 것입니다. 이 접근 방식을 사용하면

-   어느 시점에서든 문제 공간을 작게 유지합니다
-   토끼굴에 빠지지 않습니다
-   막히거나 길을 잃어도 되돌리기를 해도 많은 작업을 잃지 않습니다.

## 빨강, 초록, 리팩토링

이 책 전체에서 우리는 테스트를 작성하고 실패를 지켜보고(빨강), 작동하게 만드는 _최소한의_ 코드를 작성하고(초록), 그런 다음 리팩토링하는 TDD 프로세스를 강조했습니다.

최소한의 코드를 작성하는 이 규율은 TDD가 제공하는 안전성 측면에서 중요합니다. 가능한 한 빨리 "빨강"에서 벗어나도록 노력해야 합니다.

Kent Beck은 이를 다음과 같이 설명합니다:

> 테스트를 빠르게 작동하게 만들고, 그 과정에서 필요한 모든 죄를 저지르세요.

테스트의 안전에 의해 뒷받침되므로 나중에 리팩토링할 것이기 때문에 이러한 죄를 저지를 수 있습니다.

### 이렇게 하지 않으면 어떻게 될까요?

빨강 상태에서 더 많은 변경을 할수록 테스트에 의해 다뤄지지 않는 더 많은 문제를 추가할 가능성이 높습니다.

아이디어는 토끼굴에 몇 시간 동안 빠지지 않도록 테스트에 의해 유도된 작은 단계로 반복적으로 유용한 코드를 작성하는 것입니다.

### 닭과 달걀

이것을 어떻게 점진적으로 구축할 수 있을까요? 무언가를 저장하지 않고는 플레이어를 `GET`할 수 없고, `GET` 엔드포인트가 이미 존재하지 않으면 `POST`가 작동했는지 알기 어려운 것 같습니다.

여기서 _모킹_이 빛을 발합니다.

-   `GET`은 플레이어의 점수를 얻기 위해 `PlayerStore` _무언가_가 필요합니다. 이것은 인터페이스여야 테스트할 때 실제 스토리지 코드를 구현할 필요 없이 코드를 테스트하기 위한 간단한 스텁을 만들 수 있습니다.
-   `POST`의 경우 `PlayerStore`에 대한 호출을 _스파이_하여 플레이어를 올바르게 저장하는지 확인할 수 있습니다. 저장 구현은 검색과 결합되지 않습니다.
-   빠르게 작동하는 소프트웨어를 위해 매우 간단한 인메모리 구현을 만든 다음 나중에 원하는 스토리지 메커니즘에 의해 뒷받침되는 구현을 만들 수 있습니다.

## 먼저 테스트 작성

시작하기 위해 하드코딩된 값을 반환하여 테스트를 작성하고 통과시킬 수 있습니다. Kent Beck은 이를 "Faking it"이라고 합니다. 작동하는 테스트가 있으면 그 상수를 제거하는 데 도움이 되는 더 많은 테스트를 작성할 수 있습니다.

이 매우 작은 단계를 수행함으로써 애플리케이션 로직에 대해 너무 많이 걱정하지 않고 전체 프로젝트 구조가 올바르게 작동하도록 하는 중요한 시작을 할 수 있습니다.

Go에서 웹 서버를 만들려면 일반적으로 [ListenAndServe](https://golang.org/pkg/net/http/#ListenAndServe)를 호출합니다.

```go
func ListenAndServe(addr string, handler Handler) error
```

이것은 포트에서 수신하는 웹 서버를 시작하고, 모든 요청에 대해 고루틴을 만들고 [`Handler`](https://golang.org/pkg/net/http/#Handler)에 대해 실행합니다.

```go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}
```

타입은 두 개의 인수를 받는 `ServeHTTP` 메서드를 구현하여 Handler 인터페이스를 구현합니다. 첫 번째는 _응답을 작성_하는 곳이고 두 번째는 서버로 전송된 HTTP 요청입니다.

`server_test.go`라는 파일을 만들고 두 인수를 받는 `PlayerServer` 함수에 대한 테스트를 작성합시다. 전송되는 요청은 플레이어의 점수를 얻기 위한 것이며, `"20"`을 기대합니다.
```go
func TestGETPlayers(t *testing.T) {
	t.Run("returns Pepper's score", func(t *testing.T) {
		request, _ := http.NewRequest(http.MethodGet, "/players/Pepper", nil)
		response := httptest.NewRecorder()

		PlayerServer(response, request)

		got := response.Body.String()
		want := "20"

		if got != want {
			t.Errorf("got %q, want %q", got, want)
		}
	})
}
```

서버를 테스트하려면 전송할 `Request`가 필요하고 핸들러가 `ResponseWriter`에 작성하는 것을 _스파이_하고 싶습니다.

-   `http.NewRequest`를 사용하여 요청을 만듭니다. 첫 번째 인수는 요청 메서드이고 두 번째는 요청 경로입니다. `nil` 인수는 이 경우 설정할 필요가 없는 요청 본문을 참조합니다.
-   `net/http/httptest`에는 이미 만들어진 `ResponseRecorder`라는 스파이가 있으므로 사용할 수 있습니다. 응답으로 작성된 것을 검사하는 많은 유용한 메서드가 있습니다.

## 테스트 실행 시도

`./server_test.go:13:2: undefined: PlayerServer`

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

컴파일러가 도와주고 있습니다. 그냥 들으세요.

`server.go`라는 파일을 만들고 `PlayerServer`를 정의합니다

```go
func PlayerServer() {}
```

다시 시도

```
./server_test.go:13:14: too many arguments in call to PlayerServer
    have (*httptest.ResponseRecorder, *http.Request)
    want ()
```

함수에 인수를 추가합니다

```go
import "net/http"

func PlayerServer(w http.ResponseWriter, r *http.Request) {

}
```

코드가 이제 컴파일되고 테스트가 실패합니다

```
=== RUN   TestGETPlayers/returns_Pepper's_score
    --- FAIL: TestGETPlayers/returns_Pepper's_score (0.00s)
        server_test.go:20: got '', want '20'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

DI 챕터에서 `Greet` 함수로 HTTP 서버를 다뤘습니다. net/http의 `ResponseWriter`도 io `Writer`를 구현하므로 `fmt.Fprint`를 사용하여 문자열을 HTTP 응답으로 보낼 수 있다는 것을 배웠습니다.

```go
func PlayerServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "20")
}
```

테스트가 이제 통과해야 합니다.

## 스캐폴딩 완료

이것을 애플리케이션에 연결하고 싶습니다. 이것이 중요한 이유는

-   _실제로 작동하는 소프트웨어_를 가질 것이며, 테스트를 위해 테스트를 작성하는 것이 아니라 코드가 실제로 작동하는 것을 보는 것이 좋습니다.
-   코드를 리팩토링할 때 프로그램의 구조를 변경할 가능성이 있습니다. 점진적 접근 방식의 일부로 애플리케이션에도 반영되도록 하고 싶습니다.

애플리케이션을 위한 새 `main.go` 파일을 만들고 이 코드를 넣습니다

```go
package main

import (
	"log"
	"net/http"
)

func main() {
	handler := http.HandlerFunc(PlayerServer)
	log.Fatal(http.ListenAndServe(":5000", handler))
}
```

지금까지 모든 애플리케이션 코드가 하나의 파일에 있었지만, 더 큰 프로젝트에서는 다른 파일로 분리하는 것이 가장 좋은 방법입니다.

이것을 실행하려면 디렉토리의 모든 `.go` 파일을 가져와서 프로그램을 빌드하는 `go build`를 수행합니다. 그런 다음 `./myprogram`으로 실행할 수 있습니다.

### `http.HandlerFunc`

앞서 서버를 만들기 위해 구현해야 하는 것이 `Handler` 인터페이스라는 것을 탐구했습니다. _일반적으로_ `struct`를 만들고 자체 ServeHTTP 메서드를 구현하여 인터페이스를 구현합니다. 그러나 struct의 사용 사례는 데이터를 보유하는 것이지만 _현재_ 상태가 없으므로 구조체를 만드는 것이 옳지 않은 것 같습니다.

[HandlerFunc](https://golang.org/pkg/net/http/#HandlerFunc)는 이를 피할 수 있게 해줍니다.

> HandlerFunc 타입은 일반 함수를 HTTP 핸들러로 사용할 수 있게 해주는 어댑터입니다. f가 적절한 시그니처를 가진 함수라면 HandlerFunc(f)는 f를 호출하는 Handler입니다.

```go
type HandlerFunc func(ResponseWriter, *Request)
```

문서에서 `HandlerFunc` 타입이 이미 `ServeHTTP` 메서드를 구현했음을 알 수 있습니다.
`PlayerServer` 함수를 타입 캐스팅함으로써 이제 필요한 `Handler`를 구현했습니다.

### `http.ListenAndServe(":5000"...)`

`ListenAndServe`는 `Handler`에서 수신할 포트를 받습니다. 문제가 있으면 웹 서버는 오류를 반환합니다. 예를 들어 포트가 이미 수신 중일 수 있습니다. 그렇기 때문에 사용자에게 오류를 로깅하기 위해 호출을 `log.Fatal`로 감쌉니다.

이제 우리가 할 것은 하드코딩된 값에서 벗어나려는 긍정적인 변화를 강제하기 위해 _또 다른_ 테스트를 작성하는 것입니다.

## 먼저 테스트 작성

하드코딩된 접근 방식을 깨뜨릴 다른 플레이어의 점수를 얻으려는 또 다른 서브테스트를 스위트에 추가할 것입니다.

```go
t.Run("returns Floyd's score", func(t *testing.T) {
	request, _ := http.NewRequest(http.MethodGet, "/players/Floyd", nil)
	response := httptest.NewRecorder()

	PlayerServer(response, request)

	got := response.Body.String()
	want := "10"

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
})
```

생각하셨을 수 있습니다

> 분명히 어떤 플레이어가 어떤 점수를 얻는지 제어하기 위해 일종의 스토리지 개념이 필요합니다. 테스트에서 값이 너무 임의적인 것 같아 이상합니다.

지금은 상수를 깨려고 하는 것뿐이므로 합리적으로 가능한 한 작은 단계를 밟으려고 합니다.

## 테스트 실행 시도

```
=== RUN   TestGETPlayers/returns_Pepper's_score
    --- PASS: TestGETPlayers/returns_Pepper's_score (0.00s)
=== RUN   TestGETPlayers/returns_Floyd's_score
    --- FAIL: TestGETPlayers/returns_Floyd's_score (0.00s)
        server_test.go:34: got '20', want '10'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
//server.go
func PlayerServer(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	if player == "Pepper" {
		fmt.Fprint(w, "20")
		return
	}

	if player == "Floyd" {
		fmt.Fprint(w, "10")
		return
	}
}
```

이 테스트는 실제로 요청의 URL을 보고 결정을 내리도록 강제했습니다. 그래서 머릿속에서 플레이어 스토어와 인터페이스에 대해 걱정하고 있었을 수 있지만 다음 논리적 단계는 실제로 _라우팅_에 관한 것 같습니다.

스토어 코드로 시작했다면 변경해야 할 양이 이것에 비해 매우 클 것입니다. **이것은 최종 목표를 향한 더 작은 단계이며 테스트에 의해 주도되었습니다**.

지금은 라우팅 라이브러리를 사용하려는 유혹에 저항하고 있습니다. 테스트를 통과시키기 위한 가장 작은 단계만요.

`r.URL.Path`는 요청 경로를 반환하며, [`strings.TrimPrefix`](https://golang.org/pkg/strings/#TrimPrefix)를 사용하여 `/players/`를 잘라 요청된 플레이어를 얻을 수 있습니다. 매우 강력하지는 않지만 현재로서는 트릭을 수행할 것입니다.

## 리팩토링

점수 검색을 함수로 분리하여 `PlayerServer`를 단순화할 수 있습니다

```go
//server.go
func PlayerServer(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	fmt.Fprint(w, GetPlayerScore(player))
}

func GetPlayerScore(name string) string {
	if name == "Pepper" {
		return "20"
	}

	if name == "Floyd" {
		return "10"
	}

	return ""
}
```

그리고 헬퍼를 만들어 테스트에서 일부 코드를 DRY할 수 있습니다

```go
//server_test.go
func TestGETPlayers(t *testing.T) {
	t.Run("returns Pepper's score", func(t *testing.T) {
		request := newGetScoreRequest("Pepper")
		response := httptest.NewRecorder()

		PlayerServer(response, request)

		assertResponseBody(t, response.Body.String(), "20")
	})

	t.Run("returns Floyd's score", func(t *testing.T) {
		request := newGetScoreRequest("Floyd")
		response := httptest.NewRecorder()

		PlayerServer(response, request)

		assertResponseBody(t, response.Body.String(), "10")
	})
}

func newGetScoreRequest(name string) *http.Request {
	req, _ := http.NewRequest(http.MethodGet, fmt.Sprintf("/players/%s", name), nil)
	return req
}

func assertResponseBody(t testing.TB, got, want string) {
	t.Helper()
	if got != want {
		t.Errorf("response body is wrong, got %q want %q", got, want)
	}
}
```

하지만 아직 만족해서는 안 됩니다. 서버가 점수를 아는 것이 옳지 않은 것 같습니다.

리팩토링을 통해 무엇을 해야 할지 매우 명확해졌습니다.

점수 계산을 핸들러의 메인 본문에서 `GetPlayerScore` 함수로 이동했습니다. 이것은 인터페이스를 사용하여 관심사를 분리하기에 적합한 장소인 것 같습니다.

리팩토링한 함수를 인터페이스로 이동합시다

```go
type PlayerStore interface {
	GetPlayerScore(name string) int
}
```

`PlayerServer`가 `PlayerStore`를 사용할 수 있으려면 하나에 대한 참조가 필요합니다. 이제 아키텍처를 변경하여 `PlayerServer`가 이제 `struct`가 되도록 할 때가 된 것 같습니다.

```go
type PlayerServer struct {
	store PlayerStore
}
```

마지막으로 새 구조체에 메서드를 추가하고 기존 핸들러 코드를 넣어 `Handler` 인터페이스를 구현합니다.

```go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")
	fmt.Fprint(w, p.store.GetPlayerScore(player))
}
```

유일한 다른 변경 사항은 이제 정의한 로컬 함수(이제 삭제할 수 있음) 대신 `store.GetPlayerScore`를 호출하여 점수를 얻는 것입니다.

서버의 전체 코드 목록입니다

```go
//server.go
type PlayerStore interface {
	GetPlayerScore(name string) int
}

type PlayerServer struct {
	store PlayerStore
}

func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")
	fmt.Fprint(w, p.store.GetPlayerScore(player))
}
```

### 문제 해결

이것은 꽤 많은 변경이었고 테스트와 애플리케이션이 더 이상 컴파일되지 않을 것이라는 것을 알고 있지만, 긴장을 풀고 컴파일러가 처리하도록 하세요.

`./main.go:9:58: type PlayerServer is not an expression`

`PlayerServer`의 새 인스턴스를 만든 다음 해당 `ServeHTTP` 메서드를 호출하도록 테스트를 변경해야 합니다.

```go
//server_test.go
func TestGETPlayers(t *testing.T) {
	server := &PlayerServer{}

	t.Run("returns Pepper's score", func(t *testing.T) {
		request := newGetScoreRequest("Pepper")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertResponseBody(t, response.Body.String(), "20")
	})

	t.Run("returns Floyd's score", func(t *testing.T) {
		request := newGetScoreRequest("Floyd")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertResponseBody(t, response.Body.String(), "10")
	})
}
```

아직 스토어에 대해 걱정하지 않고 가능한 한 빨리 컴파일러를 통과시키고 싶습니다.

컴파일되고 테스트가 통과하는 코드를 우선시하는 습관을 가져야 합니다.

코드가 컴파일되지 않는 동안 더 많은 기능(스텁 스토어 등)을 추가하면 잠재적으로 _더 많은_ 컴파일 문제에 노출될 수 있습니다.

이제 같은 이유로 `main.go`가 컴파일되지 않습니다.

```go
func main() {
	server := &PlayerServer{}
	log.Fatal(http.ListenAndServe(":5000", server))
}
```

마침내 모든 것이 컴파일되지만 테스트가 실패합니다

```
=== RUN   TestGETPlayers/returns_the_Pepper's_score
panic: runtime error: invalid memory address or nil pointer dereference [recovered]
    panic: runtime error: invalid memory address or nil pointer dereference
```

이는 테스트에서 `PlayerStore`를 전달하지 않았기 때문입니다. 스텁을 만들어야 합니다.

```go
//server_test.go
type StubPlayerStore struct {
	scores map[string]int
}

func (s *StubPlayerStore) GetPlayerScore(name string) int {
	score := s.scores[name]
	return score
}
```

`map`은 테스트를 위한 스텁 키/값 스토어를 만드는 빠르고 쉬운 방법입니다. 이제 테스트를 위해 이러한 스토어 중 하나를 만들고 `PlayerServer`로 보냅시다.

```go
//server_test.go
func TestGETPlayers(t *testing.T) {
	store := StubPlayerStore{
		map[string]int{
			"Pepper": 20,
			"Floyd":  10,
		},
	}
	server := &PlayerServer{&store}

	t.Run("returns Pepper's score", func(t *testing.T) {
		request := newGetScoreRequest("Pepper")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertResponseBody(t, response.Body.String(), "20")
	})

	t.Run("returns Floyd's score", func(t *testing.T) {
		request := newGetScoreRequest("Floyd")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertResponseBody(t, response.Body.String(), "10")
	})
}
```

테스트가 이제 통과하고 더 좋아 보입니다. 스토어 도입으로 인해 코드의 _의도_가 이제 더 명확해졌습니다. `PlayerStore`에 _이 데이터가 있으므로_ `PlayerServer`와 함께 사용하면 다음 응답을 받을 것이라고 독자에게 말하고 있습니다.

### 애플리케이션 실행

이제 테스트가 통과하므로 이 리팩토링을 완료하기 위해 마지막으로 해야 할 일은 애플리케이션이 작동하는지 확인하는 것입니다. 프로그램은 시작되어야 하지만 `http://localhost:5000/players/Pepper`에서 서버에 도달하려고 하면 끔찍한 응답을 받게 됩니다.

이유는 `PlayerStore`를 전달하지 않았기 때문입니다.

하나의 구현을 만들어야 하지만 현재는 의미 있는 데이터를 저장하지 않으므로 당분간 하드코딩해야 합니다.

```go
//main.go
type InMemoryPlayerStore struct{}

func (i *InMemoryPlayerStore) GetPlayerScore(name string) int {
	return 123
}

func main() {
	server := &PlayerServer{&InMemoryPlayerStore{}}
	log.Fatal(http.ListenAndServe(":5000", server))
}
```

`go build`를 다시 실행하고 동일한 URL에 도달하면 `"123"`을 얻어야 합니다. 좋지는 않지만 데이터를 저장할 때까지는 최선입니다.
또한 메인 애플리케이션이 시작되었지만 실제로 작동하지 않는다는 것이 좋지 않았습니다. 문제를 확인하려면 수동으로 테스트해야 했습니다.

다음에 할 수 있는 몇 가지 옵션이 있습니다

-   플레이어가 존재하지 않는 시나리오 처리
-   `POST /players/{name}` 시나리오 처리

`POST` 시나리오가 "해피 패스"에 더 가깝지만 이미 해당 컨텍스트에 있으므로 누락된 플레이어 시나리오를 먼저 다루는 것이 더 쉬울 것 같습니다. 나머지는 나중에 하겠습니다.

## 먼저 테스트 작성

기존 스위트에 누락된 플레이어 시나리오를 추가합니다

```go
//server_test.go
t.Run("returns 404 on missing players", func(t *testing.T) {
	request := newGetScoreRequest("Apollo")
	response := httptest.NewRecorder()

	server.ServeHTTP(response, request)

	got := response.Code
	want := http.StatusNotFound

	if got != want {
		t.Errorf("got status %d want %d", got, want)
	}
})
```

## 테스트 실행 시도

```
=== RUN   TestGETPlayers/returns_404_on_missing_players
    --- FAIL: TestGETPlayers/returns_404_on_missing_players (0.00s)
        server_test.go:56: got status 200 want 404
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
//server.go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	w.WriteHeader(http.StatusNotFound)

	fmt.Fprint(w, p.store.GetPlayerScore(player))
}
```

때때로 TDD 지지자들이 "통과하게 만드는 최소한의 코드만 작성하세요"라고 말할 때 매우 현학적으로 느껴져서 눈을 굴립니다.

하지만 이 시나리오는 예를 잘 보여줍니다. 저는 (올바르지 않다는 것을 알면서) 최소한만 했는데, **모든 응답**에 `StatusNotFound`를 쓰지만 모든 테스트가 통과합니다!

**테스트를 통과시키기 위해 최소한만 함으로써 테스트의 간격을 강조할 수 있습니다**. 우리의 경우 플레이어가 스토어에 _있을 때_ `StatusOK`를 받아야 한다고 어설션하지 않습니다.

상태에 대해 어설션하고 코드를 수정하도록 다른 두 테스트를 업데이트하세요.

다음은 새 테스트입니다

```go
//server_test.go
func TestGETPlayers(t *testing.T) {
	store := StubPlayerStore{
		map[string]int{
			"Pepper": 20,
			"Floyd":  10,
		},
	}
	server := &PlayerServer{&store}

	t.Run("returns Pepper's score", func(t *testing.T) {
		request := newGetScoreRequest("Pepper")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusOK)
		assertResponseBody(t, response.Body.String(), "20")
	})

	t.Run("returns Floyd's score", func(t *testing.T) {
		request := newGetScoreRequest("Floyd")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusOK)
		assertResponseBody(t, response.Body.String(), "10")
	})

	t.Run("returns 404 on missing players", func(t *testing.T) {
		request := newGetScoreRequest("Apollo")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusNotFound)
	})
}

func assertStatus(t testing.TB, got, want int) {
	t.Helper()
	if got != want {
		t.Errorf("did not get correct status, got %d, want %d", got, want)
	}
}

func newGetScoreRequest(name string) *http.Request {
	req, _ := http.NewRequest(http.MethodGet, fmt.Sprintf("/players/%s", name), nil)
	return req
}

func assertResponseBody(t testing.TB, got, want string) {
	t.Helper()
	if got != want {
		t.Errorf("response body is wrong, got %q want %q", got, want)
	}
}
```

이제 모든 테스트에서 상태를 확인하므로 이를 용이하게 하기 위해 `assertStatus` 헬퍼를 만들었습니다.

이제 처음 두 테스트가 200 대신 404 때문에 실패하므로 점수가 0이면 찾을 수 없음만 반환하도록 `PlayerServer`를 수정할 수 있습니다.

```go
//server.go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	score := p.store.GetPlayerScore(player)

	if score == 0 {
		w.WriteHeader(http.StatusNotFound)
	}

	fmt.Fprint(w, score)
}
```

### 점수 저장

이제 스토어에서 점수를 검색할 수 있으므로 새 점수를 저장할 수 있는 것이 합리적입니다.

## 먼저 테스트 작성

```go
//server_test.go
func TestStoreWins(t *testing.T) {
	store := StubPlayerStore{
		map[string]int{},
	}
	server := &PlayerServer{&store}

	t.Run("it returns accepted on POST", func(t *testing.T) {
		request, _ := http.NewRequest(http.MethodPost, "/players/Pepper", nil)
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusAccepted)
	})
}
```

먼저 POST로 특정 라우트에 도달하면 올바른 상태 코드를 얻는지 확인합니다. 이를 통해 다른 종류의 요청을 수락하고 `GET /players/{name}`과 다르게 처리하는 기능을 도출할 수 있습니다. 이것이 작동하면 핸들러와 스토어의 상호 작용에 대해 어설션할 수 있습니다.

## 테스트 실행 시도

```
=== RUN   TestStoreWins/it_returns_accepted_on_POST
    --- FAIL: TestStoreWins/it_returns_accepted_on_POST (0.00s)
        server_test.go:70: did not get correct status, got 404, want 202
```

## 테스트를 통과시키기 위한 충분한 코드 작성

의도적으로 죄를 저지르고 있으므로 요청 메서드에 기반한 `if` 문이 트릭을 수행할 것입니다.

```go
//server.go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	if r.Method == http.MethodPost {
		w.WriteHeader(http.StatusAccepted)
		return
	}

	player := strings.TrimPrefix(r.URL.Path, "/players/")

	score := p.store.GetPlayerScore(player)

	if score == 0 {
		w.WriteHeader(http.StatusNotFound)
	}

	fmt.Fprint(w, score)
}
```

## 리팩토링

핸들러가 약간 복잡해 보입니다. 다른 기능을 새 함수로 분리하여 따르기 쉽게 만들어 봅시다.

```go
//server.go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	switch r.Method {
	case http.MethodPost:
		p.processWin(w)
	case http.MethodGet:
		p.showScore(w, r)
	}

}

func (p *PlayerServer) showScore(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	score := p.store.GetPlayerScore(player)

	if score == 0 {
		w.WriteHeader(http.StatusNotFound)
	}

	fmt.Fprint(w, score)
}

func (p *PlayerServer) processWin(w http.ResponseWriter) {
	w.WriteHeader(http.StatusAccepted)
}
```

이렇게 하면 `ServeHTTP`의 라우팅 측면이 좀 더 명확해지고 저장에 대한 다음 반복은 `processWin` 내부에서만 할 수 있습니다.

다음으로 `POST /players/{name}`을 수행할 때 `PlayerStore`에 승리를 기록하라고 알리는지 확인하고 싶습니다.

## 먼저 테스트 작성

`StubPlayerStore`를 새로운 `RecordWin` 메서드로 확장한 다음 호출을 스파이할 수 있습니다.

```go
//server_test.go
type StubPlayerStore struct {
	scores   map[string]int
	winCalls []string
}

func (s *StubPlayerStore) GetPlayerScore(name string) int {
	score := s.scores[name]
	return score
}

func (s *StubPlayerStore) RecordWin(name string) {
	s.winCalls = append(s.winCalls, name)
}
```

이제 먼저 호출 횟수를 확인하도록 테스트를 확장합니다

```go
//server_test.go
func TestStoreWins(t *testing.T) {
	store := StubPlayerStore{
		map[string]int{},
	}
	server := &PlayerServer{&store}

	t.Run("it records wins when POST", func(t *testing.T) {
		request := newPostWinRequest("Pepper")
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusAccepted)

		if len(store.winCalls) != 1 {
			t.Errorf("got %d calls to RecordWin want %d", len(store.winCalls), 1)
		}
	})
}

func newPostWinRequest(name string) *http.Request {
	req, _ := http.NewRequest(http.MethodPost, fmt.Sprintf("/players/%s", name), nil)
	return req
}
```

## 테스트 실행 시도

```
./server_test.go:26:20: too few values in struct initializer
./server_test.go:65:20: too few values in struct initializer
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

새 필드를 추가했으므로 `StubPlayerStore`를 만드는 코드를 업데이트해야 합니다

```go
//server_test.go
store := StubPlayerStore{
	map[string]int{},
	nil,
}
```

```
--- FAIL: TestStoreWins (0.00s)
    --- FAIL: TestStoreWins/it_records_wins_when_POST (0.00s)
        server_test.go:80: got 0 calls to RecordWin want 1
```

## 테스트를 통과시키기 위한 충분한 코드 작성

특정 값보다 호출 횟수만 어설션하므로 초기 반복이 약간 더 작습니다.

`RecordWin`을 호출하려면 `PlayerStore`가 무엇인지에 대한 `PlayerServer`의 아이디어를 인터페이스를 변경하여 업데이트해야 합니다.

```go
//server.go
type PlayerStore interface {
	GetPlayerScore(name string) int
	RecordWin(name string)
}
```

이렇게 하면 `main`이 더 이상 컴파일되지 않습니다

```
./main.go:17:46: cannot use InMemoryPlayerStore literal (type *InMemoryPlayerStore) as type PlayerStore in field value:
    *InMemoryPlayerStore does not implement PlayerStore (missing RecordWin method)
```

컴파일러가 무엇이 잘못되었는지 알려줍니다. `InMemoryPlayerStore`가 해당 메서드를 갖도록 업데이트합시다.

```go
//main.go
type InMemoryPlayerStore struct{}

func (i *InMemoryPlayerStore) RecordWin(name string) {}
```

테스트를 실행하면 컴파일되는 코드로 돌아가야 합니다 - 하지만 테스트는 여전히 실패합니다.

이제 `PlayerStore`에 `RecordWin`이 있으므로 `PlayerServer` 내에서 호출할 수 있습니다

```go
//server.go
func (p *PlayerServer) processWin(w http.ResponseWriter) {
	p.store.RecordWin("Bob")
	w.WriteHeader(http.StatusAccepted)
}
```

테스트를 실행하면 통과해야 합니다! 분명히 `"Bob"`은 `RecordWin`에 보내고 싶은 것이 아니므로 테스트를 더 세분화합시다.

## 먼저 테스트 작성

```go
//server_test.go
func TestStoreWins(t *testing.T) {
	store := StubPlayerStore{
		map[string]int{},
		nil,
	}
	server := &PlayerServer{&store}

	t.Run("it records wins on POST", func(t *testing.T) {
		player := "Pepper"

		request := newPostWinRequest(player)
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusAccepted)

		if len(store.winCalls) != 1 {
			t.Fatalf("got %d calls to RecordWin want %d", len(store.winCalls), 1)
		}

		if store.winCalls[0] != player {
			t.Errorf("did not store correct winner got %q want %q", store.winCalls[0], player)
		}
	})
}
```

이제 `winCalls` 슬라이스에 하나의 요소가 있다는 것을 알고 있으므로 첫 번째 요소를 안전하게 참조하고 `player`와 같은지 확인할 수 있습니다.

## 테스트 실행 시도

```
=== RUN   TestStoreWins/it_records_wins_on_POST
    --- FAIL: TestStoreWins/it_records_wins_on_POST (0.00s)
        server_test.go:86: did not store correct winner got 'Bob' want 'Pepper'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
//server.go
func (p *PlayerServer) processWin(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")
	p.store.RecordWin(player)
	w.WriteHeader(http.StatusAccepted)
}
```

플레이어 이름을 추출하기 위해 URL을 볼 수 있도록 `processWin`이 `http.Request`를 받도록 변경했습니다. 그것이 있으면 올바른 값으로 `store`를 호출하여 테스트를 통과시킬 수 있습니다.

## 리팩토링

두 곳에서 같은 방식으로 플레이어 이름을 추출하므로 이 코드를 DRY할 수 있습니다

```go
//server.go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	switch r.Method {
	case http.MethodPost:
		p.processWin(w, player)
	case http.MethodGet:
		p.showScore(w, player)
	}
}

func (p *PlayerServer) showScore(w http.ResponseWriter, player string) {
	score := p.store.GetPlayerScore(player)

	if score == 0 {
		w.WriteHeader(http.StatusNotFound)
	}

	fmt.Fprint(w, score)
}

func (p *PlayerServer) processWin(w http.ResponseWriter, player string) {
	p.store.RecordWin(player)
	w.WriteHeader(http.StatusAccepted)
}
```

테스트가 통과하더라도 실제로 작동하는 소프트웨어가 없습니다. `main`을 실행하고 의도한 대로 소프트웨어를 사용하려고 하면 `PlayerStore`를 올바르게 구현하지 않았기 때문에 작동하지 않습니다. 하지만 괜찮습니다; 핸들러에 집중함으로써 미리 설계하려고 하지 않고 필요한 인터페이스를 식별했습니다.

`InMemoryPlayerStore` 주변에 몇 가지 테스트를 작성하기 _시작할 수_ 있지만 플레이어 점수를 유지하는 더 강력한 방법(즉, 데이터베이스)을 구현할 때까지 일시적으로만 여기에 있습니다.

현재 우리가 할 것은 `PlayerServer`와 `InMemoryPlayerStore` 사이의 _통합 테스트_를 작성하여 기능을 완료하는 것입니다. 이렇게 하면 `InMemoryPlayerStore`를 직접 테스트하지 않고도 애플리케이션이 작동한다고 확신할 수 있습니다. 뿐만 아니라 데이터베이스로 `PlayerStore`를 구현할 때 동일한 통합 테스트로 해당 구현을 테스트할 수 있습니다.

### 통합 테스트

통합 테스트는 시스템의 더 큰 영역이 작동하는지 테스트하는 데 유용할 수 있지만 다음을 염두에 두어야 합니다:

-   작성하기 어렵습니다
-   실패하면 왜 그런지 알기 어려울 수 있고(보통 통합 테스트의 구성 요소 내의 버그) 수정하기 어려울 수 있습니다
-   때때로 실행 속도가 느립니다(데이터베이스와 같은 "실제" 구성 요소와 함께 사용되는 경우가 많기 때문)

이러한 이유로 _테스트 피라미드_를 연구하는 것이 좋습니다.

## 먼저 테스트 작성

간결성을 위해 최종 리팩토링된 통합 테스트를 보여 드리겠습니다.

```go
// server_integration_test.go
package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRecordingWinsAndRetrievingThem(t *testing.T) {
	store := InMemoryPlayerStore{}
	server := PlayerServer{&store}
	player := "Pepper"

	server.ServeHTTP(httptest.NewRecorder(), newPostWinRequest(player))
	server.ServeHTTP(httptest.NewRecorder(), newPostWinRequest(player))
	server.ServeHTTP(httptest.NewRecorder(), newPostWinRequest(player))

	response := httptest.NewRecorder()
	server.ServeHTTP(response, newGetScoreRequest(player))
	assertStatus(t, response.Code, http.StatusOK)

	assertResponseBody(t, response.Body.String(), "3")
}
```

-   통합하려는 두 구성 요소를 만들고 있습니다: `InMemoryPlayerStore`와 `PlayerServer`.
-   그런 다음 `player`에 대한 3개의 승리를 기록하기 위해 3개의 요청을 보냅니다. 잘 통합되는지 여부와 관련이 없으므로 이 테스트에서는 상태 코드에 대해 너무 걱정하지 않습니다.
-   `player`의 점수를 얻으려고 하므로 다음 응답은 신경 씁니다(변수 `response`에 저장).

## 테스트 실행 시도

```
--- FAIL: TestRecordingWinsAndRetrievingThem (0.00s)
    server_integration_test.go:24: response body is wrong, got '123' want '3'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

여기서 몇 가지 자유를 취하고 테스트 없이 더 많은 코드를 작성하겠습니다.

_이것은 허용됩니다!_ 여전히 올바르게 작동해야 하는 것을 확인하는 테스트가 있지만 작업 중인 특정 단위(`InMemoryPlayerStore`)를 중심으로 하지 않습니다.

이 시나리오에서 막히면 실패하는 테스트로 변경 사항을 되돌리고 솔루션을 도출하는 데 도움이 되도록 `InMemoryPlayerStore` 주변에 더 구체적인 단위 테스트를 작성할 것입니다.

```go
//in_memory_player_store.go
func NewInMemoryPlayerStore() *InMemoryPlayerStore {
	return &InMemoryPlayerStore{map[string]int{}}
}

type InMemoryPlayerStore struct {
	store map[string]int
}

func (i *InMemoryPlayerStore) RecordWin(name string) {
	i.store[name]++
}

func (i *InMemoryPlayerStore) GetPlayerScore(name string) int {
	return i.store[name]
}
```

-   데이터를 저장해야 하므로 `InMemoryPlayerStore` 구조체에 `map[string]int`를 추가했습니다
-   편의를 위해 스토어를 초기화하는 `NewInMemoryPlayerStore`를 만들고 통합 테스트를 업데이트하여 사용합니다:
    ```go
    //server_integration_test.go
    store := NewInMemoryPlayerStore()
    server := PlayerServer{store}
    ```
-   나머지 코드는 `map`을 감싸는 것입니다

통합 테스트가 통과합니다. 이제 `NewInMemoryPlayerStore()`를 사용하도록 `main`을 변경하면 됩니다

```go
// main.go
package main

import (
	"log"
	"net/http"
)

func main() {
	server := &PlayerServer{NewInMemoryPlayerStore()}
	log.Fatal(http.ListenAndServe(":5000", server))
}
```

빌드하고 실행한 다음 `curl`을 사용하여 테스트합니다.

-   이것을 몇 번 실행하고 원하면 플레이어 이름을 변경합니다 `curl -X POST http://localhost:5000/players/Pepper`
-   `curl http://localhost:5000/players/Pepper`로 점수를 확인합니다

좋습니다! REST-ish 서비스를 만들었습니다. 이것을 더 발전시키려면 프로그램이 실행되는 시간보다 더 오래 점수를 유지하기 위한 데이터 스토어를 선택해야 합니다.

-   스토어를 선택합니다 (Bolt? Mongo? Postgres? 파일 시스템?)
-   `PostgresPlayerStore`가 `PlayerStore`를 구현하도록 만듭니다
-   작동하는지 확인하기 위해 기능을 TDD합니다
-   통합 테스트에 연결하고 여전히 괜찮은지 확인합니다
-   마지막으로 `main`에 연결합니다

## 리팩토링

거의 다 왔습니다! 다음과 같은 동시성 오류를 방지하기 위해 약간의 노력을 기울입시다

```
fatal error: concurrent map read and map write
```

뮤텍스를 추가하여 `RecordWin` 함수의 카운터에 대한 동시성 안전을 적용할 수 있습니다. sync 챕터에서 뮤텍스에 대해 자세히 읽어보세요.

## 마무리

### `http.Handler`

-   이 인터페이스를 구현하여 웹 서버를 만듭니다
-   일반 함수를 `http.Handler`로 변환하려면 `http.HandlerFunc`를 사용합니다
-   핸들러가 보내는 응답을 스파이할 수 있도록 `ResponseWriter`로 전달하려면 `httptest.NewRecorder`를 사용합니다
-   시스템에 들어올 것으로 예상되는 요청을 구성하려면 `http.NewRequest`를 사용합니다

### 인터페이스, 모킹 및 DI

-   더 작은 청크로 시스템을 점진적으로 구축할 수 있습니다
-   실제 스토리지 없이 스토리지가 필요한 핸들러를 개발할 수 있습니다
-   필요한 인터페이스를 도출하기 위해 TDD합니다

### 죄를 저지르고 리팩토링합니다 (그런 다음 소스 컨트롤에 커밋합니다)

-   컴파일 실패 또는 테스트 실패를 가능한 한 빨리 벗어나야 하는 빨간색 상황으로 취급해야 합니다.
-   거기에 도달하기 위해 필요한 코드만 작성합니다. _그런 다음_ 리팩토링하고 코드를 멋지게 만듭니다.
-   코드가 컴파일되지 않거나 테스트가 실패하는 동안 너무 많은 변경을 시도하면 문제를 복합적으로 만들 위험이 있습니다.
-   이 접근 방식을 고수하면 작은 테스트를 작성하게 되고, 이는 작은 변경을 의미하므로 복잡한 시스템에서 작업을 관리하기 쉽게 유지하는 데 도움이 됩니다.

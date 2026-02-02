# JSON, 라우팅 & 임베딩

**[이 챕터의 모든 코드는 여기에서 찾을 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/json)**

[이전 챕터](http-server.md)에서 플레이어가 이긴 게임 수를 저장하는 웹 서버를 만들었습니다.

제품 소유자에게 새로운 요구 사항이 있습니다; 저장된 모든 플레이어의 목록을 반환하는 `/league`라는 새로운 엔드포인트입니다. 그녀는 이것이 JSON으로 반환되기를 원합니다.

## 지금까지 가진 코드

```go
// server.go
package main

import (
	"fmt"
	"net/http"
	"strings"
)

type PlayerStore interface {
	GetPlayerScore(name string) int
	RecordWin(name string)
}

type PlayerServer struct {
	store PlayerStore
}

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

```go
// in_memory_player_store.go
package main

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

챕터 상단의 링크에서 해당 테스트를 찾을 수 있습니다.

리그 테이블 엔드포인트를 만드는 것부터 시작하겠습니다.

## 먼저 테스트 작성

유용한 테스트 함수와 사용할 가짜 `PlayerStore`가 있으므로 기존 스위트를 확장합니다.

```go
//server_test.go
func TestLeague(t *testing.T) {
	store := StubPlayerStore{}
	server := &PlayerServer{&store}

	t.Run("it returns 200 on /league", func(t *testing.T) {
		request, _ := http.NewRequest(http.MethodGet, "/league", nil)
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusOK)
	})
}
```

실제 점수와 JSON에 대해 걱정하기 전에 목표를 향해 반복할 계획으로 변경 사항을 작게 유지하려고 합니다. 가장 간단한 시작은 `/league`를 히트하고 `OK`를 돌려받을 수 있는지 확인하는 것입니다.

## 테스트 실행 시도

```
    --- FAIL: TestLeague/it_returns_200_on_/league (0.00s)
        server_test.go:101: status code is wrong: got 404, want 200
FAIL
FAIL	playerstore	0.221s
FAIL
```

`PlayerServer`가 `404 Not Found`를 반환합니다, 마치 알 수 없는 플레이어의 승리를 얻으려는 것처럼. `server.go`가 `ServeHTTP`를 구현하는 방법을 보면 항상 특정 플레이어를 가리키는 URL로 호출된다고 가정합니다:

```go
player := strings.TrimPrefix(r.URL.Path, "/players/")
```

이전 챕터에서 이것이 라우팅을 수행하는 상당히 순진한 방법이라고 언급했습니다. 테스트는 다른 요청 경로를 처리할 개념이 필요하다고 올바르게 알려줍니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

Go에는 특정 요청 경로에 `http.Handler`를 첨부할 수 있는 [`ServeMux`](https://golang.org/pkg/net/http/#ServeMux)(요청 멀티플렉서)라는 내장 라우팅 메커니즘이 있습니다.

죄를 범하고 가능한 가장 빠른 방법으로 테스트를 통과하게 합시다, 테스트가 통과하면 안전하게 리팩토링할 수 있다는 것을 알고 있습니다.

```go
//server.go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	router := http.NewServeMux()

	router.Handle("/league", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	router.Handle("/players/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		player := strings.TrimPrefix(r.URL.Path, "/players/")

		switch r.Method {
		case http.MethodPost:
			p.processWin(w, player)
		case http.MethodGet:
			p.showScore(w, player)
		}
	}))

	router.ServeHTTP(w, r)
}
```

- 요청이 시작되면 라우터를 만들고 `x` 경로에 `y` 핸들러를 사용하라고 말합니다.
- 따라서 새 엔드포인트의 경우 `http.HandlerFunc`와 *익명 함수*를 사용하여 `/league`가 요청될 때 `w.WriteHeader(http.StatusOK)`를 하여 새 테스트를 통과시킵니다.
- `/players/` 경로의 경우 코드를 다른 `http.HandlerFunc`로 잘라서 붙여넣습니다.
- 마지막으로 새 라우터의 `ServeHTTP`를 호출하여 들어온 요청을 처리합니다 (`ServeMux`도 *역시* `http.Handler`인 것에 주목하세요?)

이제 테스트가 통과해야 합니다.

## 리팩토링

`ServeHTTP`가 꽤 커 보입니다, 핸들러를 별도의 메서드로 리팩토링하여 약간 분리할 수 있습니다.

```go
//server.go
func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	router := http.NewServeMux()
	router.Handle("/league", http.HandlerFunc(p.leagueHandler))
	router.Handle("/players/", http.HandlerFunc(p.playersHandler))

	router.ServeHTTP(w, r)
}

func (p *PlayerServer) leagueHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}

func (p *PlayerServer) playersHandler(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	switch r.Method {
	case http.MethodPost:
		p.processWin(w, player)
	case http.MethodGet:
		p.showScore(w, player)
	}
}
```

요청이 들어올 때 라우터를 설정하고 호출하는 것은 꽤 이상하고(비효율적) 합니다. 이상적으로는 종속성을 가져와서 라우터를 만드는 일회성 설정을 수행하는 `NewPlayerServer` 함수가 있었으면 합니다. 그러면 각 요청은 그 라우터의 하나의 인스턴스만 사용할 수 있습니다.

```go
//server.go
type PlayerServer struct {
	store  PlayerStore
	router *http.ServeMux
}

func NewPlayerServer(store PlayerStore) *PlayerServer {
	p := &PlayerServer{
		store,
		http.NewServeMux(),
	}

	p.router.Handle("/league", http.HandlerFunc(p.leagueHandler))
	p.router.Handle("/players/", http.HandlerFunc(p.playersHandler))

	return p
}

func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	p.router.ServeHTTP(w, r)
}
```

- `PlayerServer`는 이제 라우터를 저장해야 합니다.
- 라우팅 생성을 `ServeHTTP`에서 `NewPlayerServer`로 옮겨서 요청마다가 아니라 한 번만 수행하면 됩니다.
- 이전에 `PlayerServer{&store}`를 사용한 모든 테스트와 프로덕션 코드를 `NewPlayerServer(&store)`로 업데이트해야 합니다.

### 마지막 리팩토링

코드를 다음으로 변경해 보세요.

```go
type PlayerServer struct {
	store PlayerStore
	http.Handler
}

func NewPlayerServer(store PlayerStore) *PlayerServer {
	p := new(PlayerServer)

	p.store = store

	router := http.NewServeMux()
	router.Handle("/league", http.HandlerFunc(p.leagueHandler))
	router.Handle("/players/", http.HandlerFunc(p.playersHandler))

	p.Handler = router

	return p
}
```

그런 다음 `server_test.go`, `server_integration_test.go`, `main.go`에서 `server := &PlayerServer{&store}`를 `server := NewPlayerServer(&store)`로 교체합니다.

마지막으로 `func (p *PlayerServer) ServeHTTP(w http.ResponseWriter, r *http.Request)`를 **삭제**하세요. 더 이상 필요하지 않습니다!

## 임베딩

`PlayerServer`의 두 번째 속성을 변경하여 명명된 속성 `router http.ServeMux`를 제거하고 `http.Handler`로 교체했습니다; 이것을 *임베딩*이라고 합니다.

> Go는 전형적인 타입 기반 서브클래싱 개념을 제공하지 않지만 구조체나 인터페이스 내에 타입을 임베딩하여 구현의 일부를 "빌려올" 수 있습니다.

[Effective Go - 임베딩](https://golang.org/doc/effective_go.html#embedding)

이것이 의미하는 것은 `PlayerServer`가 이제 `http.Handler`가 가진 모든 메서드를 가지고 있으며, 이는 `ServeHTTP` 하나입니다.

`http.Handler`를 "채우기"위해 `NewPlayerServer`에서 만든 `router`에 할당합니다. `http.ServeMux`가 `ServeHTTP` 메서드를 가지고 있기 때문에 이렇게 할 수 있습니다.

이렇게 하면 임베딩된 타입을 통해 이미 하나를 노출하고 있으므로 자체 `ServeHTTP` 메서드를 제거할 수 있습니다.

임베딩은 매우 흥미로운 언어 기능입니다. 인터페이스와 함께 사용하여 새 인터페이스를 구성할 수 있습니다.

```go
type Animal interface {
	Eater
	Sleeper
}
```

그리고 인터페이스뿐만 아니라 구체적인 타입에서도 사용할 수 있습니다. 예상대로 구체적인 타입을 임베딩하면 모든 공개 메서드와 필드에 접근할 수 있습니다.

### 단점이 있나요?

모든 공개 메서드와 임베딩하는 타입의 필드가 노출되기 때문에 임베딩 타입에 주의해야 합니다. 우리의 경우 노출하려는 *인터페이스*(`http.Handler`)만 임베딩했기 때문에 괜찮습니다.

게으르게 대신 `http.ServeMux`(구체적인 타입)를 임베딩했다면 여전히 작동*하지만* `PlayerServer` 사용자가 `Handle(path, handler)`이 공개이기 때문에 서버에 새 경로를 추가할 수 있습니다.

**타입을 임베딩할 때 공개 API에 어떤 영향을 미치는지 정말로 생각하세요.**

임베딩을 오용하여 API를 오염시키고 타입의 내부를 노출하는 것은 *매우* 흔한 실수입니다.

이제 애플리케이션을 재구성했으므로 쉽게 새 경로를 추가하고 `/league` 엔드포인트의 시작을 가질 수 있습니다. 이제 유용한 정보를 반환하도록 해야 합니다.

다음과 같은 JSON을 반환해야 합니다.

```json
[
   {
      "Name":"Bill",
      "Wins":10
   },
   {
      "Name":"Alice",
      "Wins":15
   }
]
```

## 먼저 테스트 작성

응답을 의미 있는 것으로 파싱하는 것부터 시작합니다.

```go
//server_test.go
func TestLeague(t *testing.T) {
	store := StubPlayerStore{}
	server := NewPlayerServer(&store)

	t.Run("it returns 200 on /league", func(t *testing.T) {
		request, _ := http.NewRequest(http.MethodGet, "/league", nil)
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		var got []Player

		err := json.NewDecoder(response.Body).Decode(&got)

		if err != nil {
			t.Fatalf("Unable to parse response from server %q into slice of Player, '%v'", response.Body, err)
		}

		assertStatus(t, response.Code, http.StatusOK)
	})
}
```

### 왜 JSON 문자열을 테스트하지 않나요?

더 간단한 초기 단계는 응답 본문이 특정 JSON 문자열을 가지고 있다고 어설션하는 것이라고 주장할 수 있습니다.

제 경험에서 JSON 문자열에 대해 어설션하는 테스트는 다음과 같은 문제가 있습니다.

- *취약성*. 데이터 모델을 변경하면 테스트가 실패합니다.
- *디버그하기 어려움*. 두 JSON 문자열을 비교할 때 실제 문제가 무엇인지 이해하기 어려울 수 있습니다.
- *의도 부족*. 출력이 JSON이어야 하지만 정말 중요한 것은 인코딩 방식이 아니라 정확히 데이터가 무엇인지입니다.
- *표준 라이브러리 재테스트*. 표준 라이브러리가 JSON을 어떻게 출력하는지 테스트할 필요가 없습니다, 이미 테스트되었습니다. 다른 사람의 코드를 테스트하지 마세요.

대신 테스트하는 데 관련된 데이터 구조로 JSON을 파싱해야 합니다.

### 데이터 모델링

JSON 데이터 모델을 볼 때 일부 필드가 있는 `Player` 배열이 필요한 것 같으므로 이를 캡처하기 위해 새 타입을 만들었습니다.

```go
//server.go
type Player struct {
	Name string
	Wins int
}
```

### JSON 디코딩

```go
//server_test.go
var got []Player
err := json.NewDecoder(response.Body).Decode(&got)
```

우리 데이터 모델로 JSON을 파싱하기 위해 `encoding/json` 패키지에서 `Decoder`를 만들고 `Decode` 메서드를 호출합니다. `Decoder`를 만들려면 읽을 `io.Reader`가 필요한데 우리의 경우 응답 spy의 `Body`입니다.

`Decode`는 디코딩하려는 것의 주소를 가져가므로 이전 줄에 빈 `Player` 슬라이스를 선언합니다.

JSON 파싱이 실패할 수 있으므로 `Decode`는 `error`를 반환할 수 있습니다. 실패하면 테스트를 계속할 의미가 없으므로 에러를 확인하고 발생하면 `t.Fatalf`로 테스트를 중지합니다. 파싱할 수 없는 문자열을 테스트를 실행하는 사람이 볼 수 있도록 에러와 함께 응답 본문을 출력합니다.

## 테스트 실행 시도

```
=== RUN   TestLeague/it_returns_200_on_/league
    --- FAIL: TestLeague/it_returns_200_on_/league (0.00s)
        server_test.go:107: Unable to parse response from server '' into slice of Player, 'unexpected end of JSON input'
```

엔드포인트가 현재 본문을 반환하지 않으므로 JSON으로 파싱할 수 없습니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
//server.go
func (p *PlayerServer) leagueHandler(w http.ResponseWriter, r *http.Request) {
	leagueTable := []Player{
		{"Chris", 20},
	}

	json.NewEncoder(w).Encode(leagueTable)

	w.WriteHeader(http.StatusOK)
}
```

이제 테스트가 통과합니다.

### 인코딩과 디코딩

표준 라이브러리의 멋진 대칭성에 주목하세요.

- `Encoder`를 만들려면 `http.ResponseWriter`가 구현하는 `io.Writer`가 필요합니다.
- `Decoder`를 만들려면 응답 spy의 `Body` 필드가 구현하는 `io.Reader`가 필요합니다.

이 책 전체에서 `io.Writer`를 사용했으며 이것은 표준 라이브러리에서의 보편성과 많은 라이브러리가 이를 쉽게 작업할 수 있는 방법의 또 다른 시연입니다.

## 리팩토링

곧 하드코딩하지 않을 것을 알기 때문에 핸들러와 `leagueTable`을 가져오는 것 사이에 관심사의 분리를 도입하면 좋을 것 같습니다.

```go
//server.go
func (p *PlayerServer) leagueHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(p.getLeagueTable())
	w.WriteHeader(http.StatusOK)
}

func (p *PlayerServer) getLeagueTable() []Player {
	return []Player{
		{"Chris", 20},
	}
}
```

다음으로 원하는 데이터를 정확히 제어할 수 있도록 테스트를 확장하고 싶습니다.

## 먼저 테스트 작성

리그 테이블에 스토어에 스텁할 일부 플레이어가 포함되어 있다고 어설션하도록 테스트를 업데이트할 수 있습니다.

리그를 저장하도록 `StubPlayerStore`를 업데이트합니다, 이는 `Player`의 슬라이스입니다. 거기에 예상 데이터를 저장합니다.

```go
//server_test.go
type StubPlayerStore struct {
	scores   map[string]int
	winCalls []string
	league   []Player
}
```

다음으로 스텁의 league 속성에 일부 플레이어를 넣고 서버에서 반환되는지 어설션하여 현재 테스트를 업데이트합니다.

```go
//server_test.go
func TestLeague(t *testing.T) {

	t.Run("it returns the league table as JSON", func(t *testing.T) {
		wantedLeague := []Player{
			{"Cleo", 32},
			{"Chris", 20},
			{"Tiest", 14},
		}

		store := StubPlayerStore{nil, nil, wantedLeague}
		server := NewPlayerServer(&store)

		request, _ := http.NewRequest(http.MethodGet, "/league", nil)
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		var got []Player

		err := json.NewDecoder(response.Body).Decode(&got)

		if err != nil {
			t.Fatalf("Unable to parse response from server %q into slice of Player, '%v'", response.Body, err)
		}

		assertStatus(t, response.Code, http.StatusOK)

		if !reflect.DeepEqual(got, wantedLeague) {
			t.Errorf("got %v want %v", got, wantedLeague)
		}
	})
}
```

## 테스트 실행 시도

```
./server_test.go:33:3: too few values in struct initializer
./server_test.go:70:3: too few values in struct initializer
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

`StubPlayerStore`에 새 필드가 있으므로 다른 테스트를 업데이트해야 합니다; 다른 테스트에서는 nil로 설정합니다.

테스트를 다시 실행하면 다음을 얻어야 합니다

```
=== RUN   TestLeague/it_returns_the_league_table_as_JSON
    --- FAIL: TestLeague/it_returns_the*league_table_as_JSON (0.00s)
        server_test.go:124: got [{Chris 20}] want [{Cleo 32} {Chris 20} {Tiest 14}]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

데이터가 `StubPlayerStore`에 있고 이를 인터페이스 `PlayerStore`로 추상화했습니다. `PlayerStore`를 전달하는 모든 사람이 리그에 대한 데이터를 제공할 수 있도록 업데이트해야 합니다.

```go
//server.go
type PlayerStore interface {
	GetPlayerScore(name string) int
	RecordWin(name string)
	GetLeague() []Player
}
```

이제 하드코딩된 목록을 반환하는 대신 호출하도록 핸들러 코드를 업데이트할 수 있습니다. `getLeagueTable()` 메서드를 삭제하고 `leagueHandler`를 `GetLeague()`를 호출하도록 업데이트합니다.

```go
//server.go
func (p *PlayerServer) leagueHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(p.store.GetLeague())
	w.WriteHeader(http.StatusOK)
}
```

테스트를 실행해 봅시다.

```
# github.com/quii/learn-go-with-tests/json-and-io/v4
./main.go:9:50: cannot use NewInMemoryPlayerStore() (type *InMemoryPlayerStore) as type PlayerStore in argument to NewPlayerServer:
    *InMemoryPlayerStore does not implement PlayerStore (missing GetLeague method)
./server_integration_test.go:11:27: cannot use store (type *InMemoryPlayerStore) as type PlayerStore in argument to NewPlayerServer:
    *InMemoryPlayerStore does not implement PlayerStore (missing GetLeague method)
./server_test.go:36:28: cannot use &store (type *StubPlayerStore) as type PlayerStore in argument to NewPlayerServer:
    *StubPlayerStore does not implement PlayerStore (missing GetLeague method)
./server_test.go:74:28: cannot use &store (type *StubPlayerStore) as type PlayerStore in argument to NewPlayerServer:
    *StubPlayerStore does not implement PlayerStore (missing GetLeague method)
./server_test.go:106:29: cannot use &store (type *StubPlayerStore) as type PlayerStore in argument to NewPlayerServer:
    *StubPlayerStore does not implement PlayerStore (missing GetLeague method)
```

컴파일러가 `InMemoryPlayerStore`와 `StubPlayerStore`에 인터페이스에 추가한 새 메서드가 없기 때문에 불평하고 있습니다.

`StubPlayerStore`의 경우 꽤 쉽습니다, 이전에 추가한 `league` 필드를 반환하면 됩니다.

```go
//server_test.go
func (s *StubPlayerStore) GetLeague() []Player {
	return s.league
}
```

`InMemoryStore`가 어떻게 구현되어 있는지 상기합니다.

```go
//in_memory_player_store.go
type InMemoryPlayerStore struct {
	store map[string]int
}
```

맵을 반복하여 `GetLeague`를 "제대로" 구현하는 것은 꽤 간단하지만 *테스트를 통과시키기 위한 최소한의 코드 작성*이라는 것을 기억하세요.

그래서 지금은 컴파일러를 행복하게 하고 `InMemoryStore`의 불완전한 구현의 불편한 느낌과 함께 살아봅시다.

```go
//in_memory_player_store.go
func (i *InMemoryPlayerStore) GetLeague() []Player {
	return nil
}
```

이것이 실제로 말해주는 것은 *나중에* 이것을 테스트하고 싶다는 것이지만 지금은 보류합시다.

테스트를 실행해보세요, 컴파일러가 통과하고 테스트가 통과해야 합니다!

## 리팩토링

테스트 코드는 의도를 잘 전달하지 않고 리팩토링할 수 있는 많은 보일러플레이트가 있습니다.

```go
//server_test.go
t.Run("it returns the league table as JSON", func(t *testing.T) {
	wantedLeague := []Player{
		{"Cleo", 32},
		{"Chris", 20},
		{"Tiest", 14},
	}

	store := StubPlayerStore{nil, nil, wantedLeague}
	server := NewPlayerServer(&store)

	request := newLeagueRequest()
	response := httptest.NewRecorder()

	server.ServeHTTP(response, request)

	got := getLeagueFromResponse(t, response.Body)
	assertStatus(t, response.Code, http.StatusOK)
	assertLeague(t, got, wantedLeague)
})
```

새 헬퍼들입니다

```go
//server_test.go
func getLeagueFromResponse(t testing.TB, body io.Reader) (league []Player) {
	t.Helper()
	err := json.NewDecoder(body).Decode(&league)

	if err != nil {
		t.Fatalf("Unable to parse response from server %q into slice of Player, '%v'", body, err)
	}

	return
}

func assertLeague(t testing.TB, got, want []Player) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %v want %v", got, want)
	}
}

func newLeagueRequest() *http.Request {
	req, _ := http.NewRequest(http.MethodGet, "/league", nil)
	return req
}
```

서버가 작동하려면 기계가 `JSON`을 반환하고 있다는 것을 인식할 수 있도록 응답에 `content-type` 헤더를 반환해야 합니다.

## 먼저 테스트 작성

기존 테스트에 이 어설션을 추가합니다

```go
//server_test.go
if response.Result().Header.Get("content-type") != "application/json" {
	t.Errorf("response did not have content-type of application/json, got %v", response.Result().Header)
}
```

## 테스트 실행 시도

```
=== RUN   TestLeague/it_returns_the_league_table_as_JSON
    --- FAIL: TestLeague/it_returns_the_league_table_as_JSON (0.00s)
        server_test.go:124: response did not have content-type of application/json, got map[Content-Type:[text/plain; charset=utf-8]]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

`leagueHandler`를 업데이트합니다

```go
//server.go
func (p *PlayerServer) leagueHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	json.NewEncoder(w).Encode(p.store.GetLeague())
}
```

테스트가 통과해야 합니다.

## 리팩토링

"application/json"에 대한 상수를 만들고 `leagueHandler`에서 사용합니다

```go
//server.go
const jsonContentType = "application/json"

func (p *PlayerServer) leagueHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", jsonContentType)
	json.NewEncoder(w).Encode(p.store.GetLeague())
}
```

그런 다음 `assertContentType` 헬퍼를 추가합니다.

```go
//server_test.go
func assertContentType(t testing.TB, response *httptest.ResponseRecorder, want string) {
	t.Helper()
	if response.Result().Header.Get("content-type") != want {
		t.Errorf("response did not have content-type of %s, got %v", want, response.Result().Header)
	}
}
```

테스트에서 사용합니다.

```go
//server_test.go
assertContentType(t, response, jsonContentType)
```

이제 `PlayerServer`를 당분간 정리했으므로 `InMemoryPlayerStore`에 관심을 돌릴 수 있습니다. 지금은 제품 소유자에게 데모하려고 하면 `/league`가 작동하지 않을 것입니다.

자신감을 얻는 가장 빠른 방법은 통합 테스트에 추가하여 새 엔드포인트를 히트하고 `/league`에서 올바른 응답을 받는지 확인하는 것입니다.

## 먼저 테스트 작성

`t.Run`을 사용하여 이 테스트를 약간 분리하고 서버 테스트의 헬퍼를 재사용할 수 있습니다 - 다시 한번 테스트 리팩토링의 중요성을 보여줍니다.

```go
//server_integration_test.go
func TestRecordingWinsAndRetrievingThem(t *testing.T) {
	store := NewInMemoryPlayerStore()
	server := NewPlayerServer(store)
	player := "Pepper"

	server.ServeHTTP(httptest.NewRecorder(), newPostWinRequest(player))
	server.ServeHTTP(httptest.NewRecorder(), newPostWinRequest(player))
	server.ServeHTTP(httptest.NewRecorder(), newPostWinRequest(player))

	t.Run("get score", func(t *testing.T) {
		response := httptest.NewRecorder()
		server.ServeHTTP(response, newGetScoreRequest(player))
		assertStatus(t, response.Code, http.StatusOK)

		assertResponseBody(t, response.Body.String(), "3")
	})

	t.Run("get league", func(t *testing.T) {
		response := httptest.NewRecorder()
		server.ServeHTTP(response, newLeagueRequest())
		assertStatus(t, response.Code, http.StatusOK)

		got := getLeagueFromResponse(t, response.Body)
		want := []Player{
			{"Pepper", 3},
		}
		assertLeague(t, got, want)
	})
}
```

## 테스트 실행 시도

```
=== RUN   TestRecordingWinsAndRetrievingThem/get_league
    --- FAIL: TestRecordingWinsAndRetrievingThem/get_league (0.00s)
        server_integration_test.go:35: got [] want [{Pepper 3}]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

`InMemoryPlayerStore`는 `GetLeague()`를 호출할 때 `nil`을 반환하므로 수정해야 합니다.

```go
//in_memory_player_store.go
func (i *InMemoryPlayerStore) GetLeague() []Player {
	var league []Player
	for name, wins := range i.store {
		league = append(league, Player{name, wins})
	}
	return league
}
```

맵을 반복하고 각 키/값을 `Player`로 변환하면 됩니다.

이제 테스트가 통과해야 합니다.

## 마무리

TDD를 사용하여 프로그램을 계속 안전하게 반복하여 라우터로 유지 관리 가능한 방식으로 새 엔드포인트를 지원하고 이제 소비자를 위해 JSON을 반환할 수 있습니다. 다음 챕터에서는 데이터 지속성과 리그 정렬을 다룹니다.

다룬 내용:

- **라우팅**. 표준 라이브러리는 라우팅을 수행하기 위한 사용하기 쉬운 타입을 제공합니다. `Handler`에 경로를 할당하고 라우터 자체도 `Handler`라는 점에서 `http.Handler` 인터페이스를 완전히 수용합니다. 그러나 경로 변수(예: `/users/{id}`)와 같이 예상할 수 있는 일부 기능은 없습니다. 이 정보를 직접 쉽게 파싱할 수 있지만 부담이 되면 다른 라우팅 라이브러리를 살펴보는 것이 좋습니다. 대부분의 인기 있는 라이브러리는 `http.Handler`를 구현하는 표준 라이브러리의 철학을 고수합니다.
- **타입 임베딩**. 이 기법에 대해 약간 다뤘지만 [Effective Go에서 더 많이 배울 수 있습니다](https://golang.org/doc/effective_go.html#embedding). 이것에서 얻어야 할 한 가지가 있다면 매우 유용할 수 있지만 _항상 공개 API에 대해 생각하고 적절한 것만 노출하세요_.
- **JSON 역직렬화 및 직렬화**. 표준 라이브러리는 데이터를 직렬화하고 역직렬화하는 것을 매우 간단하게 만듭니다. 또한 구성 가능하며 필요한 경우 이러한 데이터 변환이 작동하는 방식을 사용자 정의할 수 있습니다.

# 웹소켓

[**이 챕터의 모든 코드는 여기에서 찾을 수 있습니다**](https://github.com/quii/learn-go-with-tests/tree/main/websockets)

이 챕터에서는 웹소켓을 사용하여 애플리케이션을 개선하는 방법을 배웁니다.

## 프로젝트 요약

포커 코드베이스에 두 개의 애플리케이션이 있습니다

* _커맨드 라인 앱_. 사용자에게 게임에 참여하는 플레이어 수를 입력하도록 프롬프트합니다. 그 후 플레이어에게 시간이 지남에 따라 증가하는 "블라인드 베팅" 값을 알려줍니다. 언제든지 사용자는 `"{플레이어이름} wins"`를 입력하여 게임을 종료하고 승자를 저장소에 기록할 수 있습니다.
* _웹 앱_. 사용자가 게임 승자를 기록하고 리그 테이블을 표시할 수 있습니다. 커맨드 라인 앱과 같은 저장소를 공유합니다.

## 다음 단계

제품 소유자는 커맨드 라인 애플리케이션에 만족하지만 그 기능을 브라우저로 가져올 수 있다면 더 좋겠습니다. 그녀는 사용자가 플레이어 수를 입력할 수 있는 텍스트 상자가 있는 웹 페이지를 상상합니다. 폼을 제출하면 페이지에 블라인드 값이 표시되고 적절할 때 자동으로 업데이트됩니다. 커맨드 라인 애플리케이션처럼 사용자가 승자를 선언하면 데이터베이스에 저장됩니다.

겉으로 보기에는 꽤 간단해 보이지만 항상 그렇듯이 소프트웨어 작성에 _반복적인_ 접근 방식을 취해야 합니다.

먼저 HTML을 제공해야 합니다. 지금까지 모든 HTTP 엔드포인트는 일반 텍스트나 JSON을 반환했습니다. 같은 기술을 사용할 수 _있지만_ (결국 모두 문자열이므로) 더 깔끔한 솔루션을 위해 [html/template](https://golang.org/pkg/html/template/) 패키지도 사용할 수 있습니다.

또한 브라우저를 새로 고치지 않고도 `블라인드는 이제 *y*입니다`라고 사용자에게 비동기적으로 메시지를 보낼 수 있어야 합니다. 이를 용이하게 하기 위해 [웹소켓](https://en.wikipedia.org/wiki/WebSocket)을 사용할 수 있습니다.

> 웹소켓은 단일 TCP 연결을 통해 전이중 통신 채널을 제공하는 컴퓨터 통신 프로토콜입니다

여러 기술을 다루고 있으므로 먼저 가능한 가장 작은 유용한 작업을 수행한 다음 반복하는 것이 훨씬 더 중요합니다.

그런 이유로 가장 먼저 할 일은 사용자가 승자를 기록할 수 있는 폼이 있는 웹 페이지를 만드는 것입니다. 일반 폼을 사용하는 대신 웹소켓을 사용하여 해당 데이터를 서버에 기록하도록 보냅니다.

그 후에 블라인드 알림을 작업하는데 그 시점에는 약간의 인프라 코드가 설정되어 있을 것입니다.

### JavaScript 테스트는?

이것을 하기 위해 약간의 JavaScript가 작성되지만 테스트 작성에 대해서는 다루지 않겠습니다.

물론 가능하지만 간결함을 위해 설명을 포함하지 않겠습니다.

죄송합니다. O'Reilly에 로비해서 "테스트로 JavaScript 배우기"를 만들도록 하세요.

## 먼저 테스트 작성

먼저 해야 할 일은 `/game`에 도달할 때 사용자에게 일부 HTML을 제공하는 것입니다.

웹 서버의 관련 코드를 상기시켜 드립니다

```go
type PlayerServer struct {
	store PlayerStore
	http.Handler
}

const jsonContentType = "application/json"

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

지금 할 수 있는 _가장 쉬운_ 것은 `GET /game`할 때 `200`을 받는지 확인하는 것입니다.

```go
func TestGame(t *testing.T) {
	t.Run("GET /game returns 200", func(t *testing.T) {
		server := NewPlayerServer(&StubPlayerStore{})

		request, _ := http.NewRequest(http.MethodGet, "/game", nil)
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response.Code, http.StatusOK)
	})
}
```

## 테스트 실행 시도

```
--- FAIL: TestGame (0.00s)
=== RUN   TestGame/GET_/game_returns_200
    --- FAIL: TestGame/GET_/game_returns_200 (0.00s)
    	server_test.go:109: did not get correct status, got 404, want 200
```

## 테스트를 통과시키기 위한 충분한 코드 작성

서버에 라우터 설정이 있으므로 수정하기가 비교적 쉽습니다.

라우터에 추가

```go
router.Handle("/game", http.HandlerFunc(p.game))
```

그런 다음 `game` 메서드 작성

```go
func (p *PlayerServer) game(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}
```

## 리팩토링

기존의 잘 구조화된 코드에 더 많은 코드를 쉽게 끼워 넣었기 때문에 서버 코드는 이미 괜찮습니다.

`/game`에 요청을 만드는 테스트 헬퍼 함수 `newGameRequest`를 추가하여 테스트를 약간 정리할 수 있습니다. 직접 작성해 보세요.

```go
func TestGame(t *testing.T) {
	t.Run("GET /game returns 200", func(t *testing.T) {
		server := NewPlayerServer(&StubPlayerStore{})

		request := newGameRequest()
		response := httptest.NewRecorder()

		server.ServeHTTP(response, request)

		assertStatus(t, response, http.StatusOK)
	})
}
```

`response.Code`보다 `response`를 받아들이도록 `assertStatus`를 변경한 것도 알 수 있는데 더 잘 읽힌다고 느꼈기 때문입니다.

이제 엔드포인트가 일부 HTML을 반환하도록 해야 합니다, 여기 있습니다

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Let's play poker</title>
</head>
<body>
<section id="game">
    <div id="declare-winner">
        <label for="winner">Winner</label>
        <input type="text" id="winner"/>
        <button id="winner-button">Declare winner</button>
    </div>
</section>
</body>
<script type="application/javascript">

    const submitWinnerButton = document.getElementById('winner-button')
    const winnerInput = document.getElementById('winner')

    if (window['WebSocket']) {
        const conn = new WebSocket('ws://' + document.location.host + '/ws')

        submitWinnerButton.onclick = event => {
            conn.send(winnerInput.value)
        }
    }
</script>
</html>
```

매우 간단한 웹 페이지가 있습니다

* 사용자가 승자를 입력할 텍스트 입력
* 승자를 선언하기 위해 클릭할 수 있는 버튼
* 서버에 대한 웹소켓 연결을 열고 제출 버튼을 누르는 것을 처리하는 일부 JavaScript

`WebSocket`은 대부분의 최신 브라우저에 내장되어 있으므로 라이브러리를 가져올 필요가 없습니다. 웹 페이지는 이전 브라우저에서 작동하지 않지만 이 시나리오에서는 괜찮습니다.

### 올바른 마크업을 반환하는지 어떻게 테스트합니까?

몇 가지 방법이 있습니다. 책 전체에서 강조했듯이 작성하는 테스트가 비용을 정당화할 충분한 가치가 있는 것이 중요합니다.

1. Selenium과 같은 것을 사용하여 브라우저 기반 테스트를 작성합니다. 이 테스트는 실제 웹 브라우저를 시작하고 사용자가 상호 작용하는 것을 시뮬레이션하기 때문에 모든 접근 방식 중 가장 "현실적"입니다. 이 테스트는 시스템이 작동한다는 많은 확신을 줄 수 있지만 단위 테스트보다 작성하기 어렵고 실행하기가 훨씬 느립니다. 우리 제품의 목적에서 이것은 과잉입니다.
2. 정확한 문자열 일치를 합니다. 이것은 _괜찮을 수_ 있지만 이런 종류의 테스트는 매우 취약해집니다. 누군가가 마크업을 변경하는 순간 실제로 아무것도 _깨지지 않았는데도_ 테스트가 실패하게 됩니다.
3. 올바른 템플릿을 호출하는지 확인합니다. HTML을 생성하기 위해 표준 라이브러리의 템플릿 라이브러리를 사용할 것이고 (곧 논의됩니다) HTML을 생성하는 _것_을 주입하고 올바르게 하고 있는지 확인하기 위해 호출을 스파이할 수 있습니다. 이것은 코드 디자인에 영향을 미치지만 올바른 템플릿 파일로 호출하고 있다는 것 외에는 많이 테스트하지 않습니다. 프로젝트에 하나의 템플릿만 있을 것이므로 실패 가능성은 낮아 보입니다.

그래서 "테스트로 Go 배우기" 책에서 처음으로 테스트를 작성하지 않겠습니다.

마크업을 `game.html`이라는 파일에 넣으세요

다음으로 방금 작성한 엔드포인트를 다음으로 변경합니다

```go
func (p *PlayerServer) game(w http.ResponseWriter, r *http.Request) {
	tmpl, err := template.ParseFiles("game.html")

	if err != nil {
		http.Error(w, fmt.Sprintf("problem loading template %s", err.Error()), http.StatusInternalServerError)
		return
	}

	tmpl.Execute(w, nil)
}
```

[`html/template`](https://golang.org/pkg/html/template/)는 HTML을 만들기 위한 Go 패키지입니다. 우리의 경우 html 파일의 경로를 제공하여 `template.ParseFiles`를 호출합니다. 에러가 없다고 가정하면 템플릿을 `Execute`할 수 있고 `io.Writer`에 씁니다. 우리의 경우 인터넷에 `Write`하고 싶으므로 `http.ResponseWriter`를 제공합니다.

테스트를 작성하지 않았으므로 웹 서버를 수동으로 테스트하여 예상대로 작동하는지 확인하는 것이 신중할 것입니다. `cmd/webserver`로 이동하고 `main.go` 파일을 실행하세요. `http://localhost:5000/game`을 방문하세요.

템플릿을 찾을 수 없다는 에러가 발생했을 _것입니다_. 경로를 폴더에 상대적으로 변경하거나 `cmd/webserver` 디렉토리에 `game.html` 복사본을 둘 수 있습니다. 저는 프로젝트 루트에 있는 파일에 대한 심볼릭 링크(`ln -s ../../game.html game.html`)를 만들어 변경하면 서버를 실행할 때 반영되도록 했습니다.

이 변경을 하고 다시 실행하면 UI를 볼 수 있습니다.

이제 서버에 대한 웹소켓 연결을 통해 문자열을 얻으면 게임의 승자로 선언하는지 테스트해야 합니다.

## 먼저 테스트 작성

처음으로 웹소켓 작업을 할 수 있도록 외부 라이브러리를 사용하겠습니다.

`go get github.com/gorilla/websocket`을 실행하세요

이것은 훌륭한 [Gorilla WebSocket](https://github.com/gorilla/websocket) 라이브러리의 코드를 가져옵니다. 이제 새로운 요구 사항에 대한 테스트를 업데이트할 수 있습니다.

```go
t.Run("when we get a message over a websocket it is a winner of a game", func(t *testing.T) {
	store := &StubPlayerStore{}
	winner := "Ruth"
	server := httptest.NewServer(NewPlayerServer(store))
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/ws"

	ws, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("could not open a ws connection on %s %v", wsURL, err)
	}
	defer ws.Close()

	if err := ws.WriteMessage(websocket.TextMessage, []byte(winner)); err != nil {
		t.Fatalf("could not send message over ws connection %v", err)
	}

	AssertPlayerWin(t, store, winner)
})
```

`websocket` 라이브러리에 대한 import가 있는지 확인하세요. 제 IDE가 자동으로 해줬고 여러분 것도 그래야 합니다.

브라우저에서 무슨 일이 발생하는지 테스트하려면 자체 웹소켓 연결을 열고 쓰기해야 합니다.

서버에 대한 이전 테스트는 서버의 메서드를 호출했지만 이제 서버에 대한 지속적인 연결이 필요합니다. 그렇게 하려면 `http.Handler`를 받아 스핀업하고 연결을 수신하는 `httptest.NewServer`를 사용합니다.

`websocket.DefaultDialer.Dial`을 사용하여 서버에 다이얼하고 `winner`로 메시지를 보내려고 합니다.

마지막으로 승자가 기록되었는지 플레이어 저장소에서 어설션합니다.

## 테스트 실행 시도

```
=== RUN   TestGame/when_we_get_a_message_over_a_websocket_it_is_a_winner_of_a_game
    --- FAIL: TestGame/when_we_get_a_message_over_a_websocket_it_is_a_winner_of_a_game (0.00s)
        server_test.go:124: could not open a ws connection on ws://127.0.0.1:55838/ws websocket: bad handshake
```

`/ws`에서 웹소켓 연결을 수락하도록 서버를 변경하지 않았으므로 아직 핸드셰이크하지 않습니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

라우터에 또 다른 항목 추가

```go
router.Handle("/ws", http.HandlerFunc(p.webSocket))
```

그런 다음 새 `webSocket` 핸들러 추가

```go
func (p *PlayerServer) webSocket(w http.ResponseWriter, r *http.Request) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}
	upgrader.Upgrade(w, r, nil)
}
```

웹소켓 연결을 수락하려면 요청을 `Upgrade`합니다. 이제 테스트를 다시 실행하면 다음 에러로 이동해야 합니다.

```
=== RUN   TestGame/when_we_get_a_message_over_a_websocket_it_is_a_winner_of_a_game
    --- FAIL: TestGame/when_we_get_a_message_over_a_websocket_it_is_a_winner_of_a_game (0.00s)
        server_test.go:132: got 0 calls to RecordWin want 1
```

이제 연결이 열렸으므로 메시지를 수신하고 승자로 기록합니다.

```go
func (p *PlayerServer) webSocket(w http.ResponseWriter, r *http.Request) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}
	conn, _ := upgrader.Upgrade(w, r, nil)
	_, winnerMsg, _ := conn.ReadMessage()
	p.store.RecordWin(string(winnerMsg))
}
```

(예, 지금 많은 에러를 무시하고 있습니다!)

`conn.ReadMessage()`는 연결에서 메시지를 기다리면서 블록합니다. 하나를 받으면 `RecordWin`하는 데 사용합니다. 이것은 마지막으로 웹소켓 연결을 닫습니다.

테스트를 실행하려고 하면 여전히 실패합니다.

문제는 타이밍입니다. 웹소켓 연결이 메시지를 읽고 승리를 기록하는 것과 테스트가 그 전에 끝나는 것 사이에 지연이 있습니다. 최종 어설션 전에 짧은 `time.Sleep`을 넣어 테스트할 수 있습니다.

지금은 그렇게 하되 테스트에 임의의 슬립을 넣는 것은 **매우 나쁜 관행**이라는 것을 인정합니다.

```go
time.Sleep(10 * time.Millisecond)
AssertPlayerWin(t, store, winner)
```

## 리팩토링

이 테스트를 작동시키기 위해 서버 코드와 테스트 코드 모두에서 많은 죄를 저질렀지만 이것이 우리가 작업하는 가장 쉬운 방법이라는 것을 기억하세요.

테스트로 지원되는 불쾌하고 끔찍한 _작동하는_ 소프트웨어가 있으므로 이제 자유롭게 멋지게 만들 수 있고 실수로 아무것도 깨뜨리지 않을 것입니다.

서버 코드부터 시작합시다.

모든 웹소켓 연결 요청에서 다시 선언할 필요가 없으므로 `upgrader`를 패키지 내 비공개 값으로 이동할 수 있습니다

```go
var wsUpgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

func (p *PlayerServer) webSocket(w http.ResponseWriter, r *http.Request) {
	conn, _ := wsUpgrader.Upgrade(w, r, nil)
	_, winnerMsg, _ := conn.ReadMessage()
	p.store.RecordWin(string(winnerMsg))
}
```

`template.ParseFiles("game.html")` 호출은 모든 `GET /game`에서 실행되므로 템플릿을 다시 파싱할 필요가 없는데도 모든 요청에서 파일 시스템에 갑니다. 대신 `NewPlayerServer`에서 템플릿을 한 번 파싱하도록 코드를 리팩토링합시다. 디스크에서 템플릿을 가져오거나 파싱하는 데 문제가 있을 경우 이 함수가 이제 에러를 반환할 수 있도록 해야 합니다.

`PlayerServer`에 대한 관련 변경 사항입니다

```go
type PlayerServer struct {
	store PlayerStore
	http.Handler
	template *template.Template
}

const htmlTemplatePath = "game.html"

func NewPlayerServer(store PlayerStore) (*PlayerServer, error) {
	p := new(PlayerServer)

	tmpl, err := template.ParseFiles(htmlTemplatePath)

	if err != nil {
		return nil, fmt.Errorf("problem opening %s %v", htmlTemplatePath, err)
	}

	p.template = tmpl
	p.store = store

	router := http.NewServeMux()
	router.Handle("/league", http.HandlerFunc(p.leagueHandler))
	router.Handle("/players/", http.HandlerFunc(p.playersHandler))
	router.Handle("/game", http.HandlerFunc(p.game))
	router.Handle("/ws", http.HandlerFunc(p.webSocket))

	p.Handler = router

	return p, nil
}

func (p *PlayerServer) game(w http.ResponseWriter, r *http.Request) {
	p.template.Execute(w, nil)
}
```

`NewPlayerServer`의 시그니처를 변경하면 이제 컴파일 문제가 있습니다. 직접 수정하거나 어려우면 소스 코드를 참조하세요.

테스트 코드의 경우 테스트에서 에러 노이즈를 숨길 수 있도록 `mustMakePlayerServer(t *testing.T, store PlayerStore) *PlayerServer`라는 헬퍼를 만들었습니다.

```go
func mustMakePlayerServer(t *testing.T, store PlayerStore) *PlayerServer {
	server, err := NewPlayerServer(store)
	if err != nil {
		t.Fatal("problem creating player server", err)
	}
	return server
}
```

마찬가지로 웹소켓 연결을 만들 때 불쾌한 에러 노이즈를 숨길 수 있도록 또 다른 헬퍼 `mustDialWS`를 만들었습니다.

```go
func mustDialWS(t *testing.T, url string) *websocket.Conn {
	ws, _, err := websocket.DefaultDialer.Dial(url, nil)

	if err != nil {
		t.Fatalf("could not open a ws connection on %s %v", url, err)
	}

	return ws
}
```

마지막으로 테스트 코드에서 메시지 보내기를 정리하기 위한 헬퍼를 만들 수 있습니다

```go
func writeWSMessage(t testing.TB, conn *websocket.Conn, message string) {
	t.Helper()
	if err := conn.WriteMessage(websocket.TextMessage, []byte(message)); err != nil {
		t.Fatalf("could not send message over ws connection %v", err)
	}
}
```

이제 테스트가 통과하면 서버를 실행하고 `/game`에서 일부 승자를 선언해 보세요. `/league`에 기록된 것을 볼 수 있습니다. 승자를 얻을 때마다 연결을 _닫으므로_ 연결을 다시 열려면 페이지를 새로 고쳐야 합니다.

사용자가 게임의 승자를 기록할 수 있는 간단한 웹 폼을 만들었습니다. 사용자가 플레이어 수를 제공하여 게임을 시작할 수 있고 서버가 시간이 지남에 따라 블라인드 값이 무엇인지 알려주는 메시지를 클라이언트에 푸시하도록 반복합시다.

먼저 새 요구 사항에 대한 클라이언트 측 코드를 업데이트하기 위해 `game.html`을 업데이트합니다

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lets play poker</title>
</head>
<body>
<section id="game">
    <div id="game-start">
        <label for="player-count">Number of players</label>
        <input type="number" id="player-count"/>
        <button id="start-game">Start</button>
    </div>

    <div id="declare-winner">
        <label for="winner">Winner</label>
        <input type="text" id="winner"/>
        <button id="winner-button">Declare winner</button>
    </div>

    <div id="blind-value"/>
</section>

<section id="game-end">
    <h1>Another great game of poker everyone!</h1>
    <p><a href="/league">Go check the league table</a></p>
</section>

</body>
<script type="application/javascript">
    const startGame = document.getElementById('game-start')

    const declareWinner = document.getElementById('declare-winner')
    const submitWinnerButton = document.getElementById('winner-button')
    const winnerInput = document.getElementById('winner')

    const blindContainer = document.getElementById('blind-value')

    const gameContainer = document.getElementById('game')
    const gameEndContainer = document.getElementById('game-end')

    declareWinner.hidden = true
    gameEndContainer.hidden = true

    document.getElementById('start-game').addEventListener('click', event => {
        startGame.hidden = true
        declareWinner.hidden = false

        const numberOfPlayers = document.getElementById('player-count').value

        if (window['WebSocket']) {
            const conn = new WebSocket('ws://' + document.location.host + '/ws')

            submitWinnerButton.onclick = event => {
                conn.send(winnerInput.value)
                gameEndContainer.hidden = false
                gameContainer.hidden = true
            }

            conn.onclose = evt => {
                blindContainer.innerText = 'Connection closed'
            }

            conn.onmessage = evt => {
                blindContainer.innerText = evt.data
            }

            conn.onopen = function () {
                conn.send(numberOfPlayers)
            }
        }
    })
</script>
</html>
```

주요 변경 사항은 플레이어 수를 입력하는 섹션과 블라인드 값을 표시하는 섹션을 가져오는 것입니다. 게임 단계에 따라 사용자 인터페이스를 표시/숨기는 약간의 로직이 있습니다.

`conn.onmessage`를 통해 받은 모든 메시지는 블라인드 알림이라고 가정하고 그에 따라 `blindContainer.innerText`를 설정합니다.

블라인드 알림을 어떻게 보낼까요? 이전 챕터에서 `Game`이라는 아이디어를 도입했으므로 CLI 코드가 `Game`을 호출할 수 있고 블라인드 알림 스케줄을 포함한 다른 모든 것이 처리되었습니다. 이것은 좋은 관심사 분리로 밝혀졌습니다.

```go
type Game interface {
	Start(numberOfPlayers int)
	Finish(winner string)
}
```

CLI에서 사용자에게 플레이어 수를 묻는 메시지가 표시되면 블라인드 알림을 시작하는 게임을 `Start`하고 사용자가 승자를 선언하면 `Finish`합니다. 이것은 우리가 지금 가지고 있는 것과 같은 요구 사항이지만 입력을 받는 방법이 다릅니다; 따라서 가능하면 이 개념을 재사용해야 합니다.

`Game`의 "실제" 구현은 `TexasHoldem`입니다

```go
type TexasHoldem struct {
	alerter BlindAlerter
	store   PlayerStore
}
```

`BlindAlerter`를 보내면 `TexasHoldem`이 블라인드 알림을 _어디로든_ 보내도록 스케줄할 수 있습니다

```go
type BlindAlerter interface {
	ScheduleAlertAt(duration time.Duration, amount int)
}
```

그리고 상기시켜 드리면 CLI에서 사용하는 `BlindAlerter` 구현입니다.

```go
func StdOutAlerter(duration time.Duration, amount int) {
	time.AfterFunc(duration, func() {
		fmt.Fprintf(os.Stdout, "Blind is now %d\n", amount)
	})
}
```

이것은 CLI에서 작동합니다. 왜냐하면 _항상 알림을 `os.Stdout`에 보내기를 원하기_ 때문이지만 웹 서버에서는 작동하지 않습니다. 모든 요청에 대해 새 `http.ResponseWriter`를 받고 이를 `*websocket.Conn`으로 업그레이드합니다. 따라서 종속성을 구성할 때 알림이 어디로 가야 하는지 알 수 없습니다.

그런 이유로 웹 서버에서 재사용할 수 있도록 `BlindAlerter.ScheduleAlertAt`를 변경하여 알림의 대상을 받아야 합니다.

`blind_alerter.go`를 열고 `io.Writer`에 파라미터를 추가합니다

```go
type BlindAlerter interface {
	ScheduleAlertAt(duration time.Duration, amount int, to io.Writer)
}

type BlindAlerterFunc func(duration time.Duration, amount int, to io.Writer)

func (a BlindAlerterFunc) ScheduleAlertAt(duration time.Duration, amount int, to io.Writer) {
	a(duration, amount, to)
}
```

`StdoutAlerter`의 아이디어는 새 모델에 맞지 않으므로 `Alerter`로 이름을 바꿉니다

```go
func Alerter(duration time.Duration, amount int, to io.Writer) {
	time.AfterFunc(duration, func() {
		fmt.Fprintf(to, "Blind is now %d\n", amount)
	})
}
```

컴파일하려고 하면 목적지 없이 `ScheduleAlertAt`를 호출하기 때문에 `TexasHoldem`에서 실패합니다, 컴파일되도록 _지금은_ `os.Stdout`으로 하드코딩합니다.

테스트를 실행하면 `SpyBlindAlerter`가 더 이상 `BlindAlerter`를 구현하지 않기 때문에 실패합니다, `ScheduleAlertAt`의 시그니처를 업데이트하여 수정하고 테스트를 실행하면 여전히 녹색이어야 합니다.

`TexasHoldem`이 블라인드 알림을 어디로 보낼지 아는 것은 말이 되지 않습니다. 이제 게임을 시작할 때 알림을 _어디로_ 보낼지 선언하도록 `Game`을 업데이트합시다.

```go
type Game interface {
	Start(numberOfPlayers int, alertsDestination io.Writer)
	Finish(winner string)
}
```

컴파일러가 수정해야 할 것을 알려줍니다. 변경은 그렇게 나쁘지 않습니다:

* `TexasHoldem`을 업데이트하여 `Game`을 제대로 구현합니다
* `CLI`에서 게임을 시작할 때 `out` 속성을 전달합니다 (`cli.game.Start(numberOfPlayers, cli.out)`)
* `TexasHoldem`의 테스트에서 `game.Start(5, io.Discard)`를 사용하여 컴파일 문제를 수정하고 알림 출력을 버리도록 구성합니다

모든 것이 맞다면 모든 것이 녹색이어야 합니다! 이제 `Server` 내에서 `Game`을 사용할 수 있습니다.

## 먼저 테스트 작성

`CLI`와 `Server`의 요구 사항은 같습니다! 단지 전달 메커니즘이 다를 뿐입니다.

영감을 얻기 위해 `CLI` 테스트를 살펴봅시다.

```go
t.Run("start game with 3 players and finish game with 'Chris' as winner", func(t *testing.T) {
	game := &GameSpy{}

	out := &bytes.Buffer{}
	in := userSends("3", "Chris wins")

	poker.NewCLI(in, out, game).PlayPoker()

	assertMessagesSentToUser(t, out, poker.PlayerPrompt)
	assertGameStartedWith(t, game, 3)
	assertFinishCalledWith(t, game, "Chris")
})
```

`GameSpy`를 사용하여 비슷한 결과를 테스트 드라이브할 수 있을 것 같습니다

이전 웹소켓 테스트를 다음으로 교체합니다

```go
t.Run("start a game with 3 players and declare Ruth the winner", func(t *testing.T) {
	game := &poker.GameSpy{}
	winner := "Ruth"
	server := httptest.NewServer(mustMakePlayerServer(t, dummyPlayerStore, game))
	ws := mustDialWS(t, "ws"+strings.TrimPrefix(server.URL, "http")+"/ws")

	defer server.Close()
	defer ws.Close()

	writeWSMessage(t, ws, "3")
	writeWSMessage(t, ws, winner)

	time.Sleep(10 * time.Millisecond)
	assertGameStartedWith(t, game, 3)
	assertFinishCalledWith(t, game, winner)
})
```

* 논의한 대로 스파이 `Game`을 만들고 `mustMakePlayerServer`에 전달합니다 (이를 지원하도록 헬퍼를 반드시 업데이트하세요).
* 그런 다음 게임에 대한 웹소켓 메시지를 보냅니다.
* 마지막으로 게임이 예상대로 시작되고 종료되었는지 어설션합니다.

## 테스트 실행 시도

다른 테스트에서 `mustMakePlayerServer` 주변에 여러 컴파일 에러가 있습니다. 익스포트되지 않은 변수 `dummyGame`을 도입하고 컴파일되지 않는 모든 테스트에서 사용합니다

```go
var (
	dummyGame = &GameSpy{}
)
```

마지막 에러는 `Game`을 `NewPlayerServer`에 전달하려고 하지만 아직 지원하지 않는 곳입니다

```
./server_test.go:21:38: too many arguments in call to "github.com/quii/learn-go-with-tests/WebSockets/v2".NewPlayerServer
	have ("github.com/quii/learn-go-with-tests/WebSockets/v2".PlayerStore, "github.com/quii/learn-go-with-tests/WebSockets/v2".Game)
	want ("github.com/quii/learn-go-with-tests/WebSockets/v2".PlayerStore)
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

테스트를 실행하기 위해 지금은 인수로 추가만 합니다

```go
func NewPlayerServer(store PlayerStore, game Game) (*PlayerServer, error)
```

드디어!

```
=== RUN   TestGame/start_a_game_with_3_players_and_declare_Ruth_the_winner
--- FAIL: TestGame (0.01s)
    --- FAIL: TestGame/start_a_game_with_3_players_and_declare_Ruth_the_winner (0.01s)
    	server_test.go:146: wanted Start called with 3 but got 0
    	server_test.go:147: expected finish called with 'Ruth' but got ''
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

요청을 받을 때 사용할 수 있도록 `Game`을 `PlayerServer`의 필드로 추가해야 합니다.

```go
type PlayerServer struct {
	store PlayerStore
	http.Handler
	template *template.Template
	game     Game
}
```

(이미 `game`이라는 메서드가 있으므로 `playGame`으로 이름을 바꿉니다)

다음으로 생성자에서 할당합니다

```go
func NewPlayerServer(store PlayerStore, game Game) (*PlayerServer, error) {
	p := new(PlayerServer)

	tmpl, err := template.ParseFiles(htmlTemplatePath)

	if err != nil {
		return nil, fmt.Errorf("problem opening %s %v", htmlTemplatePath, err)
	}

	p.game = game

	// etc
}
```

이제 `webSocket` 내에서 `Game`을 사용할 수 있습니다.

```go
func (p *PlayerServer) webSocket(w http.ResponseWriter, r *http.Request) {
	conn, _ := wsUpgrader.Upgrade(w, r, nil)

	_, numberOfPlayersMsg, _ := conn.ReadMessage()
	numberOfPlayers, _ := strconv.Atoi(string(numberOfPlayersMsg))
	p.game.Start(numberOfPlayers, io.Discard) //todo: Don't discard the blinds messages!

	_, winner, _ := conn.ReadMessage()
	p.game.Finish(string(winner))
}
```

만세! 테스트가 통과합니다.

아직 블라인드 메시지를 어디에도 보내지 않습니다. 그것에 대해 생각해야 합니다. `game.Start`를 호출할 때 쓰여진 모든 메시지를 버리는 `io.Discard`를 보냅니다.

지금 웹 서버를 시작합니다. `PlayerServer`에 `Game`을 전달하도록 `main.go`를 업데이트해야 합니다

```go
func main() {
	db, err := os.OpenFile(dbFileName, os.O_RDWR|os.O_CREATE, 0666)

	if err != nil {
		log.Fatalf("problem opening %s %v", dbFileName, err)
	}

	store, err := poker.NewFileSystemPlayerStore(db)

	if err != nil {
		log.Fatalf("problem creating file system player store, %v ", err)
	}

	game := poker.NewTexasHoldem(poker.BlindAlerterFunc(poker.Alerter), store)

	server, err := poker.NewPlayerServer(store, game)

	if err != nil {
		log.Fatalf("problem creating player server %v", err)
	}

	log.Fatal(http.ListenAndServe(":5000", server))
}
```

블라인드 알림을 아직 받지 못한다는 사실을 제외하면 앱이 작동합니다! `PlayerServer`로 `Game`을 재사용했고 모든 세부 사항을 처리했습니다. 버리지 않고 블라인드 알림을 웹소켓으로 보내는 방법을 알아내면 _모두_ 작동해야 합니다.

그 전에 일부 코드를 정리합시다.

## 리팩토링

웹소켓을 사용하는 방식은 상당히 기본적이고 에러 처리는 상당히 순진하므로 그 지저분함을 서버 코드에서 제거하기 위해 타입으로 캡슐화하고 싶었습니다. 나중에 다시 방문할 수 있지만 지금은 이것이 정리됩니다

```go
type playerServerWS struct {
	*websocket.Conn
}

func newPlayerServerWS(w http.ResponseWriter, r *http.Request) *playerServerWS {
	conn, err := wsUpgrader.Upgrade(w, r, nil)

	if err != nil {
		log.Printf("problem upgrading connection to WebSockets %v\n", err)
	}

	return &playerServerWS{conn}
}

func (w *playerServerWS) WaitForMsg() string {
	_, msg, err := w.ReadMessage()
	if err != nil {
		log.Printf("error reading from websocket %v\n", err)
	}
	return string(msg)
}
```

이제 서버 코드가 약간 단순화되었습니다

```go
func (p *PlayerServer) webSocket(w http.ResponseWriter, r *http.Request) {
	ws := newPlayerServerWS(w, r)

	numberOfPlayersMsg := ws.WaitForMsg()
	numberOfPlayers, _ := strconv.Atoi(numberOfPlayersMsg)
	p.game.Start(numberOfPlayers, io.Discard) //todo: Don't discard the blinds messages!

	winner := ws.WaitForMsg()
	p.game.Finish(winner)
}
```

블라인드 메시지를 버리지 않는 방법을 알아내면 끝입니다.

### 테스트를 작성하지 _맙시다_!

때때로 무언가를 어떻게 할지 모를 때 그냥 놀고 시도해 보는 것이 가장 좋습니다! 먼저 작업을 커밋하세요. 방법을 알아내면 테스트를 통해 드라이브해야 합니다.

우리가 가지고 있는 문제의 코드 줄은

```go
p.game.Start(numberOfPlayers, io.Discard) //todo: Don't discard the blinds messages!
```

게임이 블라인드 알림을 쓸 `io.Writer`를 전달해야 합니다.

이전의 `playerServerWS`를 전달할 수 있다면 좋지 않을까요? 웹소켓 주변의 래퍼이므로 메시지를 보내기 위해 `Game`에 보낼 수 있어야 할 것 _같습니다_.

시도해 보세요:

```go
func (p *PlayerServer) webSocket(w http.ResponseWriter, r *http.Request) {
	ws := newPlayerServerWS(w, r)

	numberOfPlayersMsg := ws.WaitForMsg()
	numberOfPlayers, _ := strconv.Atoi(numberOfPlayersMsg)
	p.game.Start(numberOfPlayers, ws)
	//etc...
}
```

컴파일러가 불평합니다

```
./server.go:71:14: cannot use ws (type *playerServerWS) as type io.Writer in argument to p.game.Start:
	*playerServerWS does not implement io.Writer (missing Write method)
```

분명히 해야 할 일은 `playerServerWS`가 `io.Writer`를 구현_하도록_ 하는 것입니다. 그렇게 하려면 기본 `*websocket.Conn`을 사용하여 `WriteMessage`를 사용하여 웹소켓으로 메시지를 보냅니다

```go
func (w *playerServerWS) Write(p []byte) (n int, err error) {
	err = w.WriteMessage(websocket.TextMessage, p)

	if err != nil {
		return 0, err
	}

	return len(p), nil
}
```

이것은 너무 쉬워 보입니다! 애플리케이션을 실행하고 작동하는지 확인해 보세요.

먼저 작동하는 것을 볼 수 있도록 `TexasHoldem`을 편집하여 블라인드 증가 시간을 짧게 합니다

```go
blindIncrement := time.Duration(5+numberOfPlayers) * time.Second // (rather than a minute)
```

작동하는 것을 볼 수 있습니다! 마법처럼 브라우저에서 블라인드 금액이 증가합니다.

이제 코드를 되돌리고 테스트하는 방법을 생각합시다. 구현하기 위해 우리가 한 것은 `StartGame`에 `io.Discard`가 아닌 `playerServerWS`를 전달하는 것이었으므로 작동하는지 확인하기 위해 호출을 스파이해야 할 수도 있습니다.

스파이는 훌륭하고 구현 세부 사항을 확인하는 데 도움이 되지만 가능하면 항상 _실제_ 동작을 테스트하는 것이 좋습니다. 왜냐하면 리팩토링을 결정하면 스파이 테스트가 일반적으로 변경하려는 구현 세부 사항을 확인하기 때문에 실패하기 시작하기 때문입니다.

현재 테스트는 실행 중인 서버에 웹소켓 연결을 열고 메시지를 보내 작업을 수행합니다. 마찬가지로 서버가 웹소켓 연결을 통해 다시 보내는 메시지를 테스트할 수 있어야 합니다.

## 먼저 테스트 작성

기존 테스트를 편집합니다.

현재 `GameSpy`는 `Start`를 호출할 때 `out`에 데이터를 보내지 않습니다. 통조림 메시지를 보내도록 구성한 다음 해당 메시지가 웹소켓으로 전송되는지 확인할 수 있도록 변경해야 합니다. 이것은 실제로 원하는 동작을 실행하면서 올바르게 구성했다는 확신을 줍니다.

```go
type GameSpy struct {
	StartCalled     bool
	StartCalledWith int
	BlindAlert      []byte

	FinishedCalled   bool
	FinishCalledWith string
}
```

`BlindAlert` 필드를 추가합니다.

`GameSpy` `Start`를 업데이트하여 통조림 메시지를 `out`에 보냅니다.

```go
func (g *GameSpy) Start(numberOfPlayers int, out io.Writer) {
	g.StartCalled = true
	g.StartCalledWith = numberOfPlayers
	out.Write(g.BlindAlert)
}
```

이것은 이제 `PlayerServer`를 실행할 때 게임을 `Start`하려고 하면 제대로 작동하면 웹소켓을 통해 메시지를 보내야 한다는 것을 의미합니다.

마지막으로 테스트를 업데이트할 수 있습니다

```go
t.Run("start a game with 3 players, send some blind alerts down WS and declare Ruth the winner", func(t *testing.T) {
	wantedBlindAlert := "Blind is 100"
	winner := "Ruth"

	game := &GameSpy{BlindAlert: []byte(wantedBlindAlert)}
	server := httptest.NewServer(mustMakePlayerServer(t, dummyPlayerStore, game))
	ws := mustDialWS(t, "ws"+strings.TrimPrefix(server.URL, "http")+"/ws")

	defer server.Close()
	defer ws.Close()

	writeWSMessage(t, ws, "3")
	writeWSMessage(t, ws, winner)

	time.Sleep(10 * time.Millisecond)
	assertGameStartedWith(t, game, 3)
	assertFinishCalledWith(t, game, winner)

	_, gotBlindAlert, _ := ws.ReadMessage()

	if string(gotBlindAlert) != wantedBlindAlert {
		t.Errorf("got blind alert %q, want %q", string(gotBlindAlert), wantedBlindAlert)
	}
})
```

* `wantedBlindAlert`를 추가하고 `Start`가 호출되면 `out`에 보내도록 `GameSpy`를 구성했습니다.
* 웹소켓 연결로 전송되기를 희망하므로 메시지가 전송되기를 기다리고 예상한 것인지 확인하기 위해 `ws.ReadMessage()` 호출을 추가했습니다.

## 테스트 실행 시도

테스트가 영원히 멈추는 것을 발견해야 합니다. 이것은 `ws.ReadMessage()`가 절대 받지 못할 메시지를 받을 때까지 블록하기 때문입니다.

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

테스트가 멈추면 안 되므로 타임아웃하려는 코드를 처리하는 방법을 도입합시다.

```go
func within(t testing.TB, d time.Duration, assert func()) {
	t.Helper()

	done := make(chan struct{}, 1)

	go func() {
		assert()
		done <- struct{}{}
	}()

	select {
	case <-time.After(d):
		t.Error("timed out")
	case <-done:
	}
}
```

`within`이 하는 것은 `assert` 함수를 인수로 받아 고루틴에서 실행하는 것입니다. 함수가 완료되면 `done` 채널을 통해 완료되었음을 신호합니다.

그 동안 `select` 문을 사용하여 채널이 메시지를 보낼 때까지 기다립니다. 여기서 assert 함수와 duration이 발생하면 신호를 보내는 `time.After` 사이의 경쟁입니다.

마지막으로 더 깔끔하게 하기 위해 어설션을 위한 헬퍼 함수를 만들었습니다

```go
func assertWebsocketGotMsg(t *testing.T, ws *websocket.Conn, want string) {
	_, msg, _ := ws.ReadMessage()
	if string(msg) != want {
		t.Errorf(`got "%s", want "%s"`, string(msg), want)
	}
}
```

테스트가 이제 어떻게 읽히는지 여기 있습니다

```go
t.Run("start a game with 3 players, send some blind alerts down WS and declare Ruth the winner", func(t *testing.T) {
	wantedBlindAlert := "Blind is 100"
	winner := "Ruth"

	game := &GameSpy{BlindAlert: []byte(wantedBlindAlert)}
	server := httptest.NewServer(mustMakePlayerServer(t, dummyPlayerStore, game))
	ws := mustDialWS(t, "ws"+strings.TrimPrefix(server.URL, "http")+"/ws")

	defer server.Close()
	defer ws.Close()

	writeWSMessage(t, ws, "3")
	writeWSMessage(t, ws, winner)

	time.Sleep(tenMS)

	assertGameStartedWith(t, game, 3)
	assertFinishCalledWith(t, game, winner)
	within(t, tenMS, func() { assertWebsocketGotMsg(t, ws, wantedBlindAlert) })
})
```

이제 테스트를 실행하면...

```
=== RUN   TestGame
=== RUN   TestGame/start_a_game_with_3_players,_send_some_blind_alerts_down_WS_and_declare_Ruth_the_winner
--- FAIL: TestGame (0.02s)
    --- FAIL: TestGame/start_a_game_with_3_players,_send_some_blind_alerts_down_WS_and_declare_Ruth_the_winner (0.02s)
    	server_test.go:143: timed out
    	server_test.go:150: got "", want "Blind is 100"
```

## 테스트를 통과시키기 위한 충분한 코드 작성

마지막으로 이제 서버 코드를 변경하여 게임을 시작할 때 웹소켓 연결을 게임에 보낼 수 있습니다

```go
func (p *PlayerServer) webSocket(w http.ResponseWriter, r *http.Request) {
	ws := newPlayerServerWS(w, r)

	numberOfPlayersMsg := ws.WaitForMsg()
	numberOfPlayers, _ := strconv.Atoi(numberOfPlayersMsg)
	p.game.Start(numberOfPlayers, ws)

	winner := ws.WaitForMsg()
	p.game.Finish(winner)
}
```

## 리팩토링

서버 코드는 매우 작은 변경이었으므로 여기서 변경할 것이 많지 않지만 서버가 비동기적으로 작업을 수행할 때까지 기다려야 하기 때문에 테스트 코드에는 여전히 `time.Sleep` 호출이 있습니다.

`assertGameStartedWith`와 `assertFinishCalledWith` 헬퍼를 리팩토링하여 실패하기 전에 짧은 기간 동안 어설션을 재시도할 수 있습니다.

`assertFinishCalledWith`에 대해 이렇게 할 수 있고 다른 헬퍼에도 같은 접근 방식을 사용할 수 있습니다.

```go
func assertFinishCalledWith(t testing.TB, game *GameSpy, winner string) {
	t.Helper()

	passed := retryUntil(500*time.Millisecond, func() bool {
		return game.FinishCalledWith == winner
	})

	if !passed {
		t.Errorf("expected finish called with %q but got %q", winner, game.FinishCalledWith)
	}
}
```

`retryUntil`은 다음과 같이 정의됩니다

```go
func retryUntil(d time.Duration, f func() bool) bool {
	deadline := time.Now().Add(d)
	for time.Now().Before(deadline) {
		if f() {
			return true
		}
	}
	return false
}
```

## 마무리

이제 애플리케이션이 완성되었습니다. 포커 게임을 웹 브라우저를 통해 시작할 수 있고 사용자에게 시간이 지남에 따라 웹소켓을 통해 블라인드 베팅 값이 알려집니다. 게임이 끝나면 몇 챕터 전에 작성한 코드를 사용하여 지속되는 승자를 기록할 수 있습니다. 플레이어는 웹사이트의 `/league` 엔드포인트를 사용하여 누가 최고의 (또는 가장 운이 좋은) 포커 플레이어인지 알 수 있습니다.

여정을 통해 실수를 했지만 TDD 흐름으로 작동하는 소프트웨어에서 멀리 떨어져 본 적이 없습니다. 계속 반복하고 실험할 수 있었습니다.

마지막 챕터에서는 접근 방식, 도착한 디자인을 회고하고 느슨한 끝을 묶겠습니다.

이 챕터에서 몇 가지를 다뤘습니다

### 웹소켓

* 클라이언트가 서버를 계속 폴링할 필요 없이 클라이언트와 서버 사이에 메시지를 보내는 편리한 방법입니다. 우리가 가진 클라이언트와 서버 코드 모두 매우 간단합니다.
* 테스트하기 쉽지만 테스트의 비동기적 특성을 조심해야 합니다

### 지연되거나 끝나지 않을 수 있는 테스트 코드 처리

* 어설션을 재시도하고 타임아웃을 추가하는 헬퍼 함수를 만듭니다.
* 고루틴을 사용하여 어설션이 아무것도 블록하지 않도록 한 다음 채널을 사용하여 완료되었거나 완료되지 않았음을 신호합니다.
* `time` 패키지에는 채널을 통해 시간의 이벤트에 대한 신호를 보내는 유용한 함수가 있으므로 타임아웃을 설정할 수 있습니다

# 커맨드 라인과 프로젝트 구조

**[이 챕터의 모든 코드는 여기에서 찾을 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/command-line)**

제품 소유자는 이제 두 번째 애플리케이션 - 커맨드 라인 애플리케이션을 도입하여 *피벗*하기를 원합니다.

지금은 사용자가 `Ruth wins`를 입력할 때 플레이어의 승리를 기록할 수 있으면 됩니다. 궁극적으로는 사용자가 포커를 플레이하는 것을 돕는 도구가 될 것입니다.

제품 소유자는 두 애플리케이션 간에 데이터베이스를 공유하여 새 애플리케이션에서 기록된 승리에 따라 리그가 업데이트되기를 원합니다.

## 코드 상기

HTTP 서버를 시작하는 `main.go` 파일이 있는 애플리케이션이 있습니다. HTTP 서버는 이 연습에서 흥미롭지 않지만 사용하는 추상화는 흥미롭습니다. `PlayerStore`에 의존합니다.

```go
type PlayerStore interface {
	GetPlayerScore(name string) int
	RecordWin(name string)
	GetLeague() League
}
```

이전 챕터에서 해당 인터페이스를 구현하는 `FileSystemPlayerStore`를 만들었습니다. 새 애플리케이션을 위해 이것의 일부를 재사용할 수 있어야 합니다.

## 먼저 프로젝트 리팩토링

우리 프로젝트는 이제 기존 웹 서버와 커맨드 라인 앱, 두 개의 바이너리를 만들어야 합니다.

새 작업에 착수하기 전에 이를 수용하도록 프로젝트를 구조화해야 합니다.

지금까지 모든 코드는 다음과 같은 경로에 있는 하나의 폴더에 있었습니다

`$GOPATH/src/github.com/your-name/my-app`

Go에서 애플리케이션을 만들려면 `package main` 안에 `main` 함수가 필요합니다. 지금까지 모든 "도메인" 코드는 `package main` 안에 있었고 `func main`이 모든 것을 참조할 수 있었습니다.

지금까지는 괜찮았고 패키지 구조를 과도하게 만들지 않는 것이 좋은 관행입니다. 표준 라이브러리를 살펴보면 많은 폴더와 구조를 거의 볼 수 없습니다.

다행히 *필요할 때* 구조를 추가하는 것은 꽤 간단합니다.

기존 프로젝트 안에 `cmd` 디렉토리를 만들고 그 안에 `webserver` 디렉토리를 만듭니다(예: `mkdir -p cmd/webserver`).

그 안에 `main.go`를 이동합니다.

`tree`가 설치되어 있으면 실행하고 구조는 다음과 같아야 합니다

```
.
|-- file_system_store.go
|-- file_system_store_test.go
|-- cmd
|   |-- webserver
|       |-- main.go
|-- league.go
|-- server.go
|-- server_integration_test.go
|-- server_test.go
|-- tape.go
|-- tape_test.go
```

이제 효과적으로 애플리케이션과 라이브러리 코드 사이에 분리가 있지만 이제 일부 패키지 이름을 변경해야 합니다. Go 애플리케이션을 빌드할 때 패키지는 *반드시* `main`이어야 합니다.

다른 모든 코드를 `poker`라는 패키지를 갖도록 변경합니다.

마지막으로 이 패키지를 `main.go`로 가져와 웹 서버를 만드는 데 사용할 수 있습니다. 그런 다음 `poker.FunctionName`을 사용하여 라이브러리 코드를 사용할 수 있습니다.

경로는 컴퓨터에서 다르지만 다음과 유사해야 합니다:

```go
// cmd/webserver/main.go
package main

import (
	"github.com/quii/learn-go-with-tests/command-line/v1"
	"log"
	"net/http"
	"os"
)

const dbFileName = "game.db.json"

func main() {
	db, err := os.OpenFile(dbFileName, os.O_RDWR|os.O_CREATE, 0666)

	if err != nil {
		log.Fatalf("problem opening %s %v", dbFileName, err)
	}

	store, err := poker.NewFileSystemPlayerStore(db)

	if err != nil {
		log.Fatalf("problem creating file system player store, %v ", err)
	}

	server := poker.NewPlayerServer(store)

	log.Fatal(http.ListenAndServe(":5000", server))
}
```

전체 경로가 약간 어색하게 보일 수 있지만 이것이 *모든* 공개적으로 사용 가능한 라이브러리를 코드로 가져오는 방법입니다.

도메인 코드를 별도의 패키지로 분리하고 GitHub과 같은 공개 저장소에 커밋하면 모든 Go 개발자가 해당 패키지를 가져오는 자체 코드를 작성하여 우리가 작성한 기능을 사용할 수 있습니다. 처음 실행하면 존재하지 않는다고 불평하지만 `go get`을 실행하기만 하면 됩니다.

또한 사용자는 [pkg.go.dev에서 문서](https://pkg.go.dev/github.com/quii/learn-go-with-tests/command-line/v1)를 볼 수 있습니다.

### 최종 확인

- 루트 안에서 `go test`를 실행하고 여전히 통과하는지 확인
- `cmd/webserver`로 이동하여 `go run main.go` 실행
  - `http://localhost:5000/league`를 방문하면 여전히 작동하는 것을 볼 수 있습니다

### Walking skeleton

테스트 작성에 착수하기 전에 프로젝트가 빌드할 새 애플리케이션을 추가합시다. `cmd` 안에 `cli`(커맨드 라인 인터페이스)라는 또 다른 디렉토리를 만들고 다음을 포함하는 `main.go`를 추가합니다

```go
// cmd/cli/main.go
package main

import "fmt"

func main() {
	fmt.Println("Let's play poker")
}
```

우리가 다룰 첫 번째 요구 사항은 사용자가 `{PlayerName} wins`를 입력할 때 승리를 기록하는 것입니다.

## 먼저 테스트 작성

포커를 `Play`할 수 있게 해주는 `CLI`라는 것을 만들어야 한다는 것을 알고 있습니다. 사용자 입력을 읽은 다음 `PlayerStore`에 승리를 기록해야 합니다.

하지만 너무 앞서가기 전에 원하는 대로 `PlayerStore`와 통합되는지 확인하는 테스트를 먼저 작성합시다.

`CLI_test.go` 안에(프로젝트 루트에, `cmd` 안이 아님)

```go
// CLI_test.go
package poker

import "testing"

func TestCLI(t *testing.T) {
	playerStore := &StubPlayerStore{}
	cli := &CLI{playerStore}
	cli.PlayPoker()

	if len(playerStore.winCalls) != 1 {
		t.Fatal("expected a win call but didn't get any")
	}
}
```

- 다른 테스트에서 `StubPlayerStore`를 사용할 수 있습니다
- 아직 존재하지 않는 `CLI` 타입에 종속성을 전달합니다
- 작성되지 않은 `PlayPoker` 메서드로 게임을 트리거합니다
- 승리가 기록되었는지 확인합니다

## 테스트 실행 시도

```
# github.com/quii/learn-go-with-tests/command-line/v2
./cli_test.go:25:10: undefined: CLI
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

이 시점에서 종속성에 대한 해당 필드가 있는 새 `CLI` 구조체를 만들고 메서드를 추가하는 것이 편해야 합니다.

다음과 같은 코드로 끝나야 합니다

```go
// CLI.go
package poker

type CLI struct {
	playerStore PlayerStore
}

func (cli *CLI) PlayPoker() {}
```

우리가 희망하는 대로 테스트가 실패하는지 확인할 수 있도록 테스트를 실행하려고만 합니다

```
--- FAIL: TestCLI (0.00s)
    cli_test.go:30: expected a win call but didn't get any
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
//CLI.go
func (cli *CLI) PlayPoker() {
	cli.playerStore.RecordWin("Cleo")
}
```

그것으로 통과해야 합니다.

다음으로 `Stdin`(사용자의 입력)에서 읽기를 시뮬레이션하여 특정 플레이어의 승리를 기록할 수 있습니다.

이것을 실행하도록 테스트를 확장합시다.

## 먼저 테스트 작성

```go
//CLI_test.go
func TestCLI(t *testing.T) {
	in := strings.NewReader("Chris wins\n")
	playerStore := &StubPlayerStore{}

	cli := &CLI{playerStore, in}
	cli.PlayPoker()

	if len(playerStore.winCalls) != 1 {
		t.Fatal("expected a win call but didn't get any")
	}

	got := playerStore.winCalls[0]
	want := "Chris"

	if got != want {
		t.Errorf("didn't record correct winner, got %q, want %q", got, want)
	}
}
```

`os.Stdin`은 `main`에서 사용자의 입력을 캡처하는 데 사용할 것입니다. 내부적으로 `*File`이며 이는 `io.Reader`를 구현한다는 것을 의미하고 지금쯤 알다시피 텍스트를 캡처하는 편리한 방법입니다.

사용자가 입력할 것으로 예상되는 것으로 채워진 편리한 `strings.NewReader`를 사용하여 테스트에서 `io.Reader`를 만듭니다.

## 테스트 실행 시도

`./CLI_test.go:12:32: too many values in struct initializer`

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

새 종속성을 `CLI`에 추가해야 합니다.

```go
//CLI.go
type CLI struct {
	playerStore PlayerStore
	in          io.Reader
}
```

```
--- FAIL: TestCLI (0.00s)
    CLI_test.go:23: didn't record the correct winner, got 'Cleo', want 'Chris'
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

가장 쉬운 일을 먼저 하는 것을 기억하세요

```go
func (cli *CLI) PlayPoker() {
	cli.playerStore.RecordWin("Chris")
}
```

테스트가 통과합니다. 다음에 실제 코드를 작성하도록 강제하기 위해 다른 테스트를 추가하겠지만, 먼저 리팩토링합시다.

## 리팩토링

`server_test`에서 이전에 여기서처럼 승리가 기록되었는지 확인했습니다. 해당 어설션을 헬퍼로 DRY합시다

```go
//server_test.go
func assertPlayerWin(t testing.TB, store *StubPlayerStore, winner string) {
	t.Helper()

	if len(store.winCalls) != 1 {
		t.Fatalf("got %d calls to RecordWin want %d", len(store.winCalls), 1)
	}

	if store.winCalls[0] != winner {
		t.Errorf("did not store correct winner got %q want %q", store.winCalls[0], winner)
	}
}
```

이제 `server_test.go`와 `CLI_test.go` 모두에서 어설션을 교체합니다.

테스트는 이제 다음과 같이 읽혀야 합니다

```go
//CLI_test.go
func TestCLI(t *testing.T) {
	in := strings.NewReader("Chris wins\n")
	playerStore := &StubPlayerStore{}

	cli := &CLI{playerStore, in}
	cli.PlayPoker()

	assertPlayerWin(t, playerStore, "Chris")
}
```

이제 실제로 읽도록 강제하기 위해 다른 사용자 입력으로 *다른* 테스트를 작성합시다.

## 먼저 테스트 작성

```go
//CLI_test.go
func TestCLI(t *testing.T) {

	t.Run("record chris win from user input", func(t *testing.T) {
		in := strings.NewReader("Chris wins\n")
		playerStore := &StubPlayerStore{}

		cli := &CLI{playerStore, in}
		cli.PlayPoker()

		assertPlayerWin(t, playerStore, "Chris")
	})

	t.Run("record cleo win from user input", func(t *testing.T) {
		in := strings.NewReader("Cleo wins\n")
		playerStore := &StubPlayerStore{}

		cli := &CLI{playerStore, in}
		cli.PlayPoker()

		assertPlayerWin(t, playerStore, "Cleo")
	})

}
```

## 테스트 실행 시도

```
=== RUN   TestCLI
--- FAIL: TestCLI (0.00s)
=== RUN   TestCLI/record_chris_win_from_user_input
    --- PASS: TestCLI/record_chris_win_from_user_input (0.00s)
=== RUN   TestCLI/record_cleo_win_from_user_input
    --- FAIL: TestCLI/record_cleo_win_from_user_input (0.00s)
        CLI_test.go:27: did not store correct winner got 'Chris' want 'Cleo'
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

`io.Reader`에서 입력을 읽기 위해 [`bufio.Scanner`](https://golang.org/pkg/bufio/)를 사용합니다.

> bufio 패키지는 버퍼된 I/O를 구현합니다. io.Reader 또는 io.Writer 객체를 래핑하여 인터페이스도 구현하지만 버퍼링과 텍스트 I/O에 대한 도움을 제공하는 다른 객체(Reader 또는 Writer)를 만듭니다.

다음 코드로 업데이트합니다

```go
//CLI.go
type CLI struct {
	playerStore PlayerStore
	in          io.Reader
}

func (cli *CLI) PlayPoker() {
	reader := bufio.NewScanner(cli.in)
	reader.Scan()
	cli.playerStore.RecordWin(extractWinner(reader.Text()))
}

func extractWinner(userInput string) string {
	return strings.Replace(userInput, " wins", "", 1)
}
```

이제 테스트가 통과합니다.

- `Scanner.Scan()`은 줄바꿈까지 읽습니다.
- 그런 다음 `Scanner.Text()`를 사용하여 스캐너가 읽은 `string`을 반환합니다.

이제 통과하는 테스트가 있으므로 이것을 `main`에 연결해야 합니다. 항상 가능한 빨리 완전히 통합된 작동하는 소프트웨어를 만들기 위해 노력해야 합니다.

`main.go`에 다음을 추가하고 실행합니다. (컴퓨터에 있는 것과 일치하도록 두 번째 종속성의 경로를 조정해야 할 수 있습니다)

```go
package main

import (
	"fmt"
	"github.com/quii/learn-go-with-tests/command-line/v3"
	"log"
	"os"
)

const dbFileName = "game.db.json"

func main() {
	fmt.Println("Let's play poker")
	fmt.Println("Type {Name} wins to record a win")

	db, err := os.OpenFile(dbFileName, os.O_RDWR|os.O_CREATE, 0666)

	if err != nil {
		log.Fatalf("problem opening %s %v", dbFileName, err)
	}

	store, err := poker.NewFileSystemPlayerStore(db)

	if err != nil {
		log.Fatalf("problem creating file system player store, %v ", err)
	}

	game := poker.CLI{store, os.Stdin}
	game.PlayPoker()
}
```

에러가 발생할 것입니다

```
command-line/v3/cmd/cli/main.go:32:25: implicit assignment of unexported field 'playerStore' in poker.CLI literal
command-line/v3/cmd/cli/main.go:32:34: implicit assignment of unexported field 'in' in poker.CLI literal
```

여기서 일어나는 것은 `CLI`의 필드 `playerStore`와 `in`에 할당하려고 하기 때문입니다. 이것은 내보내지지 않은(private) 필드입니다. 테스트 코드는 `CLI`와 같은 패키지(`poker`)에 있기 때문에 할 수 *있습니다*. 하지만 `main`은 패키지 `main`에 있으므로 접근 권한이 없습니다.

이것은 *작업 통합*의 중요성을 강조합니다. `CLI`의 종속성을 올바르게 private으로 만들었지만(`CLI` 사용자에게 노출하고 싶지 않기 때문에) 사용자가 구성할 방법을 만들지 않았습니다.

이 문제를 더 일찍 잡을 수 있는 방법이 있을까요?

### `package mypackage_test`

지금까지의 모든 다른 예제에서 테스트 파일을 만들 때 테스트하는 것과 같은 패키지에 있다고 선언했습니다.

이것은 괜찮고 패키지 내부의 무언가를 테스트하고 싶은 경우에 내보내지지 않은 타입에 접근할 수 있다는 것을 의미합니다.

하지만 *일반적으로* 내부 것을 테스트하지 않는 것을 옹호했다면, Go가 그것을 강제하는 데 도움이 될 수 있을까요? 내보낸 타입에만 접근할 수 있는 코드를 테스트할 수 있다면요(`main`처럼)?

여러 패키지가 있는 프로젝트를 작성할 때 테스트 패키지 이름 끝에 `_test`가 있는 것을 강력히 권장합니다. 이렇게 하면 패키지의 공개 타입에만 접근할 수 있습니다. 이것은 이 특정 경우에 도움이 되지만 공개 API만 테스트하는 규율을 강제하는 데도 도움이 됩니다. 여전히 내부를 테스트하려면 테스트하려는 패키지로 별도의 테스트를 만들 수 있습니다.

TDD의 격언은 코드를 테스트할 수 없으면 코드 사용자가 통합하기 어려울 것이라는 것입니다. `package foo_test`를 사용하면 패키지 사용자가 가져오는 것처럼 코드를 테스트하도록 강제하여 도움이 됩니다.

`main` 수정 전에 `CLI_test.go` 안의 테스트 패키지를 `poker_test`로 변경합시다.

잘 구성된 IDE가 있으면 갑자기 많은 빨간색이 표시될 것입니다! 컴파일러를 실행하면 다음 에러가 발생합니다

```
./CLI_test.go:12:19: undefined: StubPlayerStore
./CLI_test.go:17:3: undefined: assertPlayerWin
./CLI_test.go:22:19: undefined: StubPlayerStore
./CLI_test.go:27:3: undefined: assertPlayerWin
```

이제 패키지 설계에 대한 더 많은 질문에 부딪혔습니다. 소프트웨어를 테스트하기 위해 내보내지지 않은 스텁과 헬퍼 함수를 만들었는데 헬퍼가 `poker` 패키지의 `_test.go` 파일에 정의되어 있기 때문에 더 이상 `CLI_test`에서 사용할 수 없습니다.

#### 스텁과 헬퍼를 '공개'하기를 원하나요?

이것은 주관적인 논의입니다. 테스트를 용이하게 하기 위해 코드로 패키지의 API를 오염시키고 싶지 않다고 주장할 수 있습니다.

Mitchell Hashimoto의 프레젠테이션 ["Advanced Testing with Go"](https://speakerdeck.com/mitchellh/advanced-testing-with-go?slide=53)에서 HashiCorp에서 패키지 사용자가 스텁을 작성하는 휠을 다시 발명하지 않고도 테스트를 작성할 수 있도록 이렇게 하는 것을 옹호한다고 설명합니다. 우리의 경우 `poker` 패키지를 사용하는 모든 사람이 코드로 작업하려는 경우 자체 스텁 `PlayerStore`를 만들 필요가 없다는 것을 의미합니다.

일화적으로 다른 공유 패키지에서 이 기법을 사용했고 사용자가 패키지와 통합할 때 시간을 절약하는 면에서 매우 유용하다는 것이 입증되었습니다.

그래서 `testing.go`라는 파일을 만들고 스텁과 헬퍼를 추가합시다.

```go
// testing.go
package poker

import "testing"

type StubPlayerStore struct {
	scores   map[string]int
	winCalls []string
	league   []Player
}

func (s *StubPlayerStore) GetPlayerScore(name string) int {
	score := s.scores[name]
	return score
}

func (s *StubPlayerStore) RecordWin(name string) {
	s.winCalls = append(s.winCalls, name)
}

func (s *StubPlayerStore) GetLeague() League {
	return s.league
}

func AssertPlayerWin(t testing.TB, store *StubPlayerStore, winner string) {
	t.Helper()

	if len(store.winCalls) != 1 {
		t.Fatalf("got %d calls to RecordWin want %d", len(store.winCalls), 1)
	}

	if store.winCalls[0] != winner {
		t.Errorf("did not store correct winner got %q want %q", store.winCalls[0], winner)
	}
}

// todo for you - 나머지 헬퍼들
```

패키지 가져오기 도구에 노출시키려면 헬퍼를 공개해야 합니다(내보내기는 시작에 대문자로 수행됩니다).

`CLI` 테스트에서 다른 패키지 내에서 사용하는 것처럼 코드를 호출해야 합니다.

```go
//CLI_test.go
func TestCLI(t *testing.T) {

	t.Run("record chris win from user input", func(t *testing.T) {
		in := strings.NewReader("Chris wins\n")
		playerStore := &poker.StubPlayerStore{}

		cli := &poker.CLI{playerStore, in}
		cli.PlayPoker()

		poker.AssertPlayerWin(t, playerStore, "Chris")
	})

	t.Run("record cleo win from user input", func(t *testing.T) {
		in := strings.NewReader("Cleo wins\n")
		playerStore := &poker.StubPlayerStore{}

		cli := &poker.CLI{playerStore, in}
		cli.PlayPoker()

		poker.AssertPlayerWin(t, playerStore, "Cleo")
	})

}
```

이제 `main`에서 가졌던 것과 같은 문제가 있는 것을 볼 수 있습니다

```
./CLI_test.go:15:26: implicit assignment of unexported field 'playerStore' in poker.CLI literal
./CLI_test.go:15:39: implicit assignment of unexported field 'in' in poker.CLI literal
./CLI_test.go:25:26: implicit assignment of unexported field 'playerStore' in poker.CLI literal
./CLI_test.go:25:39: implicit assignment of unexported field 'in' in poker.CLI literal
```

이 문제를 해결하는 가장 쉬운 방법은 다른 타입에 대해 가지고 있는 것처럼 생성자를 만드는 것입니다. 또한 이제 생성 시 자동으로 래핑되므로 reader 대신 `bufio.Scanner`를 저장하도록 `CLI`를 변경합니다.

```go
//CLI.go
type CLI struct {
	playerStore PlayerStore
	in          *bufio.Scanner
}

func NewCLI(store PlayerStore, in io.Reader) *CLI {
	return &CLI{
		playerStore: store,
		in:          bufio.NewScanner(in),
	}
}
```

이렇게 하면 읽기 코드를 단순화하고 리팩토링할 수 있습니다

```go
//CLI.go
func (cli *CLI) PlayPoker() {
	userInput := cli.readLine()
	cli.playerStore.RecordWin(extractWinner(userInput))
}

func extractWinner(userInput string) string {
	return strings.Replace(userInput, " wins", "", 1)
}

func (cli *CLI) readLine() string {
	cli.in.Scan()
	return cli.in.Text()
}
```

대신 생성자를 사용하도록 테스트를 변경하면 테스트가 다시 통과해야 합니다.

마지막으로 새 `main.go`로 돌아가서 방금 만든 생성자를 사용할 수 있습니다

```go
//cmd/cli/main.go
game := poker.NewCLI(store, os.Stdin)
```

실행해보고 "Bob wins"를 입력하세요.

### 리팩토링

파일을 열고 그 내용에서 `file_system_store`를 만드는 각 애플리케이션에서 반복이 있습니다. 이것은 패키지 설계의 약간의 약점처럼 느껴지므로 경로에서 파일을 열고 `PlayerStore`를 반환하는 기능을 캡슐화하도록 만들어야 합니다.

```go
//file_system_store.go
func FileSystemPlayerStoreFromFile(path string) (*FileSystemPlayerStore, func(), error) {
	db, err := os.OpenFile(path, os.O_RDWR|os.O_CREATE, 0666)

	if err != nil {
		return nil, nil, fmt.Errorf("problem opening %s %v", path, err)
	}

	closeFunc := func() {
		db.Close()
	}

	store, err := NewFileSystemPlayerStore(db)

	if err != nil {
		return nil, nil, fmt.Errorf("problem creating file system player store, %v ", err)
	}

	return store, closeFunc, nil
}
```

이제 두 애플리케이션 모두 이 함수를 사용하여 스토어를 만들도록 리팩토링합니다.

#### CLI 애플리케이션 코드

```go
// cmd/cli/main.go
package main

import (
	"fmt"
	"github.com/quii/learn-go-with-tests/command-line/v3"
	"log"
	"os"
)

const dbFileName = "game.db.json"

func main() {
	store, close, err := poker.FileSystemPlayerStoreFromFile(dbFileName)

	if err != nil {
		log.Fatal(err)
	}
	defer close()

	fmt.Println("Let's play poker")
	fmt.Println("Type {Name} wins to record a win")
	poker.NewCLI(store, os.Stdin).PlayPoker()
}
```

#### 웹 서버 애플리케이션 코드

```go
// cmd/webserver/main.go
package main

import (
	"github.com/quii/learn-go-with-tests/command-line/v3"
	"log"
	"net/http"
)

const dbFileName = "game.db.json"

func main() {
	store, close, err := poker.FileSystemPlayerStoreFromFile(dbFileName)

	if err != nil {
		log.Fatal(err)
	}
	defer close()

	server := poker.NewPlayerServer(store)

	if err := http.ListenAndServe(":5000", server); err != nil {
		log.Fatalf("could not listen on port 5000 %v", err)
	}
}
```

대칭성을 주목하세요: 다른 사용자 인터페이스임에도 불구하고 설정이 거의 동일합니다. 이것은 지금까지의 설계가 좋다는 검증처럼 느껴집니다.
그리고 `FileSystemPlayerStoreFromFile`이 닫기 함수를 반환하여 Store 사용이 끝나면 기본 파일을 닫을 수 있다는 것도 주목하세요.

## 마무리

### 패키지 구조

이 챕터는 지금까지 작성한 도메인 코드를 재사용하여 두 개의 애플리케이션을 만들고 싶었습니다. 이를 위해 각 `main`에 대한 별도의 폴더가 있도록 패키지 구조를 업데이트해야 했습니다.

이렇게 함으로써 내보내지지 않은 값으로 인해 통합 문제가 발생했으므로 작은 "슬라이스"로 작업하고 자주 통합하는 것의 가치를 더 보여줍니다.

`mypackage_test`가 코드와 통합하는 다른 패키지와 동일한 경험의 테스트 환경을 만드는 데 도움이 되어 통합 문제를 잡고 코드를 작업하기 쉬운(또는 아닌) 것을 볼 수 있다는 것을 배웠습니다.

### 사용자 입력 읽기

`os.Stdin`에서 읽는 것이 `io.Reader`를 구현하기 때문에 작업하기 매우 쉽다는 것을 보았습니다. `bufio.Scanner`를 사용하여 줄별로 사용자 입력을 쉽게 읽었습니다.

### 단순한 추상화는 더 단순한 코드 재사용으로 이어집니다

`PlayerStore`를 새 애플리케이션에 통합하는 것은 (패키지 조정을 완료한 후) 거의 노력이 들지 않았고 결과적으로 스텁 버전도 노출하기로 결정했기 때문에 테스트도 매우 쉬웠습니다.

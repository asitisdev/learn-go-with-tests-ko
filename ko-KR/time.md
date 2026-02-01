# 시간

[**이 챕터의 모든 코드는 여기에서 찾을 수 있습니다**](https://github.com/quii/learn-go-with-tests/tree/main/time)

제품 소유자는 텍사스 홀덤 포커를 플레이하는 그룹을 돕기 위해 커맨드 라인 애플리케이션의 기능을 확장하기를 원합니다.

## 포커에 대한 최소한의 정보

포커에 대해 많이 알 필요는 없습니다, 특정 시간 간격으로 모든 플레이어에게 꾸준히 증가하는 "블라인드" 값을 알려야 한다는 것만 알면 됩니다.

우리 애플리케이션은 블라인드가 언제 올라가야 하는지, 그리고 얼마가 되어야 하는지 추적하는 데 도움이 됩니다.

* 시작할 때 플레이어 수를 물어봅니다. 이것은 "블라인드" 베팅이 올라가기 전의 시간을 결정합니다.
  * 기본 시간은 5분입니다.
  * 플레이어마다 1분이 추가됩니다.
  * 예: 6명의 플레이어는 블라인드에 11분입니다.
* 블라인드 시간이 만료된 후 게임은 플레이어에게 블라인드 베팅의 새로운 금액을 알려야 합니다.
* 블라인드는 100칩으로 시작한 다음 200, 400, 600, 1000, 2000으로 게임이 끝날 때까지 계속 두 배가 됩니다 ("Ruth wins"의 이전 기능은 여전히 게임을 종료해야 합니다)

## 코드 상기

이전 챕터에서 이미 `{name} wins` 명령을 수락하는 커맨드 라인 애플리케이션을 시작했습니다. 현재 `CLI` 코드가 어떻게 생겼는지 여기 있지만, 시작하기 전에 다른 코드도 숙지하세요.

```go
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

### `time.AfterFunc`

플레이어 수에 따라 특정 기간에 블라인드 베팅 값을 출력하도록 프로그램을 스케줄할 수 있어야 합니다.

해야 할 일의 범위를 제한하기 위해 지금은 플레이어 수 부분을 잊고 5명의 플레이어가 있다고 가정하여 _10분마다 블라인드 베팅의 새 값이 출력되는지_ 테스트합니다.

평소처럼 표준 라이브러리가 [`func AfterFunc(d Duration, f func()) *Timer`](https://golang.org/pkg/time/#AfterFunc)로 지원합니다

> `AfterFunc`는 duration이 경과할 때까지 기다린 다음 자체 고루틴에서 f를 호출합니다. Stop 메서드를 사용하여 호출을 취소할 수 있는 `Timer`를 반환합니다.

### [`time.Duration`](https://golang.org/pkg/time/#Duration)

> Duration은 int64 나노초 수로 두 순간 사이에 경과된 시간을 나타냅니다.

time 라이브러리에는 우리가 할 시나리오에 대해 나노초를 좀 더 읽기 쉽게 곱할 수 있는 여러 상수가 있습니다

```
5 * time.Second
```

`PlayPoker`를 호출할 때 모든 블라인드 알림을 스케줄합니다.

그러나 이것을 테스트하는 것은 약간 까다로울 수 있습니다. 각 시간 기간이 올바른 블라인드 금액으로 스케줄되었는지 확인하고 싶지만 `time.AfterFunc`의 시그니처를 보면 두 번째 인수가 실행할 함수입니다. Go에서는 함수를 비교할 수 없으므로 어떤 함수가 전달되었는지 테스트할 수 없습니다. 그래서 실행할 시간과 출력할 금액을 받아서 스파이할 수 있는 `time.AfterFunc` 주변의 일종의 래퍼를 작성해야 합니다.

## 먼저 테스트 작성

스위트에 새 테스트 추가

```go
t.Run("it schedules printing of blind values", func(t *testing.T) {
	in := strings.NewReader("Chris wins\n")
	playerStore := &poker.StubPlayerStore{}
	blindAlerter := &SpyBlindAlerter{}

	cli := poker.NewCLI(playerStore, in, blindAlerter)
	cli.PlayPoker()

	if len(blindAlerter.alerts) != 1 {
		t.Fatal("expected a blind alert to be scheduled")
	}
})
```

`CLI`에 주입하려는 `SpyBlindAlerter`를 만든 다음 `PlayPoker`를 호출한 후 알림이 스케줄되었는지 확인합니다.

(가장 간단한 시나리오를 먼저 다루고 그 다음 반복한다는 것을 기억하세요.)

`SpyBlindAlerter`의 정의입니다

```go
type SpyBlindAlerter struct {
	alerts []struct {
		scheduledAt time.Duration
		amount      int
	}
}

func (s *SpyBlindAlerter) ScheduleAlertAt(duration time.Duration, amount int) {
	s.alerts = append(s.alerts, struct {
		scheduledAt time.Duration
		amount      int
	}{duration, amount})
}
```

## 테스트 실행 시도

```
./CLI_test.go:32:27: too many arguments in call to poker.NewCLI
	have (*poker.StubPlayerStore, *strings.Reader, *SpyBlindAlerter)
	want (poker.PlayerStore, io.Reader)
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

새 인수를 추가했고 컴파일러가 불평합니다. _엄밀히 말하면_ 최소한의 코드는 `NewCLI`가 `*SpyBlindAlerter`를 받아들이도록 하는 것이지만 약간 치팅하고 종속성을 인터페이스로 정의합시다.

```go
type BlindAlerter interface {
	ScheduleAlertAt(duration time.Duration, amount int)
}
```

그런 다음 생성자에 추가

```go
func NewCLI(store PlayerStore, in io.Reader, alerter BlindAlerter) *CLI
```

`NewCLI`에 `BlindAlerter`가 전달되지 않아 다른 테스트가 이제 실패합니다.

BlindAlerter를 스파이하는 것은 다른 테스트와 관련이 없으므로 테스트 파일에 추가

```go
var dummySpyAlerter = &SpyBlindAlerter{}
```

그런 다음 다른 테스트에서 이것을 사용하여 컴파일 문제를 수정합니다. "dummy"로 레이블을 지정하면 테스트 독자에게 중요하지 않다는 것이 명확합니다.

[> Dummy 객체는 전달되지만 실제로는 사용되지 않습니다. 일반적으로 파라미터 목록을 채우는 데만 사용됩니다.](https://martinfowler.com/articles/mocksArentStubs.html)

이제 테스트가 컴파일되고 새 테스트가 실패합니다.

```
=== RUN   TestCLI
=== RUN   TestCLI/it_schedules_printing_of_blind_values
--- FAIL: TestCLI (0.00s)
    --- FAIL: TestCLI/it_schedules_printing_of_blind_values (0.00s)
    	CLI_test.go:38: expected a blind alert to be scheduled
```

## 테스트를 통과시키기 위한 충분한 코드 작성

`PlayPoker` 메서드에서 참조할 수 있도록 `BlindAlerter`를 `CLI`의 필드로 추가해야 합니다.

```go
type CLI struct {
	playerStore PlayerStore
	in          *bufio.Scanner
	alerter     BlindAlerter
}

func NewCLI(store PlayerStore, in io.Reader, alerter BlindAlerter) *CLI {
	return &CLI{
		playerStore: store,
		in:          bufio.NewScanner(in),
		alerter:     alerter,
	}
}
```

테스트를 통과시키기 위해 원하는 것으로 `BlindAlerter`를 호출할 수 있습니다

```go
func (cli *CLI) PlayPoker() {
	cli.alerter.ScheduleAlertAt(5*time.Second, 100)
	userInput := cli.readLine()
	cli.playerStore.RecordWin(extractWinner(userInput))
}
```

다음으로 5명의 플레이어에 대해 기대하는 모든 알림을 스케줄하는지 확인하고 싶습니다

## 먼저 테스트 작성

```go
	t.Run("it schedules printing of blind values", func(t *testing.T) {
		in := strings.NewReader("Chris wins\n")
		playerStore := &poker.StubPlayerStore{}
		blindAlerter := &SpyBlindAlerter{}

		cli := poker.NewCLI(playerStore, in, blindAlerter)
		cli.PlayPoker()

		cases := []struct {
			expectedScheduleTime time.Duration
			expectedAmount       int
		}{
			{0 * time.Second, 100},
			{10 * time.Minute, 200},
			{20 * time.Minute, 300},
			{30 * time.Minute, 400},
			{40 * time.Minute, 500},
			{50 * time.Minute, 600},
			{60 * time.Minute, 800},
			{70 * time.Minute, 1000},
			{80 * time.Minute, 2000},
			{90 * time.Minute, 4000},
			{100 * time.Minute, 8000},
		}

		for i, c := range cases {
			t.Run(fmt.Sprintf("%d scheduled for %v", c.expectedAmount, c.expectedScheduleTime), func(t *testing.T) {

				if len(blindAlerter.alerts) <= i {
					t.Fatalf("alert %d was not scheduled %v", i, blindAlerter.alerts)
				}

				alert := blindAlerter.alerts[i]

				amountGot := alert.amount
				if amountGot != c.expectedAmount {
					t.Errorf("got amount %d, want %d", amountGot, c.expectedAmount)
				}

				gotScheduledTime := alert.scheduledAt
				if gotScheduledTime != c.expectedScheduleTime {
					t.Errorf("got scheduled time of %v, want %v", gotScheduledTime, c.expectedScheduleTime)
				}
			})
		}
	})
```

테이블 기반 테스트가 여기서 잘 작동하고 요구 사항이 무엇인지 명확하게 보여줍니다. 테이블을 순회하고 `SpyBlindAlerter`를 확인하여 알림이 올바른 값으로 스케줄되었는지 확인합니다.

## 테스트 실행 시도

다음과 같은 많은 실패가 있어야 합니다

```
=== RUN   TestCLI
--- FAIL: TestCLI (0.00s)
=== RUN   TestCLI/it_schedules_printing_of_blind_values
    --- FAIL: TestCLI/it_schedules_printing_of_blind_values (0.00s)
=== RUN   TestCLI/it_schedules_printing_of_blind_values/100_scheduled_for_0s
        --- FAIL: TestCLI/it_schedules_printing_of_blind_values/100_scheduled_for_0s (0.00s)
        	CLI_test.go:71: got scheduled time of 5s, want 0s
=== RUN   TestCLI/it_schedules_printing_of_blind_values/200_scheduled_for_10m0s
        --- FAIL: TestCLI/it_schedules_printing_of_blind_values/200_scheduled_for_10m0s (0.00s)
        	CLI_test.go:59: alert 1 was not scheduled [{5000000000 100}]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (cli *CLI) PlayPoker() {

	blinds := []int{100, 200, 300, 400, 500, 600, 800, 1000, 2000, 4000, 8000}
	blindTime := 0 * time.Second
	for _, blind := range blinds {
		cli.alerter.ScheduleAlertAt(blindTime, blind)
		blindTime = blindTime + 10*time.Minute
	}

	userInput := cli.readLine()
	cli.playerStore.RecordWin(extractWinner(userInput))
}
```

이미 가진 것보다 훨씬 복잡하지 않습니다. 이제 `blinds` 배열을 반복하고 증가하는 `blindTime`에서 스케줄러를 호출합니다

## 리팩토링

`PlayPoker`를 조금 더 명확하게 읽을 수 있도록 스케줄된 알림을 메서드로 캡슐화할 수 있습니다.

```go
func (cli *CLI) PlayPoker() {
	cli.scheduleBlindAlerts()
	userInput := cli.readLine()
	cli.playerStore.RecordWin(extractWinner(userInput))
}

func (cli *CLI) scheduleBlindAlerts() {
	blinds := []int{100, 200, 300, 400, 500, 600, 800, 1000, 2000, 4000, 8000}
	blindTime := 0 * time.Second
	for _, blind := range blinds {
		cli.alerter.ScheduleAlertAt(blindTime, blind)
		blindTime = blindTime + 10*time.Minute
	}
}
```

마지막으로 테스트가 약간 투박해 보입니다. 동일한 것을 나타내는 두 개의 익명 구조체가 있습니다, `ScheduledAlert`. 새 타입으로 리팩토링한 다음 비교할 헬퍼를 만듭시다.

```go
type scheduledAlert struct {
	at     time.Duration
	amount int
}

func (s scheduledAlert) String() string {
	return fmt.Sprintf("%d chips at %v", s.amount, s.at)
}

type SpyBlindAlerter struct {
	alerts []scheduledAlert
}

func (s *SpyBlindAlerter) ScheduleAlertAt(at time.Duration, amount int) {
	s.alerts = append(s.alerts, scheduledAlert{at, amount})
}
```

테스트가 실패하면 잘 출력되도록 타입에 `String()` 메서드를 추가했습니다

새 타입을 사용하도록 테스트 업데이트

```go
t.Run("it schedules printing of blind values", func(t *testing.T) {
	in := strings.NewReader("Chris wins\n")
	playerStore := &poker.StubPlayerStore{}
	blindAlerter := &SpyBlindAlerter{}

	cli := poker.NewCLI(playerStore, in, blindAlerter)
	cli.PlayPoker()

	cases := []scheduledAlert{
		{0 * time.Second, 100},
		{10 * time.Minute, 200},
		{20 * time.Minute, 300},
		{30 * time.Minute, 400},
		{40 * time.Minute, 500},
		{50 * time.Minute, 600},
		{60 * time.Minute, 800},
		{70 * time.Minute, 1000},
		{80 * time.Minute, 2000},
		{90 * time.Minute, 4000},
		{100 * time.Minute, 8000},
	}

	for i, want := range cases {
		t.Run(fmt.Sprint(want), func(t *testing.T) {

			if len(blindAlerter.alerts) <= i {
				t.Fatalf("alert %d was not scheduled %v", i, blindAlerter.alerts)
			}

			got := blindAlerter.alerts[i]
			assertScheduledAlert(t, got, want)
		})
	}
})
```

`assertScheduledAlert`를 직접 구현하세요.

여기서 테스트를 작성하고 애플리케이션과 통합하지 않은 것은 약간 불량합니다. 더 많은 요구 사항을 쌓기 전에 해결합시다.

앱을 실행하려고 하면 컴파일되지 않고 `NewCLI`에 인수가 충분하지 않다고 불평합니다.

애플리케이션에서 사용할 수 있는 `BlindAlerter`의 구현을 만듭시다.

`blind_alerter.go`를 만들고 `BlindAlerter` 인터페이스를 이동하고 아래의 새 것들을 추가

```go
package poker

import (
	"fmt"
	"os"
	"time"
)

type BlindAlerter interface {
	ScheduleAlertAt(duration time.Duration, amount int)
}

type BlindAlerterFunc func(duration time.Duration, amount int)

func (a BlindAlerterFunc) ScheduleAlertAt(duration time.Duration, amount int) {
	a(duration, amount)
}

func StdOutAlerter(duration time.Duration, amount int) {
	time.AfterFunc(duration, func() {
		fmt.Fprintf(os.Stdout, "Blind is now %d\n", amount)
	})
}
```

`struct`뿐만 아니라 모든 _타입_이 인터페이스를 구현할 수 있다는 것을 기억하세요. 하나의 함수가 정의된 인터페이스를 노출하는 라이브러리를 만드는 경우 `MyInterfaceFunc` 타입도 함께 노출하는 것이 일반적인 관용구입니다.

이 타입은 인터페이스를 구현하는 `func`가 됩니다. 그렇게 하면 인터페이스 사용자가 빈 `struct` 타입을 만들 필요 없이 함수만으로 인터페이스를 구현할 수 있습니다.

그런 다음 함수와 동일한 시그니처를 가진 `StdOutAlerter` 함수를 만들고 `time.AfterFunc`를 사용하여 `os.Stdout`에 출력하도록 스케줄합니다.

이것이 작동하는 것을 보려면 `NewCLI`를 만드는 `main`을 업데이트하세요

```go
poker.NewCLI(store, os.Stdin, poker.BlindAlerterFunc(poker.StdOutAlerter)).PlayPoker()
```

실행하기 전에 작동하는 것을 볼 수 있도록 `CLI`의 `blindTime` 증가를 10분이 아닌 10초로 변경할 수 있습니다.

10초마다 예상대로 블라인드 값이 출력되는 것을 볼 수 있습니다. CLI에 `Shaun wins`를 입력해도 예상대로 프로그램이 중지됩니다.

게임이 항상 5명으로 진행되는 것은 아니므로 게임 시작 전에 플레이어 수를 입력하도록 사용자에게 프롬프트해야 합니다.

## 먼저 테스트 작성

플레이어 수를 프롬프트하는지 확인하려면 StdOut에 쓰여진 것을 기록하고 싶습니다. 이것을 몇 번 했고 `os.Stdout`이 `io.Writer`라는 것을 알고 있으므로 테스트에서 종속성 주입을 사용하여 `bytes.Buffer`를 전달하면 코드가 쓸 것을 확인할 수 있습니다.

이 테스트에서는 아직 다른 협력자에 대해 신경 쓰지 않으므로 테스트 파일에 몇 가지 더미를 만들었습니다.

`CLI`에 4개의 종속성이 있어서 너무 많은 책임을 지고 있는 것 같다는 것에 약간 주의해야 합니다. 지금은 이것으로 살아가고 이 새로운 기능을 추가하면서 리팩토링이 나타나는지 봅시다.

```go
var dummyBlindAlerter = &SpyBlindAlerter{}
var dummyPlayerStore = &poker.StubPlayerStore{}
var dummyStdIn = &bytes.Buffer{}
var dummyStdOut = &bytes.Buffer{}
```

새 테스트입니다

```go
t.Run("it prompts the user to enter the number of players", func(t *testing.T) {
	stdout := &bytes.Buffer{}
	cli := poker.NewCLI(dummyPlayerStore, dummyStdIn, stdout, dummyBlindAlerter)
	cli.PlayPoker()

	got := stdout.String()
	want := "Please enter the number of players: "

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
})
```

`main`에서 `os.Stdout`이 될 것을 전달하고 쓰여진 것을 봅니다.

## 테스트 실행 시도

```
./CLI_test.go:38:27: too many arguments in call to poker.NewCLI
	have (*poker.StubPlayerStore, *bytes.Buffer, *bytes.Buffer, *SpyBlindAlerter)
	want (poker.PlayerStore, io.Reader, poker.BlindAlerter)
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

새 종속성이 있으므로 `NewCLI`를 업데이트해야 합니다

```go
func NewCLI(store PlayerStore, in io.Reader, out io.Writer, alerter BlindAlerter) *CLI
```

이제 `NewCLI`에 `io.Writer`가 전달되지 않아 _다른_ 테스트가 컴파일되지 않습니다.

다른 테스트에 `dummyStdout`을 추가합니다.

새 테스트는 다음과 같이 실패해야 합니다

```
=== RUN   TestCLI
--- FAIL: TestCLI (0.00s)
=== RUN   TestCLI/it_prompts_the_user_to_enter_the_number_of_players
    --- FAIL: TestCLI/it_prompts_the_user_to_enter_the_number_of_players (0.00s)
    	CLI_test.go:46: got '', want 'Please enter the number of players: '
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

`PlayPoker`에서 참조할 수 있도록 `CLI`에 새 종속성을 추가해야 합니다

```go
type CLI struct {
	playerStore PlayerStore
	in          *bufio.Scanner
	out         io.Writer
	alerter     BlindAlerter
}

func NewCLI(store PlayerStore, in io.Reader, out io.Writer, alerter BlindAlerter) *CLI {
	return &CLI{
		playerStore: store,
		in:          bufio.NewScanner(in),
		out:         out,
		alerter:     alerter,
	}
}
```

그런 다음 마지막으로 게임 시작 시 프롬프트를 쓸 수 있습니다

```go
func (cli *CLI) PlayPoker() {
	fmt.Fprint(cli.out, "Please enter the number of players: ")
	cli.scheduleBlindAlerts()
	userInput := cli.readLine()
	cli.playerStore.RecordWin(extractWinner(userInput))
}
```

## 리팩토링

상수로 추출해야 하는 프롬프트에 대한 중복 문자열이 있습니다

```go
const PlayerPrompt = "Please enter the number of players: "
```

테스트 코드와 `CLI` 둘 다에서 이것을 사용하세요.

이제 숫자를 보내고 추출해야 합니다. 원하는 효과가 있는지 알 수 있는 유일한 방법은 어떤 블라인드 알림이 스케줄되었는지 보는 것입니다.

## 먼저 테스트 작성

```go
t.Run("it prompts the user to enter the number of players", func(t *testing.T) {
	stdout := &bytes.Buffer{}
	in := strings.NewReader("7\n")
	blindAlerter := &SpyBlindAlerter{}

	cli := poker.NewCLI(dummyPlayerStore, in, stdout, blindAlerter)
	cli.PlayPoker()

	got := stdout.String()
	want := poker.PlayerPrompt

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}

	cases := []scheduledAlert{
		{0 * time.Second, 100},
		{12 * time.Minute, 200},
		{24 * time.Minute, 300},
		{36 * time.Minute, 400},
	}

	for i, want := range cases {
		t.Run(fmt.Sprint(want), func(t *testing.T) {

			if len(blindAlerter.alerts) <= i {
				t.Fatalf("alert %d was not scheduled %v", i, blindAlerter.alerts)
			}

			got := blindAlerter.alerts[i]
			assertScheduledAlert(t, got, want)
		})
	}
})
```

아야! 많은 변경.

* StdIn에 대한 더미를 제거하고 대신 사용자가 7을 입력하는 것을 나타내는 모킹된 버전을 보냅니다
* 플레이어 수가 스케줄에 영향을 미쳤는지 볼 수 있도록 블라인드 알러터의 더미도 제거합니다
* 어떤 알림이 스케줄되었는지 테스트합니다

## 테스트 실행 시도

게임이 5명의 플레이어를 기반으로 하드코딩되어 있으므로 스케줄된 시간이 잘못되었다고 보고하면서 테스트가 여전히 컴파일되고 실패해야 합니다

```
=== RUN   TestCLI
--- FAIL: TestCLI (0.00s)
=== RUN   TestCLI/it_prompts_the_user_to_enter_the_number_of_players
    --- FAIL: TestCLI/it_prompts_the_user_to_enter_the_number_of_players (0.00s)
=== RUN   TestCLI/it_prompts_the_user_to_enter_the_number_of_players/100_chips_at_0s
        --- PASS: TestCLI/it_prompts_the_user_to_enter_the_number_of_players/100_chips_at_0s (0.00s)
=== RUN   TestCLI/it_prompts_the_user_to_enter_the_number_of_players/200_chips_at_12m0s
```

## 테스트를 통과시키기 위한 충분한 코드 작성

기억하세요, 이것을 작동시키기 위해 필요한 모든 죄를 저지를 수 있습니다. 작동하는 소프트웨어가 있으면 만들려는 난장판을 리팩토링하는 작업을 할 수 있습니다!

```go
func (cli *CLI) PlayPoker() {
	fmt.Fprint(cli.out, PlayerPrompt)

	numberOfPlayers, _ := strconv.Atoi(cli.readLine())

	cli.scheduleBlindAlerts(numberOfPlayers)

	userInput := cli.readLine()
	cli.playerStore.RecordWin(extractWinner(userInput))
}

func (cli *CLI) scheduleBlindAlerts(numberOfPlayers int) {
	blindIncrement := time.Duration(5+numberOfPlayers) * time.Minute

	blinds := []int{100, 200, 300, 400, 500, 600, 800, 1000, 2000, 4000, 8000}
	blindTime := 0 * time.Second
	for _, blind := range blinds {
		cli.alerter.ScheduleAlertAt(blindTime, blind)
		blindTime = blindTime + blindIncrement
	}
}
```

* `numberOfPlayersInput`을 문자열로 읽습니다
* `cli.readLine()`을 사용하여 사용자로부터 입력을 받은 다음 `Atoi`를 호출하여 정수로 변환합니다 - 에러 시나리오는 무시합니다. 나중에 해당 시나리오에 대한 테스트를 작성해야 합니다.
* 여기서부터 플레이어 수를 받아들이도록 `scheduleBlindAlerts`를 변경합니다. 그런 다음 블라인드 금액을 반복할 때 `blindTime`에 추가하는 데 사용할 `blindIncrement` 시간을 계산합니다

새 테스트가 수정되었지만 이제 시스템은 사용자가 숫자를 입력해야만 게임이 시작되므로 다른 많은 테스트가 실패합니다. 숫자 다음에 줄 바꿈이 추가되도록 사용자 입력을 변경하여 테스트를 수정해야 합니다 (이것은 지금 우리의 접근 방식에서 더 많은 결함을 보여줍니다).

## 리팩토링

이 모든 것이 꽤 끔찍하게 느껴지나요? **테스트를 들읍시다**.

* 일부 알림을 스케줄하고 있는지 테스트하기 위해 4개의 다른 종속성을 설정합니다. 시스템에서 _어떤 것_에 대해 많은 종속성이 있을 때마다 너무 많이 하고 있다는 것을 암시합니다. 시각적으로 테스트가 얼마나 어수선한지 볼 수 있습니다.
* 제게는 **사용자 입력 읽기와 수행하려는 비즈니스 로직 사이에 더 깨끗한 추상화를 만들어야 할 것 같습니다**
* 더 나은 테스트는 _이 사용자 입력이 주어지면 올바른 플레이어 수로 새 타입 `Game`을 호출하는지_입니다.
* 그런 다음 스케줄링 테스트를 새 `Game`에 대한 테스트로 추출합니다.

먼저 `Game`으로 리팩토링할 수 있고 테스트는 계속 통과해야 합니다. 원하는 구조적 변경을 만든 후 새로운 관심사 분리를 반영하도록 테스트를 리팩토링하는 방법을 생각할 수 있습니다

리팩토링할 때 변경 사항을 가능한 한 작게 유지하고 모든 변경 후에 테스트를 다시 실행하세요.

먼저 직접 시도해 보세요. `Game`이 제공할 경계와 `CLI`가 무엇을 해야 하는지 생각해 보세요.

지금은 테스트 코드와 클라이언트 코드를 동시에 변경하고 싶지 않으므로 `NewCLI`의 외부 인터페이스를 **변경하지 마세요**.

제가 생각해낸 것입니다:

```go
// game.go
type Game struct {
	alerter BlindAlerter
	store   PlayerStore
}

func (p *Game) Start(numberOfPlayers int) {
	blindIncrement := time.Duration(5+numberOfPlayers) * time.Minute

	blinds := []int{100, 200, 300, 400, 500, 600, 800, 1000, 2000, 4000, 8000}
	blindTime := 0 * time.Second
	for _, blind := range blinds {
		p.alerter.ScheduleAlertAt(blindTime, blind)
		blindTime = blindTime + blindIncrement
	}
}

func (p *Game) Finish(winner string) {
	p.store.RecordWin(winner)
}

// cli.go
type CLI struct {
	in   *bufio.Scanner
	out  io.Writer
	game *Game
}

func NewCLI(store PlayerStore, in io.Reader, out io.Writer, alerter BlindAlerter) *CLI {
	return &CLI{
		in:  bufio.NewScanner(in),
		out: out,
		game: &Game{
			alerter: alerter,
			store:   store,
		},
	}
}

const PlayerPrompt = "Please enter the number of players: "

func (cli *CLI) PlayPoker() {
	fmt.Fprint(cli.out, PlayerPrompt)

	numberOfPlayersInput := cli.readLine()
	numberOfPlayers, _ := strconv.Atoi(strings.Trim(numberOfPlayersInput, "\n"))

	cli.game.Start(numberOfPlayers)

	winnerInput := cli.readLine()
	winner := extractWinner(winnerInput)

	cli.game.Finish(winner)
}

func extractWinner(userInput string) string {
	return strings.Replace(userInput, " wins\n", "", 1)
}

func (cli *CLI) readLine() string {
	cli.in.Scan()
	return cli.in.Text()
}
```

"도메인" 관점에서:

* 몇 명이 플레이하는지 나타내어 `Game`을 `Start`하고 싶습니다
* 승자를 선언하여 `Game`을 `Finish`하고 싶습니다

새 `Game` 타입이 이것을 캡슐화합니다.

이 변경으로 이제 알림과 결과 저장을 담당하므로 `BlindAlerter`와 `PlayerStore`를 `Game`에 전달했습니다.

`CLI`는 이제 다음에만 관심을 갖습니다:

* 기존 종속성으로 `Game` 구성 (다음에 리팩토링합니다)
* 사용자 입력을 `Game`에 대한 메서드 호출로 해석

실패하는 테스트 상태로 확장된 기간 동안 "큰" 리팩토링을 피하고 싶습니다. 그러면 실수 가능성이 높아집니다. (대규모/분산 팀에서 작업하는 경우 이것이 더 중요합니다)

먼저 `CLI`에 주입하도록 `Game`을 리팩토링합니다. 테스트에서 이를 용이하게 하기 위해 가장 작은 변경을 한 다음 사용자 입력 파싱과 게임 관리라는 주제로 테스트를 어떻게 분해할 수 있는지 봅니다.

지금 해야 할 일은 `NewCLI`를 변경하는 것입니다

```go
func NewCLI(in io.Reader, out io.Writer, game *Game) *CLI {
	return &CLI{
		in:   bufio.NewScanner(in),
		out:  out,
		game: game,
	}
}
```

이것은 이미 개선된 것 같습니다. 종속성이 줄었고 _종속성 목록이 입출력에 관심을 가지고 게임 관련 작업을 `Game`에 위임하는 CLI의 전체 디자인 목표를 반영합니다_.

컴파일하려고 하면 문제가 있습니다. 지금은 `Game`에 대한 모킹을 걱정하지 말고 모든 것을 컴파일하고 테스트를 통과시키기 위해 _실제_ `Game`을 초기화하세요.

이렇게 하려면 생성자를 만들어야 합니다

```go
func NewGame(alerter BlindAlerter, store PlayerStore) *Game {
	return &Game{
		alerter: alerter,
		store:   store,
	}
}
```

수정되는 테스트 설정 중 하나의 예입니다

```go
stdout := &bytes.Buffer{}
in := strings.NewReader("7\n")
blindAlerter := &SpyBlindAlerter{}
game := poker.NewGame(blindAlerter, dummyPlayerStore)

cli := poker.NewCLI(in, stdout, game)
cli.PlayPoker()
```

테스트를 수정하고 다시 녹색으로 돌아가는 데 많은 노력이 필요하지 않을 것입니다 (그게 요점입니다!) 하지만 다음 단계 전에 `main.go`도 수정하세요.

```go
// main.go
game := poker.NewGame(poker.BlindAlerterFunc(poker.StdOutAlerter), store)
cli := poker.NewCLI(os.Stdin, os.Stdout, game)
cli.PlayPoker()
```

이제 `Game`을 추출했으므로 게임 관련 어설션을 CLI와 별도의 테스트로 이동해야 합니다.

이것은 CLI 테스트를 복사하지만 종속성이 더 적은 연습입니다

```go
func TestGame_Start(t *testing.T) {
	t.Run("schedules alerts on game start for 5 players", func(t *testing.T) {
		blindAlerter := &poker.SpyBlindAlerter{}
		game := poker.NewGame(blindAlerter, dummyPlayerStore)

		game.Start(5)

		cases := []poker.ScheduledAlert{
			{At: 0 * time.Second, Amount: 100},
			{At: 10 * time.Minute, Amount: 200},
			{At: 20 * time.Minute, Amount: 300},
			{At: 30 * time.Minute, Amount: 400},
			{At: 40 * time.Minute, Amount: 500},
			{At: 50 * time.Minute, Amount: 600},
			{At: 60 * time.Minute, Amount: 800},
			{At: 70 * time.Minute, Amount: 1000},
			{At: 80 * time.Minute, Amount: 2000},
			{At: 90 * time.Minute, Amount: 4000},
			{At: 100 * time.Minute, Amount: 8000},
		}

		checkSchedulingCases(cases, t, blindAlerter)
	})

	t.Run("schedules alerts on game start for 7 players", func(t *testing.T) {
		blindAlerter := &poker.SpyBlindAlerter{}
		game := poker.NewGame(blindAlerter, dummyPlayerStore)

		game.Start(7)

		cases := []poker.ScheduledAlert{
			{At: 0 * time.Second, Amount: 100},
			{At: 12 * time.Minute, Amount: 200},
			{At: 24 * time.Minute, Amount: 300},
			{At: 36 * time.Minute, Amount: 400},
		}

		checkSchedulingCases(cases, t, blindAlerter)
	})

}

func TestGame_Finish(t *testing.T) {
	store := &poker.StubPlayerStore{}
	game := poker.NewGame(dummyBlindAlerter, store)
	winner := "Ruth"

	game.Finish(winner)
	poker.AssertPlayerWin(t, store, winner)
}
```

포커 게임이 시작될 때 무슨 일이 발생하는지에 대한 의도가 이제 훨씬 명확합니다.

게임이 끝날 때에 대한 테스트도 이동하세요.

게임 로직에 대한 테스트를 이동했다고 만족하면 의도된 책임을 더 명확하게 반영하도록 CLI 테스트를 단순화할 수 있습니다

* 사용자 입력을 처리하고 적절할 때 `Game`의 메서드를 호출합니다
* 출력을 보냅니다
* 결정적으로 게임이 실제로 어떻게 작동하는지 알지 못합니다

이렇게 하려면 `CLI`가 더 이상 구체적인 `Game` 타입에 의존하지 않고 대신 `Start(numberOfPlayers)`와 `Finish(winner)`가 있는 인터페이스를 받아들이도록 해야 합니다. 그런 다음 해당 타입의 스파이를 만들고 올바른 호출이 이루어졌는지 확인할 수 있습니다.

여기서 명명이 때때로 어색하다는 것을 깨닫습니다. `Game`을 `TexasHoldem`으로 이름을 바꾸고 (우리가 플레이하는 게임의 _종류_이므로) 새 인터페이스를 `Game`이라고 합니다. 이것은 CLI가 우리가 플레이하는 실제 게임과 `Start`와 `Finish`할 때 무슨 일이 발생하는지 모른다는 개념에 충실합니다.

```go
type Game interface {
	Start(numberOfPlayers int)
	Finish(winner string)
}
```

`CLI` 내부의 `*Game`에 대한 모든 참조를 `Game` (새 인터페이스)으로 교체하세요. 항상 리팩토링하는 동안 모든 것이 녹색인지 확인하기 위해 테스트를 다시 실행하세요.

이제 `CLI`를 `TexasHoldem`에서 분리했으므로 스파이를 사용하여 예상할 때 올바른 인수로 `Start`와 `Finish`가 호출되는지 확인할 수 있습니다.

`Game`을 구현하는 스파이를 만듭니다

```go
type GameSpy struct {
	StartedWith  int
	FinishedWith string
}

func (g *GameSpy) Start(numberOfPlayers int) {
	g.StartedWith = numberOfPlayers
}

func (g *GameSpy) Finish(winner string) {
	g.FinishedWith = winner
}
```

게임 관련 로직을 테스트하는 모든 `CLI` 테스트를 `GameSpy`가 어떻게 호출되는지에 대한 확인으로 교체합니다. 그러면 테스트에서 CLI의 책임이 명확하게 반영됩니다.

수정되는 테스트 중 하나의 예입니다; 나머지는 직접 해보고 막히면 소스 코드를 확인하세요.

```go
	t.Run("it prompts the user to enter the number of players and starts the game", func(t *testing.T) {
		stdout := &bytes.Buffer{}
		in := strings.NewReader("7\n")
		game := &GameSpy{}

		cli := poker.NewCLI(in, stdout, game)
		cli.PlayPoker()

		gotPrompt := stdout.String()
		wantPrompt := poker.PlayerPrompt

		if gotPrompt != wantPrompt {
			t.Errorf("got %q, want %q", gotPrompt, wantPrompt)
		}

		if game.StartedWith != 7 {
			t.Errorf("wanted Start called with 7 but got %d", game.StartedWith)
		}
	})
```

이제 깔끔한 관심사 분리가 되었으므로 `CLI`의 IO 주변 엣지 케이스를 확인하는 것이 더 쉬워야 합니다.

플레이어 수를 묻는 메시지가 표시될 때 사용자가 숫자가 아닌 값을 입력하는 시나리오를 해결해야 합니다:

코드는 게임을 시작하지 않아야 하고 사용자에게 유용한 오류를 출력한 다음 종료해야 합니다.

## 먼저 테스트 작성

게임이 시작되지 않는지 확인하는 것부터 시작합니다

```go
t.Run("it prints an error when a non numeric value is entered and does not start the game", func(t *testing.T) {
	stdout := &bytes.Buffer{}
	in := strings.NewReader("Pies\n")
	game := &GameSpy{}

	cli := poker.NewCLI(in, stdout, game)
	cli.PlayPoker()

	if game.StartCalled {
		t.Errorf("game should not have started")
	}
})
```

`Start`가 호출된 경우에만 설정되는 `GameSpy`에 `StartCalled` 필드를 추가해야 합니다

## 테스트 실행 시도

```
=== RUN   TestCLI/it_prints_an_error_when_a_non_numeric_value_is_entered_and_does_not_start_the_game
    --- FAIL: TestCLI/it_prints_an_error_when_a_non_numeric_value_is_entered_and_does_not_start_the_game (0.00s)
        CLI_test.go:62: game should not have started
```

## 테스트를 통과시키기 위한 충분한 코드 작성

`Atoi`를 호출하는 곳에서 에러를 확인하기만 하면 됩니다

```go
numberOfPlayers, err := strconv.Atoi(cli.readLine())

if err != nil {
	return
}
```

다음으로 사용자에게 무엇을 잘못했는지 알려야 하므로 `stdout`에 출력된 것에 대해 어설션합니다.

## 먼저 테스트 작성

이전에 `stdout`에 출력된 것에 대해 어설션했으므로 지금은 해당 코드를 복사할 수 있습니다

```go
gotPrompt := stdout.String()

wantPrompt := poker.PlayerPrompt + "you're so silly"

if gotPrompt != wantPrompt {
	t.Errorf("got %q, want %q", gotPrompt, wantPrompt)
}
```

stdout에 쓰여진 _모든 것_을 저장하므로 여전히 `poker.PlayerPrompt`를 예상합니다. 그런 다음 추가로 출력되는 것을 확인합니다. 지금은 정확한 문구에 대해 너무 신경 쓰지 않고 리팩토링할 때 해결합니다.

## 테스트 실행 시도

```
=== RUN   TestCLI/it_prints_an_error_when_a_non_numeric_value_is_entered_and_does_not_start_the_game
    --- FAIL: TestCLI/it_prints_an_error_when_a_non_numeric_value_is_entered_and_does_not_start_the_game (0.00s)
        CLI_test.go:70: got 'Please enter the number of players: ', want 'Please enter the number of players: you're so silly'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

에러 처리 코드 변경

```go
if err != nil {
	fmt.Fprint(cli.out, "you're so silly")
	return
}
```

## 리팩토링

이제 `PlayerPrompt`처럼 메시지를 상수로 리팩토링합니다

```go
wantPrompt := poker.PlayerPrompt + poker.BadPlayerInputErrMsg
```

그리고 더 적절한 메시지를 넣습니다

```go
const BadPlayerInputErrMsg = "Bad value received for number of players, please try again with a number"
```

마지막으로 `stdout`에 전송된 것에 대한 테스트가 꽤 장황하므로 정리하기 위해 assert 함수를 작성합시다.

```go
func assertMessagesSentToUser(t testing.TB, stdout *bytes.Buffer, messages ...string) {
	t.Helper()
	want := strings.Join(messages, "")
	got := stdout.String()
	if got != want {
		t.Errorf("got %q sent to stdout but expected %+v", got, messages)
	}
}
```

다양한 양의 메시지에 대해 어설션해야 하므로 vararg 구문(`...string`)을 사용하는 것이 여기서 편리합니다.

사용자에게 전송된 메시지에 대해 어설션하는 두 테스트 모두에서 이 헬퍼를 사용합니다.

일부 `assertX` 함수로 도움이 될 수 있는 여러 테스트가 있으므로 테스트가 잘 읽히도록 리팩토링하여 정리하는 연습을 하세요.

시간을 내어 우리가 도출한 일부 테스트의 가치에 대해 생각해 보세요. 필요 이상의 테스트를 원하지 않습니다, _그리고 여전히 모든 것이 작동한다는 확신을 가지면서_ 일부를 리팩토링/제거할 수 있습니까?

제가 생각해낸 것입니다

```go
func TestCLI(t *testing.T) {

	t.Run("start game with 3 players and finish game with 'Chris' as winner", func(t *testing.T) {
		game := &GameSpy{}
		stdout := &bytes.Buffer{}

		in := userSends("3", "Chris wins")
		cli := poker.NewCLI(in, stdout, game)

		cli.PlayPoker()

		assertMessagesSentToUser(t, stdout, poker.PlayerPrompt)
		assertGameStartedWith(t, game, 3)
		assertFinishCalledWith(t, game, "Chris")
	})

	t.Run("start game with 8 players and record 'Cleo' as winner", func(t *testing.T) {
		game := &GameSpy{}

		in := userSends("8", "Cleo wins")
		cli := poker.NewCLI(in, dummyStdOut, game)

		cli.PlayPoker()

		assertGameStartedWith(t, game, 8)
		assertFinishCalledWith(t, game, "Cleo")
	})

	t.Run("it prints an error when a non numeric value is entered and does not start the game", func(t *testing.T) {
		game := &GameSpy{}

		stdout := &bytes.Buffer{}
		in := userSends("pies")

		cli := poker.NewCLI(in, stdout, game)
		cli.PlayPoker()

		assertGameNotStarted(t, game)
		assertMessagesSentToUser(t, stdout, poker.PlayerPrompt, poker.BadPlayerInputErrMsg)
	})
}
```

테스트는 이제 CLI의 주요 기능을 반영합니다, 플레이어 수와 누가 이겼는지에 대한 사용자 입력을 읽고 플레이어 수에 대해 잘못된 값이 입력되었을 때를 처리할 수 있습니다. 이렇게 하면 독자에게 `CLI`가 무엇을 하는지 명확하지만 무엇을 하지 않는지도 명확합니다.

사용자가 `Ruth wins` 대신 `Lloyd is a killer`를 입력하면 어떻게 됩니까?

이 시나리오에 대한 테스트를 작성하고 통과시켜 이 챕터를 마무리하세요.

## 마무리

### 빠른 프로젝트 요약

지난 5개 챕터 동안 상당한 양의 코드를 천천히 TDD했습니다

* 커맨드 라인 애플리케이션과 웹 서버의 두 개의 애플리케이션이 있습니다.
* 이 두 애플리케이션은 승자를 기록하기 위해 `PlayerStore`에 의존합니다
* 웹 서버는 또한 누가 가장 많이 이기고 있는지에 대한 리그 테이블을 표시할 수 있습니다
* 커맨드 라인 앱은 현재 블라인드 값이 무엇인지 추적하여 플레이어가 포커 게임을 플레이하도록 도와줍니다.

### time.Afterfunc

특정 기간 후에 함수 호출을 스케줄하는 매우 편리한 방법입니다. 작업할 많은 시간 절약 함수와 메서드가 있으므로 [`time`에 대한 문서를 살펴보는](https://golang.org/pkg/time/) 데 시간을 투자할 가치가 있습니다.

제가 좋아하는 것들 중 일부입니다

* `time.After(duration)`는 duration이 만료되면 `chan Time`을 반환합니다. 따라서 특정 시간 _이후에_ 무언가를 하고 싶다면 이것이 도움이 될 수 있습니다.
* `time.NewTicker(duration)`는 `Ticker`를 반환하는데 한 번만이 아니라 매 duration마다 "틱"하는 채널을 반환한다는 점에서 위와 유사합니다. 매 `N duration`마다 일부 코드를 실행하려면 매우 편리합니다.

### 좋은 관심사 분리의 더 많은 예

_일반적으로_ 사용자 입력 및 응답 처리의 책임을 도메인 코드에서 분리하는 것이 좋은 관행입니다. 커맨드 라인 애플리케이션과 웹 서버에서 여기서 볼 수 있습니다.

테스트가 지저분해졌습니다. 너무 많은 어설션(이 입력을 확인하고, 이 알림을 스케줄하고, 등)과 너무 많은 종속성이 있었습니다. 시각적으로 어수선한 것을 볼 수 있습니다; **테스트를 듣는 것은 매우 중요합니다**.

* 테스트가 지저분해 보이면 리팩토링해 보세요.
* 이렇게 했는데 여전히 지저분하다면 디자인의 결함을 가리키고 있을 가능성이 높습니다
* 이것은 테스트의 진정한 강점 중 하나입니다.

테스트와 프로덕션 코드가 약간 어수선해도 테스트의 지원을 받아 자유롭게 리팩토링할 수 있었습니다.

이러한 상황에 처했을 때 항상 작은 단계를 밟고 모든 변경 후에 테스트를 다시 실행하세요.

테스트 코드 _와_ 프로덕션 코드를 동시에 리팩토링하는 것은 위험했을 것입니다, 그래서 먼저 프로덕션 코드를 리팩토링했습니다 (현재 상태에서는 테스트를 많이 개선할 수 없었습니다) 인터페이스를 변경하지 않고 변경하는 동안 테스트에 가능한 한 의존할 수 있도록 했습니다. _그런 다음_ 디자인이 개선된 후 테스트를 리팩토링했습니다.

리팩토링 후 종속성 목록이 디자인 목표를 반영했습니다. 이것은 DI의 또 다른 이점으로 종종 의도를 문서화합니다. 전역 변수에 의존하면 책임이 매우 불분명해집니다.

## 인터페이스를 구현하는 함수의 예

하나의 메서드가 있는 인터페이스를 정의할 때 사용자가 함수만으로 인터페이스를 구현할 수 있도록 `MyInterfaceFunc` 타입을 보완하는 것을 고려할 수 있습니다.

```go
type BlindAlerter interface {
	ScheduleAlertAt(duration time.Duration, amount int)
}

// BlindAlerterFunc를 사용하면 함수로 BlindAlerter를 구현할 수 있습니다
type BlindAlerterFunc func(duration time.Duration, amount int)

// ScheduleAlertAt은 BlindAlerter의 BlindAlerterFunc 구현입니다
func (a BlindAlerterFunc) ScheduleAlertAt(duration time.Duration, amount int) {
	a(duration, amount)
}
```

이렇게 하면 라이브러리 사용자가 함수만으로 인터페이스를 구현할 수 있습니다. [타입 변환](https://go.dev/tour/basics/13)을 사용하여 함수를 `BlindAlerterFunc`로 변환한 다음 BlindAlerter로 사용할 수 있습니다 (`BlindAlerterFunc`가 `BlindAlerter`를 구현하므로).

```go
game := poker.NewTexasHoldem(poker.BlindAlerterFunc(poker.StdOutAlerter), store)
```

여기서 더 넓은 요점은 Go에서 구조체뿐만 아니라 _타입_에 메서드를 추가할 수 있다는 것입니다. 이것은 매우 강력한 기능이며 더 편리한 방법으로 인터페이스를 구현하는 데 사용할 수 있습니다.

함수의 타입뿐만 아니라 다른 타입 주위에 타입을 정의하여 메서드를 추가할 수도 있습니다.

```go
type Blog map[string]string

func (b Blog) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, b[r.URL.Path])
}
```

여기서 맵에 저장된 게시물에 대한 키로 URL 경로를 사용하는 매우 간단한 "블로그"를 구현하는 HTTP 핸들러를 만들었습니다.

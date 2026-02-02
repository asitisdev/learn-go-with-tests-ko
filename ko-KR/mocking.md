# 모킹

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/mocking)**

3부터 카운트다운하고, 각 숫자를 새 줄에 출력하며(1초 간격으로), 0에 도달하면 "Go!"를 출력하고 종료하는 프로그램을 작성해 달라는 요청을 받았습니다.

```
3
2
1
Go!
```

`Countdown`이라는 함수를 작성하고 `main` 프로그램에 넣어서 다음과 같이 보이도록 처리할 것입니다:

```go
package main

func main() {
	Countdown()
}
```

이것은 꽤 사소한 프로그램이지만, 완전히 테스트하려면 항상 그렇듯이 **반복적**이고 **테스트 주도** 접근 방식을 취해야 합니다.

반복적이란 무슨 뜻일까요? **유용한 소프트웨어**를 갖기 위해 가능한 가장 작은 단계를 밟도록 합니다.

이론적으로 일부 해킹 후에 작동할 코드에 오랜 시간을 보내고 싶지 않습니다. 왜냐하면 그것이 개발자들이 종종 토끼굴에 빠지는 방법이기 때문입니다. ***작동하는 소프트웨어*를 가질 수 있도록 요구 사항을 가능한 작게 분할할 수 있는 것은 중요한 기술입니다.**

작업을 나누고 반복하는 방법은 다음과 같습니다:

- 3 출력
- 3, 2, 1 그리고 Go! 출력
- 각 줄 사이에 1초 대기

## 먼저 테스트 작성

소프트웨어가 stdout에 출력해야 하고 DI 섹션에서 이를 테스트하는 것을 용이하게 하기 위해 의존성 주입(DI)을 사용할 수 있는 방법을 보았습니다.

```go
func TestCountdown(t *testing.T) {
	buffer := &bytes.Buffer{}

	Countdown(buffer)

	got := buffer.String()
	want := "3"

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

`buffer`와 같은 것이 익숙하지 않다면 [이전 섹션](dependency-injection.md)을 다시 읽으세요.

`Countdown` 함수가 데이터를 어딘가에 쓰기를 원하고 `io.Writer`는 Go에서 인터페이스로 캡처하는 사실상의 방법입니다.

- `main`에서 `os.Stdout`에 보내어 사용자가 터미널에 출력된 카운트다운을 볼 수 있도록 합니다.
- 테스트에서는 `bytes.Buffer`에 보내어 테스트가 생성되는 데이터를 캡처할 수 있습니다.

## 테스트 실행 시도

`./countdown_test.go:11:2: undefined: Countdown`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`Countdown` 정의

```go
func Countdown() {}
```

다시 시도

```
./countdown_test.go:11:11: too many arguments in call to Countdown
    have (*bytes.Buffer)
    want ()
```

컴파일러가 함수 시그니처가 무엇인지 알려주므로 업데이트하세요.

```go
func Countdown(out *bytes.Buffer) {}
```

`countdown_test.go:17: got '' want '3'`

완벽합니다!

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Countdown(out *bytes.Buffer) {
	fmt.Fprint(out, "3")
}
```

`io.Writer`(`*bytes.Buffer`와 같은)를 받아서 `string`을 보내는 `fmt.Fprint`를 사용합니다. 테스트가 통과해야 합니다.

## 리팩토링

`*bytes.Buffer`가 작동하지만, 대신 범용 인터페이스를 사용하는 것이 더 나을 것입니다.

```go
func Countdown(out io.Writer) {
	fmt.Fprint(out, "3")
}
```

테스트를 다시 실행하면 통과해야 합니다.

문제를 완료하기 위해, 진행 상황을 확인할 수 있는 작동하는 소프트웨어가 있도록 함수를 `main`에 연결합시다.

```go
package main

import (
	"fmt"
	"io"
	"os"
)

func Countdown(out io.Writer) {
	fmt.Fprint(out, "3")
}

func main() {
	Countdown(os.Stdout)
}
```

프로그램을 실행하고 손재주에 놀라세요.

네, 이것은 사소해 보이지만 이 접근 방식은 모든 프로젝트에 권장하는 것입니다. **기능의 얇은 조각을 가져와서 테스트로 뒷받침되는 엔드 투 엔드로 작동하게 만드세요.**

다음으로 2, 1을 출력한 다음 "Go!"를 출력하도록 만들 수 있습니다.

## 먼저 테스트 작성

전체 배관이 제대로 작동하도록 투자함으로써, 솔루션을 안전하고 쉽게 반복할 수 있습니다. 모든 로직이 테스트되므로 작동하는지 확신하기 위해 더 이상 멈추고 프로그램을 다시 실행할 필요가 없습니다.

```go
func TestCountdown(t *testing.T) {
	buffer := &bytes.Buffer{}

	Countdown(buffer)

	got := buffer.String()
	want := `3
2
1
Go!`

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

백틱 구문은 `string`을 만드는 또 다른 방법이며 테스트에 완벽한 줄 바꿈과 같은 것을 포함할 수 있게 합니다.

## 테스트 실행 시도

```
countdown_test.go:21: got '3' want '3
        2
        1
        Go!'
```
## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Countdown(out io.Writer) {
	for i := 3; i > 0; i-- {
		fmt.Fprintln(out, i)
	}
	fmt.Fprint(out, "Go!")
}
```

`i--`로 역순으로 세는 `for` 루프를 사용하고 `fmt.Fprintln`을 사용하여 숫자와 줄 바꿈 문자를 `out`에 출력합니다. 마지막으로 `fmt.Fprint`를 사용하여 "Go!"를 보냅니다.

## 리팩토링

일부 매직 값을 명명된 상수로 리팩토링하는 것 외에는 리팩토링할 것이 많지 않습니다.

```go
const finalWord = "Go!"
const countdownStart = 3

func Countdown(out io.Writer) {
	for i := countdownStart; i > 0; i-- {
		fmt.Fprintln(out, i)
	}
	fmt.Fprint(out, finalWord)
}
```

지금 프로그램을 실행하면 원하는 출력을 얻지만 1초 간격의 극적인 카운트다운이 없습니다.

Go에서는 `time.Sleep`으로 이것을 달성할 수 있습니다. 코드에 추가해 보세요.

```go
func Countdown(out io.Writer) {
	for i := countdownStart; i > 0; i-- {
		fmt.Fprintln(out, i)
		time.Sleep(1 * time.Second)
	}

	fmt.Fprint(out, finalWord)
}
```

프로그램을 실행하면 원하는 대로 작동합니다.

## 모킹

테스트가 여전히 통과하고 소프트웨어가 의도한 대로 작동하지만 몇 가지 문제가 있습니다:
- 테스트가 실행하는 데 3초가 걸립니다.
    - 소프트웨어 개발에 대한 모든 미래지향적인 글은 빠른 피드백 루프의 중요성을 강조합니다.
    - **느린 테스트는 개발자 생산성을 망칩니다**.
    - 요구 사항이 더 정교해져서 더 많은 테스트가 필요하다고 상상해 보세요. `Countdown`의 모든 새 테스트에 3초가 추가되는 것이 만족스러운가요?
- 함수의 중요한 속성을 테스트하지 않았습니다.

추출해야 하는 `Sleep`에 대한 의존성이 있어서 테스트에서 제어할 수 있습니다.

`time.Sleep`을 **모킹**할 수 있다면 **의존성 주입**을 사용하여 "실제" `time.Sleep` 대신 사용할 수 있고 **호출을 스파이**하여 어설션을 만들 수 있습니다.

## 먼저 테스트 작성

의존성을 인터페이스로 정의합시다. 이를 통해 `main`에서 **실제** Sleeper를 사용하고 테스트에서 **스파이 슬리퍼**를 사용할 수 있습니다. 인터페이스를 사용하면 `Countdown` 함수는 이것을 모르고 호출자에게 약간의 유연성을 추가합니다.

```go
type Sleeper interface {
	Sleep()
}
```

`Countdown` 함수가 대기 시간을 책임지지 않도록 설계 결정을 내렸습니다. 이것은 적어도 지금은 코드를 약간 단순화하고 함수 사용자가 원하는 대로 대기 시간을 구성할 수 있음을 의미합니다.

이제 테스트에서 사용할 **모킹**을 만들어야 합니다.

```go
type SpySleeper struct {
	Calls int
}

func (s *SpySleeper) Sleep() {
	s.Calls++
}
```

**스파이**는 의존성이 어떻게 사용되는지 기록할 수 있는 일종의 **모킹**입니다. 전송된 인자, 호출된 횟수 등을 기록할 수 있습니다. 우리의 경우, `Sleep()`이 호출된 횟수를 추적하여 테스트에서 확인할 수 있습니다.

Spy에 대한 의존성을 주입하고 sleep이 3번 호출되었는지 어설션하도록 테스트를 업데이트하세요.

```go
func TestCountdown(t *testing.T) {
	buffer := &bytes.Buffer{}
	spySleeper := &SpySleeper{}

	Countdown(buffer, spySleeper)

	got := buffer.String()
	want := `3
2
1
Go!`

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}

	if spySleeper.Calls != 3 {
		t.Errorf("not enough calls to sleeper, want 3 got %d", spySleeper.Calls)
	}
}
```

## 테스트 실행 시도

```
too many arguments in call to Countdown
    have (*bytes.Buffer, *SpySleeper)
    want (io.Writer)
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`Countdown`을 `Sleeper`를 받도록 업데이트해야 합니다

```go
func Countdown(out io.Writer, sleeper Sleeper) {
	for i := countdownStart; i > 0; i-- {
		fmt.Fprintln(out, i)
		time.Sleep(1 * time.Second)
	}

	fmt.Fprint(out, finalWord)
}
```

다시 시도하면, `main`도 같은 이유로 더 이상 컴파일되지 않습니다

```
./main.go:26:11: not enough arguments in call to Countdown
    have (*os.File)
    want (io.Writer, Sleeper)
```

필요한 인터페이스를 구현하는 **실제** sleeper를 만들어 봅시다

```go
type DefaultSleeper struct{}

func (d *DefaultSleeper) Sleep() {
	time.Sleep(1 * time.Second)
}
```

그런 다음 실제 애플리케이션에서 다음과 같이 사용할 수 있습니다

```go
func main() {
	sleeper := &DefaultSleeper{}
	Countdown(os.Stdout, sleeper)
}
```

## 테스트를 통과시키기 위한 충분한 코드 작성

테스트가 이제 컴파일되지만 주입된 의존성이 아닌 `time.Sleep`을 여전히 호출하고 있기 때문에 통과하지 않습니다. 수정해 봅시다.

```go
func Countdown(out io.Writer, sleeper Sleeper) {
	for i := countdownStart; i > 0; i-- {
		fmt.Fprintln(out, i)
		sleeper.Sleep()
	}

	fmt.Fprint(out, finalWord)
}
```

테스트가 통과하고 더 이상 3초가 걸리지 않아야 합니다.

### 여전히 일부 문제가 있습니다

테스트하지 않은 또 다른 중요한 속성이 있습니다.

`Countdown`은 각 다음 출력 전에 sleep해야 합니다, 예:

- `N 출력`
- `Sleep`
- `N-1 출력`
- `Sleep`
- `Go! 출력`
- 등

최신 변경 사항은 3번 sleep했다고만 어설션하지만, sleep이 순서가 맞지 않을 수 있습니다.

테스트를 작성할 때 테스트가 충분한 확신을 주는지 확신이 없으면, 그냥 깨뜨려 보세요! (먼저 소스 컨트롤에 변경 사항을 커밋했는지 확인하세요). 코드를 다음과 같이 변경하세요

```go
func Countdown(out io.Writer, sleeper Sleeper) {
	for i := countdownStart; i > 0; i-- {
		sleeper.Sleep()
	}

	for i := countdownStart; i > 0; i-- {
		fmt.Fprintln(out, i)
	}

	fmt.Fprint(out, finalWord)
}
```

테스트를 실행하면 구현이 잘못되었음에도 여전히 통과해야 합니다.

스파이를 다시 사용하여 작업 순서가 올바른지 확인하는 새 테스트를 해봅시다.

두 개의 다른 의존성이 있고 모든 작업을 하나의 목록에 기록하려고 합니다. 그래서 **둘 다를 위한 하나의 스파이**를 만들 것입니다.

```go
type SpyCountdownOperations struct {
	Calls []string
}

func (s *SpyCountdownOperations) Sleep() {
	s.Calls = append(s.Calls, sleep)
}

func (s *SpyCountdownOperations) Write(p []byte) (n int, err error) {
	s.Calls = append(s.Calls, write)
	return
}

const write = "write"
const sleep = "sleep"
```

`SpyCountdownOperations`는 `io.Writer`와 `Sleeper` 둘 다 구현하고, 모든 호출을 하나의 슬라이스에 기록합니다. 이 테스트에서는 작업 순서에만 관심이 있으므로, 명명된 작업 목록으로 기록하는 것으로 충분합니다.

이제 sleep과 print가 희망하는 순서로 작동하는지 확인하는 서브 테스트를 테스트 스위트에 추가할 수 있습니다

```go
t.Run("sleep before every print", func(t *testing.T) {
	spySleepPrinter := &SpyCountdownOperations{}
	Countdown(spySleepPrinter, spySleepPrinter)

	want := []string{
		write,
		sleep,
		write,
		sleep,
		write,
		sleep,
		write,
	}

	if !reflect.DeepEqual(want, spySleepPrinter.Calls) {
		t.Errorf("wanted calls %v got %v", want, spySleepPrinter.Calls)
	}
})
```

이 테스트는 이제 실패해야 합니다. `Countdown`을 원래대로 되돌려 테스트를 수정하세요.

이제 `Sleeper`를 스파이하는 두 개의 테스트가 있으므로 테스트를 리팩토링하여 하나는 무엇이 출력되는지 테스트하고 다른 하나는 출력 사이에 sleep하는지 확인할 수 있습니다. 마지막으로, 더 이상 사용되지 않는 첫 번째 스파이를 삭제할 수 있습니다.

```go
func TestCountdown(t *testing.T) {

	t.Run("prints 3 to Go!", func(t *testing.T) {
		buffer := &bytes.Buffer{}
		Countdown(buffer, &SpyCountdownOperations{})

		got := buffer.String()
		want := `3
2
1
Go!`

		if got != want {
			t.Errorf("got %q want %q", got, want)
		}
	})

	t.Run("sleep before every print", func(t *testing.T) {
		spySleepPrinter := &SpyCountdownOperations{}
		Countdown(spySleepPrinter, spySleepPrinter)

		want := []string{
			write,
			sleep,
			write,
			sleep,
			write,
			sleep,
			write,
		}

		if !reflect.DeepEqual(want, spySleepPrinter.Calls) {
			t.Errorf("wanted calls %v got %v", want, spySleepPrinter.Calls)
		}
	})
}
```

이제 함수와 두 가지 중요한 속성이 제대로 테스트되었습니다.

## Sleeper를 구성 가능하도록 확장

좋은 기능은 `Sleeper`를 구성 가능하게 하는 것입니다. 이것은 메인 프로그램에서 대기 시간을 조정할 수 있음을 의미합니다.

### 먼저 테스트 작성

먼저 구성 및 테스트에 필요한 것을 받아들이는 `ConfigurableSleeper`에 대한 새 타입을 만들어 봅시다.

```go
type ConfigurableSleeper struct {
	duration time.Duration
	sleep    func(time.Duration)
}
```

`duration`을 사용하여 대기 시간을 구성하고 `sleep`을 sleep 함수를 전달하는 방법으로 사용합니다. `sleep`의 시그니처는 `time.Sleep`과 동일하므로 실제 구현에서 `time.Sleep`을 사용하고 테스트에서 다음 스파이를 사용할 수 있습니다:

```go
type SpyTime struct {
	durationSlept time.Duration
}

func (s *SpyTime) SetDurationSlept(duration time.Duration) {
	s.durationSlept = duration
}
```

스파이가 준비되면 구성 가능한 sleeper에 대한 새 테스트를 만들 수 있습니다.

```go
func TestConfigurableSleeper(t *testing.T) {
	sleepTime := 5 * time.Second

	spyTime := &SpyTime{}
	sleeper := ConfigurableSleeper{sleepTime, spyTime.SetDurationSlept}
	sleeper.Sleep()

	if spyTime.durationSlept != sleepTime {
		t.Errorf("should have slept for %v but slept for %v", sleepTime, spyTime.durationSlept)
	}
}
```

이 테스트에는 새로운 것이 없어야 하며 이전 모킹 테스트와 매우 유사하게 설정됩니다.

### 테스트 실행 시도
```
sleeper.Sleep undefined (type ConfigurableSleeper has no field or method Sleep, but does have sleep)

```

`ConfigurableSleeper`에 `Sleep` 메서드가 생성되지 않았음을 나타내는 매우 명확한 오류 메시지를 볼 수 있습니다.

### 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성
```go
func (c *ConfigurableSleeper) Sleep() {
}
```

새 `Sleep` 함수가 구현되어 실패하는 테스트가 있습니다.

```
countdown_test.go:56: should have slept for 5s but slept for 0s
```

### 테스트를 통과시키기 위한 충분한 코드 작성

이제 해야 할 일은 `ConfigurableSleeper`에 대한 `Sleep` 함수를 구현하는 것입니다.

```go
func (c *ConfigurableSleeper) Sleep() {
	c.sleep(c.duration)
}
```

이 변경으로 모든 테스트가 다시 통과해야 하며 메인 프로그램이 전혀 변경되지 않았으므로 왜 이런 번거로움인지 궁금할 수 있습니다. 다음 섹션 이후에 명확해지기를 바랍니다.

### 정리 및 리팩토링

마지막으로 해야 할 일은 실제로 main 함수에서 `ConfigurableSleeper`를 사용하는 것입니다.

```go
func main() {
	sleeper := &ConfigurableSleeper{1 * time.Second, time.Sleep}
	Countdown(os.Stdout, sleeper)
}
```

테스트와 프로그램을 수동으로 실행하면 모든 동작이 동일하게 유지되는 것을 볼 수 있습니다.

`ConfigurableSleeper`를 사용하므로 이제 `DefaultSleeper` 구현을 삭제해도 안전합니다. 프로그램을 마무리하고 임의의 긴 카운트다운이 있는 더 [일반적인](https://stackoverflow.com/questions/19291776/whats-the-difference-between-abstraction-and-generalization) Sleeper를 갖게 됩니다.

## 하지만 모킹은 악하지 않나요?

모킹이 악하다고 들었을 수 있습니다. 소프트웨어 개발의 모든 것과 마찬가지로 [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)처럼 악을 위해 사용될 수 있습니다.

사람들은 보통 **테스트를 듣지 않고** **리팩토링 단계를 존중하지 않을** 때 나쁜 상태에 빠집니다.

모킹 코드가 복잡해지거나 무언가를 테스트하기 위해 많은 것을 모킹해야 한다면, 그 나쁜 느낌에 **귀 기울여** 코드에 대해 생각해야 합니다. 보통 다음의 징후입니다

- 테스트하는 것이 너무 많은 것을 해야 합니다 (모킹해야 할 의존성이 너무 많기 때문에)
  - 모듈을 분리하여 덜 하도록 하세요
- 의존성이 너무 세분화되어 있습니다
  - 이러한 의존성 중 일부를 하나의 의미 있는 모듈로 통합하는 방법을 생각하세요
- 테스트가 구현 세부 사항에 너무 관심이 있습니다
  - 구현보다는 예상 동작을 테스트하는 것을 선호하세요

일반적으로 많은 모킹은 코드의 **나쁜 추상화**를 가리킵니다.

**사람들이 여기서 TDD의 약점으로 보는 것은 실제로 강점**입니다. 종종 좋지 않은 테스트 코드는 나쁜 설계의 결과이거나 더 좋게 말하면, 잘 설계된 코드는 테스트하기 쉽습니다.

### 하지만 모킹과 테스트가 여전히 내 삶을 어렵게 만들어요!

이런 상황에 처한 적이 있나요?

- 일부 리팩토링을 하고 싶습니다
- 이를 위해 많은 테스트를 변경하게 됩니다
- TDD에 의문을 제기하고 "모킹은 해롭다"라는 제목의 Medium 게시물을 작성합니다

이것은 보통 너무 많은 **구현 세부 사항**을 테스트하고 있다는 신호입니다. 구현이 시스템 실행 방식에 정말 중요하지 않은 한 테스트가 **유용한 동작**을 테스트하도록 노력하세요.

정확히 **어느 수준**에서 테스트해야 하는지 아는 것이 때때로 어렵지만 여기에 따르려고 하는 몇 가지 사고 과정과 규칙이 있습니다:

- **리팩토링의 정의는 코드는 변경되지만 동작은 동일하게 유지된다는 것**입니다. 이론상 리팩토링을 하기로 결정했다면 테스트 변경 없이 커밋을 할 수 있어야 합니다. 그래서 테스트를 작성할 때 스스로에게 물어보세요
  - 원하는 동작을 테스트하고 있나요, 아니면 구현 세부 사항을 테스트하고 있나요?
  - 이 코드를 리팩토링한다면 테스트를 많이 변경해야 하나요?
- Go에서 private 함수를 테스트할 수 있지만, private 함수는 public 동작을 지원하는 구현 세부 사항이므로 피하는 것이 좋습니다. public 동작을 테스트하세요. Sandi Metz는 private 함수를 "덜 안정적"이라고 설명하며 테스트를 그것에 결합하고 싶지 않습니다.
- 테스트가 **3개 이상의 모킹으로 작업**하면 적신호라고 느낍니다 - 설계에 대해 다시 생각할 시간입니다
- 스파이를 주의해서 사용하세요. 스파이를 사용하면 작성 중인 알고리즘의 내부를 볼 수 있어 매우 유용할 수 있지만 테스트 코드와 구현 간의 더 긴밀한 결합을 의미합니다. **스파이하려는 것에 대해 정말 관심이 있는지 확인하세요**

#### 그냥 모킹 프레임워크를 사용하면 안 되나요?

모킹은 마법이 필요 없고 비교적 간단합니다; 프레임워크를 사용하면 모킹이 실제보다 더 복잡해 보일 수 있습니다. 이 챕터에서는 자동 모킹을 사용하지 않아서 다음을 얻습니다:

- 모킹하는 방법에 대한 더 나은 이해
- 인터페이스 구현 연습

협업 프로젝트에서는 모킹 자동 생성에 가치가 있습니다. 팀에서 모킹 생성 도구는 테스트 더블에 대한 일관성을 코드화합니다. 이것은 일관성 없이 작성된 테스트로 변환될 수 있는 일관성 없이 작성된 테스트 더블을 피할 것입니다.

인터페이스에 대해 테스트 더블을 생성하는 모킹 생성기만 사용해야 합니다. 테스트가 작성되는 방식을 과도하게 지시하거나 많은 '마법'을 사용하는 모든 도구는 바다에 버릴 수 있습니다.

## 마무리

### TDD 접근 방식에 대해 더 알아보기

- 덜 사소한 예제에 직면했을 때, 문제를 "얇은 수직 슬라이스"로 분해하세요. 토끼굴에 빠지고 "빅뱅" 접근 방식을 취하는 것을 피하기 위해 가능한 빨리 **테스트로 뒷받침되는 작동하는 소프트웨어**에 도달하려고 하세요.
- 일부 작동하는 소프트웨어가 있으면 필요한 소프트웨어에 도달할 때까지 **작은 단계로 반복**하기가 더 쉬워야 합니다.

> "반복적 개발을 언제 사용해야 하나요? 성공하고 싶은 프로젝트에만 반복적 개발을 사용해야 합니다."

Martin Fowler.

### 모킹

- **모킹 없이는 코드의 중요한 영역이 테스트되지 않습니다**. 우리의 경우 코드가 각 출력 사이에 일시 중지되는지 테스트할 수 없지만 수많은 다른 예가 있습니다. 실패할 수 있는 서비스 호출? 특정 상태에서 시스템을 테스트하고 싶으신가요? 모킹 없이는 이러한 시나리오를 테스트하기 매우 어렵습니다.
- 모킹 없이는 간단한 비즈니스 규칙을 테스트하기 위해 데이터베이스와 기타 타사 항목을 설정해야 할 수 있습니다. 느린 테스트가 발생하여 **느린 피드백 루프**가 발생할 수 있습니다.
- 무언가를 테스트하기 위해 데이터베이스나 웹 서비스를 가동해야 하면 그러한 서비스의 비신뢰성으로 인해 **취약한 테스트**가 발생할 수 있습니다.

개발자가 모킹에 대해 배우면 **무엇을 하는지**보다 **작동하는 방식**의 관점에서 시스템의 모든 면을 과도하게 테스트하는 것이 매우 쉬워집니다. 항상 **테스트의 가치**와 향후 리팩토링에 미칠 영향에 대해 유의하세요.

모킹에 대한 이 게시물에서는 모킹의 일종인 **스파이**만 다루었습니다. 모킹은 "테스트 더블"의 한 유형입니다.

> [테스트 더블은 테스트 목적으로 프로덕션 객체를 대체하는 모든 경우에 대한 일반적인 용어입니다.](https://martinfowler.com/bliki/TestDouble.html)

테스트 더블에는 스텁, 스파이, 그리고 실제로 모킹과 같은 다양한 유형이 있습니다! 자세한 내용은 [Martin Fowler의 게시물](https://martinfowler.com/bliki/TestDouble.html)을 확인하세요.

## 보너스 - Go 1.23의 이터레이터 예제

Go 1.23에서 [이터레이터가 도입되었습니다](https://tip.golang.org/doc/go1.23). 다양한 방식으로 이터레이터를 사용할 수 있으며, 이 경우 리버스 순서로 카운트다운할 숫자를 반환하는 `countdownFrom` 이터레이터를 만들 수 있습니다.

커스텀 이터레이터를 작성하는 방법에 들어가기 전에, 어떻게 사용하는지 봅시다. 숫자에서 카운트다운하기 위해 꽤 명령적으로 보이는 루프를 작성하는 대신, 커스텀 `countdownFrom` 이터레이터를 `range`하여 이 코드를 더 표현적으로 보이게 할 수 있습니다.

```go
func Countdown(out io.Writer, sleeper Sleeper) {
	for i := range countDownFrom(3) {
		fmt.Fprintln(out, i)
		sleeper.Sleep()
	}

	fmt.Fprint(out, finalWord)
}
```

`countDownFrom`과 같은 이터레이터를 작성하려면 특정 방식으로 함수를 작성해야 합니다. 문서에서:

    "for-range" 루프의 "range" 절은 이제 다음 유형의 이터레이터 함수를 허용합니다
        func(func() bool)
        func(func(K) bool)
        func(func(K, V) bool)

(`K`와 `V`는 각각 키와 값 타입을 나타냅니다.)

우리의 경우, 키가 없고 값만 있습니다. Go는 `func(func(T) bool)`의 타입 별칭인 `iter.Seq[T]`라는 편의 타입도 제공합니다.

```go
func countDownFrom(from int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := from; i > 0; i-- {
			if !yield(i) {
				return
			}
		}
	}
}
```

이것은 `from`부터 시작하여 리버스 순서로 숫자를 반환하는 간단한 이터레이터입니다 - 우리 유스케이스에 완벽합니다.

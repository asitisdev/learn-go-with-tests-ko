# 동시성

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/concurrency)**

상황은 이렇습니다: 동료가 URL 목록의 상태를 확인하는 `CheckWebsites` 함수를 작성했습니다.

```go
package concurrency

type WebsiteChecker func(string) bool

func CheckWebsites(wc WebsiteChecker, urls []string) map[string]bool {
	results := make(map[string]bool)

	for _, url := range urls {
		results[url] = wc(url)
	}

	return results
}
```

확인된 각 URL을 boolean 값에 매핑한 맵을 반환합니다: 좋은 응답에는 `true`; 나쁜 응답에는 `false`.

또한 단일 URL을 받아 boolean을 반환하는 `WebsiteChecker`를 전달해야 합니다. 이것은 함수가 모든 웹사이트를 확인하는 데 사용됩니다.

[의존성 주입][DI]을 사용하여 실제 HTTP 호출을 하지 않고도 함수를 테스트할 수 있게 되어 안정적이고 빠릅니다.

그들이 작성한 테스트는 다음과 같습니다:

```go
package concurrency

import (
	"reflect"
	"testing"
)

func mockWebsiteChecker(url string) bool {
	return url != "waat://furhurterwe.geds"
}

func TestCheckWebsites(t *testing.T) {
	websites := []string{
		"http://google.com",
		"http://blog.gypsydave5.com",
		"waat://furhurterwe.geds",
	}

	want := map[string]bool{
		"http://google.com":          true,
		"http://blog.gypsydave5.com": true,
		"waat://furhurterwe.geds":    false,
	}

	got := CheckWebsites(mockWebsiteChecker, websites)

	if !reflect.DeepEqual(want, got) {
		t.Fatalf("wanted %v, got %v", want, got)
	}
}
```

함수는 프로덕션에 있고 수백 개의 웹사이트를 확인하는 데 사용되고 있습니다. 하지만 동료가 느리다는 불만을 받기 시작해서, 속도를 높이는 데 도움을 요청했습니다.

## 테스트 작성

벤치마크를 사용하여 `CheckWebsites`의 속도를 테스트하여 변경 사항의 효과를 볼 수 있습니다.

```go
package concurrency

import (
	"testing"
	"time"
)

func slowStubWebsiteChecker(_ string) bool {
	time.Sleep(20 * time.Millisecond)
	return true
}

func BenchmarkCheckWebsites(b *testing.B) {
	urls := make([]string, 100)
	for i := 0; i < len(urls); i++ {
		urls[i] = "a url"
	}

	for b.Loop() {
		CheckWebsites(slowStubWebsiteChecker, urls)
	}
}
```

벤치마크는 100개의 url 슬라이스를 사용하여 `CheckWebsites`를 테스트하고 `WebsiteChecker`의 새로운 가짜 구현을 사용합니다. `slowStubWebsiteChecker`는 의도적으로 느립니다. `time.Sleep`을 사용하여 정확히 20밀리초를 기다린 다음 true를 반환합니다.

`go test -bench=.`를 사용하여 벤치마크를 실행하면 (Windows Powershell에서는 `go test -bench="."`):

```sh
pkg: github.com/gypsydave5/learn-go-with-tests/concurrency/v0
BenchmarkCheckWebsites-4               1        2249228637 ns/op
PASS
ok      github.com/gypsydave5/learn-go-with-tests/concurrency/v0        2.268s
```

`CheckWebsites`가 2249228637 나노초로 벤치마크되었습니다 - 약 2.25초입니다.

더 빠르게 만들어 봅시다.

### 테스트를 통과시키기 위한 충분한 코드 작성

이제 드디어 동시성에 대해 이야기할 수 있습니다. 다음에서는 "동시에 진행 중인 것이 두 개 이상 있다"는 것을 의미합니다. 이것은 우리가 매일 자연스럽게 하는 것입니다.

예를 들어, 오늘 아침 저는 차를 만들었습니다. 주전자를 올려놓고, 끓을 때까지 기다리는 동안 냉장고에서 우유를 꺼내고, 찬장에서 차를 꺼내고, 제가 좋아하는 머그컵을 찾고, 티백을 컵에 넣은 다음, 주전자가 끓으면 물을 컵에 넣었습니다.

제가 *하지 않은* 것은 주전자를 올려놓고 끓을 때까지 멍하니 주전자를 쳐다보다가 주전자가 끓으면 다른 모든 것을 하는 것이었습니다.

첫 번째 방법으로 차를 만드는 것이 왜 더 빠른지 이해할 수 있다면, `CheckWebsites`를 더 빠르게 만드는 방법을 이해할 수 있습니다. 다음 웹사이트에 요청을 보내기 전에 웹사이트가 응답할 때까지 기다리는 대신, 컴퓨터가 기다리는 동안 다음 요청을 하도록 지시할 것입니다.

일반적으로 Go에서 함수 `doSomething()`을 호출할 때 반환될 때까지 기다립니다 (반환할 값이 없더라도 완료될 때까지 기다립니다). 이 작업이 *블로킹*한다고 합니다 - 완료될 때까지 기다리게 합니다. Go에서 블로킹하지 않는 작업은 *고루틴*이라는 별도의 *프로세스*에서 실행됩니다. 프로세스를 Go 코드의 페이지를 위에서 아래로 읽으면서 호출될 때 각 함수 '안으로' 들어가서 무엇을 하는지 읽는 것으로 생각하세요. 별도의 프로세스가 시작되면, 원래 독자가 페이지 아래로 계속 진행하도록 두면서 다른 독자가 함수 안에서 읽기 시작하는 것과 같습니다.

Go에게 새 고루틴을 시작하라고 하려면 함수 호출 앞에 `go` 키워드를 넣어 `go` 문으로 바꿉니다: `go doSomething()`.

```go
package concurrency

type WebsiteChecker func(string) bool

func CheckWebsites(wc WebsiteChecker, urls []string) map[string]bool {
	results := make(map[string]bool)

	for _, url := range urls {
		go func() {
			results[url] = wc(url)
		}()
	}

	return results
}
```

고루틴을 시작하는 유일한 방법은 함수 호출 앞에 `go`를 넣는 것이기 때문에, 고루틴을 시작하고 싶을 때 종종 *익명 함수*를 사용합니다. 익명 함수 리터럴은 일반 함수 선언과 똑같이 보이지만 이름이 없습니다 (당연합니다). 위의 `for` 루프 본문에서 하나를 볼 수 있습니다.

익명 함수에는 유용하게 만드는 여러 기능이 있으며, 그 중 두 가지를 위에서 사용하고 있습니다. 첫째, 선언되는 동시에 실행될 수 있습니다 - 이것이 익명 함수 끝에 있는 `()`가 하는 일입니다. 둘째, 정의된 렉시컬 스코프에 대한 접근을 유지합니다 - 익명 함수를 선언할 때 사용 가능한 모든 변수가 함수 본문에서도 사용 가능합니다.

위의 익명 함수 본문은 이전의 루프 본문과 같습니다. 유일한 차이점은 루프의 각 반복이 현재 프로세스 (`WebsiteChecker` 함수)와 동시에 새 고루틴을 시작한다는 것입니다. 각 고루틴은 결과 맵에 결과를 추가합니다.

하지만 `go test`를 실행하면:

```sh
--- FAIL: TestCheckWebsites (0.00s)
        CheckWebsites_test.go:31: Wanted map[http://google.com:true http://blog.gypsydave5.com:true waat://furhurterwe.geds:false], got map[]
FAIL
exit status 1
FAIL    github.com/gypsydave5/learn-go-with-tests/concurrency/v1        0.010s

```

### 동시성 세계로의 빠른 우회...

이 결과를 얻지 못할 수도 있습니다. 조금 후에 이야기할 패닉 메시지를 받을 수 있습니다. 걱정하지 마세요. 위의 결과를 *얻을 때까지* 테스트를 계속 실행하세요. 아니면 얻었다고 가정하세요. 당신에게 달렸습니다. 동시성에 오신 것을 환영합니다: 올바르게 처리되지 않으면 무슨 일이 일어날지 예측하기 어렵습니다. 걱정하지 마세요 - 그래서 동시성을 예측 가능하게 처리하고 있는지 알기 위해 테스트를 작성하는 것입니다.

### ... 그리고 우리는 돌아왔습니다.

원래 테스트 `CheckWebsites`에 의해 잡혔습니다. 이제 빈 맵을 반환합니다. 무엇이 잘못되었나요?

`for` 루프가 시작한 고루틴 중 어느 것도 `results` 맵에 결과를 추가할 충분한 시간이 없었습니다; `CheckWebsites` 함수가 너무 빨라서 여전히 빈 맵을 반환합니다.

이것을 수정하기 위해 모든 고루틴이 작업을 수행하는 동안 기다린 다음 반환할 수 있습니다. 2초면 충분하겠죠?

```go
package concurrency

import "time"

type WebsiteChecker func(string) bool

func CheckWebsites(wc WebsiteChecker, urls []string) map[string]bool {
	results := make(map[string]bool)

	for _, url := range urls {
		go func() {
			results[url] = wc(url)
		}()
	}

	time.Sleep(2 * time.Second)

	return results
}
```

이제 운이 좋으면:

```sh
PASS
ok      github.com/gypsydave5/learn-go-with-tests/concurrency/v1        2.012s
```

하지만 운이 나쁘면 (벤치마크와 함께 실행하면 더 많은 시도를 하게 되므로 더 가능성이 높습니다)

```sh
fatal error: concurrent map writes

goroutine 8 [running]:
runtime.throw(0x12c5895, 0x15)
        /usr/local/Cellar/go/1.9.3/libexec/src/runtime/panic.go:605 +0x95 fp=0xc420037700 sp=0xc4200376e0 pc=0x102d395
runtime.mapassign_faststr(0x1271d80, 0xc42007acf0, 0x12c6634, 0x17, 0x0)
        /usr/local/Cellar/go/1.9.3/libexec/src/runtime/hashmap_fast.go:783 +0x4f5 fp=0xc420037780 sp=0xc420037700 pc=0x100eb65
github.com/gypsydave5/learn-go-with-tests/concurrency/v3.WebsiteChecker.func1(0xc42007acf0, 0x12d3938, 0x12c6634, 0x17)
        /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:12 +0x71 fp=0xc4200377c0 sp=0xc420037780 pc=0x12308f1
runtime.goexit()
        /usr/local/Cellar/go/1.9.3/libexec/src/runtime/asm_amd64.s:2337 +0x1 fp=0xc4200377c8 sp=0xc4200377c0 pc=0x105cf01
created by github.com/gypsydave5/learn-go-with-tests/concurrency/v3.WebsiteChecker
        /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:11 +0xa1

        ... 무서운 텍스트가 더 많이 있습니다 ...
```

이것은 길고 무섭지만, 우리가 해야 할 일은 숨을 쉬고 스택트레이스를 읽는 것입니다: `fatal error: concurrent map writes`. 때때로 테스트를 실행하면 두 개의 고루틴이 정확히 같은 시간에 results 맵에 씁니다. Go의 맵은 한 번에 둘 이상의 것이 쓰려고 하는 것을 좋아하지 않아서 `fatal error`가 발생합니다.

이것은 *레이스 조건* (경쟁 상태)입니다. 소프트웨어의 출력이 우리가 제어할 수 없는 이벤트의 타이밍과 시퀀스에 의존할 때 발생하는 버그입니다. 각 고루틴이 results 맵에 언제 쓰는지 정확히 제어할 수 없기 때문에, 두 고루틴이 동시에 쓸 수 있는 취약점이 있습니다.

Go는 내장된 [*레이스 감지기*][godoc_race_detector]로 레이스 조건을 발견하는 데 도움을 줄 수 있습니다. 이 기능을 활성화하려면 `race` 플래그와 함께 테스트를 실행하세요: `go test -race`.

다음과 같은 출력을 받아야 합니다:

```sh
==================
WARNING: DATA RACE
Write at 0x00c420084d20 by goroutine 8:
  runtime.mapassign_faststr()
      /usr/local/Cellar/go/1.9.3/libexec/src/runtime/hashmap_fast.go:774 +0x0
  github.com/gypsydave5/learn-go-with-tests/concurrency/v3.WebsiteChecker.func1()
      /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:12 +0x82

Previous write at 0x00c420084d20 by goroutine 7:
  runtime.mapassign_faststr()
      /usr/local/Cellar/go/1.9.3/libexec/src/runtime/hashmap_fast.go:774 +0x0
  github.com/gypsydave5/learn-go-with-tests/concurrency/v3.WebsiteChecker.func1()
      /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:12 +0x82

Goroutine 8 (running) created at:
  github.com/gypsydave5/learn-go-with-tests/concurrency/v3.WebsiteChecker()
      /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:11 +0xc4
  github.com/gypsydave5/learn-go-with-tests/concurrency/v3.TestWebsiteChecker()
      /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker_test.go:27 +0xad
  testing.tRunner()
      /usr/local/Cellar/go/1.9.3/libexec/src/testing/testing.go:746 +0x16c

Goroutine 7 (finished) created at:
  github.com/gypsydave5/learn-go-with-tests/concurrency/v3.WebsiteChecker()
      /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:11 +0xc4
  github.com/gypsydave5/learn-go-with-tests/concurrency/v3.TestWebsiteChecker()
      /Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker_test.go:27 +0xad
  testing.tRunner()
      /usr/local/Cellar/go/1.9.3/libexec/src/testing/testing.go:746 +0x16c
==================
```

세부 사항은 다시 읽기 어렵지만 - `WARNING: DATA RACE`는 꽤 명확합니다. 오류 본문을 읽으면 맵에 쓰기를 수행하는 두 개의 다른 고루틴을 볼 수 있습니다:

`Write at 0x00c420084d20 by goroutine 8:`

는 다음과 같은 메모리 블록에 쓰고 있습니다

`Previous write at 0x00c420084d20 by goroutine 7:`

게다가 쓰기가 발생하는 코드 줄을 볼 수 있습니다:

`/Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:12`

그리고 고루틴 7과 8이 시작된 코드 줄:

`/Users/gypsydave5/go/src/github.com/gypsydave5/learn-go-with-tests/concurrency/v3/websiteChecker.go:11`

알아야 할 모든 것이 터미널에 출력됩니다 - 읽을 인내심만 있으면 됩니다.

### 채널

*채널*을 사용하여 고루틴을 조정함으로써 이 데이터 레이스를 해결할 수 있습니다. 채널은 값을 수신하고 보낼 수 있는 Go 데이터 구조입니다. 이러한 작업과 세부 사항은 서로 다른 프로세스 간의 통신을 허용합니다.

이 경우 url로 `WebsiteChecker` 함수를 실행하는 작업을 수행하기 위해 만든 각 고루틴과 부모 프로세스 간의 통신에 대해 생각하고 싶습니다.

```go
package concurrency

type WebsiteChecker func(string) bool
type result struct {
	string
	bool
}

func CheckWebsites(wc WebsiteChecker, urls []string) map[string]bool {
	results := make(map[string]bool)
	resultChannel := make(chan result)

	for _, url := range urls {
		go func() {
			resultChannel <- result{url, wc(url)}
		}()
	}

	for i := 0; i < len(urls); i++ {
		r := <-resultChannel
		results[r.string] = r.bool
	}

	return results
}
```

`results` 맵과 함께 이제 같은 방식으로 `make`하는 `resultChannel`이 있습니다. `chan result`는 채널의 타입입니다 - `result`의 채널입니다. 새 타입 `result`는 `WebsiteChecker`의 반환 값을 확인 중인 url과 연관시키기 위해 만들어졌습니다 - `string`과 `bool`의 구조체입니다. 두 값 모두 이름이 필요하지 않으므로 구조체 내에서 각각 익명입니다; 이것은 값에 이름을 붙이기 어려울 때 유용할 수 있습니다.

이제 url을 반복할 때 `map`에 직접 쓰는 대신 *send 문*으로 `wc`에 대한 각 호출에 대해 `result` 구조체를 `resultChannel`에 보냅니다. 이것은 `<-` 연산자를 사용하여 왼쪽에 채널을 오른쪽에 값을 받습니다:

```go
// Send 문
resultChannel <- result{u, wc(u)}
```

다음 `for` 루프는 각 url에 대해 한 번씩 반복합니다. 내부에서 채널에서 받은 값을 변수에 할당하는 *receive 표현식*을 사용합니다. 이것도 `<-` 연산자를 사용하지만 두 피연산자가 이제 반전되었습니다: 채널이 이제 오른쪽에 있고 할당하는 변수가 왼쪽에 있습니다:

```go
// Receive 표현식
r := <-resultChannel
```

그런 다음 받은 `result`를 사용하여 맵을 업데이트합니다.

결과를 채널로 보냄으로써 results 맵에 대한 각 쓰기의 타이밍을 제어하여 한 번에 하나씩 발생하도록 합니다. `wc`의 각 호출과 result 채널에 대한 각 send가 자체 프로세스 내에서 동시에 발생하지만, receive 표현식으로 result 채널에서 값을 꺼내면서 각 결과가 한 번에 하나씩 처리됩니다.

더 빠르게 만들고 싶은 코드 부분에 동시성을 사용하면서, 동시에 발생할 수 없는 부분이 여전히 선형적으로 발생하도록 했습니다. 그리고 채널을 사용하여 관련된 여러 프로세스 간에 통신했습니다.

벤치마크를 실행하면:

```sh
pkg: github.com/gypsydave5/learn-go-with-tests/concurrency/v2
BenchmarkCheckWebsites-8             100          23406615 ns/op
PASS
ok      github.com/gypsydave5/learn-go-with-tests/concurrency/v2        2.377s
```
23406615 나노초 - 0.023초, 원래 함수보다 약 100배 빠릅니다. 대성공입니다.

## 마무리

이 연습은 평소보다 TDD가 약간 가벼웠습니다. 어떤 면에서 우리는 `CheckWebsites` 함수의 하나의 긴 리팩토링에 참여해 왔습니다; 입력과 출력은 변하지 않았고 더 빨라졌을 뿐입니다. 하지만 우리가 가지고 있던 테스트와 작성한 벤치마크는 `CheckWebsites`를 소프트웨어가 여전히 작동한다는 확신을 유지하면서 실제로 더 빨라졌다는 것을 보여주는 방식으로 리팩토링할 수 있게 했습니다.

더 빠르게 만들면서 다음에 대해 배웠습니다

- *고루틴*, Go의 동시성 기본 단위로, 둘 이상의 웹사이트 확인 요청을 관리할 수 있게 합니다.
- *익명 함수*, 웹사이트를 확인하는 각 동시 프로세스를 시작하는 데 사용했습니다.
- *채널*, 서로 다른 프로세스 간의 통신을 조직하고 제어하여 *레이스 조건* 버그를 피할 수 있게 합니다.
- *레이스 감지기* 동시성 코드의 문제를 디버그하는 데 도움이 되었습니다

### 빠르게 만들기

소프트웨어를 구축하는 애자일 방식의 한 공식화된 표현이 있으며, 종종 Kent Beck에게 잘못 귀속됩니다:

> [작동하게 만들고, 올바르게 만들고, 빠르게 만들라][wrf]

'작동'은 테스트를 통과시키는 것이고, '올바르게'는 코드를 리팩토링하는 것이고, '빠르게'는 예를 들어 빠르게 실행되도록 코드를 최적화하는 것입니다. 우리는 작동하게 만들고 올바르게 만든 후에야 '빠르게 만들' 수 있습니다. 우리가 받은 코드가 이미 작동하는 것으로 입증되었고 리팩토링할 필요가 없어서 운이 좋았습니다. 다른 두 단계가 수행되기 전에 '빠르게 만들'려고 절대 해서는 안 됩니다. 왜냐하면

> [성급한 최적화는 모든 악의 근원이다][popt]
> -- Donald Knuth

[DI]: dependency-injection.md
[wrf]: http://wiki.c2.com/?MakeItWorkMakeItRightMakeItFast
[godoc_race_detector]: https://blog.golang.org/race-detector
[popt]: http://wiki.c2.com/?PrematureOptimization

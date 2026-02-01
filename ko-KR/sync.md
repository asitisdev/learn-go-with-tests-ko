# Sync

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/sync)**

동시에 사용해도 안전한 카운터를 만들고 싶습니다.

안전하지 않은 카운터로 시작하고 단일 스레드 환경에서 동작을 확인할 것입니다.

그런 다음 테스트를 통해 카운터를 사용하려는 여러 고루틴으로 안전하지 않음을 연습하고 수정할 것입니다.

## 먼저 테스트 작성

API가 카운터를 증가시키는 메서드와 그 값을 검색하는 메서드를 제공하기를 원합니다.

```go
func TestCounter(t *testing.T) {
	t.Run("incrementing the counter 3 times leaves it at 3", func(t *testing.T) {
		counter := Counter{}
		counter.Inc()
		counter.Inc()
		counter.Inc()

		if counter.Value() != 3 {
			t.Errorf("got %d, want %d", counter.Value(), 3)
		}
	})
}
```

## 테스트 실행 시도

```
./sync_test.go:9:14: undefined: Counter
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`Counter`를 정의합시다.

```go
type Counter struct {
}
```

다시 시도하면 다음과 같이 실패합니다

```
./sync_test.go:14:10: counter.Inc undefined (type Counter has no field or method Inc)
./sync_test.go:18:13: counter.Value undefined (type Counter has no field or method Value)
```

따라서 마침내 테스트를 실행하려면 해당 메서드를 정의할 수 있습니다

```go
func (c *Counter) Inc() {

}

func (c *Counter) Value() int {
	return 0
}
```

이제 실행되고 실패해야 합니다

```
=== RUN   TestCounter
=== RUN   TestCounter/incrementing*the*counter*3*times*leaves*it*at*3
--- FAIL: TestCounter (0.00s)
    --- FAIL: TestCounter/incrementing*the*counter*3*times*leaves*it*at*3 (0.00s)
    	sync_test.go:27: got 0, want 3
```

## 테스트를 통과시키기 위한 충분한 코드 작성

우리 같은 Go 전문가에게는 이것이 사소할 것입니다. 데이터 타입에 카운터에 대한 상태를 유지한 다음 모든 `Inc` 호출에서 증가시켜야 합니다

```go
type Counter struct {
	value int
}

func (c *Counter) Inc() {
	c.value++
}

func (c *Counter) Value() int {
	return c.value
}
```

## 리팩토링

리팩토링할 것이 많지 않지만 `Counter` 주변에 더 많은 테스트를 작성할 것이므로 테스트가 조금 더 명확하게 읽히도록 작은 어설션 함수 `assertCount`를 작성하겠습니다.

```go
t.Run("incrementing the counter 3 times leaves it at 3", func(t *testing.T) {
	counter := Counter{}
	counter.Inc()
	counter.Inc()
	counter.Inc()

	assertCounter(t, counter, 3)
})
```
```go
func assertCounter(t testing.TB, got Counter, want int) {
	t.Helper()
	if got.Value() != want {
		t.Errorf("got %d, want %d", got.Value(), want)
	}
}
```

## 다음 단계

충분히 쉬웠지만 이제 동시 환경에서 사용하기에 안전해야 한다는 요구 사항이 있습니다. 이것을 연습하기 위해 실패하는 테스트를 작성해야 합니다.

## 먼저 테스트 작성

```go
t.Run("it runs safely concurrently", func(t *testing.T) {
	wantedCount := 1000
	counter := Counter{}

	var wg sync.WaitGroup
	wg.Add(wantedCount)

	for i := 0; i < wantedCount; i++ {
		go func() {
			counter.Inc()
			wg.Done()
		}()
	}
	wg.Wait()

	assertCounter(t, counter, wantedCount)
})
```

이것은 `wantedCount`를 반복하고 `counter.Inc()`를 호출하는 고루틴을 실행합니다.

동시 프로세스를 동기화하는 편리한 방법인 [`sync.WaitGroup`](https://golang.org/pkg/sync/#WaitGroup)을 사용합니다.

> WaitGroup은 고루틴 컬렉션이 완료될 때까지 기다립니다. 메인 고루틴은 Add를 호출하여 기다릴 고루틴 수를 설정합니다. 그런 다음 각 고루틴이 실행되고 완료되면 Done을 호출합니다. 동시에 Wait을 사용하여 모든 고루틴이 완료될 때까지 차단할 수 있습니다.

어설션을 하기 전에 `wg.Wait()`가 완료될 때까지 기다리면 모든 고루틴이 `Counter`를 `Inc`하려고 시도했다고 확신할 수 있습니다.

## 테스트 실행 시도

```
=== RUN   TestCounter/it*runs*safely*in*a*concurrent*envionment
--- FAIL: TestCounter (0.00s)
    --- FAIL: TestCounter/it*runs*safely*in*a*concurrent*envionment (0.00s)
    	sync_test.go:26: got 939, want 1000
FAIL
```

테스트는 *아마도* 다른 숫자로 실패하지만, 그럼에도 불구하고 여러 고루틴이 동시에 카운터 값을 변경하려고 할 때 작동하지 않는다는 것을 보여줍니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

간단한 해결책은 `Counter`에 잠금을 추가하여 한 번에 하나의 고루틴만 카운터를 증가시킬 수 있도록 하는 것입니다. Go의 [`Mutex`](https://golang.org/pkg/sync/#Mutex)는 그러한 잠금을 제공합니다:

> Mutex는 상호 배제 잠금입니다. Mutex의 제로 값은 잠금 해제된 뮤텍스입니다.

```go
type Counter struct {
	mu    sync.Mutex
	value int
}

func (c *Counter) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.value++
}
```

이것은 `Inc`를 호출하는 모든 고루틴이 먼저라면 `Counter`에 대한 잠금을 획득한다는 것을 의미합니다. 다른 모든 고루틴은 액세스하기 전에 `Unlock`될 때까지 기다려야 합니다.

이제 테스트를 다시 실행하면 각 고루틴이 변경하기 전에 차례를 기다려야 하므로 통과해야 합니다.

## 다른 예제에서 `sync.Mutex`가 구조체에 임베딩된 것을 봤습니다.

다음과 같은 예제를 볼 수 있습니다

```go
type Counter struct {
	sync.Mutex
	value int
}
```

코드를 조금 더 우아하게 만들 수 있다고 주장할 수 있습니다.

```go
func (c *Counter) Inc() {
	c.Lock()
	defer c.Unlock()
	c.value++
}
```

이것은 *좋아 보이지만* 프로그래밍이 매우 주관적인 분야이지만 이것은 **나쁘고 잘못되었습니다**.

때때로 사람들은 타입을 임베딩하면 해당 타입의 메서드가 *공개 인터페이스의 일부*가 된다는 것을 잊습니다; 그리고 종종 그것을 원하지 않을 것입니다. 우리는 공개 API에 매우 주의해야 합니다. 무언가를 공개하는 순간은 다른 코드가 그것에 결합할 수 있는 순간입니다. 우리는 항상 불필요한 결합을 피하고 싶습니다.

`Lock`과 `Unlock`을 노출하는 것은 기껏해야 혼란스럽지만 최악의 경우 타입의 호출자가 이러한 메서드를 호출하기 시작하면 소프트웨어에 잠재적으로 매우 해로울 수 있습니다.

![이 API의 사용자가 잠금 상태를 잘못 변경할 수 있는 방법 보여주기](https://i.imgur.com/SWYNpwm.png)

*이것은 정말 나쁜 생각 같습니다*

## 뮤텍스 복사

테스트가 통과하지만 코드는 여전히 약간 위험합니다

코드에서 `go vet`을 실행하면 다음과 같은 오류가 발생해야 합니다

```
sync/v2/sync_test.go:16: call of assertCounter copies lock value: v1.Counter contains sync.Mutex
sync/v2/sync_test.go:39: assertCounter passes lock by value: v1.Counter contains sync.Mutex
```

[`sync.Mutex`](https://golang.org/pkg/sync/#Mutex) 문서를 보면 이유를 알 수 있습니다

> Mutex는 처음 사용 후 복사되어서는 안 됩니다.

`Counter`를 (값으로) `assertCounter`에 전달하면 뮤텍스의 복사본을 만들려고 합니다.

이것을 해결하려면 대신 `Counter`에 대한 포인터를 전달해야 하므로 `assertCounter`의 시그니처를 변경하세요

```go
func assertCounter(t testing.TB, got *Counter, want int)
```

`*Counter`가 아닌 `Counter`를 전달하려고 하기 때문에 테스트가 더 이상 컴파일되지 않습니다. 이것을 해결하기 위해 API의 독자에게 타입을 직접 초기화하지 않는 것이 더 낫다는 것을 보여주는 생성자를 만드는 것이 좋습니다.

```go
func NewCounter() *Counter {
	return &Counter{}
}
```

`Counter`를 초기화할 때 테스트에서 이 함수를 사용하세요.

## 마무리

[sync 패키지](https://golang.org/pkg/sync/)에서 몇 가지를 다루었습니다

- `Mutex`는 데이터에 잠금을 추가할 수 있게 합니다
- `WaitGroup`은 고루틴이 작업을 완료할 때까지 기다리는 수단입니다

### 채널과 고루틴 대신 잠금을 사용해야 할 때?

[이전에 첫 번째 동시성 챕터에서 고루틴을 다루었습니다](concurrency.md) 이를 통해 안전한 동시성 코드를 작성할 수 있으므로 왜 잠금을 사용하나요?
[Go 위키에 이 주제에 대한 전용 페이지가 있습니다; Mutex Or Channel](https://go.dev/wiki/MutexOrChannel)

> 일반적인 Go 초보자 실수는 가능하기 때문에 또는 재미있기 때문에 채널과 고루틴을 과도하게 사용하는 것입니다. 문제에 가장 적합한 경우 sync.Mutex를 사용하는 것을 두려워하지 마세요. Go는 문제를 가장 잘 해결하는 도구를 사용할 수 있게 하고 하나의 코드 스타일로 강제하지 않는 실용적입니다.

요약하면:

- **데이터 소유권을 전달할 때 채널 사용**
- **상태 관리에는 뮤텍스 사용**

### go vet

빌드 스크립트에서 go vet을 사용하는 것을 기억하세요. 불쌍한 사용자에게 영향을 미치기 전에 코드의 미묘한 버그에 대해 경고할 수 있습니다.

### 편리하다고 임베딩을 사용하지 마세요

- 임베딩이 공개 API에 미치는 영향에 대해 생각하세요.
- *정말로* 이러한 메서드를 노출하고 사람들이 자신의 코드를 그것에 결합하게 하고 싶으신가요?
- 뮤텍스와 관련하여 이것은 매우 예측할 수 없고 이상한 방식으로 잠재적으로 치명적일 수 있습니다. 일부 악의적인 코드가 해서는 안 될 때 뮤텍스를 잠금 해제한다고 상상해 보세요; 이것은 추적하기 어려운 매우 이상한 버그를 일으킬 것입니다.

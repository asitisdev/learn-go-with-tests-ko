# Context-aware 리더

**[여기에서 모든 코드를 찾을 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/q-and-a/context-aware-reader)**

이 챕터는 Mat Ryer와 David Hernandez가 [The Pace Dev Blog](https://pace.dev/blog/2020/02/03/context-aware-ioreader-for-golang-by-mat-ryer)에 작성한 context aware `io.Reader`를 테스트 주도로 개발하는 방법을 보여줍니다.

## Context aware 리더?

먼저 `io.Reader`에 대한 빠른 입문입니다.

이 책의 다른 챕터를 읽었다면 파일을 열고, JSON을 인코딩하고 다양한 일반적인 작업을 할 때 `io.Reader`를 접했을 것입니다. 이것은 _무언가_에서 데이터를 읽는 것에 대한 간단한 추상화입니다

```go
type Reader interface {
	Read(p []byte) (n int, err error)
}
```

`io.Reader`를 사용하면 표준 라이브러리에서 많은 재사용을 얻을 수 있으며, 매우 일반적으로 사용되는 추상화입니다(짝꿍 `io.Writer`와 함께)

### Context aware?

[이전 챕터](context.md)에서 `context`를 사용하여 취소를 제공하는 방법에 대해 논의했습니다. 이것은 계산 비용이 비싼 작업을 수행하고 중지할 수 있기를 원할 때 특히 유용합니다.

`io.Reader`를 사용할 때 속도에 대한 보장이 없으며, 1나노초 또는 수백 시간이 걸릴 수 있습니다. 자체 애플리케이션에서 이러한 종류의 작업을 취소할 수 있는 것이 유용할 수 있으며 이것이 Mat과 David가 작성한 것입니다.

그들은 두 가지 간단한 추상화(`context.Context`와 `io.Reader`)를 결합하여 이 문제를 해결했습니다.

취소할 수 있도록 `io.Reader`를 래핑할 수 있도록 일부 기능을 TDD해 봅시다.

이것을 테스트하는 것은 흥미로운 도전을 제기합니다. 일반적으로 `io.Reader`를 사용할 때 다른 함수에 제공하고 세부 정보에 대해 실제로 관심을 갖지 않습니다; 예를 들어 `json.NewDecoder` 또는 `io.ReadAll`.

우리가 보여주고 싶은 것은 다음과 같습니다

> "ABCDEF"가 있는 `io.Reader`가 주어지면 중간에 취소 신호를 보내면 계속 읽으려고 할 때 아무것도 얻지 못하므로 "ABC"만 얻습니다

인터페이스를 다시 살펴봅시다.

```go
type Reader interface {
	Read(p []byte) (n int, err error)
}
```

`Reader`의 `Read` 메서드는 제공하는 `[]byte`에 가지고 있는 내용을 읽습니다.

따라서 모든 것을 읽는 대신:

 - 모든 내용을 담지 않는 고정 크기 바이트 배열 제공
 - 취소 신호 보내기
 - 다시 읽으려고 하면 0바이트가 읽힌 에러를 반환해야 함

지금은 취소가 없는 "행복한 경로" 테스트만 작성하여 아직 프로덕션 코드를 작성하지 않고도 문제에 익숙해질 수 있도록 합시다.

```go
func TestContextAwareReader(t *testing.T) {
	t.Run("lets just see how a normal reader works", func(t *testing.T) {
		rdr := strings.NewReader("123456")
		got := make([]byte, 3)
		_, err := rdr.Read(got)

		if err != nil {
			t.Fatal(err)
		}

		assertBufferHas(t, got, "123")

		_, err = rdr.Read(got)

		if err != nil {
			t.Fatal(err)
		}

		assertBufferHas(t, got, "456")
	})
}

func assertBufferHas(t testing.TB, buf []byte, want string) {
	t.Helper()
	got := string(buf)
	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

- 일부 데이터가 있는 문자열에서 `io.Reader` 만들기
- 리더의 내용보다 작은 읽기용 바이트 배열
- read 호출, 내용 확인, 반복.

이것으로부터 두 번째 읽기 전에 일종의 취소 신호를 보내 동작을 변경하는 것을 상상할 수 있습니다.

이제 어떻게 작동하는지 보았으니 나머지 기능을 TDD하겠습니다.

## 먼저 테스트 작성

`io.Reader`를 `context.Context`와 결합할 수 있기를 원합니다.

TDD에서는 원하는 API를 상상하고 그에 대한 테스트를 작성하는 것이 가장 좋습니다.

거기서부터 컴파일러와 실패하는 테스트 출력이 해결책으로 안내할 수 있습니다

```go
t.Run("behaves like a normal reader", func(t *testing.T) {
	rdr := NewCancellableReader(strings.NewReader("123456"))
	got := make([]byte, 3)
	_, err := rdr.Read(got)

	if err != nil {
		t.Fatal(err)
	}

	assertBufferHas(t, got, "123")

	_, err = rdr.Read(got)

	if err != nil {
		t.Fatal(err)
	}

	assertBufferHas(t, got, "456")
})
```

## 테스트 실행 시도

```
./cancel_readers_test.go:12:10: undefined: NewCancellableReader
```
## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

이 함수를 정의해야 하고 `io.Reader`를 반환해야 합니다

```go
func NewCancellableReader(rdr io.Reader) io.Reader {
	return nil
}
```

실행하려고 하면

```
=== RUN   TestCancelReaders
=== RUN   TestCancelReaders/behaves_like_a_normal_reader
panic: runtime error: invalid memory address or nil pointer dereference [recovered]
	panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x10f8fb5]
```

예상대로

## 테스트를 통과시키기 위한 충분한 코드 작성

지금은 전달한 `io.Reader`를 반환하기만 합니다

```go
func NewCancellableReader(rdr io.Reader) io.Reader {
	return rdr
}
```

테스트가 이제 통과해야 합니다.

알아요, 알아요, 이것은 어리석고 pedantic해 보이지만 멋진 작업에 돌입하기 전에 `io.Reader`의 "정상" 동작을 깨뜨리지 않았다는 _어떤_ 검증이 있는 것이 중요하며 이 테스트는 앞으로 나아갈 때 자신감을 줄 것입니다.

## 먼저 테스트 작성

다음으로 취소해야 합니다.

```go
t.Run("stops reading when cancelled", func(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	rdr := NewCancellableReader(ctx, strings.NewReader("123456"))
	got := make([]byte, 3)
	_, err := rdr.Read(got)

	if err != nil {
		t.Fatal(err)
	}

	assertBufferHas(t, got, "123")

	cancel()

	n, err := rdr.Read(got)

	if err == nil {
		t.Error("expected an error after cancellation but didn't get one")
	}

	if n > 0 {
		t.Errorf("expected 0 bytes to be read after cancellation but %d were read", n)
	}
})
```

첫 번째 테스트를 대부분 복사할 수 있지만 이제:
- 첫 번째 읽기 후에 `cancel`할 수 있도록 취소가 있는 `context.Context` 생성
- 코드가 작동하려면 함수에 `ctx`를 전달해야 함
- 그런 다음 `cancel` 후에 아무것도 읽히지 않았다고 어설션

## 테스트 실행 시도

```
./cancel_readers_test.go:33:30: too many arguments in call to NewCancellableReader
	have (context.Context, *strings.Reader)
	want (io.Reader)
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

컴파일러가 무엇을 해야 하는지 알려줍니다; context를 받도록 시그니처 업데이트

```go
func NewCancellableReader(ctx context.Context, rdr io.Reader) io.Reader {
	return rdr
}
```

(첫 번째 테스트에도 `context.Background`를 전달하도록 업데이트해야 합니다)

이제 매우 명확한 실패 테스트 출력이 표시됩니다

```
=== RUN   TestCancelReaders
=== RUN   TestCancelReaders/stops_reading_when_cancelled
--- FAIL: TestCancelReaders (0.00s)
    --- FAIL: TestCancelReaders/stops_reading_when_cancelled (0.00s)
        cancel_readers_test.go:48: expected an error but didn't get one
        cancel_readers_test.go:52: expected 0 bytes to be read after cancellation but 3 were read
```

## 테스트를 통과시키기 위한 충분한 코드 작성

이 시점에서 Mat과 David의 원본 게시물에서 복사하여 붙여넣기이지만 여전히 천천히 반복적으로 진행합니다.

읽는 `io.Reader`와 `context.Context`를 캡슐화하는 타입이 필요하다는 것을 알고 있으므로 그것을 만들고 원래 `io.Reader` 대신 함수에서 반환해 봅시다

```go
func NewCancellableReader(ctx context.Context, rdr io.Reader) io.Reader {
	return &readerCtx{
		ctx:      ctx,
		delegate: rdr,
	}
}

type readerCtx struct {
	ctx      context.Context
	delegate io.Reader
}
```

이 책에서 여러 번 강조했듯이, 천천히 가고 컴파일러가 도와주도록 하세요

```
./cancel_readers_test.go:60:3: cannot use &readerCtx literal (type *readerCtx) as type io.Reader in return argument:
	*readerCtx does not implement io.Reader (missing Read method)
```

추상화가 맞는 것 같지만 필요한 인터페이스(`io.Reader`)를 구현하지 않으므로 메서드를 추가합시다.

```go
func (r *readerCtx) Read(p []byte) (n int, err error) {
	panic("implement me")
}
```

테스트를 실행하면 _컴파일_되지만 패닉이 발생합니다. 이것도 여전히 진전입니다.

기본 `io.Reader`에 호출을 _위임_하여 첫 번째 테스트를 통과시킵시다

```go
func (r readerCtx) Read(p []byte) (n int, err error) {
	return r.delegate.Read(p)
}
```

이 시점에서 행복한 경로 테스트가 다시 통과하고 우리 것이 잘 추상화된 것 같습니다

두 번째 테스트를 통과시키려면 `context.Context`가 취소되었는지 확인해야 합니다.

```go
func (r readerCtx) Read(p []byte) (n int, err error) {
	if err := r.ctx.Err(); err != nil {
		return 0, err
	}
	return r.delegate.Read(p)
}
```

모든 테스트가 이제 통과해야 합니다. `context.Context`에서 에러를 반환하는 방법을 알 수 있습니다. 이를 통해 코드 호출자가 취소가 발생한 다양한 이유를 검사할 수 있으며 이것은 원본 게시물에서 더 다룹니다.

## 마무리

- 작은 인터페이스는 좋고 쉽게 구성됩니다
- 한 가지(예: `io.Reader`)를 다른 것으로 증강하려고 할 때 일반적으로 [위임 패턴](https://en.wikipedia.org/wiki/Delegation_pattern)에 도달하고 싶습니다

> 소프트웨어 엔지니어링에서 위임 패턴은 객체 구성이 상속과 동일한 코드 재사용을 달성할 수 있도록 하는 객체 지향 설계 패턴입니다.

- 이러한 종류의 작업을 시작하는 쉬운 방법은 대리자를 래핑하고 다른 부분을 구성하여 동작을 변경하기 시작하기 전에 대리자가 정상적으로 동작하는 방식처럼 동작한다고 어설션하는 테스트를 작성하는 것입니다. 이렇게 하면 목표를 향해 코딩할 때 올바르게 작동하도록 유지하는 데 도움이 됩니다

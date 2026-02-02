# 제네릭 (Generics)

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/generics)**

이 챕터는 제네릭에 대한 소개를 제공하고, 제네릭에 대해 가질 수 있는 우려를 해소하며, 앞으로 코드를 단순화하는 방법에 대한 아이디어를 제공합니다. 이것을 읽은 후 다음을 작성하는 방법을 알게 됩니다:

- 제네릭 인자를 받는 함수
- 제네릭 데이터 구조


## 자체 테스트 헬퍼 (`AssertEqual`, `AssertNotEqual`)

제네릭을 탐색하기 위해 일부 테스트 헬퍼를 작성할 것입니다.

### 정수에 대한 Assert

기본적인 것으로 시작하여 목표를 향해 반복합시다

```go
import "testing"

func TestAssertFunctions(t *testing.T) {
	t.Run("asserting on integers", func(t *testing.T) {
		AssertEqual(t, 1, 1)
		AssertNotEqual(t, 1, 2)
	})
}

func AssertEqual(t *testing.T, got, want int) {
	t.Helper()
	if got != want {
		t.Errorf("got %d, want %d", got, want)
	}
}

func AssertNotEqual(t *testing.T, got, want int) {
	t.Helper()
	if got == want {
		t.Errorf("didn't want %d", got)
	}
}
```

### 문자열에 대한 Assert

정수의 동등성을 assert 할 수 있는 것은 훌륭하지만 `string`에 대해 assert 하고 싶다면 어떨까요?

```go
t.Run("asserting on strings", func(t *testing.T) {
	AssertEqual(t, "hello", "hello")
	AssertNotEqual(t, "hello", "Grace")
})
```

오류가 발생합니다:

```
cannot use "hello" (untyped string constant) as int value in argument to AssertEqual
```

#### 타입 안전성 복습

Go 컴파일러는 작업하려는 타입을 설명하여 함수, 구조체 등을 작성하도록 기대합니다.

`integer`를 예상하는 함수에 `string`을 전달할 수 없습니다.

이러한 제약 조건을 설명함으로써:

- 함수 구현을 더 간단하게 만듭니다. 컴파일러에 작업할 타입을 설명함으로써 **가능한 유효한 구현의 수를 제한**합니다.
- 의도하지 않은 데이터를 함수에 실수로 전달하는 것을 방지합니다.

### `interface{}`의 문제

인자 타입을 `interface{}`로 선언하면 "아무것이나" 의미합니다:

```go
func AssertEqual(got, want interface{})
```

`interface{}`를 사용하면 컴파일러가 코드 작성 시 도움을 줄 수 없습니다. 함수에 전달된 것의 타입에 대해 유용한 정보를 알려주지 않기 때문입니다.

```go
AssertEqual(1, "1") // 컴파일됨!
```

이것은 **컴파일러가 도움을 줄 수 없다**는 것을 의미하고 **런타임 오류**가 발생할 가능성이 더 높습니다.

## 제네릭을 사용한 자체 테스트 헬퍼

제네릭은 **제약 조건을 설명**하여 추상화 (인터페이스와 같은)를 만드는 방법을 제공합니다. `interface{}`가 제공하는 것과 유사한 수준의 유연성을 가진 함수를 작성할 수 있지만 타입 안전성을 유지하고 호출자에게 더 나은 개발자 경험을 제공합니다.

```go
func AssertEqual[T comparable](t *testing.T, got, want T) {
	t.Helper()
	if got != want {
		t.Errorf("got %v, want %v", got, want)
	}
}

func AssertNotEqual[T comparable](t *testing.T, got, want T) {
	t.Helper()
	if got == want {
		t.Errorf("didn't want %v", got)
	}
}
```

Go에서 제네릭 함수를 작성하려면 "타입 매개변수"를 제공해야 합니다. 이것은 "제네릭 타입을 설명하고 레이블을 지정하세요"라는 멋진 표현입니다.

우리의 경우 타입 매개변수의 타입은 `comparable`이고 `T`라는 레이블을 지정했습니다. 이 레이블을 사용하면 함수의 인자에 대한 타입을 설명할 수 있습니다 (`got, want T`).

`comparable`을 사용하는 이유는 함수에서 `T` 타입의 것에 `==` 및 `!=` 연산자를 사용하고 싶다고 컴파일러에 설명하고 싶기 때문입니다!

### 제네릭 함수 [`T any`]는 `interface{}`와 같은가요?

```go
func GenericFoo[T any](x, y T)
```

```go
func InterfaceyFoo(x, y interface{})
```

`any`는 "아무것이나"를 의미하고 `interface{}`도 마찬가지입니다. 사실 `any`는 1.18에 추가되었고 _`interface{}`의 별칭_입니다.

제네릭 버전의 차이점은 **여전히 특정 타입을 설명**하고 있다는 것입니다. 이것이 의미하는 바는 이 함수가 **하나의** 타입으로만 작동하도록 제한했다는 것입니다.

유효함:
- `GenericFoo(apple1, apple2)`
- `GenericFoo(1, 2)`

유효하지 않음 (컴파일 실패):
- `GenericFoo(apple1, orange1)`
- `GenericFoo("1", 1)`

## 제네릭 데이터 타입

[스택](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)) 데이터 타입을 만들 것입니다. 스택은 요구 사항 관점에서 이해하기 쉬워야 합니다. 항목을 "상단"으로 `Push`하고 다시 가져오려면 상단에서 `Pop`하는 항목 컬렉션입니다 (LIFO - 후입선출).

### 제네릭 없이

```go
type Stack struct {
	values []interface{}
}

func (s *Stack) Pop() (interface{}, bool) {
	// ...
}
```

문제:
- 타입 안전성을 잃었습니다
- `Pop`이 `interface{}`를 반환하면 작업하기 어렵습니다

### 제네릭 데이터 구조가 해결책

```go
type Stack[T any] struct {
	values []T
}

func (s *Stack[T]) Push(value T) {
	s.values = append(s.values, value)
}

func (s *Stack[T]) IsEmpty() bool {
	return len(s.values) == 0
}

func (s *Stack[T]) Pop() (T, bool) {
	if s.IsEmpty() {
		var zero T
		return zero, false
	}

	index := len(s.values) - 1
	el := s.values[index]
	s.values = s.values[:index]
	return el, true
}
```

사용 예:

```go
myStackOfInts := new(Stack[int])
myStackOfInts.Push(123)
value, _ := myStackOfInts.Pop() // value는 int 타입
```

`Stack[Orange]` 또는 `Stack[Apple]`을 만들면 스택에 정의된 메서드는 작업 중인 스택의 특정 타입만 전달하고 반환합니다.

### 생성자

```go
func NewStack[T any]() *Stack[T] {
	return new(Stack[T])
}

myStackOfInts := NewStack[int]()
myStackOfStrings := NewStack[string]()
```

제네릭 데이터 타입을 사용하여:

- 중요한 로직의 중복을 줄였습니다
- `Pop`이 `T`를 반환하므로 `Stack[int]`를 만들면 실제로 `Pop`에서 `int`를 반환받습니다
- 컴파일 시간에 오용을 방지했습니다. 사과 스택에 오렌지를 `Push`할 수 없습니다.

## 마무리

이 챕터는 제네릭 구문의 맛과 제네릭이 도움이 될 수 있는 이유에 대한 아이디어를 제공했을 것입니다.

### 대부분의 경우 제네릭이 `interface{}` 사용보다 간단합니다

`interface{}`를 사용하면 코드가:

- 덜 안전합니다 (사과와 오렌지 혼합), 더 많은 오류 처리가 필요합니다
- 덜 표현력이 있습니다, `interface{}`는 데이터에 대해 아무것도 알려주지 않습니다
- [리플렉션](reflection.md), 타입 어설션 등에 더 의존할 가능성이 높아 코드 작업이 더 어렵고 오류가 발생하기 쉽습니다

### 제네릭이 Go를 Java로 만들까요?

- 아닙니다.

### 이미 제네릭을 사용하고 있습니다

배열, 슬라이스 또는 맵을 사용했다면 **이미 제네릭 코드의 소비자였습니다**.

```
var myApples []Apple
// 이것은 할 수 없습니다!
append(myApples, Orange{})
```

### 작동하게 만들기, 올바르게 만들기, 빠르게 만들기

사람들은 좋은 디자인 결정을 내리기에 충분한 정보 없이 너무 빨리 추상화할 때 제네릭에 문제가 생깁니다.

빨강, 초록, 리팩토링의 TDD 사이클은 **추상화를 미리 상상하는 대신** 동작을 전달하는 데 **실제로 필요한** 코드에 대한 더 많은 안내를 제공합니다.

일반적으로 같은 코드를 세 번 볼 때만 일반화하라고 조언하는데, 이것은 좋은 출발 규칙인 것 같습니다.

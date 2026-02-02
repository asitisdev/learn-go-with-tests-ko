# 리플렉션

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/reflection)**

[트위터에서](https://twitter.com/peterbourgon/status/1011403901419937792?s=09)

> golang 챌린지: 구조체 `x`를 받아서 내부에서 발견된 모든 문자열 필드에 대해 `fn`을 호출하는 함수 `walk(x interface{}, fn func(string))`을 작성하세요. 난이도: 재귀적으로.

이를 위해 *리플렉션*을 사용해야 합니다.

> 컴퓨팅에서 리플렉션은 프로그램이 특히 타입을 통해 자신의 구조를 검사하는 능력입니다; 메타프로그래밍의 한 형태입니다. 또한 혼란의 큰 원천이기도 합니다.

[The Go Blog: Reflection](https://blog.golang.org/laws-of-reflection)에서

## `interface{}`란 무엇인가?

`string`, `int` 및 `BankAccount`와 같은 알려진 타입으로 작동하는 함수 측면에서 Go가 우리에게 제공한 타입 안전성을 즐겨왔습니다.

이것은 무료로 문서를 얻고 잘못된 타입을 함수에 전달하려고 하면 컴파일러가 불평한다는 것을 의미합니다.

하지만 컴파일 시간에 타입을 모르는 함수를 작성하고 싶은 시나리오에 직면할 수 있습니다.

Go에서는 `interface{}` 타입으로 이것을 해결할 수 있으며, *모든* 타입으로 생각할 수 있습니다 (실제로 Go에서 `any`는 `interface{}`의 [별칭](https://cs.opensource.google/go/go/+/master:src/builtin/builtin.go;drc=master;l=95)입니다).

따라서 `walk(x interface{}, fn func(string))`은 `x`에 대해 어떤 값이든 받아들입니다.

### 그러면 왜 모든 것에 `interface{}`를 사용하고 정말 유연한 함수를 갖지 않나요?

- `interface{}`를 받는 함수의 사용자로서 타입 안전성을 잃습니다. `int`인 `Herd.count` 대신 `string` 타입인 `Herd.species`를 함수에 전달하려고 했다면 어떨까요? 컴파일러가 실수를 알려줄 수 없습니다. 또한 함수에 *무엇*을 전달할 수 있는지 전혀 알 수 없습니다. 예를 들어 함수가 `UserService`를 받는다는 것을 아는 것은 매우 유용합니다.
- 그러한 함수의 작성자로서, 전달된 *모든 것*을 검사하고 타입이 무엇이고 무엇을 할 수 있는지 알아내야 합니다. 이것은 *리플렉션*을 사용하여 수행됩니다. 이것은 상당히 어색하고 읽기 어려울 수 있으며 일반적으로 성능이 떨어집니다 (런타임에 검사를 해야 하기 때문에).

간단히 말해서 정말 필요한 경우에만 리플렉션을 사용하세요.

다형성 함수를 원한다면, 사용자가 함수가 작동하는 데 필요한 메서드를 구현하면 여러 타입으로 함수를 사용할 수 있도록 인터페이스 (`interface{}`가 아니라, 혼란스럽게도) 주변으로 설계할 수 있는지 고려하세요.

우리 함수는 많은 다른 것들과 함께 작동할 수 있어야 합니다. 항상 그렇듯이 우리가 지원하고 싶은 각 새로운 것에 대한 테스트를 작성하고 도중에 리팩토링하면서 반복적인 접근 방식을 취할 것입니다.

## 먼저 테스트 작성

문자열 필드가 있는 구조체 (`x`)로 함수를 호출하고 싶습니다. 그런 다음 전달된 함수 (`fn`)를 스파이하여 호출되는지 확인할 수 있습니다.

```go
func TestWalk(t *testing.T) {

	expected := "Chris"
	var got []string

	x := struct {
		Name string
	}{expected}

	walk(x, func(input string) {
		got = append(got, input)
	})

	if len(got) != 1 {
		t.Errorf("wrong number of function calls, got %d want %d", len(got), 1)
	}
}
```

- `walk`에 의해 `fn`에 전달된 문자열을 저장하는 문자열 슬라이스 (`got`)를 저장하고 싶습니다. 이전 챕터에서는 함수/메서드 호출을 스파이하기 위해 전용 타입을 만들었지만 이 경우 `got`을 클로저하는 익명 함수를 `fn`에 전달하면 됩니다.
- 가장 간단한 "행복한" 경로를 위해 타입이 string인 `Name` 필드가 있는 익명 `struct`를 사용합니다.
- 마지막으로, `x`와 스파이로 `walk`를 호출하고 지금은 `got`의 길이만 확인합니다. 매우 기본적인 것이 작동하면 어설션을 더 구체적으로 할 것입니다.

## 테스트 실행 시도

```
./reflection_test.go:21:2: undefined: walk
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`walk`를 정의해야 합니다

```go
func walk(x interface{}, fn func(input string)) {

}
```

테스트를 다시 실행해 보세요

```
=== RUN   TestWalk
--- FAIL: TestWalk (0.00s)
    reflection_test.go:19: wrong number of function calls, got 0 want 1
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

아무 문자열로 스파이를 호출하여 통과시킬 수 있습니다.

```go
func walk(x interface{}, fn func(input string)) {
	fn("I still can't believe South Korea beat Germany 2-0 to put them last in their group")
}
```

테스트가 이제 통과해야 합니다. 다음으로 해야 할 일은 `fn`이 무엇으로 호출되는지에 대해 더 구체적인 어설션을 만드는 것입니다.

## 먼저 테스트 작성

`fn`에 전달된 문자열이 올바른지 확인하기 위해 기존 테스트에 다음을 추가하세요

```go
if got[0] != expected {
	t.Errorf("got %q, want %q", got[0], expected)
}
```

## 테스트 실행 시도

```
=== RUN   TestWalk
--- FAIL: TestWalk (0.00s)
    reflection_test.go:23: got 'I still can't believe South Korea beat Germany 2-0 to put them last in their group', want 'Chris'
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func walk(x interface{}, fn func(input string)) {
	val := reflect.ValueOf(x)
	field := val.Field(0)
	fn(field.String())
}
```

이 코드는 *매우 안전하지 않고 매우 순진합니다*. 하지만 기억하세요: "빨간색" (테스트 실패) 상태에서 목표는 가능한 가장 적은 양의 코드를 작성하는 것입니다. 그런 다음 우리의 우려를 해결하기 위해 더 많은 테스트를 작성합니다.

`x`를 살펴보고 속성을 보려면 리플렉션을 사용해야 합니다.

[reflect 패키지](https://pkg.go.dev/reflect)에는 주어진 변수의 `Value`를 반환하는 함수 `ValueOf`가 있습니다. 여기에는 다음 줄에서 사용하는 필드를 포함하여 값을 검사할 수 있는 방법이 있습니다.

그런 다음 전달된 값에 대해 매우 낙관적인 가정을 합니다:

- 첫 번째이자 유일한 필드를 봅니다. 그러나 필드가 전혀 없을 수도 있으며, 이 경우 패닉이 발생합니다.
- 그런 다음 기본 값을 문자열로 반환하는 `String()`을 호출합니다. 그러나 필드가 문자열이 아닌 경우 잘못됩니다.

## 리팩토링

코드가 간단한 경우에 통과하지만 코드에 많은 단점이 있다는 것을 알고 있습니다.

다른 값을 전달하고 `fn`이 호출된 문자열 배열을 확인하는 여러 테스트를 작성할 것입니다.

새로운 시나리오를 계속 테스트하기 쉽게 테스트를 테이블 기반 테스트로 리팩토링해야 합니다.

```go
func TestWalk(t *testing.T) {

	cases := []struct {
		Name          string
		Input         interface{}
		ExpectedCalls []string
	}{
		{
			"struct with one string field",
			struct {
				Name string
			}{"Chris"},
			[]string{"Chris"},
		},
	}

	for _, test := range cases {
		t.Run(test.Name, func(t *testing.T) {
			var got []string
			walk(test.Input, func(input string) {
				got = append(got, input)
			})

			if !reflect.DeepEqual(got, test.ExpectedCalls) {
				t.Errorf("got %v, want %v", got, test.ExpectedCalls)
			}
		})
	}
}
```

이제 둘 이상의 문자열 필드가 있으면 어떻게 되는지 확인하는 시나리오를 쉽게 추가할 수 있습니다.

## 먼저 테스트 작성

`cases`에 다음 시나리오를 추가하세요.

```
{
    "struct with two string fields",
    struct {
        Name string
        City string
    }{"Chris", "London"},
    []string{"Chris", "London"},
},
```

## 테스트 실행 시도

```
=== RUN   TestWalk/struct_with_two_string_fields
    --- FAIL: TestWalk/struct_with_two_string_fields (0.00s)
        reflection_test.go:40: got [Chris], want [Chris London]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func walk(x interface{}, fn func(input string)) {
	val := reflect.ValueOf(x)

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fn(field.String())
	}
}
```

`val`에는 값의 필드 수를 반환하는 `NumField` 메서드가 있습니다. 이를 통해 필드를 반복하고 테스트를 통과시키는 `fn`을 호출할 수 있습니다.

## 리팩토링

코드를 개선할 명백한 리팩토링이 없어 보이므로 계속 진행합시다.

`walk`의 다음 단점은 모든 필드가 `string`이라고 가정한다는 것입니다. 이 시나리오에 대한 테스트를 작성해 봅시다.

## 먼저 테스트 작성

다음 케이스를 추가하세요

```
{
    "struct with non string field",
    struct {
        Name string
        Age  int
    }{"Chris", 33},
    []string{"Chris"},
},
```

## 테스트 실행 시도

```
=== RUN   TestWalk/struct_with_non_string_field
    --- FAIL: TestWalk/struct_with_non_string_field (0.00s)
        reflection_test.go:46: got [Chris <int Value>], want [Chris]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

필드의 타입이 `string`인지 확인해야 합니다.

```go
func walk(x interface{}, fn func(input string)) {
	val := reflect.ValueOf(x)

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)

		if field.Kind() == reflect.String {
			fn(field.String())
		}
	}
}
```

[`Kind`](https://pkg.go.dev/reflect#Kind)를 확인하여 이를 수행할 수 있습니다.

## 리팩토링

다시 코드가 지금은 합리적으로 보입니다.

다음 시나리오는 "평평한" `struct`가 아니라면? 다른 말로, 중첩된 필드가 있는 `struct`가 있으면 어떻게 될까요?

## 먼저 테스트 작성

테스트를 위해 임시로 타입을 선언하기 위해 익명 구조체 구문을 사용해 왔으므로 다음과 같이 계속할 수 있습니다

```
{
    "nested fields",
    struct {
        Name string
        Profile struct {
            Age  int
            City string
        }
    }{"Chris", struct {
        Age  int
        City string
    }{33, "London"}},
    []string{"Chris", "London"},
},
```

하지만 내부 익명 구조체가 있을 때 구문이 약간 지저분해지는 것을 볼 수 있습니다. [구문을 더 좋게 만드는 제안이 있습니다](https://github.com/golang/go/issues/12854).

이 시나리오에 대해 알려진 타입을 만들고 테스트에서 참조하여 리팩토링합시다. 테스트의 일부 코드가 테스트 외부에 있다는 약간의 간접성이 있지만 독자는 초기화를 보고 `struct`의 구조를 추론할 수 있어야 합니다.

테스트 파일 어딘가에 다음 타입 선언을 추가하세요

```go
type Person struct {
	Name    string
	Profile Profile
}

type Profile struct {
	Age  int
	City string
}
```

이제 이전보다 훨씬 더 명확하게 읽히는 케이스에 이것을 추가할 수 있습니다

```
{
    "nested fields",
    Person{
        "Chris",
        Profile{33, "London"},
    },
    []string{"Chris", "London"},
},
```

## 테스트 실행 시도

```
=== RUN   TestWalk/Nested_fields
    --- FAIL: TestWalk/nested_fields (0.00s)
        reflection_test.go:54: got [Chris], want [Chris London]
```

문제는 타입 계층의 첫 번째 레벨에서만 필드를 반복하고 있다는 것입니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func walk(x interface{}, fn func(input string)) {
	val := reflect.ValueOf(x)

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)

		if field.Kind() == reflect.String {
			fn(field.String())
		}

		if field.Kind() == reflect.Struct {
			walk(field.Interface(), fn)
		}
	}
}
```

솔루션은 상당히 간단합니다. 다시 `Kind`를 검사하고 `struct`인 경우 해당 내부 `struct`에서 `walk`를 다시 호출합니다.

## 리팩토링

```go
func walk(x interface{}, fn func(input string)) {
	val := reflect.ValueOf(x)

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)

		switch field.Kind() {
		case reflect.String:
			fn(field.String())
		case reflect.Struct:
			walk(field.Interface(), fn)
		}
	}
}
```

동일한 값에 대해 두 번 이상 비교를 수행하는 경우 *일반적으로* `switch`로 리팩토링하면 가독성이 향상되고 코드를 확장하기 쉬워집니다.

전달된 구조체의 값이 포인터라면 어떨까요?

## 먼저 테스트 작성

이 케이스를 추가하세요

```
{
    "pointers to things",
    &Person{
        "Chris",
        Profile{33, "London"},
    },
    []string{"Chris", "London"},
},
```

## 테스트 실행 시도

```
=== RUN   TestWalk/pointers_to_things
panic: reflect: call of reflect.Value.NumField on ptr Value [recovered]
    panic: reflect: call of reflect.Value.NumField on ptr Value
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func walk(x interface{}, fn func(input string)) {
	val := reflect.ValueOf(x)

	if val.Kind() == reflect.Pointer {
		val = val.Elem()
	}

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)

		switch field.Kind() {
		case reflect.String:
			fn(field.String())
		case reflect.Struct:
			walk(field.Interface(), fn)
		}
	}
}
```

포인터 `Value`에서는 `NumField`를 사용할 수 없습니다. `Elem()`을 사용하여 그렇게 하기 전에 기본 값을 추출해야 합니다.

## 리팩토링

주어진 `interface{}`에서 `reflect.Value`를 추출하는 책임을 함수로 캡슐화합시다.

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)

		switch field.Kind() {
		case reflect.String:
			fn(field.String())
		case reflect.Struct:
			walk(field.Interface(), fn)
		}
	}
}

func getValue(x interface{}) reflect.Value {
	val := reflect.ValueOf(x)

	if val.Kind() == reflect.Pointer {
		val = val.Elem()
	}

	return val
}
```

이것은 실제로 *더 많은* 코드를 추가하지만 추상화 수준이 올바르다고 느낍니다.

- `x`의 `reflect.Value`를 가져와서 검사할 수 있습니다. 어떻게 하는지는 신경 쓰지 않습니다.
- 필드를 반복하면서 타입에 따라 필요한 작업을 수행합니다.

다음으로 슬라이스를 다루어야 합니다.

## 먼저 테스트 작성

```
{
    "slices",
    []Profile {
        {33, "London"},
        {34, "Reykjavík"},
    },
    []string{"London", "Reykjavík"},
},
```

## 테스트 실행 시도

```
=== RUN   TestWalk/slices
panic: reflect: call of reflect.Value.NumField on slice Value [recovered]
    panic: reflect: call of reflect.Value.NumField on slice Value
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

이것은 이전의 포인터 시나리오와 유사합니다. 구조체가 아니기 때문에 `reflect.Value`에서 `NumField`를 호출하려고 합니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	if val.Kind() == reflect.Slice {
		for i := 0; i < val.Len(); i++ {
			walk(val.Index(i).Interface(), fn)
		}
		return
	}

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)

		switch field.Kind() {
		case reflect.String:
			fn(field.String())
		case reflect.Struct:
			walk(field.Interface(), fn)
		}
	}
}
```

## 리팩토링

이것은 작동하지만 지저분합니다. 걱정하지 마세요. 테스트로 뒷받침되는 작동하는 코드가 있으므로 원하는 대로 수정할 수 있습니다.

조금 추상적으로 생각하면 다음 중 하나에서 `walk`를 호출하고 싶습니다

- 구조체의 각 필드
- 슬라이스의 각 *것*

현재 코드가 이것을 수행하지만 잘 반영하지 않습니다. 시작 부분에 슬라이스인지 확인하고 (나머지 코드 실행을 중지하기 위한 `return`과 함께) 그렇지 않으면 구조체라고 가정합니다.

*먼저* 타입을 확인한 다음 작업을 수행하도록 코드를 다시 작성합시다.

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	switch val.Kind() {
	case reflect.Struct:
		for i := 0; i < val.NumField(); i++ {
			walk(val.Field(i).Interface(), fn)
		}
	case reflect.Slice:
		for i := 0; i < val.Len(); i++ {
			walk(val.Index(i).Interface(), fn)
		}
	case reflect.String:
		fn(val.String())
	}
}
```

훨씬 좋아 보입니다! 구조체나 슬라이스인 경우 값을 반복하면서 각각에 대해 `walk`를 호출합니다. 그렇지 않으면 `reflect.String`인 경우 `fn`을 호출할 수 있습니다.

하지만 저에게는 여전히 더 나을 수 있다고 느껴집니다. 필드/값을 반복하고 `walk`를 호출하는 작업의 반복이 있지만 개념적으로 동일합니다.

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	numberOfValues := 0
	var getField func(int) reflect.Value

	switch val.Kind() {
	case reflect.String:
		fn(val.String())
	case reflect.Struct:
		numberOfValues = val.NumField()
		getField = val.Field
	case reflect.Slice:
		numberOfValues = val.Len()
		getField = val.Index
	}

	for i := 0; i < numberOfValues; i++ {
		walk(getField(i).Interface(), fn)
	}
}
```

`value`가 `reflect.String`인 경우 정상적으로 `fn`을 호출합니다.

그렇지 않으면 `switch`는 타입에 따라 두 가지를 추출합니다

- 필드가 몇 개인지
- `Value`를 추출하는 방법 (`Field` 또는 `Index`)

이러한 것들을 결정하면 `getField` 함수의 결과로 `walk`를 호출하면서 `numberOfValues`를 반복할 수 있습니다.

이제 이것을 수행했으므로 배열 처리는 간단해야 합니다.

## 먼저 테스트 작성

케이스에 추가하세요

```
{
    "arrays",
    [2]Profile {
        {33, "London"},
        {34, "Reykjavík"},
    },
    []string{"London", "Reykjavík"},
},
```

## 테스트 실행 시도

```
=== RUN   TestWalk/arrays
    --- FAIL: TestWalk/arrays (0.00s)
        reflection_test.go:78: got [], want [London Reykjavík]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

배열은 슬라이스와 같은 방식으로 처리할 수 있으므로 쉼표와 함께 케이스에 추가하면 됩니다

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	numberOfValues := 0
	var getField func(int) reflect.Value

	switch val.Kind() {
	case reflect.String:
		fn(val.String())
	case reflect.Struct:
		numberOfValues = val.NumField()
		getField = val.Field
	case reflect.Slice, reflect.Array:
		numberOfValues = val.Len()
		getField = val.Index
	}

	for i := 0; i < numberOfValues; i++ {
		walk(getField(i).Interface(), fn)
	}
}
```

다음으로 처리하고 싶은 타입은 `map`입니다.

## 먼저 테스트 작성

```
{
    "maps",
    map[string]string{
        "Cow": "Moo",
        "Sheep": "Baa",
    },
    []string{"Moo", "Baa"},
},
```

## 테스트 실행 시도

```
=== RUN   TestWalk/maps
    --- FAIL: TestWalk/maps (0.00s)
        reflection_test.go:86: got [], want [Moo Baa]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

다시 조금 추상적으로 생각하면 `map`이 `struct`와 매우 유사하다는 것을 알 수 있습니다. 단지 키가 컴파일 시간에 알려지지 않았을 뿐입니다.

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	numberOfValues := 0
	var getField func(int) reflect.Value

	switch val.Kind() {
	case reflect.String:
		fn(val.String())
	case reflect.Struct:
		numberOfValues = val.NumField()
		getField = val.Field
	case reflect.Slice, reflect.Array:
		numberOfValues = val.Len()
		getField = val.Index
	case reflect.Map:
		for _, key := range val.MapKeys() {
			walk(val.MapIndex(key).Interface(), fn)
		}
	}

	for i := 0; i < numberOfValues; i++ {
		walk(getField(i).Interface(), fn)
	}
}
```

그러나 설계상 인덱스로 맵에서 값을 가져올 수 없습니다. *키*로만 수행되므로 추상화가 깨집니다, 젠장.

## 리팩토링

지금 기분이 어떠세요? 당시에는 좋은 추상화처럼 느껴졌지만 이제 코드가 약간 이상해 보입니다.

*괜찮아요!* 리팩토링은 여정이고 때때로 실수를 합니다. TDD의 주요 포인트는 이러한 것들을 시도할 자유를 준다는 것입니다.

테스트로 뒷받침되는 작은 단계를 밟으면 이것은 결코 되돌릴 수 없는 상황이 아닙니다. 리팩토링 전의 원래대로 되돌립시다.

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	walkValue := func(value reflect.Value) {
		walk(value.Interface(), fn)
	}

	switch val.Kind() {
	case reflect.String:
		fn(val.String())
	case reflect.Struct:
		for i := 0; i < val.NumField(); i++ {
			walkValue(val.Field(i))
		}
	case reflect.Slice, reflect.Array:
		for i := 0; i < val.Len(); i++ {
			walkValue(val.Index(i))
		}
	case reflect.Map:
		for _, key := range val.MapKeys() {
			walkValue(val.MapIndex(key))
		}
	}
}
```

`switch` 내에서 `walk`에 대한 호출을 DRY하여 `reflect.Value`만 추출하면 되도록 `walkValue`를 도입했습니다.

### 마지막 문제

Go에서 맵은 순서를 보장하지 않습니다. 따라서 `fn`에 대한 호출이 특정 순서로 수행된다고 어설션하기 때문에 테스트가 때때로 실패합니다.

이것을 수정하려면 순서에 신경 쓰지 않는 새 테스트로 맵에 대한 어설션을 옮겨야 합니다.

```go
t.Run("with maps", func(t *testing.T) {
	aMap := map[string]string{
		"Cow":   "Moo",
		"Sheep": "Baa",
	}

	var got []string
	walk(aMap, func(input string) {
		got = append(got, input)
	})

	assertContains(t, got, "Moo")
	assertContains(t, got, "Baa")
})
```

`assertContains`는 다음과 같이 정의됩니다

```go
func assertContains(t testing.TB, haystack []string, needle string) {
	t.Helper()
	contains := false
	for _, x := range haystack {
		if x == needle {
			contains = true
		}
	}
	if !contains {
		t.Errorf("expected %v to contain %q but it didn't", haystack, needle)
	}
}
```

맵을 새 테스트로 추출했으므로 실패 메시지를 보지 못했습니다. 오류 메시지를 확인할 수 있도록 여기서 `with maps` 테스트를 의도적으로 깨뜨린 다음 모든 테스트가 통과하도록 다시 수정하세요.

다음으로 처리하고 싶은 타입은 `chan`입니다.

## 먼저 테스트 작성

```go
t.Run("with channels", func(t *testing.T) {
	aChannel := make(chan Profile)

	go func() {
		aChannel <- Profile{33, "Berlin"}
		aChannel <- Profile{34, "Katowice"}
		close(aChannel)
	}()

	var got []string
	want := []string{"Berlin", "Katowice"}

	walk(aChannel, func(input string) {
		got = append(got, input)
	})

	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %v, want %v", got, want)
	}
})
```

## 테스트 실행 시도

```
--- FAIL: TestWalk (0.00s)
    --- FAIL: TestWalk/with_channels (0.00s)
        reflection_test.go:115: got [], want [Berlin Katowice]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

Recv()로 닫힐 때까지 채널을 통해 전송된 모든 값을 반복할 수 있습니다

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	walkValue := func(value reflect.Value) {
		walk(value.Interface(), fn)
	}

	switch val.Kind() {
	case reflect.String:
		fn(val.String())
	case reflect.Struct:
		for i := 0; i < val.NumField(); i++ {
			walkValue(val.Field(i))
		}
	case reflect.Slice, reflect.Array:
		for i := 0; i < val.Len(); i++ {
			walkValue(val.Index(i))
		}
	case reflect.Map:
		for _, key := range val.MapKeys() {
			walkValue(val.MapIndex(key))
		}
	case reflect.Chan:
		for {
			if v, ok := val.Recv(); ok {
				walkValue(v)
			} else {
				break
			}
		}
	}
}
```

다음으로 처리하고 싶은 타입은 `func`입니다.

## 먼저 테스트 작성

```go
t.Run("with function", func(t *testing.T) {
	aFunction := func() (Profile, Profile) {
		return Profile{33, "Berlin"}, Profile{34, "Katowice"}
	}

	var got []string
	want := []string{"Berlin", "Katowice"}

	walk(aFunction, func(input string) {
		got = append(got, input)
	})

	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %v, want %v", got, want)
	}
})
```

## 테스트 실행 시도

```
--- FAIL: TestWalk (0.00s)
    --- FAIL: TestWalk/with_function (0.00s)
        reflection_test.go:132: got [], want [Berlin Katowice]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

인자가 있는 함수는 이 시나리오에서 많은 의미가 없어 보입니다. 하지만 임의의 반환 값을 허용해야 합니다.

```go
func walk(x interface{}, fn func(input string)) {
	val := getValue(x)

	walkValue := func(value reflect.Value) {
		walk(value.Interface(), fn)
	}

	switch val.Kind() {
	case reflect.String:
		fn(val.String())
	case reflect.Struct:
		for i := 0; i < val.NumField(); i++ {
			walkValue(val.Field(i))
		}
	case reflect.Slice, reflect.Array:
		for i := 0; i < val.Len(); i++ {
			walkValue(val.Index(i))
		}
	case reflect.Map:
		for _, key := range val.MapKeys() {
			walkValue(val.MapIndex(key))
		}
	case reflect.Chan:
		for v, ok := val.Recv(); ok; v, ok = val.Recv() {
			walkValue(v)
		}
	case reflect.Func:
		valFnResult := val.Call(nil)
		for _, res := range valFnResult {
			walkValue(res)
		}
	}
}
```

## 마무리

- `reflect` 패키지의 일부 개념을 소개했습니다.
- 임의의 데이터 구조를 탐색하기 위해 재귀를 사용했습니다.
- 회고적으로 나쁜 리팩토링을 했지만 너무 화나지 않았습니다. 테스트와 함께 반복적으로 작업하면 큰 문제가 되지 않습니다.
- 이것은 리플렉션의 작은 측면만 다루었습니다. [The Go blog에 더 많은 세부 사항을 다루는 훌륭한 게시물이 있습니다](https://blog.golang.org/laws-of-reflection).
- 이제 리플렉션에 대해 알았으니 사용을 피하기 위해 최선을 다하세요.

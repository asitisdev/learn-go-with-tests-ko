# 맵

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/maps)**

[배열과 슬라이스](arrays-and-slices.md)에서 값을 순서대로 저장하는 방법을 보았습니다. 이제 `key`로 항목을 저장하고 빠르게 찾는 방법을 살펴보겠습니다.

맵을 사용하면 사전과 유사한 방식으로 항목을 저장할 수 있습니다. `key`를 단어로, `value`를 정의로 생각할 수 있습니다. 그리고 맵에 대해 배우는 것보다 우리만의 사전을 만드는 것보다 더 좋은 방법이 있을까요?

먼저, 사전에 이미 정의와 함께 일부 단어가 있다고 가정하면, 단어를 검색하면 해당 단어의 정의를 반환해야 합니다.

## 먼저 테스트 작성

`dictionary_test.go`에서

```go
package main

import "testing"

func TestSearch(t *testing.T) {
	dictionary := map[string]string{"test": "this is just a test"}

	got := Search(dictionary, "test")
	want := "this is just a test"

	if got != want {
		t.Errorf("got %q want %q given, %q", got, want, "test")
	}
}
```

맵 선언은 배열과 다소 유사합니다. 하지만, `map` 키워드로 시작하고 두 가지 타입이 필요합니다. 첫 번째는 `[]` 안에 작성되는 키 타입입니다. 두 번째는 `[]` 바로 뒤에 오는 값 타입입니다.

키 타입은 특별합니다. 2개의 키가 같은지 알 수 없으면 올바른 값을 얻고 있는지 확인할 방법이 없기 때문에 비교 가능한 타입만 될 수 있습니다. 비교 가능한 타입은 [언어 명세](https://golang.org/ref/spec#Comparison_operators)에서 자세히 설명됩니다.

반면에 값 타입은 원하는 어떤 타입이든 될 수 있습니다. 다른 맵도 될 수 있습니다.

이 테스트의 다른 모든 것은 익숙할 것입니다.

## 테스트 실행 시도

`go test`를 실행하면 컴파일러가 `./dictionary_test.go:8:9: undefined: Search`로 실패합니다.

## 테스트가 실행되고 출력을 확인하기 위한 최소한의 코드 작성

`dictionary.go`에서

```go
package main

func Search(dictionary map[string]string, word string) string {
	return ""
}
```

테스트가 이제 *명확한 오류 메시지*와 함께 실패해야 합니다

`dictionary_test.go:12: got '' want 'this is just a test' given, 'test'`.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Search(dictionary map[string]string, word string) string {
	return dictionary[word]
}
```

맵에서 값을 가져오는 것은 배열에서 값을 가져오는 것과 같습니다 `map[key]`.

## 리팩토링

```go
func TestSearch(t *testing.T) {
	dictionary := map[string]string{"test": "this is just a test"}

	got := Search(dictionary, "test")
	want := "this is just a test"

	assertStrings(t, got, want)
}

func assertStrings(t testing.TB, got, want string) {
	t.Helper()

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

구현을 더 일반적으로 만들기 위해 `assertStrings` 헬퍼를 만들기로 결정했습니다.

### 커스텀 타입 사용

맵 주변에 새 타입을 만들고 `Search`를 메서드로 만들어 사전 사용을 개선할 수 있습니다.

`dictionary_test.go`에서:

```go
func TestSearch(t *testing.T) {
	dictionary := Dictionary{"test": "this is just a test"}

	got := dictionary.Search("test")
	want := "this is just a test"

	assertStrings(t, got, want)
}
```

아직 정의하지 않은 `Dictionary` 타입을 사용하기 시작했습니다. 그런 다음 `Dictionary` 인스턴스에서 `Search`를 호출했습니다.

`assertStrings`를 변경할 필요가 없었습니다.

`dictionary.go`에서:

```go
type Dictionary map[string]string

func (d Dictionary) Search(word string) string {
	return d[word]
}
```

여기서 `map`에 대한 얇은 래퍼 역할을 하는 `Dictionary` 타입을 만들었습니다. 커스텀 타입이 정의되면 `Search` 메서드를 만들 수 있습니다.

## 먼저 테스트 작성

기본 검색은 구현하기 매우 쉬웠지만, 사전에 없는 단어를 제공하면 어떻게 될까요?

실제로 아무것도 돌려받지 못합니다. 프로그램이 계속 실행될 수 있기 때문에 이것은 좋지만, 더 나은 접근 방식이 있습니다. 함수가 단어가 사전에 없다고 보고할 수 있습니다. 이렇게 하면, 사용자가 단어가 존재하지 않는지 아니면 정의가 없는 것인지 궁금해하지 않습니다 (이것은 사전에는 매우 유용하지 않을 수 있습니다. 그러나 다른 사용 사례에서 중요할 수 있는 시나리오입니다).

```go
func TestSearch(t *testing.T) {
	dictionary := Dictionary{"test": "this is just a test"}

	t.Run("known word", func(t *testing.T) {
		got, _ := dictionary.Search("test")
		want := "this is just a test"

		assertStrings(t, got, want)
	})

	t.Run("unknown word", func(t *testing.T) {
		_, err := dictionary.Search("unknown")
		want := "could not find the word you were looking for"

		if err == nil {
			t.Fatal("expected to get an error.")
		}

		assertStrings(t, err.Error(), want)
	})
}
```

Go에서 이 시나리오를 처리하는 방법은 `Error` 타입인 두 번째 인자를 반환하는 것입니다.

[포인터와 에러 섹션](./pointers-and-errors.md)에서 본 것처럼 오류 메시지를 어설션하기 위해 먼저 오류가 `nil`이 아닌지 확인한 다음 `.Error()` 메서드를 사용하여 어설션에 전달할 수 있는 문자열을 얻습니다.

## 테스트 실행 시도

컴파일되지 않습니다

```
./dictionary_test.go:18:10: assignment mismatch: 2 variables but 1 values
```

## 테스트가 실행되고 출력을 확인하기 위한 최소한의 코드 작성

```go
func (d Dictionary) Search(word string) (string, error) {
	return d[word], nil
}
```

테스트가 이제 훨씬 더 명확한 오류 메시지와 함께 실패해야 합니다.

`dictionary_test.go:22: expected to get an error.`

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (d Dictionary) Search(word string) (string, error) {
	definition, ok := d[word]
	if !ok {
		return "", errors.New("could not find the word you were looking for")
	}

	return definition, nil
}
```

이것을 통과시키기 위해, 맵 조회의 흥미로운 속성을 사용합니다. 2개의 값을 반환할 수 있습니다. 두 번째 값은 키가 성공적으로 찾아졌는지 여부를 나타내는 boolean입니다.

이 속성을 통해 존재하지 않는 단어와 정의가 없는 단어를 구분할 수 있습니다.

## 리팩토링

```go
var ErrNotFound = errors.New("could not find the word you were looking for")

func (d Dictionary) Search(word string) (string, error) {
	definition, ok := d[word]
	if !ok {
		return "", ErrNotFound
	}

	return definition, nil
}
```

`Search` 함수에서 매직 오류를 변수로 추출하여 제거할 수 있습니다. 이것은 또한 더 나은 테스트를 할 수 있게 해줍니다.

```go
t.Run("unknown word", func(t *testing.T) {
	_, got := dictionary.Search("unknown")
	if got == nil {
		t.Fatal("expected to get an error.")
	}
	assertError(t, got, ErrNotFound)
})
```
```go
func assertError(t testing.TB, got, want error) {
	t.Helper()

	if got != want {
		t.Errorf("got error %q want %q", got, want)
	}
}
```

새 헬퍼를 만들어 테스트를 단순화하고, 향후 오류 텍스트를 변경해도 테스트가 실패하지 않도록 `ErrNotFound` 변수를 사용하기 시작했습니다.

## 먼저 테스트 작성

사전을 검색하는 훌륭한 방법이 있습니다. 그러나 사전에 새 단어를 추가할 방법이 없습니다.

```go
func TestAdd(t *testing.T) {
	dictionary := Dictionary{}
	dictionary.Add("test", "this is just a test")

	want := "this is just a test"
	got, err := dictionary.Search("test")
	if err != nil {
		t.Fatal("should find added word:", err)
	}

	assertStrings(t, got, want)
}
```

이 테스트에서는 `Search` 함수를 활용하여 사전 검증을 조금 더 쉽게 만들고 있습니다.

## 테스트가 실행되고 출력을 확인하기 위한 최소한의 코드 작성

`dictionary.go`에서

```go
func (d Dictionary) Add(word, definition string) {
}
```

테스트가 이제 실패해야 합니다

```
dictionary_test.go:31: should find added word: could not find the word you were looking for
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (d Dictionary) Add(word, definition string) {
	d[word] = definition
}
```

맵에 추가하는 것도 배열과 유사합니다. 키를 지정하고 값과 동일하게 설정하면 됩니다.

### 포인터, 복사 등

맵의 흥미로운 속성은 주소를 전달하지 않고도 수정할 수 있다는 것입니다 (예: `&myMap`)

이것은 "참조 타입"처럼 _느껴_지게 할 수 있지만, [Dave Cheney가 설명하듯이](https://dave.cheney.net/2017/04/30/if-a-map-isnt-a-reference-variable-what-is-it) 그렇지 않습니다.

> 맵 값은 runtime.hmap 구조체에 대한 포인터입니다.

따라서 맵을 함수/메서드에 전달할 때, 실제로 복사하지만, 데이터를 포함하는 기본 데이터 구조가 아닌 포인터 부분만 복사합니다.

맵의 함정은 `nil` 값이 될 수 있다는 것입니다. `nil` 맵은 읽을 때 빈 맵처럼 동작하지만, `nil` 맵에 쓰려고 하면 런타임 패닉이 발생합니다. 맵에 대해 [여기](https://blog.golang.org/go-maps-in-action)에서 더 읽을 수 있습니다.

따라서, nil 맵 변수를 절대 초기화해서는 안 됩니다:

```go
var m map[string]string
```

대신, 빈 맵을 초기화하거나 `make` 키워드를 사용하여 맵을 만들 수 있습니다:

```go
var dictionary = map[string]string{}

// 또는

var dictionary = make(map[string]string)
```

두 접근 방식 모두 빈 `hash map`을 만들고 `dictionary`가 이를 가리키도록 합니다. 이렇게 하면 런타임 패닉이 절대 발생하지 않습니다.

## 리팩토링

구현에서 리팩토링할 것은 많지 않지만 테스트는 약간 단순화할 수 있습니다.

```go
func TestAdd(t *testing.T) {
	dictionary := Dictionary{}
	word := "test"
	definition := "this is just a test"

	dictionary.Add(word, definition)

	assertDefinition(t, dictionary, word, definition)
}

func assertDefinition(t testing.TB, dictionary Dictionary, word, definition string) {
	t.Helper()

	got, err := dictionary.Search(word)
	if err != nil {
		t.Fatal("should find added word:", err)
	}
	assertStrings(t, got, definition)
}
```

단어와 정의에 대한 변수를 만들고, 정의 어설션을 자체 헬퍼 함수로 옮겼습니다.

`Add`가 좋아 보입니다. 하지만, 추가하려는 값이 이미 존재하는 경우에 어떻게 되는지 고려하지 않았습니다!

맵은 값이 이미 존재하면 오류를 던지지 않습니다. 대신, 새로 제공된 값으로 값을 덮어씁니다. 이것은 실제로 편리할 수 있지만, 함수 이름이 정확하지 않게 만듭니다. `Add`는 기존 값을 수정해서는 안 됩니다. 사전에 새 단어만 추가해야 합니다.

## 먼저 테스트 작성

```go
func TestAdd(t *testing.T) {
	t.Run("new word", func(t *testing.T) {
		dictionary := Dictionary{}
		word := "test"
		definition := "this is just a test"

		err := dictionary.Add(word, definition)

		assertError(t, err, nil)
		assertDefinition(t, dictionary, word, definition)
	})

	t.Run("existing word", func(t *testing.T) {
		word := "test"
		definition := "this is just a test"
		dictionary := Dictionary{word: definition}
		err := dictionary.Add(word, "new test")

		assertError(t, err, ErrWordExists)
		assertDefinition(t, dictionary, word, definition)
	})
}
```

이 테스트에서 `Add`가 오류를 반환하도록 수정했으며, 새 오류 변수 `ErrWordExists`에 대해 검증하고 있습니다. 이전 테스트도 `nil` 오류를 확인하도록 수정했습니다.

## 테스트 실행 시도

`Add`에 대해 값을 반환하지 않기 때문에 컴파일러가 실패합니다.

```
./dictionary_test.go:30:13: dictionary.Add(word, definition) used as value
./dictionary_test.go:41:13: dictionary.Add(word, "new test") used as value
```

## 테스트가 실행되고 출력을 확인하기 위한 최소한의 코드 작성

`dictionary.go`에서

```go
var (
	ErrNotFound   = errors.New("could not find the word you were looking for")
	ErrWordExists = errors.New("cannot add word because it already exists")
)

func (d Dictionary) Add(word, definition string) error {
	d[word] = definition
	return nil
}
```

이제 두 개의 오류가 더 발생합니다. 여전히 값을 수정하고 `nil` 오류를 반환합니다.

```
dictionary_test.go:43: got error '%!q(<nil>)' want 'cannot add word because it already exists'
dictionary_test.go:44: got 'new test' want 'this is just a test'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (d Dictionary) Add(word, definition string) error {
	_, err := d.Search(word)

	switch err {
	case ErrNotFound:
		d[word] = definition
	case nil:
		return ErrWordExists
	default:
		return err
	}

	return nil
}
```

여기서 오류에서 매칭하기 위해 `switch` 문을 사용합니다. 이런 `switch`는 `Search`가 `ErrNotFound` 이외의 오류를 반환하는 경우 추가 안전망을 제공합니다.

## 리팩토링

리팩토링할 것이 많지 않지만, 오류 사용이 증가함에 따라 몇 가지 수정을 할 수 있습니다.

```go
const (
	ErrNotFound   = DictionaryErr("could not find the word you were looking for")
	ErrWordExists = DictionaryErr("cannot add word because it already exists")
)

type DictionaryErr string

func (e DictionaryErr) Error() string {
	return string(e)
}
```

오류를 상수로 만들었습니다; 이것은 `error` 인터페이스를 구현하는 자체 `DictionaryErr` 타입을 만들어야 했습니다. [Dave Cheney의 이 훌륭한 기사](https://dave.cheney.net/2016/04/07/constant-errors)에서 자세한 내용을 읽을 수 있습니다. 간단히 말해서, 오류를 더 재사용 가능하고 불변으로 만듭니다.

다음으로, 단어의 정의를 `Update`하는 함수를 만들어 봅시다.

## 먼저 테스트 작성

```go
func TestUpdate(t *testing.T) {
	word := "test"
	definition := "this is just a test"
	dictionary := Dictionary{word: definition}
	newDefinition := "new definition"

	dictionary.Update(word, newDefinition)

	assertDefinition(t, dictionary, word, newDefinition)
}
```

`Update`는 `Add`와 매우 밀접하게 관련되어 있으며 다음 구현이 될 것입니다.

## 테스트 실행 시도

```
./dictionary_test.go:53:2: dictionary.Update undefined (type Dictionary has no field or method Update)
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

이와 같은 오류를 처리하는 방법을 이미 알고 있습니다. 함수를 정의해야 합니다.

```go
func (d Dictionary) Update(word, definition string) {}
```

이것이 있으면, 단어의 정의를 변경해야 한다는 것을 알 수 있습니다.

```
dictionary_test.go:55: got 'this is just a test' want 'new definition'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

`Add` 문제를 수정할 때 이것을 어떻게 하는지 이미 보았습니다. 그래서 `Add`와 정말 유사한 것을 구현합시다.

```go
func (d Dictionary) Update(word, definition string) {
	d[word] = definition
}
```

간단한 변경이었기 때문에 리팩토링할 것이 없습니다. 그러나 이제 `Add`와 같은 문제가 있습니다. 새 단어를 전달하면 `Update`가 사전에 추가합니다.

## 먼저 테스트 작성

```go
t.Run("existing word", func(t *testing.T) {
	word := "test"
	definition := "this is just a test"
	dictionary := Dictionary{word: definition}
	newDefinition := "new definition"

	err := dictionary.Update(word, newDefinition)

	assertError(t, err, nil)
	assertDefinition(t, dictionary, word, newDefinition)
})

t.Run("new word", func(t *testing.T) {
	word := "test"
	definition := "this is just a test"
	dictionary := Dictionary{}

	err := dictionary.Update(word, definition)

	assertError(t, err, ErrWordDoesNotExist)
})
```

단어가 존재하지 않을 때를 위한 또 다른 오류 타입을 추가했습니다. `Update`도 `error` 값을 반환하도록 수정했습니다.

## 테스트 실행 시도

```
./dictionary_test.go:53:16: dictionary.Update(word, newDefinition) used as value
./dictionary_test.go:64:16: dictionary.Update(word, definition) used as value
./dictionary_test.go:66:23: undefined: ErrWordDoesNotExist
```

이번에 3개의 오류가 발생하지만, 이를 처리하는 방법을 알고 있습니다.

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
const (
	ErrNotFound         = DictionaryErr("could not find the word you were looking for")
	ErrWordExists       = DictionaryErr("cannot add word because it already exists")
	ErrWordDoesNotExist = DictionaryErr("cannot perform operation on word because it does not exist")
)

func (d Dictionary) Update(word, definition string) error {
	d[word] = definition
	return nil
}
```

자체 오류 타입을 추가하고 `nil` 오류를 반환합니다.

이러한 변경으로 이제 매우 명확한 오류가 발생합니다:

```
dictionary_test.go:66: got error '%!q(<nil>)' want 'cannot update word because it does not exist'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (d Dictionary) Update(word, definition string) error {
	_, err := d.Search(word)

	switch err {
	case ErrNotFound:
		return ErrWordDoesNotExist
	case nil:
		d[word] = definition
	default:
		return err
	}

	return nil
}
```

이 함수는 `Add`와 거의 동일해 보이지만 `dictionary`를 업데이트할 때와 오류를 반환할 때를 바꿨습니다.

### Update에 대한 새 오류 선언에 대한 참고

`ErrNotFound`를 재사용하고 새 오류를 추가하지 않을 수 있습니다. 그러나 업데이트가 실패할 때 정확한 오류를 갖는 것이 종종 더 좋습니다.

특정 오류를 갖는 것은 무엇이 잘못되었는지에 대한 더 많은 정보를 제공합니다. 다음은 웹 앱의 예입니다:

> `ErrNotFound`가 발생하면 사용자를 리디렉션할 수 있지만, `ErrWordDoesNotExist`가 발생하면 오류 메시지를 표시할 수 있습니다.

다음으로, 사전에서 단어를 `Delete`하는 함수를 만들어 봅시다.

## 먼저 테스트 작성

```go
func TestDelete(t *testing.T) {
	word := "test"
	dictionary := Dictionary{word: "test definition"}

	dictionary.Delete(word)

	_, err := dictionary.Search(word)
	assertError(t, err, ErrNotFound)
}
```

테스트는 단어가 있는 `Dictionary`를 만든 다음 단어가 제거되었는지 확인합니다.

## 테스트 실행 시도

`go test`를 실행하면:

```
./dictionary_test.go:74:6: dictionary.Delete undefined (type Dictionary has no field or method Delete)
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func (d Dictionary) Delete(word string) {

}
```

이것을 추가하면, 테스트가 단어를 삭제하지 않는다고 알려줍니다.

```
dictionary_test.go:78: got error '%!q(<nil>)' want 'could not find the word you were looking for'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (d Dictionary) Delete(word string) {
	delete(d, word)
}
```

Go에는 맵에서 작동하는 내장 함수 `delete`가 있습니다. 두 개의 인자를 받고 아무것도 반환하지 않습니다. 첫 번째 인자는 맵이고 두 번째는 제거할 키입니다.

## 리팩토링

리팩토링할 것이 많지 않지만, 단어가 존재하지 않는 경우를 처리하기 위해 `Update`와 같은 로직을 구현할 수 있습니다.

```go
func TestDelete(t *testing.T) {
	t.Run("existing word", func(t *testing.T) {
		word := "test"
		dictionary := Dictionary{word: "test definition"}

		err := dictionary.Delete(word)

		assertError(t, err, nil)

		_, err = dictionary.Search(word)

		assertError(t, err, ErrNotFound)
	})

	t.Run("non-existing word", func(t *testing.T) {
		word := "test"
		dictionary := Dictionary{}

		err := dictionary.Delete(word)

		assertError(t, err, ErrWordDoesNotExist)
	})
}
```

## 테스트 실행 시도

`Delete`에 대해 값을 반환하지 않기 때문에 컴파일러가 실패합니다.

```
./dictionary_test.go:77:10: dictionary.Delete(word) (no value) used as value
./dictionary_test.go:90:10: dictionary.Delete(word) (no value) used as value
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (d Dictionary) Delete(word string) error {
	_, err := d.Search(word)

	switch err {
	case ErrNotFound:
		return ErrWordDoesNotExist
	case nil:
		delete(d, word)
	default:
		return err
	}

	return nil
}
```

존재하지 않는 단어를 삭제하려고 할 때 오류에서 매칭하기 위해 다시 switch 문을 사용합니다.

## 마무리

이 섹션에서 많은 것을 다루었습니다. 사전에 대한 전체 CRUD (생성, 읽기, 업데이트 및 삭제) API를 만들었습니다. 과정 전반에 걸쳐 다음을 배웠습니다:

* 맵 생성
* 맵에서 항목 검색
* 맵에 새 항목 추가
* 맵에서 항목 업데이트
* 맵에서 항목 삭제
* 오류에 대해 더 배움
  * 상수인 오류를 만드는 방법
  * 오류 래퍼 작성

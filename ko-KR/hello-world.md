# Hello, World

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/hello-world)**

새로운 언어에서 첫 번째 프로그램이 [Hello, World](https://en.m.wikipedia.org/wiki/%22Hello,_World!%22_program)인 것은 전통입니다.

- 원하는 곳에 폴더를 만드세요
- `hello.go`라는 새 파일을 만들고 다음 코드를 넣으세요

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello, world")
}
```

실행하려면 `go run hello.go`를 입력하세요.

## 작동 방식

Go에서 프로그램을 작성할 때, `main` 패키지를 정의하고 그 안에 `main` 함수를 정의합니다. 패키지는 관련된 Go 코드를 함께 그룹화하는 방법입니다.

`func` 키워드는 이름과 본문을 가진 함수를 정의합니다.

`import "fmt"`로 우리가 출력하는 데 사용하는 `Println` 함수를 포함하는 패키지를 임포트합니다.

## 테스트 방법

이것을 어떻게 테스트할까요? "도메인" 코드를 외부 세계\(부작용\)와 분리하는 것이 좋습니다. `fmt.Println`은 부작용\(stdout에 출력\)이고, 우리가 보내는 문자열은 우리의 도메인입니다.

그래서 테스트하기 쉽도록 이러한 관심사를 분리해 봅시다

```go
package main

import "fmt"

func Hello() string {
	return "Hello, world"
}

func main() {
	fmt.Println(Hello())
}
```

`func`로 새 함수를 만들었지만, 이번에는 정의에 또 다른 키워드 `string`을 추가했습니다. 이것은 이 함수가 `string`을 반환한다는 것을 의미합니다.

이제 `Hello` 함수에 대한 테스트를 작성할 `hello_test.go`라는 새 파일을 만드세요

```go
package main

import "testing"

func TestHello(t *testing.T) {
	got := Hello()
	want := "Hello, world"

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

## Go 모듈?

다음 단계는 테스트를 실행하는 것입니다. 터미널에서 `go test`를 입력하세요. 테스트가 통과한다면, 아마 이전 버전의 Go를 사용하고 있을 것입니다. 그러나 Go 1.16 이상을 사용하고 있다면, 테스트가 실행되지 않을 가능성이 높습니다. 대신, 터미널에 다음과 같은 오류 메시지가 표시됩니다:

```shell
$ go test
go: cannot find main module; see 'go help modules'
```

문제가 무엇일까요? 한 마디로, [모듈](https://blog.golang.org/go116-module-changes)입니다. 다행히, 문제는 쉽게 해결할 수 있습니다. 터미널에 `go mod init example.com/hello`를 입력하세요. 그러면 다음 내용으로 새 파일이 생성됩니다:

```
module example.com/hello

go 1.16
```

이 파일은 `go` 도구에게 코드에 대한 필수 정보를 알려줍니다. 애플리케이션을 배포할 계획이라면, 코드를 다운로드할 수 있는 곳과 의존성에 대한 정보를 포함해야 합니다. 모듈 이름 example\.com\/hello는 일반적으로 모듈을 찾고 다운로드할 수 있는 URL을 참조합니다. 곧 사용하기 시작할 도구와의 호환성을 위해, 모듈 이름에 example\.com/hello의 .com처럼 점이 어딘가에 포함되어 있는지 확인하세요. 지금은 모듈 파일이 최소한이며, 그렇게 두어도 됩니다. 모듈에 대해 더 읽으려면 [Golang 문서의 참조를 확인하세요](https://golang.org/doc/modules/gomod-ref). 이제 테스트가 실행될 것이므로 테스트와 Go 학습으로 돌아갈 수 있습니다. Go 1.16에서도 마찬가지입니다.

앞으로의 챕터에서는 `go test`나 `go build`와 같은 명령을 실행하기 전에 각 새 폴더에서 `go mod init SOMENAME`을 실행해야 합니다.

## 테스트로 돌아가기

터미널에서 `go test`를 실행하세요. 통과했어야 합니다! 확인을 위해 `want` 문자열을 변경하여 의도적으로 테스트를 깨뜨려 보세요.

여러 테스팅 프레임워크 중에서 선택하고 설치 방법을 알아낼 필요가 없다는 것에 주목하세요. 필요한 모든 것이 언어에 내장되어 있으며, 구문은 작성할 나머지 코드와 같습니다.

### 테스트 작성

테스트 작성은 함수 작성과 같지만, 몇 가지 규칙이 있습니다

* `xxx_test.go`와 같은 이름의 파일에 있어야 합니다
* 테스트 함수는 `Test`라는 단어로 시작해야 합니다
* 테스트 함수는 `t *testing.T` 하나의 인자만 받습니다
* `*testing.T` 타입을 사용하려면, 다른 파일에서 `fmt`를 했던 것처럼 `import "testing"`을 해야 합니다

지금은 `*testing.T` 타입의 `t`가 테스팅 프레임워크에 대한 "훅"이라는 것만 알면 됩니다. 그래서 실패하고 싶을 때 `t.Fail()`과 같은 것을 할 수 있습니다.

몇 가지 새로운 주제를 다루었습니다:

#### `if`
Go에서 if 문은 다른 프로그래밍 언어와 매우 유사합니다.

#### 변수 선언

테스트에서 가독성을 위해 일부 값을 재사용할 수 있도록 `varName := value` 구문으로 변수를 선언하고 있습니다.

#### `t.Errorf`

`t`에서 `Errorf` _메서드_를 호출하여 메시지를 출력하고 테스트를 실패시킵니다. `f`는 format을 의미하며, 플레이스홀더 값 `%q`에 값이 삽입된 문자열을 만들 수 있게 합니다. 테스트를 실패하게 만들면, 작동 방식이 명확해질 것입니다.

플레이스홀더 문자열에 대해 [fmt 문서](https://pkg.go.dev/fmt#hdr-Printing)에서 더 읽을 수 있습니다. 테스트의 경우, `%q`는 값을 큰따옴표로 감싸기 때문에 매우 유용합니다.

나중에 메서드와 함수의 차이를 탐구할 것입니다.

### Go의 문서

Go의 또 다른 편의 기능은 문서입니다. 공식 패키지 보기 웹사이트에서 fmt 패키지 문서를 방금 보았고, Go는 오프라인에서도 문서에 빠르게 접근할 수 있는 방법을 제공합니다.

Go에는 시스템에 설치된 모든 패키지나 현재 작업 중인 모듈을 검사할 수 있는 내장 도구인 doc가 있습니다. Printing verbs에 대한 동일한 문서를 보려면:

```
$ go doc fmt
package fmt // import "fmt"

Package fmt implements formatted I/O with functions analogous to C's printf and
scanf. The format 'verbs' are derived from C's but are simpler.

# Printing

The verbs:

General:

    %v	the value in a default format
    	when printing structs, the plus flag (%+v) adds field names
    %#v	a Go-syntax representation of the value
    %T	a Go-syntax representation of the type of the value
    %%	a literal percent sign; consumes no value
...
```

문서를 보기 위한 Go의 두 번째 도구는 Go의 공식 패키지 보기 웹사이트를 구동하는 pkgsite 명령입니다. `go install golang.org/x/pkgsite/cmd/pkgsite@latest`로 pkgsite를 설치한 다음, `pkgsite -open .`으로 실행할 수 있습니다. Go의 install 명령은 해당 저장소에서 소스 파일을 다운로드하고 실행 가능한 바이너리로 빌드합니다. 기본 Go 설치의 경우, 해당 실행 파일은 Linux와 macOS에서는 `$HOME/go/bin`에, Windows에서는 `%USERPROFILE%\go\bin`에 있습니다. 아직 $PATH 변수에 해당 경로를 추가하지 않았다면, go로 설치된 명령을 더 쉽게 실행하기 위해 추가하는 것이 좋습니다.

표준 라이브러리의 대부분은 예제와 함께 훌륭한 문서를 가지고 있습니다. [http://localhost:8080/testing](http://localhost:8080/testing)으로 이동하여 사용할 수 있는 것을 확인해 보는 것이 좋습니다.


### Hello, YOU

이제 테스트가 있으므로, 안전하게 소프트웨어를 반복할 수 있습니다.

마지막 예제에서는 테스트 작성 방법과 함수 선언 방법의 예를 보여주기 위해 코드가 작성된 _후에_ 테스트를 작성했습니다. 이 시점부터는 _테스트를 먼저 작성_할 것입니다.

다음 요구 사항은 인사 대상을 지정할 수 있게 하는 것입니다.

이러한 요구 사항을 테스트로 캡처하는 것부터 시작합시다. 이것은 기본적인 테스트 주도 개발이며, 테스트가 _실제로_ 원하는 것을 테스트하고 있는지 확인할 수 있게 해줍니다. 회고적으로 테스트를 작성할 때, 코드가 의도한 대로 작동하지 않더라도 테스트가 계속 통과할 수 있는 위험이 있습니다.

```go
package main

import "testing"

func TestHello(t *testing.T) {
	got := Hello("Chris")
	want := "Hello, Chris"

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

이제 `go test`를 실행하면 컴파일 오류가 발생해야 합니다

```text
./hello_test.go:6:18: too many arguments in call to Hello
    have (string)
    want ()
```

Go와 같은 정적 타입 언어를 사용할 때 _컴파일러의 말을 듣는 것_이 중요합니다. 컴파일러는 코드가 어떻게 함께 맞물려 작동해야 하는지 이해하므로 직접 알아낼 필요가 없습니다.

이 경우 컴파일러는 계속 진행하기 위해 무엇을 해야 하는지 알려주고 있습니다. `Hello` 함수가 인자를 받도록 변경해야 합니다.

`Hello` 함수를 string 타입의 인자를 받도록 수정하세요

```go
func Hello(name string) string {
	return "Hello, world"
}
```

테스트를 다시 실행하려고 하면 인자를 전달하지 않아서 `hello.go`가 컴파일되지 않습니다. 컴파일되도록 "world"를 보내세요.

```go
func main() {
	fmt.Println(Hello("world"))
}
```

이제 테스트를 실행하면 다음과 같은 것이 보일 것입니다

```text
hello_test.go:10: got 'Hello, world' want 'Hello, Chris''
```

드디어 컴파일되는 프로그램이 되었지만 테스트에 따르면 요구 사항을 충족하지 못합니다.

name 인자를 사용하고 `Hello,`와 연결하여 테스트를 통과시킵시다

```go
func Hello(name string) string {
	return "Hello, " + name
}
```

테스트를 실행하면 이제 통과해야 합니다. 보통, TDD 사이클의 일부로, 이제 _리팩토링_해야 합니다.

### 소스 컨트롤에 대한 참고

이 시점에서, 소스 컨트롤을 사용하고 있다면\(사용해야 합니다!\) 코드를 그대로 `커밋`할 것입니다. 테스트로 뒷받침되는 작동하는 소프트웨어가 있습니다.

하지만 다음에 리팩토링할 계획이므로 main으로 _푸시하지 않을_ 것입니다. 리팩토링 중에 엉망이 되더라도 항상 작동하는 버전으로 돌아갈 수 있으므로 이 시점에서 커밋하는 것이 좋습니다.

여기서 리팩토링할 것이 많지 않지만, 또 다른 언어 기능인 _상수_를 소개할 수 있습니다.

### 상수

상수는 다음과 같이 정의됩니다

```go
const englishHelloPrefix = "Hello, "
```

이제 코드를 리팩토링할 수 있습니다

```go
const englishHelloPrefix = "Hello, "

func Hello(name string) string {
	return englishHelloPrefix + name
}
```

리팩토링 후, 테스트를 다시 실행하여 아무것도 깨뜨리지 않았는지 확인하세요.

값의 의미를 캡처하고 때로는 성능을 돕기 위해 상수를 만드는 것이 좋습니다.

## Hello, world... 다시

다음 요구 사항은 함수가 빈 문자열로 호출될 때 "Hello, " 대신 "Hello, World"를 기본값으로 출력하는 것입니다.

새로운 실패하는 테스트를 작성하는 것부터 시작하세요

```go
func TestHello(t *testing.T) {
	t.Run("saying hello to people", func(t *testing.T) {
		got := Hello("Chris")
		want := "Hello, Chris"

		if got != want {
			t.Errorf("got %q want %q", got, want)
		}
	})
	t.Run("say 'Hello, World' when an empty string is supplied", func(t *testing.T) {
		got := Hello("")
		want := "Hello, World"

		if got != want {
			t.Errorf("got %q want %q", got, want)
		}
	})
}
```

여기서 테스팅 무기고에 또 다른 도구를 소개합니다: 서브테스트. 때로는 "것" 주위에 테스트를 그룹화한 다음 다른 시나리오를 설명하는 서브테스트를 갖는 것이 유용합니다.

이 접근 방식의 이점은 다른 테스트에서 사용할 수 있는 공유 코드를 설정할 수 있다는 것입니다.

실패하는 테스트가 있는 동안, `if`를 사용하여 코드를 수정합시다.

```go
const englishHelloPrefix = "Hello, "

func Hello(name string) string {
	if name == "" {
		name = "World"
	}
	return englishHelloPrefix + name
}
```

테스트를 실행하면 새로운 요구 사항을 충족하면서 실수로 다른 기능을 깨뜨리지 않았다는 것을 볼 수 있습니다.

테스트가 코드가 해야 할 일에 대한 _명확한 명세_인 것이 중요합니다. 하지만 메시지가 예상한 것인지 확인할 때 반복되는 코드가 있습니다.

리팩토링은 프로덕션 코드만을 위한 것이 _아닙니다_!

이제 테스트가 통과했으므로, 테스트를 리팩토링할 수 있고 해야 합니다.

```go
func TestHello(t *testing.T) {
	t.Run("saying hello to people", func(t *testing.T) {
		got := Hello("Chris")
		want := "Hello, Chris"
		assertCorrectMessage(t, got, want)
	})

	t.Run("empty string defaults to 'world'", func(t *testing.T) {
		got := Hello("")
		want := "Hello, World"
		assertCorrectMessage(t, got, want)
	})

}

func assertCorrectMessage(t testing.TB, got, want string) {
	t.Helper()
	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

여기서 무엇을 했을까요?

어설션을 새로운 함수로 리팩토링했습니다. 이것은 중복을 줄이고 테스트의 가독성을 향상시킵니다. 필요할 때 테스트 코드가 실패하도록 지시할 수 있도록 `t *testing.T`를 전달해야 합니다.

헬퍼 함수의 경우, `*testing.T`와 `*testing.B` 둘 다 만족하는 인터페이스인 `testing.TB`를 받는 것이 좋습니다. 그래서 테스트 또는 벤치마크에서 헬퍼 함수를 호출할 수 있습니다 ("인터페이스"와 같은 단어가 지금은 아무 의미가 없더라도 걱정하지 마세요, 나중에 다룰 것입니다).

`t.Helper()`는 이 메서드가 헬퍼임을 테스트 스위트에 알리는 데 필요합니다. 이렇게 하면, 실패할 때 보고되는 줄 번호가 테스트 헬퍼 내부가 아닌 _함수 호출_에서 나옵니다. 이것은 다른 개발자가 문제를 더 쉽게 추적할 수 있게 도와줍니다. 아직도 이해가 안 된다면, 주석 처리하고, 테스트를 실패하게 만들고, 테스트 출력을 관찰하세요. Go에서 주석은 코드에 추가 정보를 추가하거나, 이 경우 컴파일러에게 줄을 무시하도록 지시하는 빠른 방법입니다. 줄 시작 부분에 두 개의 슬래시 `//`를 추가하여 `t.Helper()` 코드를 주석 처리할 수 있습니다. 해당 줄이 회색으로 바뀌거나 나머지 코드와 다른 색으로 바뀌어 이제 주석 처리되었음을 나타내는 것을 볼 수 있습니다.

같은 타입의 인자가 두 개 이상 있을 때\(우리의 경우 두 개의 문자열\) `(got string, want string)` 대신 `(got, want string)`으로 줄일 수 있습니다.

### 소스 컨트롤로 돌아가기

이제 코드가 만족스러우므로, 테스트와 함께 아름다운 버전의 코드만 체크인하도록 이전 커밋을 수정할 것입니다.

### 규율

사이클을 다시 살펴봅시다

* 테스트 작성
* 컴파일러 통과
* 테스트 실행, 실패 확인 및 오류 메시지가 의미 있는지 확인
* 테스트를 통과할 만큼만 코드 작성
* 리팩토링

겉보기에는 지루해 보일 수 있지만 피드백 루프를 고수하는 것이 중요합니다.

_관련 있는 테스트_가 있는지 확인할 뿐만 아니라, 테스트의 안전성으로 리팩토링하여 _좋은 소프트웨어를 설계_할 수 있게 합니다.

테스트 실패를 보는 것은 중요한 확인입니다. 오류 메시지가 어떻게 보이는지도 볼 수 있기 때문입니다. 개발자로서 실패한 테스트가 문제가 무엇인지 명확하게 알려주지 않는 코드베이스로 작업하는 것은 매우 어려울 수 있습니다.

테스트가 _빠르고_ 테스트 실행이 간단하도록 도구를 설정하면 코드를 작성할 때 흐름 상태에 들어갈 수 있습니다.

테스트를 작성하지 않으면, 소프트웨어를 실행하여 코드를 수동으로 확인하는 것에 전념하게 되며, 이것은 흐름 상태를 깨뜨립니다. 특히 장기적으로 시간을 절약하지 못합니다.

## 계속해봅시다! 더 많은 요구 사항

맙소사, 더 많은 요구 사항이 있습니다. 이제 인사 언어를 지정하는 두 번째 매개변수를 지원해야 합니다. 인식하지 못하는 언어가 전달되면 영어를 기본값으로 사용합니다.

TDD를 사용하여 이 기능을 쉽게 구현할 수 있다는 자신감이 있어야 합니다!

스페인어를 전달하는 사용자에 대한 테스트를 작성하세요. 기존 스위트에 추가하세요.

```go
	t.Run("in Spanish", func(t *testing.T) {
		got := Hello("Elodie", "Spanish")
		want := "Hola, Elodie"
		assertCorrectMessage(t, got, want)
	})
```

속이지 않도록 주의하세요! _테스트 먼저_. 테스트를 실행하려고 하면, 컴파일러가 하나가 아닌 두 개의 인자로 `Hello`를 호출하고 있다고 불평_해야_ 합니다.

```text
./hello_test.go:27:19: too many arguments in call to Hello
    have (string, string)
    want (string)
```

`Hello`에 또 다른 문자열 인자를 추가하여 컴파일 문제를 해결하세요

```go
func Hello(name string, language string) string {
	if name == "" {
		name = "World"
	}
	return englishHelloPrefix + name
}
```

테스트를 다시 실행하려고 하면 다른 테스트와 `hello.go`에서 `Hello`에 충분한 인자를 전달하지 않는다고 불평할 것입니다

```text
./hello.go:15:19: not enough arguments in call to Hello
    have (string)
    want (string, string)
```

빈 문자열을 전달하여 수정하세요. 이제 새로운 시나리오를 제외한 모든 테스트가 컴파일_되고_ 통과해야 합니다

```text
hello_test.go:29: got 'Hello, Elodie' want 'Hola, Elodie'
```

여기서 `if`를 사용하여 언어가 "Spanish"와 같은지 확인하고, 그렇다면 메시지를 변경할 수 있습니다

```go
func Hello(name string, language string) string {
	if name == "" {
		name = "World"
	}

	if language == "Spanish" {
		return "Hola, " + name
	}
	return englishHelloPrefix + name
}
```

테스트가 이제 통과해야 합니다.

이제 _리팩토링_할 시간입니다. 코드에서 일부 문제를 볼 수 있을 것입니다, "매직" 문자열, 그 중 일부는 반복됩니다. 직접 리팩토링해 보세요, 모든 변경 후에 테스트를 다시 실행하여 리팩토링이 아무것도 깨뜨리지 않는지 확인하세요.

```go
	const spanish = "Spanish"
	const englishHelloPrefix = "Hello, "
	const spanishHelloPrefix = "Hola, "

	func Hello(name string, language string) string {
		if name == "" {
			name = "World"
		}

		if language == spanish {
			return spanishHelloPrefix + name
		}
		return englishHelloPrefix + name
	}
```

### 프랑스어

* `"French"`를 전달하면 `"Bonjour, "`를 받는다고 주장하는 테스트를 작성하세요
* 실패하는지 확인하고, 오류 메시지가 읽기 쉬운지 확인하세요
* 코드에서 가장 작은 합리적인 변경을 하세요

다음과 같은 것을 작성했을 것입니다

```go
func Hello(name string, language string) string {
	if name == "" {
		name = "World"
	}

	if language == spanish {
		return spanishHelloPrefix + name
	}
	if language == french {
		return frenchHelloPrefix + name
	}
	return englishHelloPrefix + name
}
```

## `switch`

특정 값을 확인하는 `if` 문이 많을 때 대신 `switch` 문을 사용하는 것이 일반적입니다. `switch`를 사용하여 나중에 더 많은 언어 지원을 추가하려는 경우 더 읽기 쉽고 확장하기 쉽도록 코드를 리팩토링할 수 있습니다

```go
func Hello(name string, language string) string {
	if name == "" {
		name = "World"
	}

	prefix := englishHelloPrefix

	switch language {
	case spanish:
		prefix = spanishHelloPrefix
	case french:
		prefix = frenchHelloPrefix
	}

	return prefix + name
}
```

원하는 언어로 인사를 포함하는 테스트를 작성하고 _훌륭한_ 함수를 확장하는 것이 얼마나 간단한지 확인하세요.

### 마지막...리팩토링?

함수가 조금 커지고 있다고 주장할 수 있습니다. 이를 위한 가장 간단한 리팩토링은 일부 기능을 다른 함수로 추출하는 것입니다.

```go

const (
	spanish = "Spanish"
	french  = "French"

	englishHelloPrefix = "Hello, "
	spanishHelloPrefix = "Hola, "
	frenchHelloPrefix  = "Bonjour, "
)

func Hello(name string, language string) string {
	if name == "" {
		name = "World"
	}

	return greetingPrefix(language) + name
}

func greetingPrefix(language string) (prefix string) {
	switch language {
	case french:
		prefix = frenchHelloPrefix
	case spanish:
		prefix = spanishHelloPrefix
	default:
		prefix = englishHelloPrefix
	}
	return
}
```

몇 가지 새로운 개념:

* 함수 시그니처에서 _네임드 반환 값_ `(prefix string)`을 만들었습니다.
* 이것은 함수에 `prefix`라는 변수를 생성합니다.
  * "제로" 값이 할당됩니다. 이것은 타입에 따라 다릅니다, 예를 들어 `int`의 경우 0이고 `string`의 경우 `""`입니다.
    * `return prefix` 대신 `return`만 호출하여 설정된 값을 반환할 수 있습니다.
  * 이것은 함수의 Go Doc에 표시되므로 코드의 의도를 더 명확하게 만들 수 있습니다.
* switch case의 `default`는 다른 `case` 문이 일치하지 않을 때 분기됩니다.
* 함수 이름은 소문자로 시작합니다. Go에서 public 함수는 대문자로 시작하고, private 함수는 소문자로 시작합니다. 알고리즘의 내부를 세상에 노출하고 싶지 않으므로 이 함수를 private으로 만들었습니다.
* 또한, 상수를 각자의 줄에 선언하는 대신 블록으로 그룹화할 수 있습니다. 가독성을 위해, 관련 상수 집합 사이에 줄을 사용하는 것이 좋습니다.

## 마무리

`Hello, world`에서 이렇게 많은 것을 얻을 수 있다니 누가 알았겠습니까?

이제 다음에 대해 어느 정도 이해했어야 합니다:

### Go의 일부 구문

* 테스트 작성
* 인자와 반환 타입이 있는 함수 선언
* `if`, `const` 그리고 `switch`
* 변수와 상수 선언

### TDD 프로세스와 단계가 _왜_ 중요한지

* _실패하는 테스트를 작성하고 실패를 확인_하여 요구 사항에 대한 _관련 있는_ 테스트를 작성했고 _실패에 대한 이해하기 쉬운 설명_을 생성하는지 확인합니다
* 통과하기 위한 최소한의 코드를 작성하여 작동하는 소프트웨어가 있음을 알 수 있습니다
* _그런 다음_ 테스트의 안전성으로 뒷받침되어 리팩토링하여 작업하기 쉬운 잘 만들어진 코드가 있는지 확인합니다

우리의 경우, `Hello()`에서 `Hello("name")`으로, 그런 다음 `Hello("name", "French")`로 작고 이해하기 쉬운 단계로 진행했습니다.

물론, 이것은 "실제" 소프트웨어에 비해 사소하지만, 원칙은 여전히 유효합니다. TDD는 개발하기 위해 연습이 필요한 기술이지만, 문제를 테스트할 수 있는 더 작은 구성 요소로 분해하면 소프트웨어를 작성하는 것이 훨씬 쉬워집니다.

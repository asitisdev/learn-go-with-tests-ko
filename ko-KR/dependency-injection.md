# 의존성 주입

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/di)**

이 내용을 이해하기 위해서는 인터페이스에 대한 이해가 필요하므로 [구조체 섹션](./structs-methods-and-interfaces.md)을 먼저 읽었다고 가정합니다.

프로그래밍 커뮤니티에서 의존성 주입에 대한 오해가 *많이* 있습니다. 이 가이드가 다음을 보여주길 바랍니다

* 프레임워크가 필요하지 않습니다
* 설계를 지나치게 복잡하게 만들지 않습니다
* 테스트를 용이하게 합니다
* 훌륭하고 범용적인 함수를 작성할 수 있게 합니다.

hello-world 챕터에서 했던 것처럼 누군가에게 인사하는 함수를 작성하고 싶지만 이번에는 *실제 출력*을 테스트할 것입니다.

복습하자면, 해당 함수는 다음과 같을 수 있습니다

```go
func Greet(name string) {
	fmt.Printf("Hello, %s", name)
}
```

하지만 이것을 어떻게 테스트할까요? `fmt.Printf`를 호출하면 stdout에 출력되는데, 테스팅 프레임워크를 사용하여 캡처하기가 꽤 어렵습니다.

우리가 해야 할 일은 출력의 의존성을 **주입**\(전달한다는 멋진 표현일 뿐\)할 수 있도록 하는 것입니다.

**우리 함수는 출력이 *어디서* 또는 *어떻게* 일어나는지 신경 쓸 필요가 없으므로, 구체적인 타입보다는 *인터페이스*를 받아들여야 합니다.**

그렇게 하면, 테스트할 수 있도록 제어할 수 있는 무언가에 출력하도록 구현을 변경할 수 있습니다. "실제 생활"에서는 stdout에 쓰는 무언가를 주입할 것입니다.

[`fmt.Printf`](https://pkg.go.dev/fmt#Printf)의 소스 코드를 보면 연결할 수 있는 방법을 볼 수 있습니다

```go
// It returns the number of bytes written and any write error encountered.
func Printf(format string, a ...interface{}) (n int, err error) {
	return Fprintf(os.Stdout, format, a...)
}
```

흥미롭네요! 내부적으로 `Printf`는 `os.Stdout`을 전달하면서 `Fprintf`를 호출합니다.

`os.Stdout`이 정확히 *무엇*일까요? `Fprintf`는 첫 번째 인자로 무엇을 전달받기를 기대할까요?

```go
func Fprintf(w io.Writer, format string, a ...interface{}) (n int, err error) {
	p := newPrinter()
	p.doPrintf(format, a)
	n, err = w.Write(p.buf)
	p.free()
	return
}
```

`io.Writer`입니다

```go
type Writer interface {
	Write(p []byte) (n int, err error)
}
```

이것으로 `os.Stdout`이 `io.Writer`를 구현한다고 추론할 수 있습니다; `Printf`는 `io.Writer`를 기대하는 `Fprintf`에 `os.Stdout`을 전달합니다.

더 많은 Go 코드를 작성할수록 이 인터페이스가 많이 나타나는 것을 발견할 것입니다. 왜냐하면 "이 데이터를 어딘가에 넣어라"를 위한 훌륭한 범용 인터페이스이기 때문입니다.

그래서 내부적으로 우리는 궁극적으로 `Writer`를 사용하여 인사말을 어딘가에 보내고 있다는 것을 알고 있습니다. 이 기존 추상화를 사용하여 코드를 테스트 가능하고 더 재사용 가능하게 만듭시다.

## 먼저 테스트 작성

```go
func TestGreet(t *testing.T) {
	buffer := bytes.Buffer{}
	Greet(&buffer, "Chris")

	got := buffer.String()
	want := "Hello, Chris"

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

`bytes` 패키지의 `Buffer` 타입은 `Write(p []byte) (n int, err error)` 메서드가 있기 때문에 `Writer` 인터페이스를 구현합니다.

그래서 테스트에서 `Writer`로 보내고 `Greet`를 호출한 후 무엇이 쓰여졌는지 확인할 수 있습니다

## 테스트 실행 시도

테스트가 컴파일되지 않습니다

```text
./di_test.go:10:2: undefined: Greet
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

*컴파일러의 말을 듣고* 문제를 수정하세요.

```go
func Greet(writer *bytes.Buffer, name string) {
	fmt.Printf("Hello, %s", name)
}
```

`Hello, Chris di_test.go:16: got '' want 'Hello, Chris'`

테스트가 실패합니다. 이름이 출력되고 있지만 stdout으로 가고 있다는 것에 주목하세요.

## 테스트를 통과시키기 위한 충분한 코드 작성

테스트에서 버퍼에 인사말을 보내기 위해 writer를 사용하세요. `fmt.Fprintf`는 `fmt.Printf`와 비슷하지만 문자열을 보낼 `Writer`를 받는 반면, `fmt.Printf`는 기본적으로 stdout입니다.

```go
func Greet(writer *bytes.Buffer, name string) {
	fmt.Fprintf(writer, "Hello, %s", name)
}
```

테스트가 이제 통과합니다.

## 리팩토링

앞서 컴파일러가 `bytes.Buffer`에 대한 포인터를 전달하라고 했습니다. 이것은 기술적으로 정확하지만 별로 유용하지 않습니다.

이것을 시연하기 위해, stdout에 출력하고자 하는 Go 애플리케이션에 `Greet` 함수를 연결해 보세요.

```go
func main() {
	Greet(os.Stdout, "Elodie")
}
```

`./di.go:14:7: cannot use os.Stdout (type *os.File) as type *bytes.Buffer in argument to Greet`

앞서 논의했듯이 `fmt.Fprintf`는 `os.Stdout`과 `bytes.Buffer` 둘 다 구현하는 `io.Writer`를 전달할 수 있게 합니다.

더 범용적인 인터페이스를 사용하도록 코드를 변경하면 이제 테스트와 애플리케이션 모두에서 사용할 수 있습니다.

```go
package main

import (
	"fmt"
	"io"
	"os"
)

func Greet(writer io.Writer, name string) {
	fmt.Fprintf(writer, "Hello, %s", name)
}

func main() {
	Greet(os.Stdout, "Elodie")
}
```

## io.Writer에 대해 더 알아보기

`io.Writer`를 사용하여 데이터를 어디에 더 쓸 수 있을까요? `Greet` 함수는 얼마나 범용적일까요?

### 인터넷

다음을 실행하세요

```go
package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
)

func Greet(writer io.Writer, name string) {
	fmt.Fprintf(writer, "Hello, %s", name)
}

func MyGreeterHandler(w http.ResponseWriter, r *http.Request) {
	Greet(w, "world")
}

func main() {
	log.Fatal(http.ListenAndServe(":5001", http.HandlerFunc(MyGreeterHandler)))
}
```

프로그램을 실행하고 [http://localhost:5001](http://localhost:5001)로 이동하세요. 인사말 함수가 사용되는 것을 볼 수 있습니다.

HTTP 서버는 이후 챕터에서 다룰 예정이므로 세부 사항에 대해 너무 걱정하지 마세요.

HTTP 핸들러를 작성할 때, 요청에 사용된 `http.ResponseWriter`와 `http.Request`가 주어집니다. 서버를 구현할 때 writer를 사용하여 응답을 *쓰게* 됩니다.

`http.ResponseWriter`도 `io.Writer`를 구현한다고 추측할 수 있을 것입니다. 그래서 핸들러 내에서 `Greet` 함수를 재사용할 수 있습니다.

## 마무리

첫 번째 코드 라운드는 제어할 수 없는 곳에 데이터를 썼기 때문에 테스트하기 쉽지 않았습니다.

*테스트에 의해 동기 부여되어* 다음을 허용하는 **의존성을 주입**하여 데이터가 *어디에* 쓰이는지 제어할 수 있도록 코드를 리팩토링했습니다:

* **코드 테스트** 함수를 *쉽게* 테스트할 수 없다면, 보통 함수에 하드와이어링된 의존성이나 전역 상태 때문입니다. 예를 들어 일종의 서비스 레이어에서 사용되는 전역 데이터베이스 연결 풀이 있다면, 테스트하기 어렵고 실행이 느릴 가능성이 높습니다. DI는 테스트에서 제어할 수 있는 것으로 모킹할 수 있는 데이터베이스 의존성\(인터페이스를 통해\)을 주입하도록 동기를 부여합니다.
* **관심사 분리**, *데이터가 가는 곳*과 *생성하는 방법*을 분리합니다. 메서드/함수가 너무 많은 책임을 갖고 있다고 느끼면\(데이터 생성 *및* db에 쓰기? HTTP 요청 처리 *및* 도메인 레벨 로직 수행?\) DI가 아마 필요한 도구일 것입니다.
* **코드가 다른 컨텍스트에서 재사용되도록 허용** 코드가 사용될 수 있는 첫 번째 "새로운" 컨텍스트는 테스트 내부입니다. 하지만 나중에 누군가가 함수로 새로운 것을 시도하고 싶다면 자체 의존성을 주입할 수 있습니다.

### 모킹은요? DI에 필요하고 또한 악하다고 들었어요

모킹은 나중에 자세히 다룰 것입니다\(그리고 악하지 않습니다\). 테스트에서 제어하고 검사할 수 있는 가짜 버전으로 주입하는 실제 것을 대체하기 위해 모킹을 사용합니다. 하지만 우리의 경우, 표준 라이브러리에 우리가 사용할 수 있는 것이 이미 준비되어 있었습니다.

### Go 표준 라이브러리는 정말 좋습니다, 공부하는 데 시간을 투자하세요

`io.Writer` 인터페이스에 어느 정도 익숙해지면 테스트에서 `bytes.Buffer`를 `Writer`로 사용할 수 있고, 커맨드 라인 앱이나 웹 서버에서 함수를 사용하기 위해 표준 라이브러리의 다른 `Writer`를 사용할 수 있습니다.

표준 라이브러리에 더 익숙해질수록 자체 코드에서 재사용하여 소프트웨어를 다양한 컨텍스트에서 재사용 가능하게 만들 수 있는 이러한 범용 인터페이스를 더 많이 볼 수 있습니다.

이 예제는 [The Go Programming language](https://www.amazon.co.uk/Programming-Language-Addison-Wesley-Professional-Computing/dp/0134190440)의 한 챕터에 크게 영향을 받았으므로, 이것을 즐겼다면 구매하세요!

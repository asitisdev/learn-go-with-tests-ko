# 정수

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/integers)**

정수는 예상대로 작동합니다. 테스트해보기 위해 `Add` 함수를 작성해 봅시다. `adder_test.go`라는 테스트 파일을 만들고 다음 코드를 작성하세요.

**참고:** Go 소스 파일은 디렉토리당 하나의 `package`만 가질 수 있습니다. 파일이 각자의 패키지로 구성되어 있는지 확인하세요. [여기에 이에 대한 좋은 설명이 있습니다.](https://dave.cheney.net/2014/12/01/five-suggestions-for-setting-up-a-go-project)

프로젝트 디렉토리는 다음과 같을 수 있습니다:

```
learnGoWithTests
    |
    |-> helloworld
    |    |- hello.go
    |    |- hello_test.go
    |
    |-> integers
    |    |- adder_test.go
    |
    |- go.mod
    |- README.md
```

## 먼저 테스트 작성

```go
package integers

import "testing"

func TestAdder(t *testing.T) {
	sum := Add(2, 2)
	expected := 4

	if sum != expected {
		t.Errorf("expected '%d' but got '%d'", expected, sum)
	}
}
```

포맷 문자열로 `%q` 대신 `%d`를 사용하고 있다는 것을 알 수 있습니다. 그것은 문자열이 아닌 정수를 출력하기를 원하기 때문입니다.

또한 main 패키지를 더 이상 사용하지 않고, 이름에서 알 수 있듯이 `Add`와 같은 정수 작업을 위한 함수를 그룹화할 `integers`라는 패키지를 정의했습니다.

## 테스트 실행 시도

`go test` 테스트를 실행하세요

컴파일 오류를 검사하세요

`./adder_test.go:6:9: undefined: Add`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

컴파일러를 만족시키기 위한 충분한 코드만 작성하세요 - 테스트가 올바른 이유로 실패하는지 확인하고 싶다는 것을 기억하세요.

```go
package integers

func Add(x, y int) int {
	return 0
}
```

같은 타입의 인자가 두 개 이상 있을 때\(우리 경우 두 개의 정수\) `(x int, y int)` 대신 `(x, y int)`로 줄일 수 있다는 것을 기억하세요.

이제 테스트를 실행하면, 테스트가 무엇이 잘못되었는지 올바르게 보고하는 것을 볼 수 있어야 합니다.

`adder_test.go:10: expected '4' but got '0'`

[이전](hello-world.md#one...last...refactor?) 섹션에서 *네임드 반환 값*에 대해 배웠지만 여기서는 사용하지 않고 있습니다. 일반적으로 결과의 의미가 컨텍스트에서 명확하지 않을 때 사용해야 하며, 우리 경우 `Add` 함수가 매개변수를 더한다는 것이 꽤 명확합니다. 자세한 내용은 [이](https://go.dev/wiki/CodeReviewComments#named-result-parameters) 위키를 참조할 수 있습니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

TDD의 가장 엄격한 의미에서 우리는 이제 *테스트를 통과시키기 위한 최소한의 코드*를 작성해야 합니다. 꼼꼼한 프로그래머는 이렇게 할 수 있습니다

```go
func Add(x, y int) int {
	return 4
}
```

아하! 또 당했군요, TDD는 사기죠?

다른 숫자로 또 다른 테스트를 작성하여 해당 테스트가 실패하도록 강제할 수 있지만, [고양이와 쥐 게임](https://en.m.wikipedia.org/wiki/Cat_and_mouse)처럼 느껴집니다.

Go 구문에 더 익숙해지면 **"속성 기반 테스팅"**이라는 기술을 소개할 것인데, 이것은 성가신 개발자를 막고 버그를 찾는 데 도움이 될 것입니다.

지금은 제대로 고쳐봅시다

```go
func Add(x, y int) int {
	return x + y
}
```

테스트를 다시 실행하면 통과해야 합니다.

## 리팩토링

여기서 *실제* 코드에서 개선할 수 있는 것은 많지 않습니다.

반환 인자에 이름을 지정하면 문서에 나타나고 대부분의 개발자 텍스트 에디터에도 나타난다는 것을 앞서 탐구했습니다.

이것은 작성 중인 코드의 사용성을 돕기 때문에 훌륭합니다. 사용자가 타입 시그니처와 문서만 보고 코드의 사용법을 이해할 수 있는 것이 바람직합니다.

주석으로 함수에 문서를 추가할 수 있으며, 표준 라이브러리의 문서를 볼 때처럼 Go Doc에 나타납니다.

```go
// Add takes two integers and returns the sum of them.
func Add(x, y int) int {
	return x + y
}
```

### 테스트 가능한 예제

정말로 더 노력하고 싶다면 [테스트 가능한 예제](https://blog.golang.org/examples)를 만들 수 있습니다. 표준 라이브러리 문서에서 많은 예제를 찾을 수 있습니다.

종종 readme 파일과 같은 코드베이스 외부에서 찾을 수 있는 코드 예제는 확인되지 않기 때문에 실제 코드에 비해 오래되고 부정확해집니다.

예제 함수는 테스트가 실행될 때마다 컴파일됩니다. 이러한 예제는 Go 컴파일러에 의해 검증되므로 문서의 예제가 항상 현재 코드 동작을 반영한다고 확신할 수 있습니다.

예제 함수는 `Example`로 시작하며(테스트 함수가 `Test`로 시작하는 것처럼), 패키지의 `_test.go` 파일에 있습니다. 다음 `ExampleAdd` 함수를 `adder_test.go` 파일에 추가하세요.

```go
func ExampleAdd() {
	sum := Add(1, 5)
	fmt.Println(sum)
	// Output: 6
}
```

(에디터가 자동으로 패키지를 임포트하지 않으면, `adder_test.go`에서 `import "fmt"`가 없어서 컴파일 단계가 실패합니다. 사용하는 에디터에서 이러한 종류의 오류를 자동으로 수정하는 방법을 연구하는 것이 강력히 권장됩니다.)

이 코드를 추가하면 예제가 문서에 나타나 코드를 더욱 접근하기 쉽게 만듭니다. 코드가 변경되어 예제가 더 이상 유효하지 않으면 빌드가 실패합니다.

패키지의 테스트 스위트를 실행하면, 우리의 추가 조치 없이 `ExampleAdd` 예제 함수가 실행되는 것을 볼 수 있습니다:

```bash
$ go test -v
=== RUN   TestAdder
--- PASS: TestAdder (0.00s)
=== RUN   ExampleAdd
--- PASS: ExampleAdd (0.00s)
```

주석의 특별한 형식 `// Output: 6`에 주목하세요. 예제는 항상 컴파일되지만, 이 주석을 추가하면 예제도 실행됩니다. `// Output: 6` 주석을 일시적으로 제거하고 `go test`를 실행하면, `ExampleAdd`가 더 이상 실행되지 않는 것을 볼 수 있습니다.

출력 주석이 없는 예제는 네트워크에 액세스하는 것과 같이 단위 테스트로 실행할 수 없는 코드를 시연하는 데 유용하면서도 예제가 최소한 컴파일된다는 것을 보장합니다.

예제 문서를 보려면, `pkgsite`를 빠르게 살펴봅시다. 프로젝트 디렉토리로 이동하기 전에, `go install golang.org/x/pkgsite/cmd/pkgsite@latest` 명령을 실행하여 `pkgsite`를 설치했는지 확인한 다음, `pkgsite -open .`을 실행하면 `http://localhost:8080`을 가리키는 웹 브라우저가 열릴 것입니다. 여기에서 모든 Go 표준 라이브러리 패키지 목록과 설치한 서드파티 패키지를 볼 수 있으며, 그 아래에서 `github.com/quii/learn-go-with-tests`에 대한 예제 문서를 볼 수 있습니다. 해당 링크를 따라가서 `Integers` 아래, `func Add` 아래를 보고, `Example`을 확장하면 `sum := Add(1, 5)`에 대해 추가한 예제를 볼 수 있습니다.

예제와 함께 코드를 공개 URL에 게시하면 [pkg.go.dev](https://pkg.go.dev/)에서 코드 문서를 공유할 수 있습니다. 예를 들어, [여기](https://pkg.go.dev/github.com/quii/learn-go-with-tests/integers/v2)에 이 챕터의 최종 API가 있습니다. 이 웹 인터페이스를 사용하면 표준 라이브러리 패키지와 서드파티 패키지의 문서를 검색할 수 있습니다.

## 마무리

다룬 내용:

*   TDD 워크플로우의 더 많은 연습
*   정수, 덧셈
*   코드 사용자가 사용법을 빠르게 이해할 수 있도록 더 나은 문서 작성
*   테스트의 일부로 확인되는 코드 사용 예제

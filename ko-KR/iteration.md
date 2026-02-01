# 반복문

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/for)**

Go에서 무언가를 반복적으로 수행하려면 `for`가 필요합니다. Go에는 `while`, `do`, `until` 키워드가 없으며, `for`만 사용할 수 있습니다. 이것은 좋은 일입니다!

문자를 5번 반복하는 함수에 대한 테스트를 작성해 봅시다.

지금까지 새로운 것은 없으니, 연습을 위해 직접 작성해 보세요.

## 먼저 테스트 작성

```go
package iteration

import "testing"

func TestRepeat(t *testing.T) {
	repeated := Repeat("a")
	expected := "aaaaa"

	if repeated != expected {
		t.Errorf("expected %q but got %q", expected, repeated)
	}
}
```

## 테스트 실행 시도

`./repeat_test.go:6:14: undefined: Repeat`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

*규율을 유지하세요!* 테스트가 제대로 실패하도록 하기 위해 지금 새로운 것을 알 필요가 없습니다.

지금 해야 할 일은 컴파일되도록 충분히 작성하여 테스트가 잘 작성되었는지 확인할 수 있도록 하는 것입니다.

```go
package iteration

func Repeat(character string) string {
	return ""
}
```

이미 기본적인 문제에 대한 테스트를 작성할 수 있을 만큼 Go를 알고 있다는 것이 좋지 않나요? 이것은 이제 원하는 만큼 프로덕션 코드를 가지고 놀 수 있고 기대한 대로 동작하는지 알 수 있다는 것을 의미합니다.

`repeat_test.go:10: expected 'aaaaa' but got ''`

## 테스트를 통과시키기 위한 충분한 코드 작성

`for` 구문은 매우 평범하며 대부분의 C 계열 언어를 따릅니다.

```go
func Repeat(character string) string {
	var repeated string
	for i := 0; i < 5; i++ {
		repeated = repeated + character
	}
	return repeated
}
```

C, Java, JavaScript와 같은 다른 언어와 달리 for 문의 세 가지 구성 요소를 둘러싸는 괄호가 없으며 중괄호 `{ }`가 항상 필요합니다. 다음 줄에서 무슨 일이 일어나고 있는지 궁금할 수 있습니다

```go
	var repeated string
```

지금까지 변수를 선언하고 초기화하기 위해 `:=`를 사용해 왔습니다. 그러나 `:=`는 단순히 [두 단계에 대한 단축형](https://gobyexample.com/variables)입니다. 여기서는 `string` 변수만 선언하고 있습니다. 따라서 명시적 버전입니다. 나중에 보게 되겠지만, `var`를 사용하여 함수도 선언할 수 있습니다.

테스트를 실행하면 통과해야 합니다.

for 루프의 추가 변형은 [여기](https://gobyexample.com/for)에서 설명됩니다.

## 리팩토링

이제 리팩토링하고 또 다른 구조 `+=` 대입 연산자를 소개할 시간입니다.

```go
const repeatCount = 5

func Repeat(character string) string {
	var repeated string
	for i := 0; i < repeatCount; i++ {
		repeated += character
	}
	return repeated
}
```

_"더하기 AND 대입 연산자"_라고 불리는 `+=`는 오른쪽 피연산자를 왼쪽 피연산자에 더하고 결과를 왼쪽 피연산자에 할당합니다. 정수와 같은 다른 타입에서도 작동합니다.

### 벤치마킹

Go에서 [벤치마크](https://golang.org/pkg/testing/#hdr-Benchmarks)를 작성하는 것은 언어의 또 다른 일급 기능이며 테스트 작성과 매우 유사합니다.

```go
func BenchmarkRepeat(b *testing.B) {
	for b.Loop() {
		Repeat("a")
	}
}
```

코드가 테스트와 매우 유사하다는 것을 알 수 있습니다.

`testing.B`는 루프 함수에 대한 액세스를 제공합니다. `Loop()`는 벤치마크가 계속 실행되어야 하는 동안 true를 반환합니다.

벤치마크 코드가 실행되면, 얼마나 오래 걸리는지 측정합니다. `Loop()`가 false를 반환한 후, `b.N`에는 실행된 총 반복 횟수가 포함됩니다.

코드가 실행되는 횟수는 신경 쓰지 않아도 됩니다. 프레임워크가 괜찮은 결과를 얻을 수 있는 "좋은" 값을 결정합니다.

벤치마크를 실행하려면 `go test -bench=.`를 실행하세요 (Windows Powershell에서는 `go test -bench="."`)

```text
goos: darwin
goarch: amd64
pkg: github.com/quii/learn-go-with-tests/for/v4
10000000           136 ns/op
PASS
```

`136 ns/op`이 의미하는 것은 함수가 \(제 컴퓨터에서\) 평균 136 나노초가 걸린다는 것입니다. 꽤 괜찮습니다! 이것을 테스트하기 위해 10000000번 실행했습니다.

**참고:** 기본적으로 벤치마크는 순차적으로 실행됩니다.

루프의 본문만 시간이 측정됩니다; 벤치마크 타이밍에서 설정 및 정리 코드를 자동으로 제외합니다. 일반적인 벤치마크는 다음과 같이 구조화됩니다:

```go
func Benchmark(b *testing.B) {
	//... 설정 ...
	for b.Loop() {
		//... 측정할 코드 ...
	}
	//... 정리 ...
}
```

Go에서 문자열은 불변이며, 이는 `Repeat` 함수에서와 같이 모든 연결이 새 문자열을 수용하기 위해 메모리 복사를 수반한다는 것을 의미합니다. 이것은 특히 무거운 문자열 연결 중에 성능에 영향을 미칩니다.

표준 라이브러리는 메모리 복사를 최소화하는 `strings.Builder`[stringsBuilder] 타입을 제공합니다.
문자열을 연결하는 데 사용할 수 있는 `WriteString` 메서드를 구현합니다:

```go
const repeatCount = 5

func Repeat(character string) string {
	var repeated strings.Builder
	for i := 0; i < repeatCount; i++ {
		repeated.WriteString(character)
	}
	return repeated.String()
}
```

**참고**: 최종 결과를 검색하려면 `String` 메서드를 호출해야 합니다.

`BenchmarkRepeat`를 사용하여 `strings.Builder`가 성능을 크게 향상시키는지 확인할 수 있습니다.
`go test -bench=. -benchmem`을 실행하세요:

```text
goos: darwin
goarch: amd64
pkg: github.com/quii/learn-go-with-tests/for/v4
10000000           25.70 ns/op           8 B/op           1 allocs/op
PASS
```

`-benchmem` 플래그는 메모리 할당에 대한 정보를 보고합니다:

* `B/op`: 반복당 할당된 바이트 수
* `allocs/op`: 반복당 메모리 할당 수

## 연습 문제

* 호출자가 문자가 반복되는 횟수를 지정할 수 있도록 테스트를 변경하고 코드를 수정하세요
* 함수를 문서화하기 위해 `ExampleRepeat`를 작성하세요
* [strings](https://golang.org/pkg/strings) 패키지를 살펴보세요. 유용할 것 같은 함수를 찾고 여기서 한 것처럼 테스트를 작성하여 실험하세요. 표준 라이브러리를 배우는 데 시간을 투자하면 시간이 지남에 따라 정말 효과가 있을 것입니다.

## 마무리

* 더 많은 TDD 연습
* `for` 학습
* 벤치마크 작성 방법 학습

[stringsBuilder]: https://pkg.go.dev/strings#Builder

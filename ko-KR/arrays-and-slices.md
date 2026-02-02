# 배열과 슬라이스

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/arrays)**

배열을 사용하면 동일한 타입의 여러 요소를 특정 순서로 변수에 저장할 수 있습니다.

배열이 있을 때, 이를 반복해야 하는 경우가 매우 흔합니다. 그래서 [`for`에 대해 새로 배운 지식](iteration.md)을 사용하여 `Sum` 함수를 만들어 봅시다. `Sum`은 숫자 배열을 받아 총합을 반환합니다.

TDD 기술을 사용합시다

## 먼저 테스트 작성

작업할 새 폴더를 만드세요. `sum_test.go`라는 새 파일을 만들고 다음을 삽입하세요:

```go
package main

import "testing"

func TestSum(t *testing.T) {

	numbers := [5]int{1, 2, 3, 4, 5}

	got := Sum(numbers)
	want := 15

	if got != want {
		t.Errorf("got %d want %d given, %v", got, want, numbers)
	}
}
```

배열은 변수를 선언할 때 정의하는 **고정 용량**이 있습니다.
배열을 두 가지 방법으로 초기화할 수 있습니다:

* \[N\]type{value1, value2, ..., valueN} 예: `numbers := [5]int{1, 2, 3, 4, 5}`
* \[...\]type{value1, value2, ..., valueN} 예: `numbers := [...]int{1, 2, 3, 4, 5}`

오류 메시지에서 함수에 대한 입력도 출력하는 것이 때때로 유용합니다.
여기서는 배열에 잘 작동하는 "기본" 형식을 출력하기 위해 `%v` 플레이스홀더를 사용하고 있습니다.

[형식 문자열에 대해 더 읽어보기](https://golang.org/pkg/fmt/)

## 테스트 실행 시도

`go mod init main`으로 go mod를 초기화했다면 `_testmain.go:13:2: cannot import "main"` 오류가 표시됩니다. 이것은 일반적인 관행에 따르면, package main은 다른 패키지의 통합만 포함하고 단위 테스트 가능한 코드는 포함하지 않으므로 Go가 `main`이라는 이름의 패키지를 임포트하도록 허용하지 않기 때문입니다.

이것을 수정하려면, `go.mod`의 main 모듈을 다른 이름으로 변경하면 됩니다.

위의 오류가 수정되면, `go test`를 실행하면 익숙한 `./sum_test.go:10:15: undefined: Sum` 오류와 함께 컴파일러가 실패합니다. 이제 테스트할 실제 메서드를 작성할 수 있습니다.

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`sum.go`에서

```go
package main

func Sum(numbers [5]int) int {
	return 0
}
```

테스트가 이제 **명확한 오류 메시지**와 함께 실패해야 합니다

`sum_test.go:13: got 0 want 15 given, [1 2 3 4 5]`

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Sum(numbers [5]int) int {
	sum := 0
	for i := 0; i < 5; i++ {
		sum += numbers[i]
	}
	return sum
}
```

특정 인덱스에서 배열의 값을 가져오려면, `array[index]` 구문을 사용하면 됩니다. 이 경우, 배열을 통해 작업하고 각 항목을 `sum`에 추가하기 위해 `for`를 사용하여 5번 반복합니다.

## 리팩토링

코드를 정리하는 데 도움이 되도록 [`range`](https://gobyexample.com/range)를 소개합시다

```go
func Sum(numbers [5]int) int {
	sum := 0
	for _, number := range numbers {
		sum += number
	}
	return sum
}
```

`range`를 사용하면 배열을 반복할 수 있습니다. 각 반복에서 `range`는 인덱스와 값의 두 값을 반환합니다.
`_` [빈 식별자](https://golang.org/doc/effective_go.html#blank)를 사용하여 인덱스 값을 무시하기로 선택합니다.

### 배열과 타입

배열의 흥미로운 속성은 크기가 타입에 인코딩된다는 것입니다. `[5]int`를 기대하는 함수에 `[4]int`를 전달하려고 하면 컴파일되지 않습니다.
이들은 다른 타입이므로 `int`를 원하는 함수에 `string`을 전달하려는 것과 같습니다.

배열이 고정 길이를 갖는 것이 다소 번거롭다고 생각할 수 있으며, 대부분의 경우 아마 사용하지 않을 것입니다!

Go에는 컬렉션의 크기를 인코딩하지 않고 대신 어떤 크기든 가질 수 있는 **슬라이스**가 있습니다.

다음 요구 사항은 다양한 크기의 컬렉션을 합산하는 것입니다.

## 먼저 테스트 작성

이제 어떤 크기의 컬렉션이든 가질 수 있는 [슬라이스 타입][slice]을 사용할 것입니다. 구문은 배열과 매우 유사하며, 선언할 때 크기를 생략하기만 하면 됩니다

`mySlice := []int{1,2,3}` 대신 `myArray := [3]int{1,2,3}`

```go
func TestSum(t *testing.T) {

	t.Run("collection of 5 numbers", func(t *testing.T) {
		numbers := [5]int{1, 2, 3, 4, 5}

		got := Sum(numbers)
		want := 15

		if got != want {
			t.Errorf("got %d want %d given, %v", got, want, numbers)
		}
	})

	t.Run("collection of any size", func(t *testing.T) {
		numbers := []int{1, 2, 3}

		got := Sum(numbers)
		want := 6

		if got != want {
			t.Errorf("got %d want %d given, %v", got, want, numbers)
		}
	})

}
```

## 테스트 실행 시도

컴파일되지 않습니다

`./sum_test.go:22:13: cannot use numbers (type []int) as type [5]int in argument to Sum`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

여기서 문제는 다음 중 하나를 할 수 있다는 것입니다

* `Sum`의 인자를 배열 대신 슬라이스로 변경하여 기존 API를 깨뜨립니다. 이렇게 하면 **다른** 테스트가 더 이상 컴파일되지 않기 때문에 누군가의 하루를 망칠 수 있습니다!
* 새 함수 만들기

우리의 경우, 다른 누구도 우리 함수를 사용하지 않으므로, 유지할 함수가 두 개가 아닌 하나만 갖도록 합시다.

```go
func Sum(numbers []int) int {
	sum := 0
	for _, number := range numbers {
		sum += number
	}
	return sum
}
```

테스트를 실행하려고 하면 여전히 컴파일되지 않으며, 배열 대신 슬라이스를 전달하도록 첫 번째 테스트를 변경해야 합니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

컴파일러 문제를 수정하는 것이 여기서 해야 할 전부였고 테스트가 통과합니다!

## 리팩토링

이미 `Sum`을 리팩토링했습니다 - 배열을 슬라이스로 대체한 것뿐이므로 추가 변경이 필요하지 않습니다.
리팩토링 단계에서 테스트 코드를 소홀히 해서는 안 된다는 것을 기억하세요 - `Sum` 테스트를 더 개선할 수 있습니다.

```go
func TestSum(t *testing.T) {

	t.Run("collection of 5 numbers", func(t *testing.T) {
		numbers := []int{1, 2, 3, 4, 5}

		got := Sum(numbers)
		want := 15

		if got != want {
			t.Errorf("got %d want %d given, %v", got, want, numbers)
		}
	})

	t.Run("collection of any size", func(t *testing.T) {
		numbers := []int{1, 2, 3}

		got := Sum(numbers)
		want := 6

		if got != want {
			t.Errorf("got %d want %d given, %v", got, want, numbers)
		}
	})

}
```

테스트의 가치에 의문을 제기하는 것이 중요합니다. 가능한 한 많은 테스트를 갖는 것이 목표가 아니라, 코드베이스에 가능한 한 많은 **확신**을 갖는 것이 목표여야 합니다. 너무 많은 테스트를 갖는 것은 실제 문제가 될 수 있으며 유지보수에 더 많은 오버헤드를 추가할 뿐입니다. **모든 테스트에는 비용이 있습니다**.

우리의 경우, 이 함수에 대해 두 개의 테스트가 있는 것이 중복됨을 알 수 있습니다.
한 크기의 슬라이스에서 작동하면 \(합리적인 범위 내에서\) 어떤 크기의 슬라이스에서든 작동할 가능성이 매우 높습니다.

Go의 내장 테스팅 툴킷에는 [커버리지 도구](https://blog.golang.org/cover)가 포함되어 있습니다.
100% 커버리지를 목표로 하는 것이 최종 목표가 되어서는 안 되지만, 커버리지 도구는 테스트되지 않은 코드 영역을 식별하는 데 도움이 될 수 있습니다. TDD를 엄격하게 따랐다면, 어쨌든 100%에 가까운 커버리지를 가질 가능성이 높습니다.

실행해 보세요

`go test -cover`

다음을 볼 수 있어야 합니다

```bash
PASS
coverage: 100.0% of statements
```

이제 테스트 중 하나를 삭제하고 커버리지를 다시 확인하세요.

이제 잘 테스트된 함수가 있다는 것에 만족한다면 다음 도전을 시작하기 전에 훌륭한 작업을 커밋해야 합니다.

다양한 수의 슬라이스를 받아 전달된 각 슬라이스의 총합을 포함하는 새 슬라이스를 반환하는 `SumAll`이라는 새 함수가 필요합니다.

예를 들어

`SumAll([]int{1,2}, []int{0,9})`는 `[]int{3, 9}`를 반환합니다

또는

`SumAll([]int{1,1,1})`는 `[]int{3}`을 반환합니다

## 먼저 테스트 작성

```go
func TestSumAll(t *testing.T) {

	got := SumAll([]int{1, 2}, []int{0, 9})
	want := []int{3, 9}

	if got != want {
		t.Errorf("got %v want %v", got, want)
	}
}
```

## 테스트 실행 시도

`./sum_test.go:23:9: undefined: SumAll`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

테스트가 원하는 대로 `SumAll`을 정의해야 합니다.

Go는 가변 개수의 인자를 받을 수 있는 [**가변 함수**](https://gobyexample.com/variadic-functions)를 작성할 수 있게 합니다.

```go
func SumAll(numbersToSum ...[]int) []int {
	return nil
}
```

이것은 유효하지만, 테스트가 여전히 컴파일되지 않습니다!

`./sum_test.go:26:9: invalid operation: got != want (slice can only be compared to nil)`

Go에서는 슬라이스와 함께 동등 연산자를 사용할 수 없습니다. 각 `got`과 `want` 슬라이스를 반복하고 그 값을 확인하는 함수를 작성**할 수** 있지만, 더 편리한 방법이 있다면 어떨까요?

Go 1.21부터, [slices](https://pkg.go.dev/slices#pkg-overview) 표준 패키지가 사용 가능하며, 위의 경우처럼 타입에 대해 걱정할 필요 없이 슬라이스에서 간단한 얕은 비교를 수행하는 [slices.Equal](https://pkg.go.dev/slices#Equal) 함수가 있습니다.
이 함수는 요소가 [comparable](https://pkg.go.dev/builtin#comparable)할 것을 기대합니다.
따라서, 2D 슬라이스와 같이 비교할 수 없는 요소가 있는 슬라이스에는 적용할 수 없습니다.

실제로 이것을 적용해 봅시다!

```go
func TestSumAll(t *testing.T) {

	got := SumAll([]int{1, 2}, []int{0, 9})
	want := []int{3, 9}

	if !slices.Equal(got, want) {
		t.Errorf("got %v want %v", got, want)
	}
}
```

다음과 같은 테스트 출력이 있어야 합니다:
`sum_test.go:30: got [] want [3 9]`

## 테스트를 통과시키기 위한 충분한 코드 작성

해야 할 일은 varargs를 반복하고, 기존 `Sum` 함수를 사용하여 합계를 계산한 다음, 반환할 슬라이스에 추가하는 것입니다

```go
func SumAll(numbersToSum ...[]int) []int {
	lengthOfNumbers := len(numbersToSum)
	sums := make([]int, lengthOfNumbers)

	for i, numbers := range numbersToSum {
		sums[i] = Sum(numbers)
	}

	return sums
}
```

배울 것이 많습니다!

슬라이스를 만드는 새로운 방법이 있습니다. `make`를 사용하면 작업해야 하는 `numbersToSum`의 `len`의 시작 용량으로 슬라이스를 만들 수 있습니다. 슬라이스의 길이는 보유하고 있는 요소의 수 `len(mySlice)`이고, 용량은 기본 배열에 보유할 수 있는 요소의 수 `cap(mySlice)`입니다, 예: `make([]int, 0, 5)`는 길이 0과 용량 5의 슬라이스를 만듭니다.

배열처럼 `mySlice[N]`으로 슬라이스를 인덱싱하여 값을 가져오거나 `=`로 새 값을 할당할 수 있습니다

테스트가 이제 통과해야 합니다.

## 리팩토링

언급했듯이, 슬라이스에는 용량이 있습니다. 용량이 2인 슬라이스가 있고 `mySlice[10] = 1`을 시도하면 **런타임** 오류가 발생합니다.

그러나, 슬라이스와 새 값을 받아 모든 항목이 포함된 새 슬라이스를 반환하는 `append` 함수를 사용할 수 있습니다.

```go
func SumAll(numbersToSum ...[]int) []int {
	var sums []int
	for _, numbers := range numbersToSum {
		sums = append(sums, Sum(numbers))
	}

	return sums
}
```

이 구현에서, 우리는 용량에 대해 덜 걱정합니다. 빈 슬라이스 `sums`로 시작하고 varargs를 통해 작업하면서 `Sum`의 결과를 추가합니다.

다음 요구 사항은 `SumAll`을 `SumAllTails`로 변경하는 것입니다. 여기서 각 슬라이스의 "꼬리"의 총합을 계산합니다. 컬렉션의 꼬리는 첫 번째 항목\("머리"\)을 제외한 컬렉션의 모든 항목입니다.

## 먼저 테스트 작성

```go
func TestSumAllTails(t *testing.T) {
	got := SumAllTails([]int{1, 2}, []int{0, 9})
	want := []int{2, 9}

	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %v want %v", got, want)
	}
}
```

## 테스트 실행 시도

`./sum_test.go:26:9: undefined: SumAllTails`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

함수 이름을 `SumAllTails`로 변경하고 테스트를 다시 실행하세요

`sum_test.go:30: got [3 9] want [2 9]`

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func SumAllTails(numbersToSum ...[]int) []int {
	var sums []int
	for _, numbers := range numbersToSum {
		tail := numbers[1:]
		sums = append(sums, Sum(tail))
	}

	return sums
}
```

슬라이스는 슬라이싱할 수 있습니다! 구문은 `slice[low:high]`입니다. `:` 한쪽에 값을 생략하면 그 쪽의 모든 것을 캡처합니다. 우리의 경우, `numbers[1:]`로 "1부터 끝까지 가져오기"라고 말하고 있습니다. 슬라이스 주변에 다른 테스트를 작성하고 슬라이스 연산자를 더 익숙해지도록 실험해 보는 데 시간을 투자할 수 있습니다.

## 리팩토링

이번에는 리팩토링할 것이 많지 않습니다.

빈 슬라이스를 함수에 전달하면 어떻게 될까요? 빈 슬라이스의 "꼬리"는 무엇일까요? `myEmptySlice[1:]`에서 모든 요소를 캡처하라고 Go에게 말하면 어떻게 될까요?

## 먼저 테스트 작성

```go
func TestSumAllTails(t *testing.T) {

	t.Run("make the sums of some slices", func(t *testing.T) {
		got := SumAllTails([]int{1, 2}, []int{0, 9})
		want := []int{2, 9}

		if !reflect.DeepEqual(got, want) {
			t.Errorf("got %v want %v", got, want)
		}
	})

	t.Run("safely sum empty slices", func(t *testing.T) {
		got := SumAllTails([]int{}, []int{3, 4, 5})
		want := []int{0, 9}

		if !reflect.DeepEqual(got, want) {
			t.Errorf("got %v want %v", got, want)
		}
	})

}
```

## 테스트 실행 시도

```text
panic: runtime error: slice bounds out of range [recovered]
    panic: runtime error: slice bounds out of range
```

이런! 테스트가 **컴파일되었지만** **런타임 오류**가 있다는 것에 주목하는 것이 중요합니다.

컴파일 타임 오류는 작동하는 소프트웨어를 작성하는 데 도움이 되기 때문에 우리 친구이고, 런타임 오류는 사용자에게 영향을 미치기 때문에 우리의 적입니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func SumAllTails(numbersToSum ...[]int) []int {
	var sums []int
	for _, numbers := range numbersToSum {
		if len(numbers) == 0 {
			sums = append(sums, 0)
		} else {
			tail := numbers[1:]
			sums = append(sums, Sum(tail))
		}
	}

	return sums
}
```

## 리팩토링

테스트에 어설션 주변에 반복되는 코드가 다시 있으므로, 함수로 추출합시다.

```go
func TestSumAllTails(t *testing.T) {

	checkSums := func(t testing.TB, got, want []int) {
		t.Helper()
		if !reflect.DeepEqual(got, want) {
			t.Errorf("got %v want %v", got, want)
		}
	}

	t.Run("make the sums of tails of", func(t *testing.T) {
		got := SumAllTails([]int{1, 2}, []int{0, 9})
		want := []int{2, 9}
		checkSums(t, got, want)
	})

	t.Run("safely sum empty slices", func(t *testing.T) {
		got := SumAllTails([]int{}, []int{3, 4, 5})
		want := []int{0, 9}
		checkSums(t, got, want)
	})

}
```

평소처럼 새 함수 `checkSums`를 만들 수 있었지만, 이 경우 새로운 기술을 보여주고 있습니다. 변수에 함수를 할당하는 것입니다. 이상하게 보일 수 있지만, `string`이나 `int`에 변수를 할당하는 것과 다르지 않습니다. 함수도 사실상 값입니다.

여기서는 보여지지 않지만, 이 기술은 함수를 "스코프" 내의 다른 로컬 변수에 바인딩하려는 경우(예: 일부 `{}` 사이) 유용할 수 있습니다. 또한 API의 표면적을 줄일 수 있습니다.

테스트 내에서 이 함수를 정의함으로써, 이 패키지의 다른 함수에서 사용할 수 없습니다. 내보내 필요가 없는 변수와 함수를 숨기는 것은 중요한 설계 고려 사항입니다.

이것의 편리한 부작용은 코드에 약간의 타입 안전성을 추가한다는 것입니다. 개발자가 실수로 `checkSums(t, got, "dave")`로 새 테스트를 추가하면 컴파일러가 막습니다.

```bash
$ go test
./sum_test.go:52:21: cannot use "dave" (type string) as type []int in argument to checkSums
```

## 마무리

다룬 내용

* 배열
* 슬라이스
  * 만드는 다양한 방법
  * **고정** 용량이 있지만 `append`를 사용하여 이전 슬라이스에서 새 슬라이스를 만들 수 있는 방법
  * 슬라이스를 슬라이싱하는 방법!
* 배열이나 슬라이스의 길이를 얻는 `len`
* 테스트 커버리지 도구
* `reflect.DeepEqual`과 유용하지만 코드의 타입 안전성을 줄일 수 있는 이유

정수로 슬라이스와 배열을 사용했지만 배열/슬라이스 자체를 포함한 다른 타입에서도 작동합니다. 따라서 필요한 경우 `[][]string` 변수를 선언할 수 있습니다.

슬라이스에 대한 심층적인 내용은 [Go 블로그의 슬라이스 포스트][blog-slice]를 확인하세요.
읽은 내용을 확고히 하기 위해 더 많은 테스트를 작성해 보세요.

테스트 작성 외에 Go를 실험하는 또 다른 편리한 방법은 Go playground입니다. 대부분의 것을 시도해 볼 수 있고 질문이 있으면 쉽게 코드를 공유할 수 있습니다. [실험할 수 있도록 슬라이스가 있는 Go playground를 만들었습니다.](https://play.golang.org/p/ICCWcRGIO68)

[여기에](https://play.golang.org/p/bTrRmYfNYCp) 배열을 슬라이싱하고 슬라이스를 변경하면 원래 배열에 영향을 미치는 예제가 있습니다; 하지만 슬라이스의 "복사본"은 원래 배열에 영향을 미치지 않습니다.
[또 다른 예제](https://play.golang.org/p/Poth8JS28sc)는 매우 큰 슬라이스를 슬라이싱한 후 슬라이스의 복사본을 만드는 것이 왜 좋은 생각인지 보여줍니다.

[for]: ../iteration.md#
[blog-slice]: https://blog.golang.org/go-slices-usage-and-internals
[deepEqual]: https://golang.org/pkg/reflect/#DeepEqual
[slice]: https://golang.org/doc/effective_go.html#slices

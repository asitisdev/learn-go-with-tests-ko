# 제네릭을 활용한 배열과 슬라이스 재방문

**[이 챕터의 코드는 배열과 슬라이스 챕터의 연속이며, 여기에서 찾을 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/arrays)**

[배열과 슬라이스](arrays-and-slices.md)에서 작성한 `SumAll`과 `SumAllTails`를 살펴보세요.

```go
// Sum은 숫자 슬라이스에서 합계를 계산합니다.
func Sum(numbers []int) int {
	var sum int
	for _, number := range numbers {
		sum += number
	}
	return sum
}

// SumAllTails는 슬라이스 컬렉션이 주어지면 각각의 첫 번째 숫자를 제외한 합계를 계산합니다.
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

반복되는 패턴이 보이시나요?

- 어떤 종류의 "초기" 결과 값을 생성합니다.
- 컬렉션을 반복하며 결과와 슬라이스의 다음 항목에 어떤 종류의 연산 (또는 함수)을 적용하고 결과에 새 값을 설정합니다
- 결과를 반환합니다.

이 아이디어는 함수형 프로그래밍 서클에서 흔히 'reduce' 또는 [fold](https://en.wikipedia.org/wiki/Fold_(higher-order_function))라고 합니다.

> 함수형 프로그래밍에서 fold (reduce, accumulate, aggregate, compress 또는 inject라고도 함)는 재귀적 데이터 구조를 분석하고 주어진 결합 연산을 사용하여 구성 부분을 재귀적으로 처리한 결과를 재결합하여 반환 값을 빌드하는 고차 함수 계열을 말합니다.

Go는 항상 고차 함수를 가졌고, 버전 1.18부터 [제네릭](./generics.md)도 가지고 있으므로 이제 더 넓은 분야에서 논의되는 이러한 함수 중 일부를 정의할 수 있습니다.

일부 분들은 이것에 움츠러들 수 있습니다.

> Go는 단순해야 합니다

**쉬움과 단순함을 혼동하지 마세요**. 루프를 돌리고 코드를 복사-붙여넣기하는 것은 쉽지만 반드시 단순하지는 않습니다.

**익숙하지 않음과 복잡함을 혼동하지 마세요**. Fold/reduce는 처음에는 무섭고 컴퓨터 과학적으로 들릴 수 있지만, 실제로는 매우 일반적인 연산에 대한 추상화일 뿐입니다. 컬렉션을 가져와서 하나의 항목으로 결합하는 것입니다.

## 제네릭 리팩토링

반짝이는 새 언어 기능으로 사람들이 종종 저지르는 실수는 구체적인 사용 사례 없이 사용하기 시작하는 것입니다.

다행히 우리는 "유용한" 함수를 작성하고 테스트를 했으므로 TDD의 리팩토링 단계에서 아이디어를 자유롭게 실험할 수 있습니다.

[이전 챕터](generics.md)에서 제네릭 구문에 익숙해야 합니다. 직접 `Reduce` 함수를 작성하고 `Sum`과 `SumAllTails` 내에서 사용해 보세요.

### 첫 번째 `Reduce` 버전

```go
func Reduce[A any](collection []A, f func(A, A) A, initialValue A) A {
	var result = initialValue
	for _, x := range collection {
		result = f(result, x)
	}
	return result
}
```

Reduce는 패턴의 *본질*을 캡처합니다. 컬렉션, 누적 함수, 초기 값을 받아 단일 값을 반환하는 함수입니다.

### 사용법

```go
// Sum은 숫자 슬라이스에서 합계를 계산합니다.
func Sum(numbers []int) int {
	add := func(acc, x int) int { return acc + x }
	return Reduce(numbers, add, 0)
}

// SumAllTails는 슬라이스 컬렉션이 주어지면 각각의 첫 번째 숫자를 제외한 합계를 계산합니다.
func SumAllTails(numbers ...[]int) []int {
	sumTail := func(acc, x []int) []int {
		if len(x) == 0 {
			return append(acc, 0)
		} else {
			tail := x[1:]
			return append(acc, Sum(tail))
		}
	}

	return Reduce(numbers, sumTail, []int{})
}
```

## Reduce의 추가 적용

```go
func TestReduce(t *testing.T) {
	t.Run("multiplication of all elements", func(t *testing.T) {
		multiply := func(x, y int) int {
			return x * y
		}

		AssertEqual(t, Reduce([]int{1, 2, 3}, multiply, 1), 6)
	})

	t.Run("concatenate strings", func(t *testing.T) {
		concatenate := func(x, y string) string {
			return x + y
		}

		AssertEqual(t, Reduce([]string{"a", "b", "c"}, concatenate, ""), "abc")
	})
}
```

### 항등원

곱셈 예제에서 `Reduce`에 기본값을 인자로 갖는 이유를 보여줍니다. Go의 `int` 기본값 0에 의존하면 초기 값에 0을 곱하게 되어 항상 0만 얻게 됩니다. 1로 설정하면 슬라이스의 첫 번째 요소가 그대로 유지됩니다.

이것을 [항등원](https://en.wikipedia.org/wiki/Identity_element)이라고 합니다.

- 덧셈에서 항등원은 0입니다: `1 + 0 = 1`
- 곱셈에서 항등원은 1입니다: `1 * 1 = 1`

## 다른 타입으로 Reduce하려면?

`Transaction` 목록이 있고 이름과 함께 은행 잔액을 계산하는 함수가 필요하다고 가정합니다.

```go
type Transaction struct {
	From string
	To   string
	Sum  float64
}

func BalanceFor(transactions []Transaction, name string) float64 {
	adjustBalance := func(currentBalance float64, t Transaction) float64 {
		if t.From == name {
			return currentBalance - t.Sum
		}
		if t.To == name {
			return currentBalance + t.Sum
		}
		return currentBalance
	}
	return Reduce(transactions, adjustBalance, 0.0)
}
```

하지만 이것은 컴파일되지 않습니다. 컬렉션과 *다른* 타입으로 reduce하려고 하기 때문입니다. `Reduce`의 타입 서명을 조정해야 합니다.

```go
func Reduce[A, B any](collection []A, f func(B, A) B, initialValue B) B {
	var result = initialValue
	for _, x := range collection {
		result = f(result, x)
	}
	return result
}
```

두 번째 타입 제약 조건을 추가하여 `Reduce`의 제약 조건을 느슨하게 했습니다. 이를 통해 `A` 컬렉션에서 `B`로 `Reduce`할 수 있습니다. 우리의 경우 `Transaction`에서 `float64`로.

## Find

이제 Go에 제네릭이 있으므로 고차 함수와 결합하여 프로젝트 내의 많은 보일러플레이트 코드를 줄일 수 있습니다.

더 이상 검색하려는 각 컬렉션 타입에 대해 특정 `Find` 함수를 작성할 필요가 없습니다.

```go
func Find[A any](items []A, predicate func(A) bool) (value A, found bool) {
	for _, v := range items {
		if predicate(v) {
			return v, true
		}
	}
	return
}
```

제네릭 타입을 취하므로 여러 방식으로 재사용할 수 있습니다:

```go
t.Run("find first even number", func(t *testing.T) {
	numbers := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	firstEvenNumber, found := Find(numbers, func(x int) bool {
		return x%2 == 0
	})
	AssertTrue(t, found)
	AssertEqual(t, firstEvenNumber, 2)
})
```

## 마무리

맛있게 수행되면 이와 같은 고차 함수는 코드를 더 쉽게 읽고 유지 관리할 수 있게 만들지만 경험 법칙을 기억하세요:

TDD 프로세스를 사용하여 실제로 필요한 구체적인 동작을 이끌어낸 다음, 리팩토링 단계에서 코드를 정리하는 데 도움이 되는 유용한 추상화를 *발견*할 수 있습니다.

### 이름이 중요합니다

Go 외부에서 조사하여 이미 확립된 이름으로 존재하는 패턴을 다시 발명하지 마세요.

`A` 컬렉션을 `B`로 변환하는 함수를 작성하시나요? `Convert`라고 부르지 마세요, 그것은 [`Map`](https://en.wikipedia.org/wiki/Map_(higher-order_function))입니다.

### 관용적이지 않은 것 같나요?

열린 마음을 가지세요.

Go의 관용구는 제네릭이 출시되어 *급격하게* 변경되어서는 안 되지만, 관용구는 언어가 변경되기 때문에 *변경될 것*입니다!

동료와 교리가 아닌 장점에 따라 코드의 패턴과 스타일을 논의하세요. 잘 설계된 테스트가 있는 한 항상 리팩토링하고 자신과 팀에게 잘 작동하는 것을 이해하면서 변경할 수 있습니다.

### 리소스

Fold는 컴퓨터 과학의 진정한 기초입니다. 더 파고들고 싶다면 흥미로운 리소스가 있습니다:
- [Wikipedia: Fold](https://en.wikipedia.org/wiki/Fold)
- [A tutorial on the universality and expressiveness of fold](http://www.cs.nott.ac.uk/~pszgmh/fold.pdf)

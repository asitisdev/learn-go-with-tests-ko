# 로마 숫자

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/roman-numerals)**

일부 회사는 면접 과정의 일부로 [Roman Numeral Kata](http://codingdojo.org/kata/RomanNumerals/)를 요청합니다. 이 챕터는 TDD로 이것을 해결하는 방법을 보여줄 것입니다.

[아라비아 숫자](https://en.wikipedia.org/wiki/Arabic_numerals) (0에서 9까지의 숫자)를 로마 숫자로 변환하는 함수를 작성할 것입니다.

[로마 숫자](https://en.wikipedia.org/wiki/Roman_numerals)에 대해 들어본 적이 없다면, 이것은 로마인들이 숫자를 쓰는 방법입니다.

기호를 함께 붙여서 만들고 그 기호들은 숫자를 나타냅니다

따라서 `I`는 "일"입니다. `III`는 삼입니다.

쉬워 보이지만 몇 가지 흥미로운 규칙이 있습니다. `V`는 오를 의미하지만, `IV`는 4입니다 (`IIII`가 아님).

`MCMLXXXIV`는 1984입니다. 복잡해 보이고 처음부터 이것을 알아내는 코드를 작성하는 것이 어떻게 가능할지 상상하기 어렵습니다.

이 책이 강조하듯이, 소프트웨어 개발자의 핵심 기술은 *유용한* 기능의 "얇은 수직 슬라이스"를 식별한 다음 **반복**하는 것입니다. TDD 워크플로우는 반복적인 개발을 용이하게 합니다.

따라서 1984가 아니라 1부터 시작합시다.

## 먼저 테스트 작성

```go
func TestRomanNumerals(t *testing.T) {
	got := ConvertToRoman(1)
	want := "I"

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

이 책에서 여기까지 왔다면 이것이 매우 지루하고 일상적으로 느껴지길 바랍니다. 그것은 좋은 것입니다.

## 테스트 실행 시도

```console
./numeral_test.go:6:9: undefined: ConvertToRoman
```

컴파일러가 길을 안내하게 하세요

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

함수를 만들되 아직 테스트를 통과시키지 마세요, 항상 테스트가 예상대로 실패하는지 확인하세요

```go
func ConvertToRoman(arabic int) string {
	return ""
}
```

이제 실행되어야 합니다

```console
=== RUN   TestRomanNumerals
--- FAIL: TestRomanNumerals (0.00s)
    numeral_test.go:10: got '', want 'I'
FAIL
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func ConvertToRoman(arabic int) string {
	return "I"
}
```

## 리팩토링

아직 리팩토링할 것이 많지 않습니다.

결과를 하드코딩하는 것이 이상하게 느껴진다는 것을 *알지만* TDD에서는 가능한 오래 "빨간색"에서 벗어나고 싶습니다. 많이 달성하지 못한 것처럼 *느껴질* 수 있지만 API를 정의하고 규칙 중 하나를 캡처하는 테스트를 얻었습니다; "실제" 코드가 꽤 바보 같더라도.

이제 그 불편한 느낌을 사용하여 약간 덜 바보 같은 코드를 작성하도록 강제하는 새 테스트를 작성하세요.

## 먼저 테스트 작성

서브테스트를 사용하여 테스트를 멋지게 그룹화할 수 있습니다

```go
func TestRomanNumerals(t *testing.T) {
	t.Run("1 gets converted to I", func(t *testing.T) {
		got := ConvertToRoman(1)
		want := "I"

		if got != want {
			t.Errorf("got %q, want %q", got, want)
		}
	})

	t.Run("2 gets converted to II", func(t *testing.T) {
		got := ConvertToRoman(2)
		want := "II"

		if got != want {
			t.Errorf("got %q, want %q", got, want)
		}
	})
}
```

## 테스트 실행 시도

```console
=== RUN   TestRomanNumerals/2*gets*converted*to*II
    --- FAIL: TestRomanNumerals/2*gets*converted*to*II (0.00s)
        numeral_test.go:20: got 'I', want 'II'
```

별로 놀랍지 않습니다

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func ConvertToRoman(arabic int) string {
	if arabic == 2 {
		return "II"
	}
	return "I"
}
```

네, 여전히 실제로 문제를 해결하지 않는 것처럼 느껴집니다. 그래서 우리를 앞으로 이끌기 위해 더 많은 테스트를 작성해야 합니다.

## 리팩토링

테스트에 약간의 반복이 있습니다. "주어진 입력 X, Y를 기대한다"는 것처럼 느껴지는 것을 테스트할 때 테이블 기반 테스트를 사용해야 할 것입니다.

```go
func TestRomanNumerals(t *testing.T) {
	cases := []struct {
		Description string
		Arabic      int
		Want        string
	}{
		{"1 gets converted to I", 1, "I"},
		{"2 gets converted to II", 2, "II"},
	}

	for _, test := range cases {
		t.Run(test.Description, func(t *testing.T) {
			got := ConvertToRoman(test.Arabic)
			if got != test.Want {
				t.Errorf("got %q, want %q", got, test.Want)
			}
		})
	}
}
```

이제 더 많은 테스트 보일러플레이트를 작성하지 않고도 더 많은 케이스를 쉽게 추가할 수 있습니다.

밀어붙여서 3을 해봅시다

## 먼저 테스트 작성

케이스에 다음을 추가하세요

```
{"3 gets converted to III", 3, "III"},
```

## 테스트 실행 시도

```console
=== RUN   TestRomanNumerals/3*gets*converted*to*III
    --- FAIL: TestRomanNumerals/3*gets*converted*to*III (0.00s)
        numeral_test.go:20: got 'I', want 'III'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func ConvertToRoman(arabic int) string {
	if arabic == 3 {
		return "III"
	}
	if arabic == 2 {
		return "II"
	}
	return "I"
}
```

## 리팩토링

좋아요, 저는 이 if 문들이 마음에 들지 않기 시작하고 코드를 충분히 자세히 보면 `arabic`의 크기에 따라 `I`의 문자열을 빌드하고 있다는 것을 볼 수 있습니다.

더 복잡한 숫자에 대해서는 일종의 산술과 문자열 연결을 할 것이라는 것을 "알고" 있습니다.

이러한 생각을 염두에 두고 리팩토링을 시도해 봅시다. 최종 솔루션에 적합하지 *않을 수도* 있지만 괜찮습니다. 우리를 안내하는 테스트로 항상 코드를 버리고 새로 시작할 수 있습니다.

```go
func ConvertToRoman(arabic int) string {

	var result strings.Builder

	for i := 0; i < arabic; i++ {
		result.WriteString("I")
	}

	return result.String()
}
```

[벤치마킹](iteration.md#benchmarking)에 대한 논의에서 [`strings.Builder`](https://golang.org/pkg/strings/#Builder)를 기억할 수 있습니다

> Builder는 Write 메서드를 사용하여 문자열을 효율적으로 빌드하는 데 사용됩니다. 메모리 복사를 최소화합니다.

일반적으로 실제 성능 문제가 있을 때까지 이러한 최적화를 신경 쓰지 않겠지만 코드 양이 문자열에 "수동" 추가보다 훨씬 크지 않으므로 더 빠른 접근 방식을 사용할 수 있습니다.

코드가 저에게 더 좋아 보이고 *현재 우리가 알고 있는* 도메인을 설명합니다.

### 로마인들도 DRY를 좋아했습니다...

이제 상황이 더 복잡해지기 시작합니다. 로마인들은 지혜롭게도 문자를 반복하면 읽고 세기 어려워질 것이라고 생각했습니다. 따라서 로마 숫자의 규칙은 동일한 문자를 연속으로 3번 이상 반복할 수 없다는 것입니다.

대신 다음으로 높은 기호를 가져와 왼쪽에 기호를 놓아 "빼기"합니다. 모든 기호를 빼는 기호로 사용할 수 있는 것은 아닙니다; 오직 I (1), X (10) 및 C (100)만 가능합니다.

예를 들어 로마 숫자에서 `5`는 `V`입니다. 4를 만들려면 `IIII`가 아니라 `IV`를 합니다.

## 먼저 테스트 작성

```
{"4 gets converted to IV (can't repeat more than 3 times)", 4, "IV"},
```

## 테스트 실행 시도

```console
=== RUN   TestRomanNumerals/4*gets*converted*to*IV_(cant*repeat*more*than*3_times)
    --- FAIL: TestRomanNumerals/4*gets*converted*to*IV_(cant*repeat*more*than*3_times) (0.00s)
        numeral_test.go:24: got 'IIII', want 'IV'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func ConvertToRoman(arabic int) string {

	if arabic == 4 {
		return "IV"
	}

	var result strings.Builder

	for i := 0; i < arabic; i++ {
		result.WriteString("I")
	}

	return result.String()
}
```

## 리팩토링

문자열 빌드 패턴을 깨뜨린 것이 "마음에 들지" 않고 계속하고 싶습니다.

```go
func ConvertToRoman(arabic int) string {

	var result strings.Builder

	for i := arabic; i > 0; i-- {
		if i == 4 {
			result.WriteString("IV")
			break
		}
		result.WriteString("I")
	}

	return result.String()
}
```

4가 현재 제 생각에 "맞게" 하기 위해 이제 아라비아 숫자에서 카운트다운하면서 진행하면서 문자열에 기호를 추가합니다. 장기적으로 이것이 작동할지 확실하지 않지만 봅시다!

5가 작동하도록 합시다

## 먼저 테스트 작성

```
{"5 gets converted to V", 5, "V"},
```

## 테스트 실행 시도

```console
=== RUN   TestRomanNumerals/5*gets*converted*to*V
    --- FAIL: TestRomanNumerals/5*gets*converted*to*V (0.00s)
        numeral_test.go:25: got 'IIV', want 'V'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

4에서 한 접근 방식을 복사하세요

```go
func ConvertToRoman(arabic int) string {

	var result strings.Builder

	for i := arabic; i > 0; i-- {
		if i == 5 {
			result.WriteString("V")
			break
		}
		if i == 4 {
			result.WriteString("IV")
			break
		}
		result.WriteString("I")
	}

	return result.String()
}
```

## 리팩토링

이와 같은 루프에서의 반복은 보통 호출되기를 기다리는 추상화의 신호입니다. 루프를 단락시키는 것은 가독성을 위한 효과적인 도구가 될 수 있지만 다른 것을 말할 수도 있습니다.

우리는 아라비아 숫자를 반복하고 특정 기호를 만나면 `break`를 호출하지만 우리가 *실제로* 하는 것은 서투른 방식으로 `i`를 빼는 것입니다.

```go
func ConvertToRoman(arabic int) string {

	var result strings.Builder

	for arabic > 0 {
		switch {
		case arabic > 4:
			result.WriteString("V")
			arabic -= 5
		case arabic > 3:
			result.WriteString("IV")
			arabic -= 4
		default:
			result.WriteString("I")
			arabic--
		}
	}

	return result.String()
}
```

- 몇 가지 매우 기본적인 시나리오의 테스트에서 주도하여 코드에서 읽는 신호를 감안할 때, 로마 숫자를 빌드하려면 기호를 적용하면서 `arabic`에서 빼야 한다는 것을 알 수 있습니다
- `for` 루프는 더 이상 `i`에 의존하지 않고 대신 `arabic`에서 충분한 기호를 뺄 때까지 문자열을 계속 빌드합니다.

이 접근 방식이 6 (VI), 7 (VII) 및 8 (VIII)에도 유효하다고 확신합니다. 그럼에도 불구하고 테스트 스위트에 케이스를 추가하고 확인하세요 (간결함을 위해 코드를 포함하지 않겠습니다. 확실하지 않으면 github에서 샘플을 확인하세요).

9는 4와 같은 규칙을 따르며 다음 숫자의 표현에서 `I`를 빼야 합니다. 10은 로마 숫자에서 `X`로 표시됩니다; 따라서 9는 `IX`여야 합니다.

## 먼저 테스트 작성

```
{"9 gets converted to IX", 9, "IX"},
```

## 테스트 실행 시도

```console
=== RUN   TestRomanNumerals/9*gets*converted*to*IX
    --- FAIL: TestRomanNumerals/9*gets*converted*to*IX (0.00s)
        numeral_test.go:29: got 'VIV', want 'IX'
```

## 테스트를 통과시키기 위한 충분한 코드 작성

이전과 같은 접근 방식을 채택할 수 있어야 합니다

```
case arabic > 8:
    result.WriteString("IX")
    arabic -= 9
```

## 리팩토링

코드가 여전히 어딘가에 리팩토링이 있다고 말하는 것처럼 *느껴지지만* 저에게는 완전히 명백하지 않으므로 계속합시다.

이것도 코드를 건너뛰겠지만, `10`에 대한 테스트를 테스트 케이스에 추가하세요. 이것은 `X`여야 하고 읽기 전에 통과시키세요.

39까지 코드가 작동해야 한다고 확신하므로 몇 가지 테스트를 추가했습니다

```
{"10 gets converted to X", 10, "X"},
{"14 gets converted to XIV", 14, "XIV"},
{"18 gets converted to XVIII", 18, "XVIII"},
{"20 gets converted to XX", 20, "XX"},
{"39 gets converted to XXXIX", 39, "XXXIX"},
```

OO 프로그래밍을 해본 적이 있다면, `switch` 문을 약간 의심해야 한다는 것을 알 것입니다. 보통 클래스 구조에 캡처될 수 있을 때 명령형 코드 내에서 개념이나 데이터를 캡처하고 있습니다.

Go는 엄격히 OO가 아니지만 OO가 제공하는 교훈을 완전히 무시한다는 의미는 아닙니다 (일부가 당신에게 말하고 싶어하는 만큼).

switch 문은 동작과 함께 로마 숫자에 대한 일부 진실을 설명하고 있습니다.

데이터를 동작에서 분리하여 이것을 리팩토링할 수 있습니다.

```go
type RomanNumeral struct {
	Value  int
	Symbol string
}

var allRomanNumerals = []RomanNumeral{
	{10, "X"},
	{9, "IX"},
	{5, "V"},
	{4, "IV"},
	{1, "I"},
}

func ConvertToRoman(arabic int) string {

	var result strings.Builder

	for _, numeral := range allRomanNumerals {
		for arabic >= numeral.Value {
			result.WriteString(numeral.Symbol)
			arabic -= numeral.Value
		}
	}

	return result.String()
}
```

훨씬 좋아 보입니다. 알고리즘에 숨기는 대신 데이터로 숫자에 대한 규칙을 선언했고 아라비아 숫자를 통해 작업하면서 맞으면 결과에 기호를 추가하려고 하는 것을 볼 수 있습니다.

이 추상화가 더 큰 숫자에 작동하나요? 50인 `L`인 로마 숫자에 대해 작동하도록 테스트 스위트를 확장하세요.

여기에 몇 가지 테스트 케이스가 있습니다. 통과시키려고 해보세요.

```
{"40 gets converted to XL", 40, "XL"},
{"47 gets converted to XLVII", 47, "XLVII"},
{"49 gets converted to XLIX", 49, "XLIX"},
{"50 gets converted to L", 50, "L"},
```

도움이 필요하신가요? [이 gist](https://gist.github.com/pamelafox/6c7b948213ba55332d86efd0f0b037de)에서 추가할 기호를 볼 수 있습니다.

## 그리고 나머지!

나머지 기호는 다음과 같습니다

| 아라비아 | 로마 |
| ------ | :---: |
| 100    |   C   |
| 500    |   D   |
| 1000   |   M   |

나머지 기호에 대해 동일한 접근 방식을 취하세요. 테스트와 기호 배열 모두에 데이터를 추가하기만 하면 됩니다.

코드가 `1984`: `MCMLXXXIV`에 작동하나요?

여기 제 최종 테스트 스위트가 있습니다

```go
func TestRomanNumerals(t *testing.T) {
	cases := []struct {
		Arabic int
		Roman  string
	}{
		{Arabic: 1, Roman: "I"},
		{Arabic: 2, Roman: "II"},
		{Arabic: 3, Roman: "III"},
		{Arabic: 4, Roman: "IV"},
		{Arabic: 5, Roman: "V"},
		{Arabic: 6, Roman: "VI"},
		{Arabic: 7, Roman: "VII"},
		{Arabic: 8, Roman: "VIII"},
		{Arabic: 9, Roman: "IX"},
		{Arabic: 10, Roman: "X"},
		{Arabic: 14, Roman: "XIV"},
		{Arabic: 18, Roman: "XVIII"},
		{Arabic: 20, Roman: "XX"},
		{Arabic: 39, Roman: "XXXIX"},
		{Arabic: 40, Roman: "XL"},
		{Arabic: 47, Roman: "XLVII"},
		{Arabic: 49, Roman: "XLIX"},
		{Arabic: 50, Roman: "L"},
		{Arabic: 100, Roman: "C"},
		{Arabic: 90, Roman: "XC"},
		{Arabic: 400, Roman: "CD"},
		{Arabic: 500, Roman: "D"},
		{Arabic: 900, Roman: "CM"},
		{Arabic: 1000, Roman: "M"},
		{Arabic: 1984, Roman: "MCMLXXXIV"},
		{Arabic: 3999, Roman: "MMMCMXCIX"},
		{Arabic: 2014, Roman: "MMXIV"},
		{Arabic: 1006, Roman: "MVI"},
		{Arabic: 798, Roman: "DCCXCVIII"},
	}
	for _, test := range cases {
		t.Run(fmt.Sprintf("%d gets converted to %q", test.Arabic, test.Roman), func(t *testing.T) {
			got := ConvertToRoman(test.Arabic)
			if got != test.Roman {
				t.Errorf("got %q, want %q", got, test.Roman)
			}
		})
	}
}
```

- *데이터*가 충분한 정보를 설명한다고 느꼈기 때문에 `description`을 제거했습니다.
- 조금 더 확신을 주기 위해 몇 가지 다른 엣지 케이스를 추가했습니다. 테이블 기반 테스트로 이것은 매우 저렴하게 할 수 있습니다.

알고리즘을 변경하지 않았습니다. `allRomanNumerals` 배열만 업데이트하면 되었습니다.

```go
var allRomanNumerals = []RomanNumeral{
	{1000, "M"},
	{900, "CM"},
	{500, "D"},
	{400, "CD"},
	{100, "C"},
	{90, "XC"},
	{50, "L"},
	{40, "XL"},
	{10, "X"},
	{9, "IX"},
	{5, "V"},
	{4, "IV"},
	{1, "I"},
}
```

## 로마 숫자 파싱

아직 끝나지 않았습니다. 다음으로 로마 숫자*에서* `int`로 변환하는 함수를 작성할 것입니다

## 먼저 테스트 작성

약간의 리팩토링으로 여기서 테스트 케이스를 재사용할 수 있습니다

`var` 블록에서 `cases` 변수를 테스트 외부로 패키지 변수로 이동하세요.

```go
func TestConvertingToArabic(t *testing.T) {
	for _, test := range cases[:1] {
		t.Run(fmt.Sprintf("%q gets converted to %d", test.Roman, test.Arabic), func(t *testing.T) {
			got := ConvertToArabic(test.Roman)
			if got != test.Arabic {
				t.Errorf("got %d, want %d", got, test.Arabic)
			}
		})
	}
}
```

모든 테스트를 한 번에 통과시키려고 하면 너무 큰 도약이므로 지금은 하나의 테스트만 실행하기 위해 슬라이스 기능을 사용하고 있습니다 (`cases[:1]`)

## 테스트 실행 시도

```console
./numeral_test.go:60:11: undefined: ConvertToArabic
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

새 함수 정의를 추가하세요

```go
func ConvertToArabic(roman string) int {
	return 0
}
```

테스트가 이제 실행되고 실패해야 합니다

```console
--- FAIL: TestConvertingToArabic (0.00s)
    --- FAIL: TestConvertingToArabic/'I'*gets*converted*to*1 (0.00s)
        numeral_test.go:62: got 0, want 1
```

## 테스트를 통과시키기 위한 충분한 코드 작성

무엇을 해야 하는지 알고 있습니다

```go
func ConvertToArabic(roman string) int {
	return 1
}
```

다음으로 테스트에서 슬라이스 인덱스를 다음 테스트 케이스로 이동하세요 (예: `cases[:2]`). 생각할 수 있는 가장 바보 같은 코드로 직접 통과시키세요, 세 번째 케이스도 계속 바보 같은 코드를 작성하세요 (역대 최고의 책이죠?). 여기 제 바보 같은 코드가 있습니다.

```go
func ConvertToArabic(roman string) int {
	if roman == "III" {
		return 3
	}
	if roman == "II" {
		return 2
	}
	return 1
}
```

*작동하는 실제 코드*의 바보 같은 것을 통해 이전처럼 패턴을 보기 시작할 수 있습니다. 입력을 반복하고 *무언가*를 빌드해야 합니다. 이 경우 합계입니다.

```go
func ConvertToArabic(roman string) int {
	total := 0
	for range roman {
		total++
	}
	return total
}
```

## 먼저 테스트 작성

다음으로 `cases[:4]` (`IV`)로 이동하면 문자열 길이가 2이기 때문에 2를 반환하므로 실패합니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
// 이전..
var allRomanNumerals = RomanNumerals{
	{1000, "M"},
	{900, "CM"},
	{500, "D"},
	{400, "CD"},
	{100, "C"},
	{90, "XC"},
	{50, "L"},
	{40, "XL"},
	{10, "X"},
	{9, "IX"},
	{5, "V"},
	{4, "IV"},
	{1, "I"},
}

// 나중에..
func ConvertToArabic(roman string) int {
	var arabic = 0

	for _, numeral := range allRomanNumerals {
		for strings.HasPrefix(roman, numeral.Symbol) {
			arabic += numeral.Value
			roman = strings.TrimPrefix(roman, numeral.Symbol)
		}
	}

	return arabic
}
```

기본적으로 `ConvertToRoman(int)` 알고리즘을 역으로 구현한 것입니다. 여기서 주어진 로마 숫자 문자열을 반복합니다:
- `allRomanNumerals`에서 가져온 로마 숫자 기호를 문자열 시작 부분에서 가장 높은 것부터 가장 낮은 것까지 찾습니다.
- 접두사를 찾으면 `arabic`에 값을 추가하고 접두사를 제거합니다.

마지막으로 합계를 아라비아 숫자로 반환합니다.

`HasPrefix(s, prefix)`는 문자열 `s`가 `prefix`로 시작하는지 확인하고 `TrimPrefix(s, prefix)`는 `s`에서 `prefix`를 제거하므로 나머지 로마 숫자 기호로 진행할 수 있습니다. `IV` 및 모든 다른 테스트 케이스에서 작동합니다.

이것을 더 우아한 재귀 함수로 구현할 수 있지만 (제 생각에는) 더 느릴 수 있습니다. 이것은 당신과 일부 `Benchmark...` 테스트에 맡기겠습니다.

이제 아라비아 숫자를 로마 숫자로 변환하고 다시 변환하는 함수가 있으므로 테스트를 한 단계 더 나아갈 수 있습니다:

## 속성 기반 테스트 소개

이 챕터에서 작업한 로마 숫자의 도메인에 몇 가지 규칙이 있었습니다

- 연속으로 3개 이상의 기호를 가질 수 없습니다
- I (1), X (10) 및 C (100)만 "빼는 기호"가 될 수 있습니다
- `ConvertToRoman(N)`의 결과를 가져와서 `ConvertToArabic`에 전달하면 `N`을 반환해야 합니다

지금까지 작성한 테스트는 도구가 확인할 *예제*를 제공하는 "예제" 기반 테스트로 설명될 수 있습니다.

도메인에 대해 알고 있는 이러한 규칙을 어떻게든 코드에 대해 연습할 수 있다면 어떨까요?

속성 기반 테스트는 코드에 임의의 데이터를 던지고 설명하는 규칙이 항상 참임을 확인하여 이것을 할 수 있게 합니다. 많은 사람들이 속성 기반 테스트가 주로 임의의 데이터에 관한 것이라고 생각하지만 그들은 틀렸습니다. 속성 기반 테스트에 대한 진정한 도전은 이러한 속성을 작성할 수 있도록 도메인에 대한 *좋은* 이해를 갖는 것입니다.

말이 충분합니다. 코드를 봅시다

```go
func TestPropertiesOfConversion(t *testing.T) {
	assertion := func(arabic int) bool {
		roman := ConvertToRoman(arabic)
		fromRoman := ConvertToArabic(roman)
		return fromRoman == arabic
	}

	if err := quick.Check(assertion, nil); err != nil {
		t.Error("failed checks", err)
	}
}
```

### 속성의 근거

첫 번째 테스트는 숫자를 로마 숫자로 변환한 다음 다른 함수를 사용하여 숫자로 다시 변환할 때 원래 가지고 있던 것을 얻는지 확인합니다.

- 임의의 숫자 (예: `4`)가 주어집니다.
- 임의의 숫자로 `ConvertToRoman`을 호출합니다 (`4`이면 `IV`를 반환해야 함).
- 위의 결과를 가져와 `ConvertToArabic`에 전달합니다.
- 위의 것은 원래 입력 (`4`)을 제공해야 합니다.

이것은 어느 쪽에 버그가 있으면 깨져야 하기 때문에 확신을 구축하기 위한 좋은 테스트처럼 느껴집니다. 통과할 수 있는 유일한 방법은 같은 종류의 버그가 있는 것입니다; 불가능하지 않지만 가능성이 낮아 보입니다.

### 기술적 설명

 표준 라이브러리에서 [testing/quick](https://golang.org/pkg/testing/quick/) 패키지를 사용합니다

 아래에서 읽으면 `quick.Check`에 여러 임의 입력에 대해 실행할 함수를 제공합니다. 함수가 `false`를 반환하면 검사에 실패한 것으로 간주됩니다.

 위의 `assertion` 함수는 임의의 숫자를 받아 속성을 테스트하기 위해 함수를 실행합니다.

### 테스트 실행

 실행해 보세요; 컴퓨터가 잠시 멈출 수 있으므로 지루하면 종료하세요 :)

 무슨 일이 일어나고 있나요? assertion 코드에 다음을 추가해 보세요.

 ```go
assertion := func(arabic int) bool {
	if arabic < 0 || arabic > 3999 {
		log.Println(arabic)
		return true
	}
	roman := ConvertToRoman(arabic)
	fromRoman := ConvertToArabic(roman)
	return fromRoman == arabic
}
```

다음과 같은 것을 볼 수 있습니다:

```console
=== RUN   TestPropertiesOfConversion
2019/07/09 14:41:27 6849766357708982977
2019/07/09 14:41:27 -7028152357875163913
2019/07/09 14:41:27 -6752532134903680693
2019/07/09 14:41:27 4051793897228170080
2019/07/09 14:41:27 -1111868396280600429
2019/07/09 14:41:27 8851967058300421387
2019/07/09 14:41:27 562755830018219185
```

이 매우 간단한 속성을 실행하는 것만으로도 구현의 결함이 노출되었습니다. 입력으로 `int`를 사용했지만:
- 로마 숫자로 음수를 할 수 없습니다
- 최대 3개의 연속 기호 규칙으로 3999보다 큰 값을 나타낼 수 없습니다 ([뭐, 일종](https://www.quora.com/Which-is-the-maximum-number-in-Roman-numerals)) 그리고 `int`는 3999보다 훨씬 더 큰 최대값을 가집니다.

훌륭합니다! 도메인에 대해 더 깊이 생각하게 되었으며 이것은 속성 기반 테스트의 진정한 강점입니다.

분명히 `int`는 좋은 타입이 아닙니다. 조금 더 적절한 것을 시도하면 어떨까요?

### [`uint16`](https://golang.org/pkg/builtin/#uint16)

Go에는 *부호 없는 정수*에 대한 타입이 있습니다. 이것은 음수가 될 수 없으므로 코드에서 한 클래스의 버그를 즉시 배제합니다. 16을 추가하면 16비트 정수로 최대 `65535`를 저장할 수 있으며, 이것도 너무 크지만 필요한 것에 더 가깝습니다.

`int` 대신 `uint16`을 사용하도록 코드를 업데이트해 보세요. 조금 더 가시성을 주기 위해 테스트에서 `assertion`을 업데이트했습니다.

```go
assertion := func(arabic uint16) bool {
	if arabic > 3999 {
		return true
	}
	t.Log("testing", arabic)
	roman := ConvertToRoman(arabic)
	fromRoman := ConvertToArabic(roman)
	return fromRoman == arabic
}
```
테스팅 프레임워크의 `log` 메서드를 사용하여 입력을 로깅하고 있습니다. 추가 출력을 출력하려면 `-v` 플래그와 함께 `go test` 명령을 실행해야 합니다 (`go test -v`).

테스트를 실행하면 이제 실제로 실행되고 무엇이 테스트되는지 볼 수 있습니다. 여러 번 실행하여 코드가 다양한 값에 잘 작동하는지 확인할 수 있습니다! 이것은 코드가 원하는 대로 작동한다는 많은 확신을 줍니다.

`quick.Check`가 수행하는 기본 실행 횟수는 100이지만 설정으로 변경할 수 있습니다.

```go
if err := quick.Check(assertion, &quick.Config{
	MaxCount: 1000,
}); err != nil {
	t.Error("failed checks", err)
}
```

### 추가 작업

- 설명한 다른 속성을 확인하는 속성 테스트를 작성할 수 있나요?
- 누군가가 3999보다 큰 숫자로 코드를 호출하는 것이 불가능하게 만드는 방법을 생각할 수 있나요?
    - 오류를 반환할 수 있습니다
    - 또는 > 3999를 나타낼 수 없는 새 타입을 만들 수 있습니다
        - 무엇이 최선이라고 생각하시나요?

## 마무리

### 반복적인 개발로 더 많은 TDD 연습

1984를 MCMLXXXIV로 변환하는 코드를 작성하는 생각이 처음에 위협적으로 느껴졌나요? 저에게는 그랬고 저는 꽤 오래 소프트웨어를 작성해 왔습니다.

비결은 항상 그렇듯이 **간단한 것으로 시작**하고 **작은 단계**를 밟는 것입니다.

이 과정의 어느 시점에서도 큰 도약을 하거나, 거대한 리팩토링을 하거나, 엉망이 되지 않았습니다.

누군가가 냉소적으로 "이건 그냥 카타야"라고 말하는 것을 들을 수 있습니다. 그것에 대해 반박할 수 없지만, 저는 작업하는 모든 프로젝트에 대해 동일한 접근 방식을 취합니다. 첫 번째 단계에서 큰 분산 시스템을 배포하지 않고 팀이 배포할 수 있는 가장 간단한 것 (보통 "Hello world" 웹사이트)을 찾은 다음 여기서와 같이 관리 가능한 청크로 기능의 작은 비트를 반복합니다.

기술은 작업을 분할하는 *방법*을 아는 것이며, 이것은 연습과 함께 TDD로 도움을 받습니다.

### 속성 기반 테스트

- 표준 라이브러리에 내장되어 있습니다
- 도메인 규칙을 코드로 설명하는 방법을 생각할 수 있다면 더 많은 확신을 주는 훌륭한 도구입니다
- 도메인에 대해 깊이 생각하게 합니다
- 테스트 스위트에 좋은 보완이 될 수 있습니다

## 후기

이 책은 커뮤니티의 귀중한 피드백에 의존합니다.
[Dave](http://github.com/gypsydave5)는 실질적으로 모든
챕터에서 엄청난 도움이 됩니다. 하지만 그는 이 챕터에서 제가 '아라비아 숫자'를 사용한 것에 대해 진짜 불만을 터뜨렸으므로, 완전한 공개를 위해 그가 말한 것이 여기 있습니다.

> `int` 타입의 값이 왜 정확히 '아라비아 숫자'가 아닌지 설명하겠습니다. 이것이 제가 너무 정확한 것일 수 있으므로 f off하라고 하셔도 완전히 이해하겠습니다.
>
> *숫자(digit)*는 숫자의 표현에 사용되는 문자입니다 - 보통 10개를 가지고 있으므로 '손가락'을 뜻하는 라틴어에서 유래했습니다. 아라비아 (힌두-아라비아라고도 함) 숫자 체계에는 10개가 있습니다. 이러한 아라비아 숫자는:
>
> ```console
>   0 1 2 3 4 5 6 7 8 9
> ```
>
> *수사(numeral)*는 숫자 모음을 사용한 숫자의 표현입니다.
> 아라비아 수사는 10진법 위치 숫자 체계에서 아라비아 숫자로 표현된 숫자입니다. 각 숫자가 수사에서의 위치에 따라 다른 값을 가지므로 '위치'라고 말합니다. 따라서
>
> ```console
>   1337
> ```
>
> `1`은 4자리 수사의 첫 번째 숫자이므로 1000의 값을 가집니다.
>
> 로마 숫자는 감소된 숫자 (`I`, `V` 등...)를 주로 수사를 생성하기 위한 값으로 사용하여 빌드됩니다. 약간의 위치 관련 것이 있지만 대부분 `I`는 항상 '일'을 나타냅니다.
>
> 그래서 이것을 감안할 때, `int`는 '아라비아 숫자'인가요? 숫자의 아이디어는 표현과 전혀 관련이 없습니다 - 이 숫자의 올바른 표현이 무엇인지 물어보면 이것을 볼 수 있습니다:
>
> ```console
> 255
> 11111111
> two-hundred and fifty-five
> FF
> 377
> ```
>
> 네, 이것은 함정 질문입니다. 모두 맞습니다. 각각 10진, 2진, 영어, 16진 및 8진 숫자 체계에서 같은 숫자의 표현입니다.
>
> 수사로서의 숫자 표현은 숫자로서의 속성과 *독립적*입니다 - Go에서 정수 리터럴을 볼 때 이것을 볼 수 있습니다:
>
> ```go
> 	0xFF == 255 // true
> ```
>
> 그리고 형식 문자열로 정수를 출력하는 방법:
>
> ```go
> n := 255
> fmt.Printf("%b %c %d %o %q %x %X %U", n, n, n, n, n, n, n, n)
> // 11111111 ÿ 255 377 'ÿ' ff FF U+00FF
> ```
>
> 동일한 정수를 16진 및 아라비아 (10진) 수사로 쓸 수 있습니다.
>
> 따라서 함수 시그니처가 `ConvertToRoman(arabic int) string`처럼 보일 때
> 호출되는 방식에 대해 약간의 가정을 하고 있습니다. 왜냐하면
> 때때로 `arabic`은 10진 정수 리터럴로 작성될 것입니다
>
> ```go
> 	ConvertToRoman(255)
> ```
>
> 하지만 다음과 같이 작성될 수도 있습니다
>
> ```go
> 	ConvertToRoman(0xFF)
> ```
>
> 실제로 우리는 아라비아 수사에서 '변환'하는 것이 아니라, `int`를 로마 수사로 '출력' - 표현 - 하고 있습니다 - `int`는 수사가 아니라,
> 아라비아 숫자든 아니든; 그냥 숫자입니다. `ConvertToRoman` 함수는
> `int`를 `string`으로 바꾸는 점에서 `strconv.Itoa`와 더 비슷합니다.
>
> 하지만 카타의 다른 모든 버전은 이 구분에 신경 쓰지 않으므로
> :shrug:

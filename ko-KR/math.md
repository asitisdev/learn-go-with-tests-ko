# 수학

[**이 챕터의 모든 코드는 여기에서 확인할 수 있습니다**](https://github.com/quii/learn-go-with-tests/tree/main/math)

현대 컴퓨터가 엄청난 속도로 거대한 계산을 수행하는 능력에도 불구하고, 평범한 개발자는 업무를 수행하는 데 수학을 거의 사용하지 않습니다. 하지만 오늘은 아닙니다! 오늘 우리는 수학을 사용하여 *실제* 문제를 해결할 것입니다. 그리고 지루한 수학이 아닙니다 - 삼각법과 벡터 그리고 고등학교를 졸업하면 절대 사용할 일이 없다고 말했던 모든 것을 사용할 것입니다.

## 문제

시계의 SVG를 만들고 싶습니다. 디지털 시계가 아닙니다 - 아니요, 그것은 쉬울 것입니다 - 바늘이 있는 *아날로그* 시계입니다. 화려한 것을 찾고 있지 않습니다. 그저 `time` 패키지에서 `Time`을 받아 모든 바늘 - 시, 분, 초 - 이 올바른 방향을 가리키는 시계의 SVG를 내뱉는 멋진 함수입니다. 얼마나 어려울 수 있을까요?

먼저 우리가 가지고 놀 시계의 SVG가 필요합니다. SVG는 프로그래밍으로 조작하기 환상적인 이미지 형식입니다. XML로 설명된 일련의 도형으로 작성되기 때문입니다. 그래서 이 시계:

![an svg of a clock](.gitbook/assets/example_clock.svg)

는 다음과 같이 설명됩니다:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg"
     width="100%"
     height="100%"
     viewBox="0 0 300 300"
     version="2.0">

  <!-- bezel -->
  <circle cx="150" cy="150" r="100" style="fill:#fff;stroke:#000;stroke-width:5px;"/>

  <!-- hour hand -->
  <line x1="150" y1="150" x2="114.150000" y2="132.260000"
        style="fill:none;stroke:#000;stroke-width:7px;"/>

  <!-- minute hand -->
  <line x1="150" y1="150" x2="101.290000" y2="99.730000"
        style="fill:none;stroke:#000;stroke-width:7px;"/>

  <!-- second hand -->
  <line x1="150" y1="150" x2="77.190000" y2="202.900000"
        style="fill:none;stroke:#f00;stroke-width:3px;"/>
</svg>
```

이것은 세 개의 선이 있는 원입니다. 각 선은 원의 중심(x=150, y=150)에서 시작하여 어느 정도 떨어진 곳에서 끝납니다.

그래서 우리가 할 일은 위의 것을 어떻게든 재구성하되, 주어진 시간에 대해 적절한 방향을 가리키도록 선을 변경하는 것입니다.

## 인수 테스트

너무 깊이 들어가기 전에 인수 테스트에 대해 생각해 봅시다.

잠깐, 아직 인수 테스트가 무엇인지 모르시죠. 설명해 드리겠습니다.

질문해 보겠습니다: 이기는 것은 어떤 모습일까요? 작업을 마쳤다는 것을 어떻게 알 수 있을까요? TDD는 언제 끝났는지 알 수 있는 좋은 방법을 제공합니다: 테스트가 통과할 때. 때로는 멋집니다 - 사실 거의 항상 멋집니다 - 전체 사용 가능한 기능 작성을 완료했을 때 알려주는 테스트를 작성하는 것입니다. 특정 함수가 예상대로 작동하는지 알려주는 테스트만이 아니라, 달성하려는 전체 것 - '기능' - 이 완료되었음을 알려주는 테스트입니다.

이러한 테스트는 때때로 '인수 테스트'라고 불리고, 때때로 '기능 테스트'라고 불립니다. 아이디어는 달성하려는 것을 설명하는 정말 높은 수준의 테스트를 작성하는 것입니다 - 예를 들어 사용자가 웹사이트의 버튼을 클릭하면 잡은 포켓몬의 완전한 목록을 봅니다. 그 테스트를 작성한 후 인수 테스트를 통과할 작동하는 시스템을 향해 구축하는 더 많은 테스트 - 단위 테스트 - 를 작성할 수 있습니다. 그래서 우리 예제에서 이러한 테스트는 버튼이 있는 웹페이지 렌더링, 웹 서버의 라우트 핸들러 테스트, 데이터베이스 조회 수행 등에 관한 것일 수 있습니다. 이 모든 것은 TDD되고, 모두 원래 인수 테스트 통과를 향해 갈 것입니다.

Nat Pryce와 Steve Freeman의 이 *고전적인* 그림과 같은 것입니다

![Outside-in feedback loops in TDD](.gitbook/assets/TDD-outside-in.jpg)

어쨌든 그 인수 테스트를 작성해 봅시다 - 언제 끝났는지 알려줄 것입니다.

예제 시계가 있으므로 중요한 매개변수가 무엇인지 생각해 봅시다.

```
<line x1="150" y1="150" x2="114.150000" y2="132.260000"
        style="fill:none;stroke:#000;stroke-width:7px;"/>
```

시계의 중심(이 선에 대한 `x1` 및 `y1` 속성)은 시계의 각 바늘에 대해 동일합니다. 시계의 각 바늘에 대해 변경해야 하는 숫자 - SVG를 빌드하는 것에 대한 매개변수 - 는 `x2` 및 `y2` 속성입니다. 시계의 각 바늘에 대해 X와 Y가 필요합니다.

더 많은 매개변수에 대해 생각할 *수 있습니다* - 시계 원의 반경, SVG의 크기, 바늘의 색상, 모양 등... 하지만 간단하고 구체적인 해결책으로 간단하고 구체적인 문제를 해결하는 것부터 시작한 다음 매개변수를 추가하여 일반화하는 것이 더 좋습니다.

그래서 다음과 같이 말할 것입니다

* 모든 시계의 중심은 (150, 150)입니다
* 시침은 50 길이입니다
* 분침은 80 길이입니다
* 초침은 90 길이입니다.

SVG에 대해 참고할 사항: 원점 - 점 (0,0) - 은 예상할 수 있는 *왼쪽 하단*이 아니라 *왼쪽 상단* 모서리에 있습니다. 선에 어떤 숫자를 넣어야 할지 계산할 때 이것을 기억하는 것이 중요합니다.

마지막으로, SVG를 *어떻게* 구성할지 결정하지 않습니다 - [`text/template`](https://golang.org/pkg/text/template/) 패키지에서 템플릿을 사용하거나 `bytes.Buffer` 또는 writer에 바이트를 보낼 수 있습니다. 하지만 그 숫자가 필요하다는 것을 알고 있으므로 그것들을 생성하는 것을 테스트하는 데 집중합시다.

### 먼저 테스트 작성

그래서 첫 번째 테스트는 다음과 같습니다:

```go
package clockface_test

import (
	"projectpath/clockface"
	"testing"
	"time"
)

func TestSecondHandAtMidnight(t *testing.T) {
	tm := time.Date(1337, time.January, 1, 0, 0, 0, 0, time.UTC)

	want := clockface.Point{X: 150, Y: 150 - 90}
	got := clockface.SecondHand(tm)

	if got != want {
		t.Errorf("Got %v, wanted %v", got, want)
	}
}
```

SVG가 왼쪽 상단 모서리에서 좌표를 그리는 방법을 기억하세요? 자정에 초침을 배치하려면 X 축에서 시계 중심에서 이동하지 않았을 것으로 예상합니다 - 여전히 150 - 그리고 Y 축은 중심에서 '위로' 바늘의 길이입니다; 150 빼기 90.

### 테스트 실행 시도

이것은 누락된 함수와 타입에 대한 예상 실패를 유도합니다:

```
--- FAIL: TestSecondHandAtMidnight (0.00s)
./clockface_test.go:13:10: undefined: clockface.Point
./clockface_test.go:14:9: undefined: clockface.SecondHand
```

초침 끝이 있어야 할 `Point`와 그것을 얻는 함수입니다.

### 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

코드를 컴파일하기 위해 해당 타입을 구현합시다

```go
package clockface

import "time"

// A Point represents a two-dimensional Cartesian coordinate
type Point struct {
	X float64
	Y float64
}

// SecondHand is the unit vector of the second hand of an analogue clock at time `t`
// represented as a Point.
func SecondHand(t time.Time) Point {
	return Point{}
}
```

이제 다음을 얻습니다:

```
--- FAIL: TestSecondHandAtMidnight (0.00s)
    clockface_test.go:17: Got {0 0}, wanted {150 60}
FAIL
exit status 1
FAIL	learn-go-with-tests/math/clockface	0.006s
```

### 테스트를 통과시키기 위한 충분한 코드 작성

예상 실패를 얻으면 `SecondHand`의 반환 값을 채울 수 있습니다:

```go
// SecondHand is the unit vector of the second hand of an analogue clock at time `t`
// represented as a Point.
func SecondHand(t time.Time) Point {
	return Point{150, 60}
}
```

보세요, 통과하는 테스트입니다.

```
PASS
ok  	    clockface	0.006s
```

### 리팩토링

아직 리팩토링할 필요가 없습니다 - 코드가 거의 없습니다!

### 새 요구 사항에 대해 반복

아마 모든 시간에 대해 자정을 보여주는 시계를 반환하는 것만 포함하지 않는 어떤 작업을 해야 할 것입니다...

### 먼저 테스트 작성

```go
func TestSecondHandAt30Seconds(t *testing.T) {
	tm := time.Date(1337, time.January, 1, 0, 0, 30, 0, time.UTC)

	want := clockface.Point{X: 150, Y: 150 + 90}
	got := clockface.SecondHand(tm)

	if got != want {
		t.Errorf("Got %v, wanted %v", got, want)
	}
}
```

같은 아이디어지만 이제 초침이 *아래쪽*을 가리키므로 Y 축에 길이를 *더합니다*.

이것은 컴파일됩니다... 하지만 어떻게 통과시킬까요?

## 생각 시간

이 문제를 어떻게 해결할까요?

매 분마다 초침은 60가지 상태를 거쳐 60가지 다른 방향을 가리킵니다. 0초일 때 시계 상단을 가리키고, 30초일 때 시계 하단을 가리킵니다. 충분히 쉽습니다.

그래서 37초에 초침이 어떤 방향을 가리키는지 생각하고 싶다면, 12시와 원 주위 37/60 사이의 각도를 원할 것입니다. 도 단위로 이것은 `(360 / 60) * 37 = 222`이지만, 완전한 회전의 `37/60`임을 기억하는 것이 더 쉽습니다.

하지만 각도는 이야기의 절반에 불과합니다; 초침 끝이 가리키는 X 및 Y 좌표를 알아야 합니다. 어떻게 알아낼 수 있을까요?

## 수학

원점 - 좌표 `0, 0` - 주위에 그려진 반경 1의 원을 상상해 보세요.

![picture of the unit circle](.gitbook/assets/unit_circle.png)

이것은 '단위원'이라고 불립니다. 왜냐하면... 음, 반경이 1 단위이기 때문입니다!

원의 둘레는 그리드의 점 - 더 많은 좌표 - 으로 구성됩니다. 이러한 각 좌표의 x 및 y 구성요소는 삼각형을 형성하며, 빗변은 항상 1입니다 (즉, 원의 반경).

![picture of the unit circle with a point defined on the circumference](.gitbook/assets/unit_circle_coords.png)

이제 삼각법을 사용하면 원점과 이루는 각도를 알면 각 삼각형에 대해 X와 Y의 길이를 계산할 수 있습니다. X 좌표는 cos(a)이고 Y 좌표는 sin(a)입니다. 여기서 a는 선과 (양의) x 축 사이에 형성된 각도입니다.

![picture of the unit circle with the x and y elements of a ray defined as cos(a) and sin(a) respectively, where a is the angle made by the ray with the x axis](<.gitbook/assets/unit_circle_params (1).png>)

(이것을 믿지 않는다면, [위키피디아를 보세요...](https://en.wikipedia.org/wiki/Sine#Unit_circle_definition))

마지막 꼬임 하나 - X 축(3시)이 아닌 12시부터 각도를 측정하고 싶기 때문에 축을 바꿔야 합니다; 이제 x = sin(a)이고 y = cos(a)입니다.

![unit circle ray defined from by angle from y axis](.gitbook/assets/unit_circle_12_oclock.png)

이제 초침의 각도(각 초에 대해 원의 1/60)와 X 및 Y 좌표를 얻는 방법을 알았습니다. `sin`과 `cos` 모두에 대한 함수가 필요합니다.

## `math`

다행히 Go `math` 패키지에는 둘 다 있으며, 우리가 이해해야 할 작은 문제가 하나 있습니다; [`math.Cos`](https://golang.org/pkg/math/#Cos)의 설명을 보면:

> Cos는 라디안 인수 x의 코사인을 반환합니다.

각도가 라디안이기를 원합니다. 그래서 라디안이 무엇일까요? 원의 전체 회전이 360도로 구성되는 것으로 정의하는 대신 전체 회전을 2π 라디안으로 정의합니다. 이렇게 하는 좋은 이유가 있지만 자세히 다루지 않겠습니다.

이제 읽기, 학습, 생각을 마쳤으므로 다음 테스트를 작성할 수 있습니다.

### 먼저 테스트 작성

이 모든 수학은 어렵고 혼란스럽습니다. 무슨 일이 일어나는지 이해한다고 확신하지 못합니다 - 그러니 테스트를 작성합시다! 한 번에 전체 문제를 해결할 필요는 없습니다 - 특정 시간에 초침에 대한 올바른 각도를 라디안으로 계산하는 것부터 시작합시다.

이 테스트를 작업하는 동안 작업 중이던 인수 테스트를 *주석 처리*하겠습니다 - 이것을 통과시키면서 그 테스트에 의해 산만해지고 싶지 않습니다.

### 패키지에 대한 요약

현재 인수 테스트는 `clockface_test` 패키지에 있습니다. 테스트는 `clockface` 패키지 외부에 있을 수 있습니다 - 이름이 `_test.go`로 끝나기만 하면 실행할 수 있습니다.

이 라디안 테스트를 `clockface` 패키지 *내에서* 작성하겠습니다; 내보내지 않을 수 있고, 무슨 일이 일어나는지 더 잘 이해하면 삭제(또는 이동)될 수 있습니다. 인수 테스트 파일의 이름을 `clockface_acceptance_test.go`로 변경하여 초를 라디안으로 테스트할 `clockface_test`라는 *새* 파일을 만들 수 있습니다.

```go
package clockface

import (
	"math"
	"testing"
	"time"
)

func TestSecondsInRadians(t *testing.T) {
	thirtySeconds := time.Date(312, time.October, 28, 0, 0, 30, 0, time.UTC)
	want := math.Pi
	got := secondsInRadians(thirtySeconds)

	if want != got {
		t.Fatalf("Wanted %v radians, but got %v", want, got)
	}
}
```

여기서 분의 30초가 시계 주위에서 초침을 절반 지점에 놓아야 한다고 테스트하고 있습니다. 그리고 `math` 패키지의 첫 번째 사용입니다! 원의 전체 회전이 2π 라디안이면 절반은 π 라디안이어야 합니다. `math.Pi`는 π에 대한 값을 제공합니다.

### 테스트 실행 시도

```
./clockface_test.go:12:9: undefined: secondsInRadians
```

### 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func secondsInRadians(t time.Time) float64 {
	return 0
}
```

```
clockface_test.go:15: Wanted 3.141592653589793 radians, but got 0
```

### 테스트를 통과시키기 위한 충분한 코드 작성

```go
func secondsInRadians(t time.Time) float64 {
	return math.Pi
}
```

```
PASS
ok  	clockface	0.011s
```

### 리팩토링

아직 리팩토링할 것이 없습니다

### 새 요구 사항에 대해 반복

이제 몇 가지 더 많은 시나리오를 다루도록 테스트를 확장할 수 있습니다. 약간 앞으로 건너뛰고 이미 리팩토링된 테스트 코드를 보여 드리겠습니다 - 어떻게 원하는 곳에 도달했는지 충분히 명확해야 합니다.

```go
func TestSecondsInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(0, 0, 30), math.Pi},
		{simpleTime(0, 0, 0), 0},
		{simpleTime(0, 0, 45), (math.Pi / 2) * 3},
		{simpleTime(0, 0, 7), (math.Pi / 30) * 7},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := secondsInRadians(c.time)
			if got != c.angle {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

이 테이블 기반 테스트를 작성하는 것을 조금 덜 지루하게 만들기 위해 몇 가지 헬퍼 함수를 추가했습니다. `testName`은 시간을 디지털 시계 형식 (HH:MM:SS)으로 변환하고, `simpleTime`은 실제로 관심 있는 부분 (다시, 시, 분, 초)만 사용하여 `time.Time`을 구성합니다. 다음과 같습니다:

```go
func simpleTime(hours, minutes, seconds int) time.Time {
	return time.Date(312, time.October, 28, hours, minutes, seconds, 0, time.UTC)
}

func testName(t time.Time) string {
	return t.Format("15:04:05")
}
```

이 두 함수는 이러한 테스트(및 향후 테스트)를 작성하고 유지 관리하기 조금 더 쉽게 만드는 데 도움이 됩니다.

이것은 좋은 테스트 출력을 제공합니다:

```
clockface_test.go:24: Wanted 0 radians, but got 3.141592653589793

clockface_test.go:24: Wanted 4.71238898038469 radians, but got 3.141592653589793
```

위에서 이야기한 모든 수학을 구현할 시간입니다:

```go
func secondsInRadians(t time.Time) float64 {
	return float64(t.Second()) * (math.Pi / 30)
}
```

1초는 (2π / 60) 라디안입니다... 2를 취소하면 π/30 라디안을 얻습니다. 그것에 초 수를 (`float64`로) 곱하면 이제 모든 테스트가 통과해야 합니다...

```
clockface_test.go:24: Wanted 3.141592653589793 radians, but got 3.1415926535897936
```

잠깐, 뭐라고요?

### 부동 소수점은 끔찍합니다

부동 소수점 연산은 [악명 높게 부정확합니다](https://0.30000000000000004.com/). 컴퓨터는 정수와 어느 정도까지 유리수만 실제로 처리할 수 있습니다. 십진수는 `secondsInRadians` 함수에서와 같이 위아래로 인수분해할 때 특히 부정확해지기 시작합니다. `math.Pi`를 30으로 나눈 다음 30으로 곱하면 *더 이상 `math.Pi`와 같지 않은 숫자*가 됩니다.

이것을 해결하는 두 가지 방법이 있습니다:

1. 그냥 받아들입니다
2. 방정식을 리팩토링하여 함수를 리팩토링합니다

이제 (1)은 그다지 매력적으로 보이지 않을 수 있지만, 종종 부동 소수점 동등성을 작동하게 만드는 유일한 방법입니다. 아주 작은 소수점만큼 부정확한 것은 시계를 그리는 목적으로는 솔직히 문제가 되지 않으므로, 각도에 대해 '충분히 가까운' 동등성을 정의하는 함수를 작성할 수 있습니다. 그러나 정확도를 다시 얻을 수 있는 간단한 방법이 있습니다: 더 이상 나누고 곱하지 않도록 방정식을 재배열합니다. 나누기만으로 모든 것을 할 수 있습니다.

따라서

```
numberOfSeconds * π / 30
```

대신

```
π / (30 / numberOfSeconds)
```

이것은 동등합니다.

Go에서:

```go
func secondsInRadians(t time.Time) float64 {
	return (math.Pi / (30 / (float64(t.Second()))))
}
```

그리고 통과합니다.

```
PASS
ok      clockface     0.005s
```

모든 것이 [이와 같이 보여야 합니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v3/clockface).

### 0으로 나누기에 대한 참고

컴퓨터는 종종 0으로 나누는 것을 싫어합니다. 무한대가 조금 이상하기 때문입니다.

Go에서 명시적으로 0으로 나누려고 하면 컴파일 오류가 발생합니다.

```go
package main

import (
	"fmt"
)

func main() {
	fmt.Println(10.0 / 0.0) // 컴파일 실패
}
```

물론 컴파일러가 `t.Second()`와 같이 0으로 나눌 것인지 항상 예측할 수는 없습니다

이것을 시도해 보세요

```go
func main() {
	fmt.Println(10.0 / zero())
}

func zero() float64 {
	return 0.0
}
```

`+Inf` (무한대)를 출력합니다. +Inf로 나누면 0이 되는 것 같고 다음으로 확인할 수 있습니다:

```go
package main

import (
	"fmt"
	"math"
)

func main() {
	fmt.Println(secondsinradians())
}

func zero() float64 {
	return 0.0
}

func secondsinradians() float64 {
	return (math.Pi / (30 / (float64(zero()))))
}
```

### 새 요구 사항에 대해 반복

첫 번째 부분을 다루었습니다 - 초침이 라디안에서 어떤 각도를 가리킬지 알고 있습니다. 이제 좌표를 계산해야 합니다.

다시, 가능한 한 간단하게 유지하고 *단위원*으로만 작업합시다; 반경이 1인 원입니다. 이것은 바늘이 모두 길이가 1이 되지만, 밝은 면에서 수학이 우리가 소화하기 쉬울 것을 의미합니다.

### 먼저 테스트 작성

```go
func TestSecondHandPoint(t *testing.T) {
	cases := []struct {
		time  time.Time
		point Point
	}{
		{simpleTime(0, 0, 30), Point{0, -1}},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := secondHandPoint(c.time)
			if got != c.point {
				t.Fatalf("Wanted %v Point, but got %v", c.point, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
./clockface_test.go:40:11: undefined: secondHandPoint
```

### 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func secondHandPoint(t time.Time) Point {
	return Point{}
}
```

```
clockface_test.go:42: Wanted {0 -1} Point, but got {0 0}
```

### 테스트를 통과시키기 위한 충분한 코드 작성

```go
func secondHandPoint(t time.Time) Point {
	return Point{0, -1}
}
```

```
PASS
ok  	clockface	0.007s
```

### 새 요구 사항에 대해 반복

```go
func TestSecondHandPoint(t *testing.T) {
	cases := []struct {
		time  time.Time
		point Point
	}{
		{simpleTime(0, 0, 30), Point{0, -1}},
		{simpleTime(0, 0, 45), Point{-1, 0}},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := secondHandPoint(c.time)
			if got != c.point {
				t.Fatalf("Wanted %v Point, but got %v", c.point, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
clockface_test.go:43: Wanted {-1 0} Point, but got {0 -1}
```

### 테스트를 통과시키기 위한 충분한 코드 작성

단위원 그림을 기억하세요?

![picture of the unit circle with the x and y elements of a ray defined as cos(a) and sin(a) respectively, where a is the angle made by the ray with the x axis](.gitbook/assets/unit_circle_params (1).png)

또한 초침과 3시 사이의 각도를 측정하는 것보다 X 축이 아닌 Y 축인 12시부터 각도를 측정하고 싶다는 것을 기억하세요.

![unit circle ray defined from by angle from y axis](.gitbook/assets/unit_circle_12_oclock.png)

이제 X와 Y를 생성하는 방정식을 원합니다. 초에 작성해 봅시다:

```go
func secondHandPoint(t time.Time) Point {
	angle := secondsInRadians(t)
	x := math.Sin(angle)
	y := math.Cos(angle)

	return Point{x, y}
}
```

이제 다음을 얻습니다

```
clockface_test.go:43: Wanted {0 -1} Point, but got {1.2246467991473515e-16 -1}

clockface_test.go:43: Wanted {-1 0} Point, but got {-1 -1.8369701987210272e-16}
```

잠깐, 뭐라고요 (다시)? 부동 소수점에 다시 저주를 받은 것 같습니다 - 그 예상치 못한 숫자는 모두 *무한소*입니다 - 16번째 소수점에 있습니다. 그래서 다시 정밀도를 높이거나 대략적으로 동등하다고 말하고 삶을 계속할 수 있습니다.

이러한 각도의 정확성을 높이는 한 가지 옵션은 `math/big` 패키지의 유리수 타입 `Rat`을 사용하는 것입니다. 그러나 목표가 달에 착륙하는 것이 아니라 SVG를 그리는 것이므로 약간의 퍼지하게 살 수 있다고 생각합니다.

```go
func TestSecondHandPoint(t *testing.T) {
	cases := []struct {
		time  time.Time
		point Point
	}{
		{simpleTime(0, 0, 30), Point{0, -1}},
		{simpleTime(0, 0, 45), Point{-1, 0}},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := secondHandPoint(c.time)
			if !roughlyEqualPoint(got, c.point) {
				t.Fatalf("Wanted %v Point, but got %v", c.point, got)
			}
		})
	}
}

func roughlyEqualFloat64(a, b float64) bool {
	const equalityThreshold = 1e-7
	return math.Abs(a-b) < equalityThreshold
}

func roughlyEqualPoint(a, b Point) bool {
	return roughlyEqualFloat64(a.X, b.X) &&
		roughlyEqualFloat64(a.Y, b.Y)
}
```

두 `Point` 사이의 대략적인 동등성을 정의하는 두 함수를 정의했습니다 - X와 Y 요소가 서로 0.0000001 이내이면 작동합니다. 그것은 여전히 꽤 정확합니다.

이제 다음을 얻습니다:

```
PASS
ok  	clockface	0.007s
```

### 리팩토링

아직 꽤 만족합니다.

[지금 어떻게 보이는지 여기 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v4/clockface)

### 새 요구 사항에 대해 반복

음, *새로운* 것은 완전히 정확하지 않습니다 - 실제로 지금 할 수 있는 것은 그 인수 테스트를 통과시키는 것입니다! 어떻게 생겼는지 상기시켜 드리겠습니다:

```go
func TestSecondHandAt30Seconds(t *testing.T) {
	tm := time.Date(1337, time.January, 1, 0, 0, 30, 0, time.UTC)

	want := clockface.Point{X: 150, Y: 150 + 90}
	got := clockface.SecondHand(tm)

	if got != want {
		t.Errorf("Got %v, wanted %v", got, want)
	}
}
```

### 테스트 실행 시도

```
clockface_acceptance_test.go:28: Got {150 60}, wanted {150 240}
```

### 테스트를 통과시키기 위한 충분한 코드 작성

단위 벡터를 SVG의 점으로 변환하기 위해 세 가지를 해야 합니다:

1. 바늘 길이로 크기 조정
2. SVG가 왼쪽 상단 모서리에 원점이 있음을 고려하여 X 축에서 뒤집기
3. 올바른 위치로 변환 ((150,150) 원점에서 오도록)

재미있는 시간입니다!

```go
// SecondHand is the unit vector of the second hand of an analogue clock at time `t`
// represented as a Point.
func SecondHand(t time.Time) Point {
	p := secondHandPoint(t)
	p = Point{p.X * 90, p.Y * 90}   // 크기 조정
	p = Point{p.X, -p.Y}            // 뒤집기
	p = Point{p.X + 150, p.Y + 150} // 변환
	return p
}
```

정확히 그 순서로 크기 조정, 뒤집기, 변환합니다. 만세 수학!

```
PASS
ok  	clockface	0.007s
```

### 리팩토링

상수로 추출해야 하는 몇 가지 매직 넘버가 있으므로 그렇게 합시다

```go
const secondHandLength = 90
const clockCentreX = 150
const clockCentreY = 150

// SecondHand is the unit vector of the second hand of an analogue clock at time `t`
// represented as a Point.
func SecondHand(t time.Time) Point {
	p := secondHandPoint(t)
	p = Point{p.X * secondHandLength, p.Y * secondHandLength}
	p = Point{p.X, -p.Y}
	p = Point{p.X + clockCentreX, p.Y + clockCentreY} // 변환
	return p
}
```

## 시계 그리기

음... 초침만...

이것을 합시다 - 세상에 나가서 사람들을 눈부시게 할 준비가 된 가치를 전달하지 않는 것보다 더 나쁜 것은 없습니다. 초침을 그리자!

메인 `clockface` 패키지 디렉토리 아래에 (혼란스럽게도) `clockface`라는 새 디렉토리를 넣을 것입니다. 거기에 SVG를 빌드할 바이너리를 만들 `main` 패키지를 넣을 것입니다:

```
|-- clockface
|       |-- main.go
|-- clockface.go
|-- clockface_acceptance_test.go
|-- clockface_test.go
```

`main.go` 안에서 이 코드로 시작하지만 clockface 패키지에 대한 import를 자신의 버전을 가리키도록 변경합니다:

```go
package main

import (
	"fmt"
	"io"
	"os"
	"time"

	"learn-go-with-tests/math/clockface" // 이것을 바꾸세요!
)

func main() {
	t := time.Now()
	sh := clockface.SecondHand(t)
	io.WriteString(os.Stdout, svgStart)
	io.WriteString(os.Stdout, bezel)
	io.WriteString(os.Stdout, secondHandTag(sh))
	io.WriteString(os.Stdout, svgEnd)
}

func secondHandTag(p clockface.Point) string {
	return fmt.Sprintf(`<line x1="150" y1="150" x2="%f" y2="%f" style="fill:none;stroke:#f00;stroke-width:3px;"/>`, p.X, p.Y)
}

const svgStart = `<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg"
     width="100%"
     height="100%"
     viewBox="0 0 300 300"
     version="2.0">`

const bezel = `<circle cx="150" cy="150" r="100" style="fill:#fff;stroke:#000;stroke-width:5px;"/>`

const svgEnd = `</svg>`
```

이 *엉망진창*으로 아름다운 코드 상을 받으려고 하지는 않지만 - 작업을 수행합니다. `os.Stdout`에 SVG를 작성합니다 - 한 번에 하나의 문자열씩.

이것을 빌드하면

```
go build
```

실행하고 출력을 파일로 보내면

```
./clockface > clock.svg
```

다음과 같이 보여야 합니다

![a clock with only a second hand](.gitbook/assets/clock.svg)

[코드가 어떻게 보이는지 여기 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v6/clockface).

### 리팩토링

이것은 냄새납니다. 음, 정확히 *냄새* 냄새는 아니지만, 만족스럽지 않습니다.

1. 그 전체 `SecondHand` 함수가 *매우* SVG에 종속되어 있습니다... SVG를 언급하거나 실제로 SVG를 생성하지 않고...
2. ... 동시에 SVG 코드를 테스트하지 않습니다.

네, 망쳤나 봅니다. 이것은 잘못된 느낌입니다. 더 SVG 중심적인 테스트로 복구해 봅시다.

옵션은 무엇일까요? 음, `SVGWriter`가 내뱉는 문자들이 특정 시간에 대해 기대하는 SVG 태그처럼 보이는 것을 포함하는지 테스트할 수 있습니다. 예를 들어:

```go
func TestSVGWriterAtMidnight(t *testing.T) {
	tm := time.Date(1337, time.January, 1, 0, 0, 0, 0, time.UTC)

	var b strings.Builder
	clockface.SVGWriter(&b, tm)
	got := b.String()

	want := `<line x1="150" y1="150" x2="150" y2="60"`

	if !strings.Contains(got, want) {
		t.Errorf("Expected to find the second hand %v, in the SVG output %v", want, got)
	}
}
```

하지만 이것이 정말 개선일까요?

유효한 SVG를 생성하지 않아도 여전히 통과할 것이고 (출력에 문자열이 나타나는지만 테스트하므로), 그 문자열을 가장 작고 중요하지 않은 변경을 해도 실패할 것입니다 - 예를 들어 속성 사이에 여분의 공백을 추가하면.

*가장 큰* 냄새는 데이터 구조 - XML - 를 문자 시리즈로 표현하여 테스트하고 있다는 것입니다 - 문자열로. 이것은 *절대*, *절대* 좋은 아이디어가 아닙니다. 위에서 설명한 것과 같은 문제를 만들기 때문입니다: 너무 취약하고 충분히 민감하지 않은 테스트. 잘못된 것을 테스트하는 테스트!

그래서 유일한 해결책은 출력을 *XML로* 테스트하는 것입니다. 그리고 그렇게 하려면 파싱해야 합니다.

## XML 파싱

[`encoding/xml`](https://pkg.go.dev/encoding/xml)은 간단한 XML 파싱과 관련된 모든 것을 처리할 수 있는 Go 패키지입니다.

[`xml.Unmarshal`](https://pkg.go.dev/encoding/xml#Unmarshal) 함수는 XML 데이터의 `[]byte`와 언마샬할 구조체에 대한 포인터를 받습니다.

그래서 XML을 언마샬할 구조체가 필요합니다. 시간을 들여 모든 노드와 속성에 대한 올바른 이름과 올바른 구조를 작성하는 방법을 알아낼 수 있지만, 다행히도 누군가가 [`zek`](https://github.com/miku/zek)라는 모든 힘든 작업을 자동화해 주는 프로그램을 작성했습니다. 더 좋은 것은 [https://xml-to-go.github.io/](https://xml-to-go.github.io/)에 온라인 버전이 있습니다. 파일 상단의 SVG를 하나의 상자에 붙여 넣으면 - 짜잔 - 다음이 나옵니다:

```go
type Svg struct {
	XMLName xml.Name `xml:"svg"`
	Text    string   `xml:",chardata"`
	Xmlns   string   `xml:"xmlns,attr"`
	Width   string   `xml:"width,attr"`
	Height  string   `xml:"height,attr"`
	ViewBox string   `xml:"viewBox,attr"`
	Version string   `xml:"version,attr"`
	Circle  struct {
		Text  string `xml:",chardata"`
		Cx    string `xml:"cx,attr"`
		Cy    string `xml:"cy,attr"`
		R     string `xml:"r,attr"`
		Style string `xml:"style,attr"`
	} `xml:"circle"`
	Line []struct {
		Text  string `xml:",chardata"`
		X1    string `xml:"x1,attr"`
		Y1    string `xml:"y1,attr"`
		X2    string `xml:"x2,attr"`
		Y2    string `xml:"y2,attr"`
		Style string `xml:"style,attr"`
	} `xml:"line"`
}
```

필요하다면 이것을 조정할 수 있지만 (구조체 이름을 `SVG`로 변경하는 것처럼) 시작하기에 충분히 좋습니다. 구조체를 `clockface_acceptance_test` 파일에 붙여 넣고 테스트를 작성합시다:

```go
func TestSVGWriterAtMidnight(t *testing.T) {
	tm := time.Date(1337, time.January, 1, 0, 0, 0, 0, time.UTC)

	b := bytes.Buffer{}
	clockface.SVGWriter(&b, tm)

	svg := Svg{}
	xml.Unmarshal(b.Bytes(), &svg)

	x2 := "150"
	y2 := "60"

	for _, line := range svg.Line {
		if line.X2 == x2 && line.Y2 == y2 {
			return
		}
	}

	t.Errorf("Expected to find the second hand with x2 of %+v and y2 of %+v, in the SVG output %v", x2, y2, b.String())
}
```

`clockface.SVGWriter`의 출력을 `bytes.Buffer`에 쓴 다음 `Svg`로 `Unmarshal`합니다. 그런 다음 `Svg`의 각 `Line`을 확인하여 예상된 `X2` 및 `Y2` 값을 가진 것이 있는지 확인합니다. 일치하면 일찍 반환합니다 (테스트 통과); 그렇지 않으면 (희망적으로) 유익한 메시지와 함께 실패합니다.

```sh
./clockface_acceptance_test.go:41:2: undefined: clockface.SVGWriter
```

`SVGWriter.go`를 만들어야 할 것 같습니다...

```go
package clockface

import (
	"fmt"
	"io"
	"time"
)

const (
	secondHandLength = 90
	clockCentreX     = 150
	clockCentreY     = 150
)

// SVGWriter writes an SVG representation of an analogue clock, showing the time t, to the writer w
func SVGWriter(w io.Writer, t time.Time) {
	io.WriteString(w, svgStart)
	io.WriteString(w, bezel)
	secondHand(w, t)
	io.WriteString(w, svgEnd)
}

func secondHand(w io.Writer, t time.Time) {
	p := secondHandPoint(t)
	p = Point{p.X * secondHandLength, p.Y * secondHandLength} // 크기 조정
	p = Point{p.X, -p.Y}                                      // 뒤집기
	p = Point{p.X + clockCentreX, p.Y + clockCentreY}         // 변환
	fmt.Fprintf(w, `<line x1="150" y1="150" x2="%f" y2="%f" style="fill:none;stroke:#f00;stroke-width:3px;"/>`, p.X, p.Y)
}

const svgStart = `<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg"
     width="100%"
     height="100%"
     viewBox="0 0 300 300"
     version="2.0">`

const bezel = `<circle cx="150" cy="150" r="100" style="fill:#fff;stroke:#000;stroke-width:5px;"/>`

const svgEnd = `</svg>`
```

가장 아름다운 SVG writer? 아니오. 하지만 작업을 수행할 것입니다...

```
clockface_acceptance_test.go:56: Expected to find the second hand with x2 of 150 and y2 of 60, in the SVG output <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
    <svg xmlns="http://www.w3.org/2000/svg"
         width="100%"
         height="100%"
         viewBox="0 0 300 300"
         version="2.0"><circle cx="150" cy="150" r="100" style="fill:#fff;stroke:#000;stroke-width:5px;"/><line x1="150" y1="150" x2="150.000000" y2="60.000000" style="fill:none;stroke:#f00;stroke-width:3px;"/></svg>
```

이런! `%f` 형식 지시어가 좌표를 기본 정밀도 수준 - 6자리 소수점 - 으로 출력하고 있습니다. 좌표에 대해 기대하는 정밀도 수준을 명시해야 합니다. 소수점 세 자리라고 합시다.

```go
	fmt.Fprintf(w, `<line x1="150" y1="150" x2="%.3f" y2="%.3f" style="fill:none;stroke:#f00;stroke-width:3px;"/>`, p.X, p.Y)
```

그리고 테스트에서 기대치를 업데이트한 후

```go
	x2 := "150.000"
	y2 := "60.000"
```

다음을 얻습니다:

```
PASS
ok  	clockface	0.006s
```

이제 `main` 함수를 줄일 수 있습니다:

```go
package main

import (
	"os"
	"time"

	"learn-go-with-tests/math/clockface"
)

func main() {
	t := time.Now()
	clockface.SVGWriter(os.Stdout, t)
}
```

[지금 상태는 이렇게 보여야 합니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v7b/clockface).

그리고 같은 패턴으로 또 다른 시간에 대한 테스트를 작성할 수 있지만, 먼저...

### 리팩토링

세 가지가 눈에 띕니다:

1. 우리는 실제로 존재해야 하는 모든 정보를 테스트하고 있지 않습니다 - 예를 들어 `x1` 값은요?
2. 또한 `x1` 등에 대한 속성은 실제로 `string`이 아니지 않나요? 숫자입니다!
3. 손의 `style`에 정말로 관심이 있나요? 또는 `zak`에 의해 생성된 빈 `Text` 노드는요?

더 잘할 수 있습니다. `Svg` 구조체와 테스트를 몇 가지 조정하여 모든 것을 날카롭게 합시다.

```go
type SVG struct {
	XMLName xml.Name `xml:"svg"`
	Xmlns   string   `xml:"xmlns,attr"`
	Width   string   `xml:"width,attr"`
	Height  string   `xml:"height,attr"`
	ViewBox string   `xml:"viewBox,attr"`
	Version string   `xml:"version,attr"`
	Circle  Circle   `xml:"circle"`
	Line    []Line   `xml:"line"`
}

type Circle struct {
	Cx float64 `xml:"cx,attr"`
	Cy float64 `xml:"cy,attr"`
	R  float64 `xml:"r,attr"`
}

type Line struct {
	X1 float64 `xml:"x1,attr"`
	Y1 float64 `xml:"y1,attr"`
	X2 float64 `xml:"x2,attr"`
	Y2 float64 `xml:"y2,attr"`
}
```

여기서 저는

* 구조체의 중요한 부분을 명명된 타입으로 만들었습니다 -- `Line`과 `Circle`
* 숫자 속성을 `string`에서 `float64`로 변경했습니다.
* `Style` 및 `Text`와 같은 사용하지 않는 속성을 삭제했습니다
* `Svg`를 `SVG`로 이름을 바꿨습니다. *올바른 일이니까요*.

이것은 우리가 찾고 있는 선에 대해 더 정확하게 어설션할 수 있게 합니다:

```go
func TestSVGWriterAtMidnight(t *testing.T) {
	tm := time.Date(1337, time.January, 1, 0, 0, 0, 0, time.UTC)
	b := bytes.Buffer{}

	clockface.SVGWriter(&b, tm)

	svg := SVG{}

	xml.Unmarshal(b.Bytes(), &svg)

	want := Line{150, 150, 150, 60}

	for _, line := range svg.Line {
		if line == want {
			return
		}
	}

	t.Errorf("Expected to find the second hand line %+v, in the SVG lines %+v", want, svg.Line)
}
```

마지막으로 단위 테스트의 테이블에서 교훈을 얻을 수 있고, 이 테스트들을 정말 빛나게 하기 위해 `containsLine(line Line, lines []Line) bool` 헬퍼 함수를 작성할 수 있습니다:

```go
func TestSVGWriterSecondHand(t *testing.T) {
	cases := []struct {
		time time.Time
		line Line
	}{
		{
			simpleTime(0, 0, 0),
			Line{150, 150, 150, 60},
		},
		{
			simpleTime(0, 0, 30),
			Line{150, 150, 150, 240},
		},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			b := bytes.Buffer{}
			clockface.SVGWriter(&b, c.time)

			svg := SVG{}
			xml.Unmarshal(b.Bytes(), &svg)

			if !containsLine(c.line, svg.Line) {
				t.Errorf("Expected to find the second hand line %+v, in the SVG lines %+v", c.line, svg.Line)
			}
		})
	}
}

func containsLine(l Line, ls []Line) bool {
	for _, line := range ls {
		if line == l {
			return true
		}
	}
	return false
}
```

[이렇게 보입니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v7c/clockface)

이제 *그것*이 제가 말하는 인수 테스트입니다!

### 먼저 테스트 작성

초침은 끝났습니다. 이제 분침을 시작합시다.

```go
func TestSVGWriterMinuteHand(t *testing.T) {
	cases := []struct {
		time time.Time
		line Line
	}{
		{
			simpleTime(0, 0, 0),
			Line{150, 150, 150, 70},
		},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			b := bytes.Buffer{}
			clockface.SVGWriter(&b, c.time)

			svg := SVG{}
			xml.Unmarshal(b.Bytes(), &svg)

			if !containsLine(c.line, svg.Line) {
				t.Errorf("Expected to find the minute hand line %+v, in the SVG lines %+v", c.line, svg.Line)
			}
		})
	}
}
```

### 테스트 실행 시도

```
clockface_acceptance_test.go:87: Expected to find the minute hand line {X1:150 Y1:150 X2:150 Y2:70}, in the SVG lines [{X1:150 Y1:150 X2:150 Y2:60}]
```

다른 시계 바늘을 구축하기 시작해야 합니다. 초침에 대한 테스트를 생성한 것과 같은 방식으로 다음 테스트 세트를 생성하기 위해 반복할 수 있습니다. 다시 한번 작동하는 동안 인수 테스트를 주석 처리하겠습니다:

```go
func TestMinutesInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(0, 30, 0), math.Pi},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := minutesInRadians(c.time)
			if got != c.angle {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
./clockface_test.go:59:11: undefined: minutesInRadians
```

### 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func minutesInRadians(t time.Time) float64 {
	return math.Pi
}
```

### 새 요구 사항에 대해 반복

좋아요 - 이제 *진짜* 작업을 하게 합시다. 분침을 매 분마다만 움직이는 것으로 모델링할 수 있습니다 - 그래서 30분에서 31분으로 사이에 움직이지 않고 '점프'합니다. 하지만 그것은 조금 허접해 보일 것입니다. 우리가 원하는 것은 매 초마다 *아주 조금씩* 움직이는 것입니다.

```go
func TestMinutesInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(0, 30, 0), math.Pi},
		{simpleTime(0, 0, 7), 7 * (math.Pi / (30 * 60))},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := minutesInRadians(c.time)
		if got != c.angle {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

그 작은 비트는 얼마나 작을까요? 음...

* 1분에 60초
* 원의 반 회전에 30분 (`math.Pi` 라디안)
* 그래서 반 회전에 `30 * 60`초.
* 그래서 시간이 정각 7초가 지났다면 ...
* ... 분침이 12에서 `7 * (math.Pi / (30 * 60))` 라디안 떨어진 곳에 있을 것으로 예상합니다.

### 테스트 실행 시도

```
clockface_test.go:62: Wanted 0.012217304763960306 radians, but got 3.141592653589793
```

### 테스트를 통과시키기 위한 충분한 코드 작성

Jennifer Aniston의 불멸의 말로: [Here comes the science bit](https://www.youtube.com/watch?v=29Im23SPNok)

```go
func minutesInRadians(t time.Time) float64 {
	return (secondsInRadians(t) / 60) +
		(math.Pi / (30 / float64(t.Minute())))
}
```

매 초마다 분침을 얼마나 밀어야 하는지를 처음부터 계산하는 대신 `secondsInRadians` 함수를 활용할 수 있습니다. 매 초마다 분침은 초침이 움직이는 각도의 1/60만큼 움직입니다.

```go
secondsInRadians(t) / 60
```

그런 다음 분에 대한 움직임을 더합니다 - 초침의 움직임과 유사합니다.

```go
math.Pi / (30 / float64(t.Minute()))
```

그리고...

```
PASS
ok  	clockface	0.007s
```

멋지고 쉽습니다. [지금 상태는 이렇습니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v8/clockface/clockface_acceptance_test.go)

### 새 요구 사항에 대해 반복

`minutesInRadians` 테스트에 더 많은 케이스를 추가해야 할까요? 현재 두 개뿐입니다. `minuteHandPoint` 함수 테스트로 넘어가기 전에 얼마나 많은 케이스가 필요할까요?

Kent Beck에게 종종 기인하는 내가 가장 좋아하는 TDD 인용문 중 하나는

> 두려움이 지루함으로 변할 때까지 테스트를 작성하세요.

그리고 솔직히 그 함수를 테스트하는 것이 지루합니다. 어떻게 작동하는지 확신합니다. 그래서 다음으로 넘어갑니다.

### 먼저 테스트 작성

```go
func TestMinuteHandPoint(t *testing.T) {
	cases := []struct {
		time  time.Time
		point Point
	}{
		{simpleTime(0, 30, 0), Point{0, -1}},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := minuteHandPoint(c.time)
			if !roughlyEqualPoint(got, c.point) {
				t.Fatalf("Wanted %v Point, but got %v", c.point, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
./clockface_test.go:79:11: undefined: minuteHandPoint
```

### 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func minuteHandPoint(t time.Time) Point {
	return Point{}
}
```

```
clockface_test.go:80: Wanted {0 -1} Point, but got {0 0}
```

### 테스트를 통과시키기 위한 충분한 코드 작성

```go
func minuteHandPoint(t time.Time) Point {
	return Point{0, -1}
}
```

```
PASS
ok  	clockface	0.007s
```

### 새 요구 사항에 대해 반복

이제 실제 작업을 해봅시다

```go
func TestMinuteHandPoint(t *testing.T) {
	cases := []struct {
		time  time.Time
		point Point
	}{
		{simpleTime(0, 30, 0), Point{0, -1}},
		{simpleTime(0, 45, 0), Point{-1, 0}},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := minuteHandPoint(c.time)
			if !roughlyEqualPoint(got, c.point) {
				t.Fatalf("Wanted %v Point, but got %v", c.point, got)
			}
		})
	}
}
```

```
clockface_test.go:81: Wanted {-1 0} Point, but got {0 -1}
```

### 테스트를 통과시키기 위한 충분한 코드 작성

약간의 변경과 함께 `secondHandPoint` 함수를 빠르게 복사하여 붙여넣으면 됩니다...

```go
func minuteHandPoint(t time.Time) Point {
	angle := minutesInRadians(t)
	x := math.Sin(angle)
	y := math.Cos(angle)

	return Point{x, y}
}
```

```
PASS
ok  	clockface	0.009s
```

### 리팩토링

`minuteHandPoint`와 `secondHandPoint`에 확실히 반복이 있습니다 - 알고 있습니다. 하나를 복사하여 붙여넣어 다른 것을 만들었으니까요. 함수로 DRY 해봅시다.

```go
func angleToPoint(angle float64) Point {
	x := math.Sin(angle)
	y := math.Cos(angle)

	return Point{x, y}
}
```

그리고 `minuteHandPoint`와 `secondHandPoint`를 한 줄로 다시 작성할 수 있습니다:

```go
func minuteHandPoint(t time.Time) Point {
	return angleToPoint(minutesInRadians(t))
}
```

```go
func secondHandPoint(t time.Time) Point {
	return angleToPoint(secondsInRadians(t))
}
```

```
PASS
ok  	clockface	0.007s
```

이제 인수 테스트의 주석을 해제하고 분침 그리기 작업을 시작할 수 있습니다.

### 테스트를 통과시키기 위한 충분한 코드 작성

`minuteHand` 함수는 `secondHand`를 복사하여 붙여넣은 것이며 `minuteHandLength` 선언과 같은 약간의 조정이 있습니다:

```go
const minuteHandLength = 80

//...

func minuteHand(w io.Writer, t time.Time) {
	p := minuteHandPoint(t)
	p = Point{p.X * minuteHandLength, p.Y * minuteHandLength}
	p = Point{p.X, -p.Y}
	p = Point{p.X + clockCentreX, p.Y + clockCentreY}
	fmt.Fprintf(w, `<line x1="150" y1="150" x2="%.3f" y2="%.3f" style="fill:none;stroke:#000;stroke-width:3px;"/>`, p.X, p.Y)
}
```

그리고 `SVGWriter` 함수에서 호출:

```go
func SVGWriter(w io.Writer, t time.Time) {
	io.WriteString(w, svgStart)
	io.WriteString(w, bezel)
	secondHand(w, t)
	minuteHand(w, t)
	io.WriteString(w, svgEnd)
}
```

이제 `TestSVGWriterMinuteHand`가 통과하는 것을 볼 수 있습니다:

```
PASS
ok  	clockface	0.006s
```

하지만 푸딩의 증거는 먹는 것에 있습니다 - 이제 `clockface` 프로그램을 컴파일하고 실행하면 다음과 같은 것을 볼 수 있어야 합니다

![a clock with second and minute hands](<.gitbook/assets/clock (1).svg>)

### 리팩토링

`secondHand` 및 `minuteHand` 함수에서 중복을 제거하고 모든 크기 조정, 뒤집기 및 변환 로직을 한 곳에 넣어봅시다.

```go
func secondHand(w io.Writer, t time.Time) {
	p := makeHand(secondHandPoint(t), secondHandLength)
	fmt.Fprintf(w, `<line x1="150" y1="150" x2="%.3f" y2="%.3f" style="fill:none;stroke:#f00;stroke-width:3px;"/>`, p.X, p.Y)
}

func minuteHand(w io.Writer, t time.Time) {
	p := makeHand(minuteHandPoint(t), minuteHandLength)
	fmt.Fprintf(w, `<line x1="150" y1="150" x2="%.3f" y2="%.3f" style="fill:none;stroke:#000;stroke-width:3px;"/>`, p.X, p.Y)
}

func makeHand(p Point, length float64) Point {
	p = Point{p.X * length, p.Y * length}
	p = Point{p.X, -p.Y}
	return Point{p.X + clockCentreX, p.Y + clockCentreY}
}
```

```
PASS
ok  	clockface	0.007s
```

[지금 현재 상태입니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v9/clockface).

거기서... 이제 시침만 하면 됩니다!

### 먼저 테스트 작성

```go
func TestSVGWriterHourHand(t *testing.T) {
	cases := []struct {
		time time.Time
		line Line
	}{
		{
			simpleTime(6, 0, 0),
			Line{150, 150, 150, 200},
		},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			b := bytes.Buffer{}
			clockface.SVGWriter(&b, c.time)

			svg := SVG{}
			xml.Unmarshal(b.Bytes(), &svg)

			if !containsLine(c.line, svg.Line) {
				t.Errorf("Expected to find the hour hand line %+v, in the SVG lines %+v", c.line, svg.Line)
			}
		})
	}
}
```

### 테스트 실행 시도

```
clockface_acceptance_test.go:113: Expected to find the hour hand line {X1:150 Y1:150 X2:150 Y2:200}, in the SVG lines [{X1:150 Y1:150 X2:150 Y2:60} {X1:150 Y1:150 X2:150 Y2:70}]
```

다시 낮은 수준의 테스트로 커버리지를 확보할 때까지 이것을 주석 처리합시다:

### 먼저 테스트 작성

```go
func TestHoursInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(6, 0, 0), math.Pi},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := hoursInRadians(c.time)
			if got != c.angle {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
./clockface_test.go:97:11: undefined: hoursInRadians
```

### 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func hoursInRadians(t time.Time) float64 {
	return math.Pi
}
```

```
PASS
ok  	clockface	0.007s
```

### 새 요구 사항에 대해 반복

```go
func TestHoursInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(6, 0, 0), math.Pi},
		{simpleTime(0, 0, 0), 0},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := hoursInRadians(c.time)
			if got != c.angle {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
clockface_test.go:100: Wanted 0 radians, but got 3.141592653589793
```

### 테스트를 통과시키기 위한 충분한 코드 작성

```go
func hoursInRadians(t time.Time) float64 {
	return (math.Pi / (6 / float64(t.Hour())))
}
```

### 새 요구 사항에 대해 반복

```go
func TestHoursInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(6, 0, 0), math.Pi},
		{simpleTime(0, 0, 0), 0},
		{simpleTime(21, 0, 0), math.Pi * 1.5},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := hoursInRadians(c.time)
			if got != c.angle {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
clockface_test.go:101: Wanted 4.71238898038469 radians, but got 10.995574287564276
```

### 테스트를 통과시키기 위한 충분한 코드 작성

```go
func hoursInRadians(t time.Time) float64 {
	return (math.Pi / (6 / (float64(t.Hour() % 12))))
}
```

기억하세요, 이것은 24시간 시계가 아닙니다; 현재 시간을 12로 나눈 나머지를 얻기 위해 나머지 연산자를 사용해야 합니다.

```
PASS
ok  	learn-go-with-tests/math/clockface	0.008s
```

### 먼저 테스트 작성

이제 지나간 분과 초에 따라 시침을 시계 주위로 움직여 봅시다.

```go
func TestHoursInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(6, 0, 0), math.Pi},
		{simpleTime(0, 0, 0), 0},
		{simpleTime(21, 0, 0), math.Pi * 1.5},
		{simpleTime(0, 1, 30), math.Pi / ((6 * 60 * 60) / 90)},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := hoursInRadians(c.time)
			if got != c.angle {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

### 테스트 실행 시도

```
clockface_test.go:102: Wanted 0.013089969389957472 radians, but got 0
```

### 테스트를 통과시키기 위한 충분한 코드 작성

다시, 약간의 생각이 필요합니다. 분과 초 모두에 대해 시침을 조금씩 움직여야 합니다. 다행히 분과 초에 대한 각도가 이미 있습니다 - `minutesInRadians`가 반환하는 것입니다. 재사용할 수 있습니다!

유일한 질문은 그 각도의 크기를 얼마나 줄일 것인가입니다. 분침의 경우 한 바퀴가 1시간이지만 시침의 경우 12시간입니다. 그래서 `minutesInRadians`가 반환하는 각도를 12로 나누면 됩니다:

```go
func hoursInRadians(t time.Time) float64 {
	return (minutesInRadians(t) / 12) +
		(math.Pi / (6 / float64(t.Hour()%12)))
}
```

그리고 보세요:

```
clockface_test.go:104: Wanted 0.013089969389957472 radians, but got 0.01308996938995747
```

부동 소수점 연산이 다시 발생합니다.

각도 비교를 위해 `roughlyEqualFloat64`를 사용하도록 테스트를 업데이트합시다.

```go
func TestHoursInRadians(t *testing.T) {
	cases := []struct {
		time  time.Time
		angle float64
	}{
		{simpleTime(6, 0, 0), math.Pi},
		{simpleTime(0, 0, 0), 0},
		{simpleTime(21, 0, 0), math.Pi * 1.5},
		{simpleTime(0, 1, 30), math.Pi / ((6 * 60 * 60) / 90)},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := hoursInRadians(c.time)
			if !roughlyEqualFloat64(got, c.angle) {
				t.Fatalf("Wanted %v radians, but got %v", c.angle, got)
			}
		})
	}
}
```

```
PASS
ok  	clockface	0.007s
```

### 리팩토링

라디안 테스트 중 *하나*에서 `roughlyEqualFloat64`를 사용하려면 아마 *모든* 테스트에서 사용해야 합니다. 그것은 간단하고 쉬운 리팩토링이며 [이렇게 보이게 됩니다](https://github.com/quii/learn-go-with-tests/tree/main/math/v10/clockface).

## 시침 포인트

좋아요, 단위 벡터를 계산하여 시침 포인트가 어디로 갈지 계산할 시간입니다.

### 먼저 테스트 작성

```go
func TestHourHandPoint(t *testing.T) {
	cases := []struct {
		time  time.Time
		point Point
	}{
		{simpleTime(6, 0, 0), Point{0, -1}},
		{simpleTime(21, 0, 0), Point{-1, 0}},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			got := hourHandPoint(c.time)
			if !roughlyEqualPoint(got, c.point) {
				t.Fatalf("Wanted %v Point, but got %v", c.point, got)
			}
		})
	}
}
```

잠깐, *두 개의* 테스트 케이스를 *한 번에* 작성하려고 하나요? 이것은 *나쁜 TDD*가 아닌가요?

### TDD 광신에 대해

테스트 주도 개발은 종교가 아닙니다. 어떤 사람들은 그것처럼 행동할 수 있습니다 - 보통 TDD를 하지 않지만 Twitter나 Dev.to에서 광신자들만 한다고 불평하고 테스트를 작성하지 않을 때 '실용적'이라고 말하는 사람들입니다. 하지만 종교가 아닙니다. 도구입니다.

두 테스트가 무엇인지 *알고 있습니다* - 정확히 같은 방식으로 다른 두 시계 바늘을 테스트했습니다 - 그리고 구현이 무엇인지 이미 알고 있습니다 - 분침 반복에서 각도를 점으로 바꾸는 일반적인 경우를 위한 함수를 작성했습니다.

그냥 의식을 위해 TDD 의식을 거치지 않을 것입니다. TDD는 작성하는 코드 - 그리고 작성할 코드 - 를 더 잘 이해할 수 있도록 도와주는 기술입니다. TDD는 피드백, 지식 및 통찰력을 제공합니다. 하지만 이미 그 지식이 있다면 이유 없이 의식을 거치지 않을 것입니다. 테스트도 TDD도 그 자체로 목적이 아닙니다.

자신감이 높아졌으므로 더 큰 보폭으로 나아갈 수 있다고 느낍니다. 몇 가지 단계를 '건너뛸' 것입니다. 제가 어디에 있는지 알고, 어디로 가는지 알고, 이 길을 전에 갔으니까요.

하지만 또한 주목하세요: 테스트를 완전히 건너뛰는 것이 아닙니다 - 여전히 먼저 작성하고 있습니다. 그냥 덜 세분화된 청크로 나타나고 있습니다.

### 테스트 실행 시도

```
./clockface_test.go:119:11: undefined: hourHandPoint
```

### 테스트를 통과시키기 위한 충분한 코드 작성

```go
func hourHandPoint(t time.Time) Point {
	return angleToPoint(hoursInRadians(t))
}
```

말했듯이 제가 어디에 있는지 알고 어디로 가는지 알고 있습니다. 왜 다른 척 하나요? 테스트는 곧 제가 틀렸다면 알려줄 것입니다.

```
PASS
ok  	learn-go-with-tests/math/clockface	0.009s
```

## 시침 그리기

마지막으로 시침을 그립니다. 인수 테스트의 주석을 해제하여 가져올 수 있습니다:

```go
func TestSVGWriterHourHand(t *testing.T) {
	cases := []struct {
		time time.Time
		line Line
	}{
		{
			simpleTime(6, 0, 0),
			Line{150, 150, 150, 200},
		},
	}

	for _, c := range cases {
		t.Run(testName(c.time), func(t *testing.T) {
			b := bytes.Buffer{}
			clockface.SVGWriter(&b, c.time)

			svg := SVG{}
			xml.Unmarshal(b.Bytes(), &svg)

			if !containsLine(c.line, svg.Line) {
				t.Errorf("Expected to find the hour hand line %+v, in the SVG lines %+v", c.line, svg.Line)
			}
		})
	}
}
```

### 테스트 실행 시도

```
clockface_acceptance_test.go:113: Expected to find the hour hand line {X1:150 Y1:150 X2:150 Y2:200},
    in the SVG lines [{X1:150 Y1:150 X2:150 Y2:60} {X1:150 Y1:150 X2:150 Y2:70}]
```

### 테스트를 통과시키기 위한 충분한 코드 작성

이제 SVG 작성 상수와 함수에 대한 최종 조정을 할 수 있습니다:

```go
const (
	secondHandLength = 90
	minuteHandLength = 80
	hourHandLength   = 50
	clockCentreX     = 150
	clockCentreY     = 150
)

// SVGWriter writes an SVG representation of an analogue clock, showing the time t, to the writer w
func SVGWriter(w io.Writer, t time.Time) {
	io.WriteString(w, svgStart)
	io.WriteString(w, bezel)
	secondHand(w, t)
	minuteHand(w, t)
	hourHand(w, t)
	io.WriteString(w, svgEnd)
}

// ...

func hourHand(w io.Writer, t time.Time) {
	p := makeHand(hourHandPoint(t), hourHandLength)
	fmt.Fprintf(w, `<line x1="150" y1="150" x2="%.3f" y2="%.3f" style="fill:none;stroke:#000;stroke-width:3px;"/>`, p.X, p.Y)
}

```

그래서...

```
ok  	clockface	0.007s
```

`clockface` 프로그램을 컴파일하고 실행하여 확인해 봅시다.

![a clock](<.gitbook/assets/clock (2).svg>)

### 리팩토링

`clockface.go`를 보면 몇 가지 '매직 넘버'가 떠다니고 있습니다. 그것들은 모두 시계 반 바퀴에 몇 시간/분/초가 있는지에 기반합니다. 의미를 명시적으로 만들기 위해 리팩토링합시다.

```go
const (
	secondsInHalfClock = 30
	secondsInClock     = 2 * secondsInHalfClock
	minutesInHalfClock = 30
	minutesInClock     = 2 * minutesInHalfClock
	hoursInHalfClock   = 6
	hoursInClock       = 2 * hoursInHalfClock
)
```

왜 이렇게 하나요? 방정식에서 각 숫자가 *의미하는* 것을 명시적으로 만듭니다. - *만약* - 이 코드로 돌아오면 이 이름들이 무슨 일이 일어나는지 이해하는 데 도움이 될 것입니다.

게다가 정말, 정말 이상한 시계를 만들고 싶다면 - 예를 들어 시침에 4시간, 초침에 20초가 있는 시계 - 이 상수들은 쉽게 매개변수가 될 수 있습니다. 그 문을 열어두는 데 도움을 주고 있습니다 (비록 그 문을 통과하지 않더라도).

## 마무리

다른 것을 해야 할까요?

먼저 스스로를 칭찬합시다 - 우리는 SVG 시계를 만드는 프로그램을 작성했습니다. 작동하고 좋습니다. 한 종류의 시계만 만들 것입니다 - 하지만 괜찮습니다! 아마도 한 종류의 시계만 *원할* 것입니다. 특정 문제를 해결하고 그 외에는 아무것도 하지 않는 프로그램에는 아무런 문제가 없습니다.

### 프로그램... 그리고 라이브러리

하지만 우리가 작성한 코드는 시계 그리기와 관련된 더 일반적인 문제 세트를 *해결합니다*. 테스트를 사용하여 문제의 각 작은 부분을 고립시켜 생각했고, 함수로 그 고립을 코드화했기 때문에 시계 계산을 위한 매우 합리적인 작은 API를 구축했습니다.

이 프로젝트를 작업하여 더 일반적인 것으로 만들 수 있습니다 - 시계 각도 및/또는 벡터를 계산하기 위한 라이브러리입니다.

사실 프로그램과 함께 라이브러리를 제공하는 것은 *정말 좋은 아이디어*입니다. 비용이 들지 않으면서 프로그램의 유용성을 높이고 작동 방식을 문서화하는 데 도움이 됩니다.

> API는 프로그램과 함께 제공되어야 하며 그 반대도 마찬가지입니다. 사용하려면 C 코드를 작성해야 하고 명령줄에서 쉽게 호출할 수 없는 API는 배우고 사용하기 어렵습니다. 그리고 반대로 유일한 열린, 문서화된 형태가 프로그램이어서 C 프로그램에서 쉽게 호출할 수 없는 인터페이스는 왕실의 고통입니다. -- Henry Spencer, *The Art of Unix Programming*에서

[제 최종 버전의 이 프로그램](https://github.com/quii/learn-go-with-tests/tree/main/math/vFinal/clockface)에서 `clockface` 내의 내보내지 않는 함수들을 라이브러리의 공용 API로 만들었고, 각 시계 바늘에 대한 각도와 단위 벡터를 계산하는 함수가 있습니다. 또한 SVG 생성 부분을 자체 패키지인 `svg`로 분리하여 `clockface` 프로그램에서 직접 사용합니다. 당연히 각 함수와 패키지를 문서화했습니다.

SVG에 대해 이야기하자면...

### 가장 가치 있는 테스트

SVG를 처리하는 가장 정교한 코드가 애플리케이션 코드에 있지 않다는 것을 분명히 알아차렸을 것입니다; 테스트 코드에 있습니다. 이것이 불편하게 느껴져야 할까요? 다음과 같은 것을 해야 하지 않을까요

* `text/template`에서 템플릿을 사용하나요?
* XML 라이브러리를 사용하나요 (테스트에서 하는 것처럼)?
* SVG 라이브러리를 사용하나요?

이러한 것 중 하나를 수행하기 위해 코드를 리팩토링할 수 있으며, SVG를 *어떻게* 생성하는지는 중요하지 않기 때문에 그렇게 할 수 있습니다. 중요한 것은 *무엇을* 생성하는가입니다 - *SVG*. 따라서 SVG에 대해 가장 많이 알아야 하는 시스템 부분 - SVG가 무엇인지에 대해 가장 엄격해야 하는 부분 - 은 SVG 출력에 대한 테스트입니다: SVG를 출력하고 있다고 확신할 수 있도록 SVG가 무엇인지에 대한 충분한 맥락과 지식이 있어야 합니다. SVG의 *무엇*은 테스트에 있습니다; *어떻게*는 코드에 있습니다.

SVG 테스트에 많은 시간과 노력을 투자하는 것이 이상하게 느껴졌을 수 있습니다 - XML 라이브러리를 가져오고, XML을 파싱하고, 구조체를 리팩토링하는 것 - 하지만 그 테스트 코드는 코드베이스의 가치 있는 부분입니다 - 아마도 현재 프로덕션 코드보다 더 가치 있을 것입니다. 그것이 무엇을 사용하여 생성하든 출력이 항상 유효한 SVG임을 보장하는 데 도움이 될 것입니다.

테스트는 이등 시민이 아닙니다 - '버리는' 코드가 아닙니다. 좋은 테스트는 테스트하는 코드 버전보다 훨씬 오래 지속됩니다. 테스트를 작성하는 데 '너무 많은 시간'을 보내고 있다고 느껴서는 안 됩니다. 그것은 투자입니다.

1. 간단히 말해서 일반 도 단위를 사용하면 π가 각도로 계속 나타나므로 원으로 미적분을 하기 쉽게 만들어주므로, π로 각도를 세면 모든 방정식이 더 간단해집니다.

# 구조체, 메서드 & 인터페이스

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/structs)**

높이와 너비가 주어진 직사각형의 둘레를 계산하는 기하학 코드가 필요하다고 가정합시다. `Perimeter(width float64, height float64)` 함수를 작성할 수 있습니다. 여기서 `float64`는 `123.45`와 같은 부동 소수점 숫자를 위한 것입니다.

TDD 사이클은 이제 꽤 익숙해졋을 것입니다.

## 먼저 테스트 작성

```go
func TestPerimeter(t *testing.T) {
	got := Perimeter(10.0, 10.0)
	want := 40.0

	if got != want {
		t.Errorf("got %.2f want %.2f", got, want)
	}
}
```

새로운 형식 문자열에 주목하셨나요? `f`는 `float64`를 위한 것이고 `.2`는 소수점 2자리를 출력한다는 의미입니다.

## 테스트 실행 시도

`./shapes_test.go:6:9: undefined: Perimeter`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func Perimeter(width float64, height float64) float64 {
	return 0
}
```

결과는 `shapes_test.go:10: got 0.00 want 40.00`입니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Perimeter(width float64, height float64) float64 {
	return 2 * (width + height)
}
```

지금까지 쉬웠죠. 이제 직사각형의 면적을 반환하는 `Area(width, height float64)`라는 함수를 만들어 봅시다.

TDD 사이클을 따라 직접 해보세요.

다음과 같은 테스트가 있어야 합니다

```go
func TestPerimeter(t *testing.T) {
	got := Perimeter(10.0, 10.0)
	want := 40.0

	if got != want {
		t.Errorf("got %.2f want %.2f", got, want)
	}
}

func TestArea(t *testing.T) {
	got := Area(12.0, 6.0)
	want := 72.0

	if got != want {
		t.Errorf("got %.2f want %.2f", got, want)
	}
}
```

그리고 다음과 같은 코드

```go
func Perimeter(width float64, height float64) float64 {
	return 2 * (width + height)
}

func Area(width float64, height float64) float64 {
	return width * height
}
```

## 리팩토링

코드가 작업을 수행하지만, 직사각형에 대해 명시적인 것을 포함하지 않습니다. 부주의한 개발자가 잘못된 답을 반환할 것이라는 것을 모르고 이 함수들에 삼각형의 너비와 높이를 제공하려고 할 수 있습니다.

`RectangleArea`와 같이 함수에 더 구체적인 이름을 줄 수 있습니다. 더 깔끔한 해결책은 이 개념을 캡슐화하는 `Rectangle`이라는 자체 **타입**을 정의하는 것입니다.

**struct**를 사용하여 간단한 타입을 만들 수 있습니다. [구조체](https://golang.org/ref/spec#Struct_types)는 데이터를 저장할 수 있는 필드의 명명된 모음일 뿐입니다.

`shapes.go` 파일에 다음과 같이 구조체를 선언하세요

```go
type Rectangle struct {
	Width  float64
	Height float64
}
```

이제 일반 `float64` 대신 `Rectangle`을 사용하도록 테스트를 리팩토링해 봅시다.

```go
func TestPerimeter(t *testing.T) {
	rectangle := Rectangle{10.0, 10.0}
	got := Perimeter(rectangle)
	want := 40.0

	if got != want {
		t.Errorf("got %.2f want %.2f", got, want)
	}
}

func TestArea(t *testing.T) {
	rectangle := Rectangle{12.0, 6.0}
	got := Area(rectangle)
	want := 72.0

	if got != want {
		t.Errorf("got %.2f want %.2f", got, want)
	}
}
```

수정을 시도하기 전에 테스트를 실행하는 것을 기억하세요. 테스트는 다음과 같은 유용한 오류를 보여줘야 합니다

```text
./shapes_test.go:7:18: not enough arguments in call to Perimeter
    have (Rectangle)
    want (float64, float64)
```

`myStruct.field` 구문으로 구조체의 필드에 접근할 수 있습니다.

테스트를 수정하기 위해 두 함수를 변경하세요.

```go
func Perimeter(rectangle Rectangle) float64 {
	return 2 * (rectangle.Width + rectangle.Height)
}

func Area(rectangle Rectangle) float64 {
	return rectangle.Width * rectangle.Height
}
```

`Rectangle`을 함수에 전달하는 것이 의도를 더 명확하게 전달한다는 데 동의하실 것입니다. 하지만 나중에 다룰 구조체 사용의 더 많은 이점이 있습니다.

다음 요구 사항은 원에 대한 `Area` 함수를 작성하는 것입니다.

## 먼저 테스트 작성

```go
func TestArea(t *testing.T) {

	t.Run("rectangles", func(t *testing.T) {
		rectangle := Rectangle{12, 6}
		got := Area(rectangle)
		want := 72.0

		if got != want {
			t.Errorf("got %g want %g", got, want)
		}
	})

	t.Run("circles", func(t *testing.T) {
		circle := Circle{10}
		got := Area(circle)
		want := 314.1592653589793

		if got != want {
			t.Errorf("got %g want %g", got, want)
		}
	})

}
```

보시다시피, `f`가 `g`로 대체되었습니다.
`g`를 사용하면 오류 메시지에 더 정확한 소수를 출력합니다\([fmt 옵션](https://golang.org/pkg/fmt/)\).
예를 들어, 원 면적 계산에서 반지름 1.5를 사용하면, `f`는 `7.068583`을 표시하지만 `g`는 `7.0685834705770345`를 표시합니다.

## 테스트 실행 시도

`./shapes_test.go:28:13: undefined: Circle`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`Circle` 타입을 정의해야 합니다.

```go
type Circle struct {
	Radius float64
}
```

이제 테스트를 다시 실행해 보세요

`./shapes_test.go:29:14: cannot use circle (type Circle) as type Rectangle in argument to Area`

일부 프로그래밍 언어에서는 다음과 같은 것을 할 수 있습니다:

```go
func Area(circle Circle) float64       {}
func Area(rectangle Rectangle) float64 {}
```

하지만 Go에서는 불가능합니다

`./shapes.go:20:32: Area redeclared in this block`

두 가지 선택지가 있습니다:

* 같은 이름의 함수를 다른 **패키지**에 선언할 수 있습니다. 그래서 새 패키지에 `Area(Circle)`를 만들 수 있지만, 여기서는 과도하게 느껴집니다.
* 새로 정의된 타입에 [**메서드**](https://golang.org/ref/spec#Method_declarations)를 정의할 수 있습니다.

### 메서드란 무엇인가?

지금까지 **함수**만 작성했지만 일부 메서드를 사용해 왔습니다. `t.Errorf`를 호출할 때 `t`\(`testing.T`\)의 인스턴스에서 `Errorf` 메서드를 호출합니다.

메서드는 리시버가 있는 함수입니다.
메서드 선언은 식별자인 메서드 이름을 메서드에 바인딩하고, 메서드를 리시버의 기본 타입과 연결합니다.

메서드는 함수와 매우 유사하지만 특정 타입의 인스턴스에서 호출하여 호출됩니다. `Area(rectangle)`과 같이 원하는 곳에서 함수를 호출할 수 있는 반면, 메서드는 "것들"에서만 호출할 수 있습니다.

예가 도움이 될 것이므로 먼저 테스트를 변경하여 대신 메서드를 호출하고 코드를 수정합시다.

```go
func TestArea(t *testing.T) {

	t.Run("rectangles", func(t *testing.T) {
		rectangle := Rectangle{12, 6}
		got := rectangle.Area()
		want := 72.0

		if got != want {
			t.Errorf("got %g want %g", got, want)
		}
	})

	t.Run("circles", func(t *testing.T) {
		circle := Circle{10}
		got := circle.Area()
		want := 314.1592653589793

		if got != want {
			t.Errorf("got %g want %g", got, want)
		}
	})

}
```

테스트를 실행하면

```text
./shapes_test.go:19:19: rectangle.Area undefined (type Rectangle has no field or method Area)
./shapes_test.go:29:16: circle.Area undefined (type Circle has no field or method Area)
```

> type Circle has no field or method Area

여기서 컴파일러가 얼마나 훌륭한지 다시 한번 강조하고 싶습니다. 오류 메시지를 천천히 읽는 시간을 갖는 것이 매우 중요하며, 장기적으로 도움이 될 것입니다.

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

타입에 일부 메서드를 추가합시다

```go
type Rectangle struct {
	Width  float64
	Height float64
}

func (r Rectangle) Area() float64 {
	return 0
}

type Circle struct {
	Radius float64
}

func (c Circle) Area() float64 {
	return 0
}
```

메서드를 선언하는 구문은 함수와 거의 같으며, 그것은 매우 유사하기 때문입니다. 유일한 차이점은 메서드 리시버의 구문 `func (receiverName ReceiverType) MethodName(args)`입니다.

메서드가 해당 타입의 변수에서 호출되면, `receiverName` 변수를 통해 데이터에 대한 참조를 얻습니다. 다른 많은 프로그래밍 언어에서는 이것이 암시적으로 수행되고 `this`를 통해 리시버에 접근합니다.

Go에서는 리시버 변수가 타입의 첫 글자가 되는 것이 관례입니다.

```
r Rectangle
```

테스트를 다시 실행하면 이제 컴파일되고 일부 실패 출력을 제공해야 합니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

이제 새 메서드를 수정하여 직사각형 테스트를 통과시킵시다

```go
func (r Rectangle) Area() float64 {
	return r.Width * r.Height
}
```

테스트를 다시 실행하면 직사각형 테스트는 통과하지만 원은 여전히 실패해야 합니다.

원의 `Area` 함수를 통과시키기 위해 `math` 패키지에서 `Pi` 상수를 빌려옵니다\(임포트하는 것을 기억하세요\).

```go
func (c Circle) Area() float64 {
	return math.Pi * c.Radius * c.Radius
}
```

## 리팩토링

테스트에 일부 중복이 있습니다.

원하는 것은 **도형** 컬렉션을 가져와서 `Area()` 메서드를 호출하고 결과를 확인하는 것입니다.

`Rectangle`과 `Circle` 둘 다 전달할 수 있지만 도형이 아닌 것을 전달하려고 하면 컴파일에 실패하는 일종의 `checkArea` 함수를 작성할 수 있기를 원합니다.

Go에서는 **인터페이스**로 이 의도를 코드화할 수 있습니다.

[인터페이스](https://golang.org/ref/spec#Interface_types)는 Go와 같은 정적 타입 언어에서 매우 강력한 개념입니다. 다른 타입과 함께 사용할 수 있는 함수를 만들고 타입 안전성을 유지하면서 고도로 분리된 코드를 만들 수 있기 때문입니다.

테스트를 리팩토링하여 이것을 소개합시다.

```go
func TestArea(t *testing.T) {

	checkArea := func(t testing.TB, shape Shape, want float64) {
		t.Helper()
		got := shape.Area()
		if got != want {
			t.Errorf("got %g want %g", got, want)
		}
	}

	t.Run("rectangles", func(t *testing.T) {
		rectangle := Rectangle{12, 6}
		checkArea(t, rectangle, 72.0)
	})

	t.Run("circles", func(t *testing.T) {
		circle := Circle{10}
		checkArea(t, circle, 314.1592653589793)
	})

}
```

다른 연습에서와 같이 헬퍼 함수를 만들고 있지만 이번에는 `Shape`를 전달하라고 요청합니다. 도형이 아닌 것으로 이것을 호출하려고 하면 컴파일되지 않습니다.

무언가가 도형이 되는 방법은? 인터페이스 선언을 사용하여 Go에게 `Shape`가 무엇인지 알려주기만 하면 됩니다

```go
type Shape interface {
	Area() float64
}
```

`Rectangle`과 `Circle`에서 했던 것처럼 새로운 `type`을 만들고 있지만, 이번에는 `struct`가 아닌 `interface`입니다.

이것을 코드에 추가하면 테스트가 통과합니다.

### 잠깐, 뭐요?

이것은 대부분의 다른 프로그래밍 언어의 인터페이스와 상당히 다릅니다. 일반적으로 `My type Foo implements interface Bar`라고 말하는 코드를 작성해야 합니다.

하지만 우리의 경우

* `Rectangle`은 `float64`를 반환하는 `Area`라는 메서드가 있으므로 `Shape` 인터페이스를 만족합니다
* `Circle`은 `float64`를 반환하는 `Area`라는 메서드가 있으므로 `Shape` 인터페이스를 만족합니다
* `string`에는 그러한 메서드가 없으므로 인터페이스를 만족하지 않습니다
* 등등.

Go에서 **인터페이스 해결은 암시적**입니다. 전달하는 타입이 인터페이스가 요청하는 것과 일치하면 컴파일됩니다.

### 디커플링

헬퍼가 도형이 `Rectangle`인지 `Circle`인지 `Triangle`인지 걱정할 필요가 없다는 것에 주목하세요. 인터페이스를 선언함으로써, 헬퍼는 구체적인 타입에서 **분리되고** 작업을 수행하는 데 필요한 메서드만 있습니다.

**필요한 것만 선언**하기 위해 인터페이스를 사용하는 이러한 접근 방식은 소프트웨어 설계에서 매우 중요하며 이후 섹션에서 더 자세히 다룰 것입니다.

## 추가 리팩토링

이제 구조체에 대해 약간 이해했으므로 "테이블 주도 테스트"를 소개할 수 있습니다.

[테이블 주도 테스트](https://go.dev/wiki/TableDrivenTests)는 같은 방식으로 테스트할 수 있는 테스트 케이스 목록을 만들고 싶을 때 유용합니다.

```go
func TestArea(t *testing.T) {

	areaTests := []struct {
		shape Shape
		want  float64
	}{
		{Rectangle{12, 6}, 72.0},
		{Circle{10}, 314.1592653589793},
	}

	for _, tt := range areaTests {
		got := tt.shape.Area()
		if got != tt.want {
			t.Errorf("got %g want %g", got, tt.want)
		}
	}

}
```

여기서 유일한 새로운 구문은 "익명 구조체" `areaTests`를 만드는 것입니다. `[]struct`를 사용하여 `shape`와 `want`의 두 필드를 가진 구조체 슬라이스를 선언합니다. 그런 다음 케이스로 슬라이스를 채웁니다.

그런 다음 다른 슬라이스처럼 반복하고, 구조체 필드를 사용하여 테스트를 실행합니다.

개발자가 새로운 도형을 추가하고, `Area`를 구현한 다음 테스트 케이스에 추가하는 것이 얼마나 쉬운지 알 수 있습니다. 또한, `Area`에서 버그가 발견되면 수정하기 전에 이를 실행하기 위해 새 테스트 케이스를 추가하는 것이 매우 쉽습니다.

테이블 주도 테스트는 도구 상자에서 훌륭한 항목이 될 수 있지만, 테스트에서 추가 노이즈가 필요한지 확인하세요.
인터페이스의 다양한 구현을 테스트하거나 함수에 전달되는 데이터가 테스트가 필요한 많은 다른 요구 사항이 있는 경우 적합합니다.

다른 도형을 추가하고 테스트하여 이 모든 것을 시연해 봅시다; 삼각형.

## 먼저 테스트 작성

새 도형에 대한 새 테스트를 추가하는 것은 매우 쉽습니다. 목록에 `{Triangle{12, 6}, 36.0},`만 추가하면 됩니다.

```go
func TestArea(t *testing.T) {

	areaTests := []struct {
		shape Shape
		want  float64
	}{
		{Rectangle{12, 6}, 72.0},
		{Circle{10}, 314.1592653589793},
		{Triangle{12, 6}, 36.0},
	}

	for _, tt := range areaTests {
		got := tt.shape.Area()
		if got != tt.want {
			t.Errorf("got %g want %g", got, tt.want)
		}
	}

}
```

## 테스트 실행 시도

테스트를 계속 실행하고 컴파일러가 해결책을 향해 안내하도록 하세요.

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`./shapes_test.go:25:4: undefined: Triangle`

아직 `Triangle`을 정의하지 않았습니다

```go
type Triangle struct {
	Base   float64
	Height float64
}
```

다시 시도

```text
./shapes_test.go:25:8: cannot use Triangle literal (type Triangle) as type Shape in field value:
    Triangle does not implement Shape (missing Area method)
```

`Area()` 메서드가 없기 때문에 `Triangle`을 도형으로 사용할 수 없다고 말하고 있으므로, 테스트가 작동하도록 빈 구현을 추가하세요

```go
func (t Triangle) Area() float64 {
	return 0
}
```

마침내 코드가 컴파일되고 오류가 발생합니다

`shapes_test.go:31: got 0.00 want 36.00`

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (t Triangle) Area() float64 {
	return (t.Base * t.Height) * 0.5
}
```

테스트가 통과합니다!

## 리팩토링

다시, 구현은 괜찮지만 테스트는 약간 개선될 수 있습니다.

이것을 스캔할 때

```
{Rectangle{12, 6}, 72.0},
{Circle{10}, 314.1592653589793},
{Triangle{12, 6}, 36.0},
```

모든 숫자가 무엇을 나타내는지 즉시 명확하지 않으며 테스트가 쉽게 이해되도록 노력해야 합니다.

지금까지 `MyStruct{val1, val2}` 구조체 인스턴스를 만드는 구문만 보여줬지만 선택적으로 필드 이름을 지정할 수 있습니다.

어떻게 보이는지 봅시다

```
        {shape: Rectangle{Width: 12, Height: 6}, want: 72.0},
        {shape: Circle{Radius: 10}, want: 314.1592653589793},
        {shape: Triangle{Base: 12, Height: 6}, want: 36.0},
```

[Test-Driven Development by Example](https://g.co/kgs/yCzDLF)에서 Kent Beck은 일부 테스트를 어느 시점까지 리팩토링하고 다음과 같이 주장합니다:

> 테스트가 우리에게 더 명확하게 말하는 것처럼, 마치 진실의 주장인 것처럼, **작업의 시퀀스가 아니라**

\(인용문에서 강조는 제 것입니다\)

이제 테스트 - 더 정확히 말하면 테스트 케이스 목록 - 은 도형과 그 면적에 대한 진실의 주장을 만듭니다.

## 테스트 출력이 도움이 되도록 하기

앞서 `Triangle`을 구현할 때 실패한 테스트가 있었던 것을 기억하세요? `shapes_test.go:31: got 0.00 want 36.00`을 출력했습니다.

우리가 방금 작업하고 있었기 때문에 이것이 `Triangle`과 관련이 있다는 것을 알았습니다.
하지만 테이블의 20개 케이스 중 하나에서 버그가 시스템에 들어갔다면?
개발자는 어떤 케이스가 실패했는지 어떻게 알 수 있을까요?
이것은 개발자에게 좋은 경험이 아닙니다. 실제로 어떤 케이스가 실패했는지 알아내기 위해 수동으로 케이스를 살펴봐야 합니다.

오류 메시지를 `%#v got %g want %g`로 변경할 수 있습니다. `%#v` 형식 문자열은 필드에 값이 있는 구조체를 출력하므로 개발자가 테스트 중인 속성을 한눈에 볼 수 있습니다.

테스트 케이스의 가독성을 더 높이기 위해 `want` 필드의 이름을 `hasArea`와 같은 더 설명적인 이름으로 변경할 수 있습니다.

테이블 주도 테스트에 대한 마지막 팁은 `t.Run`을 사용하고 테스트 케이스 이름을 지정하는 것입니다.

각 케이스를 `t.Run`으로 감싸면 케이스 이름이 출력되므로 실패 시 더 명확한 테스트 출력을 얻을 수 있습니다

```text
--- FAIL: TestArea (0.00s)
    --- FAIL: TestArea/Rectangle (0.00s)
        shapes_test.go:33: main.Rectangle{Width:12, Height:6} got 72.00 want 72.10
```

그리고 `go test -run TestArea/Rectangle`로 테이블 내의 특정 테스트를 실행할 수 있습니다.

이것을 캡처하는 최종 테스트 코드는 다음과 같습니다

```go
func TestArea(t *testing.T) {

	areaTests := []struct {
		name    string
		shape   Shape
		hasArea float64
	}{
		{name: "Rectangle", shape: Rectangle{Width: 12, Height: 6}, hasArea: 72.0},
		{name: "Circle", shape: Circle{Radius: 10}, hasArea: 314.1592653589793},
		{name: "Triangle", shape: Triangle{Base: 12, Height: 6}, hasArea: 36.0},
	}

	for _, tt := range areaTests {
		// 케이스의 tt.name을 사용하여 `t.Run` 테스트 이름으로 사용
		t.Run(tt.name, func(t *testing.T) {
			got := tt.shape.Area()
			if got != tt.hasArea {
				t.Errorf("%#v got %g want %g", tt.shape, got, tt.hasArea)
			}
		})

	}

}
```

## 마무리

이것은 더 많은 TDD 연습이었습니다. 기본 수학 문제에 대한 솔루션을 반복하고 테스트에 의해 동기 부여된 새로운 언어 기능을 배웠습니다.

* 자체 데이터 타입을 만들기 위해 구조체를 선언하여 관련 데이터를 함께 묶고 코드의 의도를 더 명확하게 만들기
* 다른 타입에서 사용할 수 있는 함수를 정의할 수 있도록 인터페이스 선언 \([매개변수 다형성](https://en.wikipedia.org/wiki/Parametric_polymorphism)\)
* 데이터 타입에 기능을 추가하고 인터페이스를 구현할 수 있도록 메서드 추가
* 어설션을 더 명확하게 만들고 테스트 스위트를 확장 및 유지 관리하기 쉽게 만드는 테이블 주도 테스트

이것은 중요한 챕터였습니다. 이제 자체 타입을 정의하기 시작했기 때문입니다. Go와 같은 정적 타입 언어에서, 이해하기 쉽고, 조립하기 쉽고, 테스트하기 쉬운 소프트웨어를 구축하는 데 자체 타입을 설계할 수 있는 것이 필수적입니다.

인터페이스는 시스템의 다른 부분에서 복잡성을 숨기기 위한 훌륭한 도구입니다. 우리의 경우 테스트 헬퍼 **코드**는 어설션하는 정확한 도형을 알 필요가 없고, 면적을 "묻는" 방법만 알면 됩니다.

Go에 더 익숙해지면 인터페이스와 표준 라이브러리의 진정한 강점을 보게 될 것입니다. **어디서나** 사용되는 표준 라이브러리에 정의된 인터페이스에 대해 배우고, 자체 타입에 대해 구현함으로써 많은 훌륭한 기능을 매우 빠르게 재사용할 수 있습니다.

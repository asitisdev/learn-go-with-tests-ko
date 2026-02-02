# 포인터 & 에러

[**이 챕터의 모든 코드는 여기에서 확인할 수 있습니다**](https://github.com/quii/learn-go-with-tests/tree/main/pointers)

지난 섹션에서 개념과 관련된 여러 값을 캡처할 수 있는 구조체에 대해 배웠습니다.

어느 시점에서 구조체를 사용하여 상태를 관리하고, 사용자가 제어할 수 있는 방식으로 상태를 변경할 수 있도록 메서드를 노출하고 싶을 수 있습니다.

**핀테크는 Go를 좋아하고** 어, 비트코인도요? 그러니 우리가 만들 수 있는 놀라운 뱅킹 시스템을 보여줍시다.

`Bitcoin`을 입금할 수 있는 `Wallet` 구조체를 만들어 봅시다.

## 먼저 테스트 작성

```go
func TestWallet(t *testing.T) {

	wallet := Wallet{}

	wallet.Deposit(10)

	got := wallet.Balance()
	want := 10

	if got != want {
		t.Errorf("got %d want %d", got, want)
	}
}
```

[이전 예제](structs-methods-and-interfaces.md)에서는 필드 이름으로 필드에 직접 접근했지만, **매우 안전한 지갑**에서는 내부 상태를 외부 세계에 노출하고 싶지 않습니다. 메서드를 통해 접근을 제어하고 싶습니다.

## 테스트 실행 시도

`./wallet_test.go:7:12: undefined: Wallet`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

컴파일러가 `Wallet`이 무엇인지 모르므로 알려줍시다.

```go
type Wallet struct{}
```

이제 지갑을 만들었으니, 테스트를 다시 실행해 보세요

```
./wallet_test.go:9:8: wallet.Deposit undefined (type Wallet has no field or method Deposit)
./wallet_test.go:11:15: wallet.Balance undefined (type Wallet has no field or method Balance)
```

이 메서드들을 정의해야 합니다.

테스트가 실행되도록 하는 데 충분한 것만 하는 것을 기억하세요. 테스트가 명확한 오류 메시지와 함께 올바르게 실패하는지 확인해야 합니다.

```go
func (w Wallet) Deposit(amount int) {

}

func (w Wallet) Balance() int {
	return 0
}
```

이 구문이 익숙하지 않다면 돌아가서 구조체 섹션을 읽으세요.

테스트가 이제 컴파일되고 실행되어야 합니다

`wallet_test.go:15: got 0 want 10`

## 테스트를 통과시키기 위한 충분한 코드 작성

상태를 저장하기 위해 구조체에 일종의 **balance** 변수가 필요합니다

```go
type Wallet struct {
	balance int
}
```

Go에서 심볼(변수, 타입, 함수 등)이 소문자로 시작하면 **정의된 패키지 외부에서** private입니다.

우리의 경우 메서드가 이 값을 조작할 수 있기를 원하지만, 다른 누구도 그러지 못하게 하고 싶습니다.

"리시버" 변수를 사용하여 구조체의 내부 `balance` 필드에 접근할 수 있다는 것을 기억하세요.

```go
func (w Wallet) Deposit(amount int) {
	w.balance += amount
}

func (w Wallet) Balance() int {
	return w.balance
}
```

핀테크에서의 경력이 보장되었으니, 테스트 스위트를 실행하고 통과하는 테스트를 즐기세요

`wallet_test.go:15: got 0 want 10`

### 뭔가 잘못되었네요

음, 혼란스럽네요, 코드가 작동할 것처럼 보입니다. 잔액에 새 금액을 추가하고 balance 메서드가 현재 상태를 반환해야 합니다.

Go에서, **함수나 메서드를 호출할 때 인자는** _**복사됩니다**_.

`func (w Wallet) Deposit(amount int)`를 호출할 때 `w`는 메서드를 호출한 것의 복사본입니다.

너무 컴퓨터 과학적이지 않게, 값을 만들 때 - 지갑처럼, 메모리 어딘가에 저장됩니다. `&myVal`로 그 메모리 비트의 **주소**를 알아낼 수 있습니다.

코드에 일부 출력을 추가하여 실험해 보세요

```go
func TestWallet(t *testing.T) {

	wallet := Wallet{}

	wallet.Deposit(10)

	got := wallet.Balance()

	fmt.Printf("address of balance in test is %p \n", &wallet.balance)

	want := 10

	if got != want {
		t.Errorf("got %d want %d", got, want)
	}
}
```

```go
func (w Wallet) Deposit(amount int) {
	fmt.Printf("address of balance in Deposit is %p \n", &w.balance)
	w.balance += amount
}
```

`%p` 플레이스홀더는 16진수 표기법으로 메모리 주소를 출력하며 앞에 `0x`가 붙고, 이스케이프 문자는 새 줄을 출력합니다. 심볼 앞에 `&` 문자를 놓으면 무언가의 포인터(메모리 주소)를 얻습니다.

이제 테스트를 다시 실행하세요

```
address of balance in Deposit is 0xc420012268
address of balance in test is 0xc420012260
```

두 잔액의 주소가 다른 것을 볼 수 있습니다. 그래서 코드 내에서 잔액 값을 변경할 때, 테스트에서 온 것의 복사본에서 작업하고 있습니다. 따라서 테스트의 잔액은 변경되지 않습니다.

**포인터**로 이것을 수정할 수 있습니다. [포인터](https://gobyexample.com/pointers)를 사용하면 일부 값을 **가리키고** 변경할 수 있습니다. 그래서 전체 Wallet의 복사본을 가져가는 대신, 해당 지갑에 대한 포인터를 가져가서 내부의 원래 값을 변경할 수 있습니다.

```go
func (w *Wallet) Deposit(amount int) {
	w.balance += amount
}

func (w *Wallet) Balance() int {
	return w.balance
}
```

차이점은 리시버 타입이 `Wallet`이 아닌 `*Wallet`이며, 이것은 "지갑에 대한 포인터"로 읽을 수 있습니다.

테스트를 다시 실행하면 통과해야 합니다.

이제 왜 통과했는지 궁금할 수 있습니다. 다음과 같이 함수에서 포인터를 역참조하지 않았습니다:

```go
func (w *Wallet) Balance() int {
	return (*w).balance
}
```

그리고 객체를 직접 주소 지정한 것처럼 보입니다. 사실, `(*w)`를 사용하는 위의 코드는 절대적으로 유효합니다. 그러나, Go 제작자들은 이 표기법이 번거롭다고 생각하여, 명시적인 역참조 없이 `w.balance`를 작성할 수 있게 언어가 허용합니다. 구조체에 대한 이러한 포인터는 심지어 자체 이름이 있습니다: **struct pointers**이고 [자동으로 역참조됩니다](https://golang.org/ref/spec#Method_values).

기술적으로 잔액의 복사본을 가져가는 것이 괜찮기 때문에 `Balance`를 포인터 리시버를 사용하도록 변경할 필요가 없습니다. 그러나, 관례상 일관성을 위해 메서드 리시버 타입을 동일하게 유지해야 합니다.

## 리팩토링

비트코인 지갑을 만든다고 했지만 지금까지 언급하지 않았습니다. 물건을 세는 데 좋은 타입이기 때문에 `int`를 사용했습니다!

이것을 위해 `struct`를 만드는 것은 약간 과도해 보입니다. `int`는 작동하는 방식 면에서는 괜찮지만 설명적이지 않습니다.

Go에서는 기존 타입에서 새 타입을 만들 수 있습니다.

구문은 `type MyName OriginalType`입니다

```go
type Bitcoin int

type Wallet struct {
	balance Bitcoin
}

func (w *Wallet) Deposit(amount Bitcoin) {
	w.balance += amount
}

func (w *Wallet) Balance() Bitcoin {
	return w.balance
}
```

```go
func TestWallet(t *testing.T) {

	wallet := Wallet{}

	wallet.Deposit(Bitcoin(10))

	got := wallet.Balance()

	want := Bitcoin(10)

	if got != want {
		t.Errorf("got %d want %d", got, want)
	}
}
```

`Bitcoin`을 만들려면 `Bitcoin(999)` 구문을 사용하면 됩니다.

이렇게 하면 새 타입을 만들고 **메서드**를 선언할 수 있습니다. 기존 타입 위에 도메인 특정 기능을 추가하려는 경우 매우 유용할 수 있습니다.

Bitcoin에 [Stringer](https://golang.org/pkg/fmt/#Stringer)를 구현해 봅시다

```go
type Stringer interface {
	String() string
}
```

이 인터페이스는 `fmt` 패키지에 정의되어 있으며 출력에서 `%s` 형식 문자열과 함께 사용될 때 타입이 어떻게 출력되는지 정의할 수 있게 합니다.

```go
func (b Bitcoin) String() string {
	return fmt.Sprintf("%d BTC", b)
}
```

보시다시피, 타입 선언에 메서드를 만드는 구문은 구조체에서와 동일합니다.

다음으로 `String()`대신 사용하도록 테스트 형식 문자열을 업데이트해야 합니다.

```go
	if got != want {
		t.Errorf("got %s want %s", got, want)
	}
```

이것이 실제로 작동하는지 보려면, 테스트를 의도적으로 깨뜨려서 볼 수 있습니다

`wallet_test.go:18: got 10 BTC want 20 BTC`

이것은 테스트에서 무슨 일이 일어나고 있는지 더 명확하게 만듭니다.

다음 요구 사항은 `Withdraw` 함수입니다.

## 먼저 테스트 작성

`Deposit()`과 거의 반대입니다

```go
func TestWallet(t *testing.T) {

	t.Run("deposit", func(t *testing.T) {
		wallet := Wallet{}

		wallet.Deposit(Bitcoin(10))

		got := wallet.Balance()

		want := Bitcoin(10)

		if got != want {
			t.Errorf("got %s want %s", got, want)
		}
	})

	t.Run("withdraw", func(t *testing.T) {
		wallet := Wallet{balance: Bitcoin(20)}

		wallet.Withdraw(Bitcoin(10))

		got := wallet.Balance()

		want := Bitcoin(10)

		if got != want {
			t.Errorf("got %s want %s", got, want)
		}
	})
}
```

## 테스트 실행 시도

`./wallet_test.go:26:9: wallet.Withdraw undefined (type Wallet has no field or method Withdraw)`

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func (w *Wallet) Withdraw(amount Bitcoin) {

}
```

`wallet_test.go:33: got 20 BTC want 10 BTC`

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (w *Wallet) Withdraw(amount Bitcoin) {
	w.balance -= amount
}
```

## 리팩토링

테스트에 일부 중복이 있으니, 리팩토링합시다.

```go
func TestWallet(t *testing.T) {

	assertBalance := func(t testing.TB, wallet Wallet, want Bitcoin) {
		t.Helper()
		got := wallet.Balance()

		if got != want {
			t.Errorf("got %s want %s", got, want)
		}
	}

	t.Run("deposit", func(t *testing.T) {
		wallet := Wallet{}
		wallet.Deposit(Bitcoin(10))
		assertBalance(t, wallet, Bitcoin(10))
	})

	t.Run("withdraw", func(t *testing.T) {
		wallet := Wallet{balance: Bitcoin(20)}
		wallet.Withdraw(Bitcoin(10))
		assertBalance(t, wallet, Bitcoin(10))
	})

}
```

계좌에 남은 것보다 더 많이 `Withdraw`하려고 하면 어떻게 될까요? 지금은 당좌 대월 시설이 없다고 가정하는 것이 요구 사항입니다.

`Withdraw`를 사용할 때 문제를 어떻게 알릴까요?

Go에서, 오류를 나타내려면 함수가 호출자가 확인하고 조치할 수 있도록 `err`를 반환하는 것이 관용적입니다.

테스트에서 이것을 시도해 봅시다.

## 먼저 테스트 작성

```go
t.Run("withdraw insufficient funds", func(t *testing.T) {
	startingBalance := Bitcoin(20)
	wallet := Wallet{startingBalance}
	err := wallet.Withdraw(Bitcoin(100))

	assertBalance(t, wallet, startingBalance)

	if err == nil {
		t.Error("wanted an error but didn't get one")
	}
})
```

가진 것보다 더 많이 인출하려고 하면 `Withdraw`가 오류를 반환하고 잔액은 동일하게 유지되기를 원합니다.

그런 다음 `nil`이면 테스트를 실패시켜 오류가 반환되었는지 확인합니다.

`nil`은 다른 프로그래밍 언어의 `null`과 동의어입니다. `Withdraw`의 반환 타입이 인터페이스인 `error`이기 때문에 오류가 `nil`일 수 있습니다. 인터페이스인 인자를 받거나 값을 반환하는 함수를 보면, nil일 수 있습니다.

`null`처럼 `nil`인 값에 접근하려고 하면 **런타임 패닉**이 발생합니다. 이것은 나쁩니다! nil을 확인해야 합니다.

## 테스트 실행 시도

`./wallet_test.go:31:25: wallet.Withdraw(Bitcoin(100)) used as value`

문구가 약간 불분명할 수 있지만, `Withdraw`에 대한 이전 의도는 그냥 호출하는 것이었고, 절대 값을 반환하지 않습니다. 컴파일되도록 하려면 반환 타입이 있도록 변경해야 합니다.

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func (w *Wallet) Withdraw(amount Bitcoin) error {
	w.balance -= amount
	return nil
}
```

다시, 컴파일러를 만족시키기에 충분한 코드만 작성하는 것이 매우 중요합니다. `Withdraw` 메서드를 `error`를 반환하도록 수정하고 지금은 **무언가**를 반환해야 하므로 그냥 `nil`을 반환합시다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (w *Wallet) Withdraw(amount Bitcoin) error {

	if amount > w.balance {
		return errors.New("oh no")
	}

	w.balance -= amount
	return nil
}
```

코드에 `errors`를 임포트하는 것을 기억하세요.

`errors.New`는 선택한 메시지로 새 `error`를 만듭니다.

## 리팩토링

테스트의 가독성을 향상시키기 위해 오류 확인을 위한 빠른 테스트 헬퍼를 만들어 봅시다

```go
assertError := func(t testing.TB, err error) {
	t.Helper()
	if err == nil {
		t.Error("wanted an error but didn't get one")
	}
}
```

그리고 테스트에서

```go
t.Run("withdraw insufficient funds", func(t *testing.T) {
	startingBalance := Bitcoin(20)
	wallet := Wallet{startingBalance}
	err := wallet.Withdraw(Bitcoin(100))

	assertError(t, err)
	assertBalance(t, wallet, startingBalance)
})
```

"oh no"라는 오류를 반환할 때 유용해 보이지 않기 때문에 반복할 **수도** 있다고 생각했을 것입니다.

오류가 궁극적으로 사용자에게 반환된다고 가정하고, 오류의 존재뿐만 아니라 일종의 오류 메시지를 어설션하도록 테스트를 업데이트해 봅시다.

## 먼저 테스트 작성

비교할 `string`에 대한 헬퍼를 업데이트하세요.

```go
assertError := func(t testing.TB, got error, want string) {
	t.Helper()

	if got == nil {
		t.Fatal("didn't get an error but wanted one")
	}

	if got.Error() != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

보시다시피 `Error`는 원하는 문자열과 비교하기 위해 `.Error()` 메서드로 문자열로 변환할 수 있습니다. 또한 `nil`에서 `.Error()`를 호출하지 않도록 오류가 `nil`이 아닌지 확인하고 있습니다.

그리고 호출자를 업데이트하세요

```go
t.Run("withdraw insufficient funds", func(t *testing.T) {
	startingBalance := Bitcoin(20)
	wallet := Wallet{startingBalance}
	err := wallet.Withdraw(Bitcoin(100))

	assertError(t, err, "cannot withdraw, insufficient funds")
	assertBalance(t, wallet, startingBalance)
})
```

`t.Fatal`을 도입했는데, 호출되면 테스트를 중지합니다. 이것은 오류가 없으면 반환된 오류에 대해 더 이상 어설션을 하고 싶지 않기 때문입니다. 이것이 없으면 테스트가 다음 단계로 진행되고 nil 포인터 때문에 패닉이 발생합니다.

## 테스트 실행 시도

`wallet_test.go:61: got err 'oh no' want 'cannot withdraw, insufficient funds'`

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (w *Wallet) Withdraw(amount Bitcoin) error {

	if amount > w.balance {
		return errors.New("cannot withdraw, insufficient funds")
	}

	w.balance -= amount
	return nil
}
```

## 리팩토링

테스트 코드와 `Withdraw` 코드 모두에서 오류 메시지의 중복이 있습니다.

누군가가 오류를 다시 작성하려고 하면 테스트가 실패하는 것은 정말 성가시고 테스트에 너무 많은 세부 사항입니다. 정확한 문구가 무엇인지 **정말** 신경 쓰지 않습니다. 특정 조건이 주어졌을 때 인출과 관련된 일종의 의미 있는 오류가 반환되기만 하면 됩니다.

Go에서 오류는 값이므로, 변수로 리팩토링하고 단일 진실의 소스를 가질 수 있습니다.

```go
var ErrInsufficientFunds = errors.New("cannot withdraw, insufficient funds")

func (w *Wallet) Withdraw(amount Bitcoin) error {

	if amount > w.balance {
		return ErrInsufficientFunds
	}

	w.balance -= amount
	return nil
}
```

`var` 키워드를 사용하면 패키지에 전역 값을 정의할 수 있습니다.

이것은 그 자체로 긍정적인 변화입니다. 이제 `Withdraw` 함수가 매우 명확해 보입니다.

다음으로 특정 문자열 대신 이 값을 사용하도록 테스트 코드를 리팩토링할 수 있습니다.

```go
func TestWallet(t *testing.T) {

	t.Run("deposit", func(t *testing.T) {
		wallet := Wallet{}
		wallet.Deposit(Bitcoin(10))
		assertBalance(t, wallet, Bitcoin(10))
	})

	t.Run("withdraw with funds", func(t *testing.T) {
		wallet := Wallet{Bitcoin(20)}
		wallet.Withdraw(Bitcoin(10))
		assertBalance(t, wallet, Bitcoin(10))
	})

	t.Run("withdraw insufficient funds", func(t *testing.T) {
		wallet := Wallet{Bitcoin(20)}
		err := wallet.Withdraw(Bitcoin(100))

		assertError(t, err, ErrInsufficientFunds)
		assertBalance(t, wallet, Bitcoin(20))
	})
}

func assertBalance(t testing.TB, wallet Wallet, want Bitcoin) {
	t.Helper()
	got := wallet.Balance()

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}

func assertError(t testing.TB, got, want error) {
	t.Helper()
	if got == nil {
		t.Fatal("didn't get an error but wanted one")
	}

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

이제 테스트도 따라가기 쉬워졌습니다.

누군가가 파일을 열면 헬퍼보다 먼저 어설션을 읽을 수 있도록 헬퍼를 메인 테스트 함수 밖으로 옮겼습니다.

테스트의 또 다른 유용한 속성은 코드의 **실제** 사용법을 이해하는 데 도움이 되어 공감적인 코드를 만들 수 있다는 것입니다. 여기서 개발자가 단순히 코드를 호출하고 `ErrInsufficientFunds`와 동등 비교를 수행하고 그에 따라 행동할 수 있다는 것을 볼 수 있습니다.

### 확인되지 않은 오류

Go 컴파일러가 많은 도움을 주지만, 때때로 여전히 놓칠 수 있는 것들이 있고 오류 처리는 때때로 까다로울 수 있습니다.

테스트하지 않은 시나리오가 하나 있습니다. 찾으려면 터미널에서 다음을 실행하여 Go에 사용 가능한 많은 린터 중 하나인 `errcheck`를 설치하세요.

`go install github.com/kisielk/errcheck@latest`

그런 다음, 코드가 있는 디렉토리 내에서 `errcheck .`를 실행하세요

다음과 같은 것을 얻어야 합니다

`wallet_test.go:17:18: wallet.Withdraw(Bitcoin(10))`

이것은 해당 줄의 코드에서 반환되는 오류를 확인하지 않았다는 것을 알려줍니다. 내 컴퓨터의 해당 줄 코드는 정상적인 인출 시나리오에 해당합니다. `Withdraw`가 성공하면 오류가 **반환되지 않는지** 확인하지 않았기 때문입니다.

이것을 고려한 최종 테스트 코드는 다음과 같습니다.

```go
func TestWallet(t *testing.T) {

	t.Run("deposit", func(t *testing.T) {
		wallet := Wallet{}
		wallet.Deposit(Bitcoin(10))

		assertBalance(t, wallet, Bitcoin(10))
	})

	t.Run("withdraw with funds", func(t *testing.T) {
		wallet := Wallet{Bitcoin(20)}
		err := wallet.Withdraw(Bitcoin(10))

		assertNoError(t, err)
		assertBalance(t, wallet, Bitcoin(10))
	})

	t.Run("withdraw insufficient funds", func(t *testing.T) {
		wallet := Wallet{Bitcoin(20)}
		err := wallet.Withdraw(Bitcoin(100))

		assertError(t, err, ErrInsufficientFunds)
		assertBalance(t, wallet, Bitcoin(20))
	})
}

func assertBalance(t testing.TB, wallet Wallet, want Bitcoin) {
	t.Helper()
	got := wallet.Balance()

	if got != want {
		t.Errorf("got %s want %s", got, want)
	}
}

func assertNoError(t testing.TB, got error) {
	t.Helper()
	if got != nil {
		t.Fatal("got an error but didn't want one")
	}
}

func assertError(t testing.TB, got error, want error) {
	t.Helper()
	if got == nil {
		t.Fatal("didn't get an error but wanted one")
	}

	if got != want {
		t.Errorf("got %s, want %s", got, want)
	}
}
```

## 마무리

### 포인터

* Go는 함수/메서드에 전달할 때 값을 복사하므로, 상태를 변경해야 하는 함수를 작성하는 경우 변경하려는 것에 대한 포인터를 가져가야 합니다.
* Go가 값의 복사본을 가져가는 것이 많은 경우 유용하지만 때때로 시스템이 무언가의 복사본을 만들지 않기를 원할 것입니다. 이 경우 참조를 전달해야 합니다. 예로는 매우 큰 데이터 구조를 참조하거나 하나의 인스턴스만 필요한 것들(데이터베이스 연결 풀 같은)이 있습니다.

### nil

* 포인터는 nil일 수 있습니다
* 함수가 무언가에 대한 포인터를 반환할 때, nil인지 확인해야 합니다. 그렇지 않으면 런타임 예외가 발생할 수 있습니다 - 컴파일러는 여기서 도움이 되지 않습니다.
* 누락될 수 있는 값을 설명하려는 경우 유용합니다

### 에러

* 함수/메서드를 호출할 때 실패를 알리는 방법입니다.
* 테스트를 들으면서 오류의 문자열을 확인하면 불안정한 테스트가 된다고 결론지었습니다. 그래서 대신 의미 있는 값을 사용하도록 구현을 리팩토링했고, 이것은 테스트하기 쉬운 코드를 만들었고 API 사용자에게도 더 쉬울 것이라고 결론지었습니다.
* 이것은 오류 처리의 끝이 아닙니다, 더 정교한 것을 할 수 있지만 이것은 소개일 뿐입니다. 이후 섹션에서 더 많은 전략을 다룰 것입니다.
* [오류를 그냥 확인하지 말고, 우아하게 처리하세요](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully)

### 기존 타입에서 새 타입 만들기

* 값에 더 도메인 특정 의미를 추가하는 데 유용합니다
* 인터페이스를 구현할 수 있게 합니다

포인터와 에러는 Go를 작성하는 데 있어 익숙해져야 하는 큰 부분입니다. 다행히 컴파일러가 **보통** 잘못된 것을 하면 도와줄 것입니다. 시간을 갖고 오류를 읽으세요.

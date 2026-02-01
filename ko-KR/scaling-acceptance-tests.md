# 테스트로 Go 배우기 - 인수 테스트 확장하기 (gRPC 간단한 소개 포함)

이 챕터는 [인수 테스트 소개](intro-to-acceptance-tests.md)의 후속편입니다. [이 챕터의 완성된 코드는 GitHub에서 찾을 수 있습니다](https://github.com/quii/go-specs-greet).

인수 테스트는 필수적이며, 합리적인 변경 비용으로 시간이 지남에 따라 시스템을 자신 있게 발전시키는 능력에 직접적인 영향을 미칩니다.

또한 레거시 코드 작업에 도움이 되는 환상적인 도구입니다. 테스트가 없는 열악한 코드베이스에 직면했을 때 리팩토링을 시작하려는 유혹에 저항하세요. 대신 시스템의 내부를 자유롭게 변경할 수 있도록 외부 기능적 동작에 영향을 주지 않으면서 안전망을 제공하는 인수 테스트를 작성하세요. AT는 내부 품질에 관심을 가질 필요가 없으므로 이러한 상황에 잘 맞습니다.

이 글을 읽은 후에는 인수 테스트가 검증에 유용하며 시스템을 더 신중하고 체계적으로 변경하여 낭비되는 노력을 줄이는 개발 프로세스에서도 사용될 수 있다는 것을 알게 될 것입니다.

## 전제 조건 자료

이 챕터의 영감은 수년간의 인수 테스트 좌절에서 비롯되었습니다. 추천하는 두 가지 비디오:

- Dave Farley - [인수 테스트 작성 방법](https://www.youtube.com/watch?v=JDD5EEJgpHU)
- Nat Pryce - [밀리초 단위로 실행할 수 있는 E2E 기능 테스트](https://www.youtube.com/watch?v=Fk4rCn4YLLU)

"Growing Object Oriented Software" (GOOS)는 저를 포함한 많은 소프트웨어 엔지니어에게 매우 중요한 책입니다. 이 책이 제시하는 접근 방식은 제가 함께 일하는 엔지니어들에게 코칭하는 것입니다.

- [GOOS](http://www.growing-object-oriented-software.com) - Nat Pryce & Steve Freeman

마지막으로, [Riya Dattani](https://twitter.com/dattaniriya)와 저는 [Acceptance tests, BDD and Go](https://www.youtube.com/watch?v=ZMWJCk_0WrY) 강연에서 BDD 맥락에서 이 주제에 대해 이야기했습니다.

## 요약

우리는 시스템이 외부에서, **비즈니스 관점**에서 예상대로 동작하는지 확인하는 "블랙박스" 테스트에 대해 이야기하고 있습니다. 테스트는 테스트하는 시스템의 내부에 접근할 수 없습니다; 시스템이 **어떻게** 하는지가 아니라 **무엇을** 하는지에만 관심이 있습니다.

## 나쁜 인수 테스트의 해부학

수년 동안 여러 회사와 팀에서 일했습니다. 각각은 인수 테스트의 필요성을 인식했습니다; 사용자 관점에서 시스템을 테스트하고 의도한 대로 작동하는지 확인하는 어떤 방법이지만, 거의 예외 없이 이러한 테스트의 비용이 팀에게 진정한 문제가 되었습니다.

- 실행 속도가 느림
- 취약함
- 불안정함
- 유지 관리 비용이 비싸고 소프트웨어 변경이 어려워야 할 것보다 더 어려워 보임
- 특정 환경에서만 실행 가능하여 느리고 나쁜 피드백 루프 유발

구축 중인 웹사이트에 대한 인수 테스트를 작성하려고 한다고 가정해 봅시다. 사용자가 웹사이트에서 버튼을 클릭하는 것을 시뮬레이션하기 위해 헤드리스 웹 브라우저([Selenium](https://www.selenium.dev) 등)를 사용하기로 결정합니다.

시간이 지남에 따라 웹사이트의 마크업은 새로운 기능이 발견되고 엔지니어들이 `<article>`이어야 하는지 `<section>`이어야 하는지에 대해 수십억 번째로 자전거 창고 논쟁을 하면서 변경되어야 합니다.

팀이 시스템에 사소한 변경만 하고 있고 실제 사용자에게는 거의 눈에 띄지 않더라도 AT를 업데이트하는 데 많은 시간을 낭비하고 있습니다.

### 긴밀한 결합

인수 테스트가 변경되도록 촉발하는 것에 대해 생각해 보세요:

- 외부 동작 변경. 시스템이 하는 일을 변경하려면 인수 테스트 스위트를 변경하는 것이 합리적이고 바람직해 보입니다.
- 구현 세부 정보 변경 / 리팩토링. 이상적으로 이것은 변경을 유발하지 않아야 하거나 사소한 변경만 있어야 합니다.

하지만 너무 자주 후자가 인수 테스트를 변경해야 하는 이유가 됩니다. 엔지니어들이 테스트 업데이트의 인지된 노력 때문에 시스템을 변경하기를 꺼리게 되는 지경까지요!

![Riya와 저는 테스트에서 관심사 분리에 대해 이야기하고 있습니다](https://i.imgur.com/bbG6z57.png)

이러한 문제는 위에서 언급한 저자들이 작성한 잘 확립되고 실천된 엔지니어링 습관을 적용하지 않은 데서 비롯됩니다. **인수 테스트를 단위 테스트처럼 작성할 수 없습니다**; 더 많은 생각과 다른 관행이 필요합니다.

## 좋은 인수 테스트의 해부학

동작을 변경할 때만 변경되고 구현 세부 정보가 아닌 인수 테스트를 원한다면 그러한 관심사를 분리해야 합니다.

### 복잡성의 유형

소프트웨어 엔지니어로서 두 가지 종류의 복잡성을 다루어야 합니다.

- **우발적 복잡성**은 컴퓨터로 작업하기 때문에 처리해야 하는 복잡성입니다. 네트워크, 디스크, API 등과 같은 것들입니다.

- **본질적 복잡성**은 때때로 "도메인 로직"이라고 합니다. 도메인 내의 특정 규칙과 진실입니다.
  - 예를 들어 "계좌 소유자가 가용한 것보다 더 많은 돈을 인출하면 초과 인출됩니다". 이 명제는 컴퓨터에 대해 아무것도 말하지 않습니다; 이 명제는 컴퓨터가 은행에서 사용되기 전에도 사실이었습니다!

본질적 복잡성은 비기술적인 사람에게 표현할 수 있어야 하며, "도메인" 코드와 인수 테스트에서 모델링하는 것이 가치 있습니다.

### 관심사 분리

이전 비디오에서 Dave Farley가 제안한 것과 Riya와 제가 논의한 것은 **명세(specifications)** 개념입니다. 명세는 우발적 복잡성이나 구현 세부 정보와 결합되지 않고 원하는 시스템의 동작을 설명합니다.

이 아이디어는 합리적으로 느껴져야 합니다. 프로덕션 코드에서 우리는 자주 관심사를 분리하고 작업 단위를 분리하려고 노력합니다. `HTTP` 핸들러를 비HTTP 관심사와 분리하기 위해 `interface`를 도입하는 것을 주저하지 않을 것입니다? 인수 테스트에도 같은 사고 방식을 적용합시다.

Dave Farley는 특정 구조를 설명합니다.

![인수 테스트에 대한 Dave Farley](https://i.imgur.com/nPwpihG.png)

GopherconUK에서 Riya와 저는 이것을 Go 용어로 설명했습니다.

![관심사 분리](https://i.imgur.com/qdY4RJe.png)

### 스테로이드를 맞은 테스트

명세 실행 방식을 분리하면 다른 시나리오에서 재사용할 수 있습니다. 우리는:

#### 드라이버를 구성 가능하게 만들기

이것은 로컬, 스테이징 및 (이상적으로) 프로덕션 환경에서 AT를 실행할 수 있음을 의미합니다.
- 너무 많은 팀이 인수 테스트를 로컬에서 실행할 수 없도록 시스템을 엔지니어링합니다. 이것은 참을 수 없을 정도로 느린 피드백 루프를 도입합니다. 코드를 통합하기 _전에_ AT가 통과할 것이라고 확신하고 싶지 않습니까?
- 스테이징에서 테스트가 통과한다고 해서 시스템이 작동한다는 의미는 아닙니다. Dev/Prod 동등성은 기껏해야 선의의 거짓말입니다. [저는 프로덕션에서 테스트합니다](https://increment.com/testing/i-test-in-production/).
- 시스템의 *동작*에 영향을 줄 수 있는 환경 간의 차이가 항상 있습니다.

#### 시스템의 다른 부분을 테스트하기 위해 _다른_ 드라이버 연결

이 유연성으로 다른 추상화 및 아키텍처 계층에서 동작을 테스트할 수 있어 블랙박스 테스트를 넘어 더 집중된 테스트를 할 수 있습니다.
- 예를 들어 뒤에 API가 있는 웹 페이지가 있을 수 있습니다. 왜 같은 명세를 사용하여 둘 다 테스트하지 않습니까?
- 이 아이디어를 더 발전시키면 이상적으로 **코드가 본질적 복잡성을 모델링**하기를 원하므로("도메인" 코드로) 단위 테스트에도 명세를 사용할 수 있어야 합니다.

### 올바른 이유로 인수 테스트 변경

이 접근 방식을 사용하면 명세가 변경되는 유일한 이유는 시스템의 동작이 변경되는 것이며, 이는 합리적입니다.

- HTTP API가 변경되어야 하면 업데이트할 명확한 곳이 하나 있습니다. 드라이버입니다.
- 마크업이 변경되면 다시 특정 드라이버를 업데이트합니다.

시스템이 성장함에 따라 여러 테스트에서 드라이버를 재사용하게 될 것이며, 이는 구현 세부 정보가 변경되면 일반적으로 명확한 한 곳만 업데이트하면 됨을 의미합니다.

올바르게 수행되면 이 접근 방식은 구현 세부 정보에 유연성을 제공하고 명세에 안정성을 제공합니다. 중요하게도 시스템과 팀이 성장함에 따라 필수적인 변경 관리를 위한 간단하고 명확한 구조를 제공합니다.

### 소프트웨어 개발 방법으로서의 인수 테스트

강연에서 Riya와 저는 인수 테스트와 BDD와의 관계에 대해 논의했습니다. 해결하려는 _문제를 이해_하고 명세로 표현하여 작업을 시작하면 의도에 집중하는 데 도움이 되고 작업을 시작하는 좋은 방법이라고 이야기했습니다.

저는 GOOS에서 처음으로 이 작업 방식을 소개받았습니다. 블로그에서 아이디어를 요약했습니다. [Why TDD](https://quii.dev/The_Why_of_TDD)에서 발췌:

---

TDD는 반복적으로 정확히 필요한 동작에 맞게 설계할 수 있도록 하는 데 초점을 맞춥니다. 새로운 영역을 시작할 때 핵심적이고 필요한 동작을 식별하고 범위를 공격적으로 줄여야 합니다.

외부에서 동작을 실행하는 인수 테스트(AT)로 시작하는 "상향식" 접근 방식을 따르세요. 이것은 노력의 북극성 역할을 합니다. 집중해야 할 것은 그 테스트를 통과시키는 것뿐입니다.

![](https://i.imgur.com/pxTaYu4.png)

AT가 설정되면 TDD 프로세스에 들어가 AT를 통과시키기에 충분한 단위를 도출할 수 있습니다. 비결은 이 시점에서 설계에 대해 너무 걱정하지 않는 것입니다; 여전히 문제를 배우고 탐구하고 있으므로 AT를 통과시키기에 충분한 코드를 얻으세요.

![](https://i.imgur.com/t5y5opw.png)

개발하면서 테스트를 듣고, 상상이 아닌 동작에 기반하여 설계를 더 나은 방향으로 밀어주는 신호를 줄 것입니다.

일반적으로 AT를 통과시키기 위해 어려운 작업을 수행하는 첫 번째 "단위"는 이 적은 양의 동작에도 편안하기에는 너무 커질 것입니다. 이때 문제를 분해하고 새로운 협력자를 도입하는 방법에 대해 생각하기 시작할 수 있습니다.

![](https://i.imgur.com/UYqd7Cq.png)

#### 상향식의 위험

이것은 "상향식"이 아닌 "하향식" 접근 방식입니다. 상향식에도 용도가 있지만 위험 요소가 있습니다. 애플리케이션에 빠르게 통합하지 않고 높은 수준의 테스트로 확인하지 않으면서 "서비스"와 코드를 빌드하면 **검증되지 않은 아이디어에 많은 노력을 낭비할 위험이 있습니다**.

## 충분한 이야기, 코드 작성 시간

다른 챕터와 달리 [Docker](https://www.docker.com)가 설치되어 있어야 합니다. 컨테이너에서 애플리케이션을 실행할 것이기 때문입니다. 이 책의 이 시점에서 Go 코드를 작성하고 다른 패키지에서 가져오는 것 등에 익숙하다고 가정합니다.

`go mod init github.com/quii/go-specs-greet`로 새 프로젝트를 만드세요 (원하는 대로 넣을 수 있지만 경로를 변경하면 모든 내부 가져오기를 일치하도록 변경해야 합니다)

명세를 담을 `specifications` 폴더를 만들고 `greet.go` 파일을 추가하세요

```go
package specifications

import (
	"testing"

	"github.com/alecthomas/assert/v2"
)

type Greeter interface {
	Greet() (string, error)
}

func GreetSpecification(t testing.TB, greeter Greeter) {
	got, err := greeter.Greet()
	assert.NoError(t, err)
	assert.Equal(t, got, "Hello, world")
}
```

IDE(Goland)가 종속성 추가의 번거로움을 처리해 주지만 수동으로 해야 한다면

`go get github.com/alecthomas/assert/v2`

Farley의 인수 테스트 설계(Specification->DSL->Driver->System)를 고려하면 이제 구현에서 분리된 명세가 있습니다. `Greet`를 _어떻게_ 하는지 알지도 관심도 없습니다; 도메인의 본질적 복잡성에만 관심이 있습니다. 당연히 이 복잡성은 현재 많지 않지만 더 반복하면서 기능을 추가하기 위해 명세를 확장할 것입니다. 작게 시작하는 것이 항상 중요합니다!

인터페이스를 DSL의 첫 번째 단계로 볼 수 있습니다; 프로젝트가 성장하면 다르게 추상화할 필요가 있을 수 있지만 현재는 괜찮습니다.

이 시점에서 구현에서 명세를 분리하는 이 수준의 의식이 일부 사람들에게는 "과도한 추상화"라고 비난받을 수 있습니다. **구현에 너무 결합된 인수 테스트는 엔지니어링 팀에게 진정한 부담이 된다고 약속합니다**. 야생의 대부분의 인수 테스트는 과도하게 추상적이기보다는 이러한 부적절한 결합으로 인해 유지 관리 비용이 비싸다고 확신합니다.

`Greet`할 수 있는 모든 "시스템"을 확인하기 위해 이 명세를 사용할 수 있습니다.

### 첫 번째 시스템: HTTP API

HTTP를 통해 "greeter 서비스"를 제공해야 합니다. 따라서 다음을 만들어야 합니다:

1. **드라이버**. 이 경우 **HTTP 클라이언트**를 사용하여 HTTP 시스템과 작동합니다. 이 코드는 API와 작동하는 방법을 알 것입니다. 드라이버는 DSL을 시스템별 호출로 변환합니다; 우리의 경우 드라이버는 명세가 정의하는 인터페이스를 구현합니다.
2. greet API가 있는 **HTTP 서버**
3. 서버 스핀업 수명 주기를 관리하고 드라이버를 명세에 연결하여 테스트로 실행하는 **테스트**

## 먼저 테스트 작성

컴파일되고 프로그램을 실행하여 테스트를 실행하고 모든 것을 정리하는 블랙박스 테스트를 만드는 초기 프로세스는 상당히 노동 집약적일 수 있습니다. 그래서 최소한의 기능으로 프로젝트 시작에 하는 것이 좋습니다. 저는 일반적으로 "hello world" 서버 구현으로 모든 프로젝트를 시작하고, 모든 테스트가 설정되어 있어 실제 기능을 빠르게 빌드할 준비가 되어 있습니다.

"명세", "드라이버", "인수 테스트"의 정신적 모델은 익숙해지는 데 약간의 시간이 걸릴 수 있으므로 신중하게 따르세요. 먼저 명세를 호출하려고 "뒤로 작업"하는 것이 도움이 될 수 있습니다.

출시하려는 프로그램을 담을 구조를 만드세요.

`mkdir -p cmd/httpserver`

새 폴더 안에 새 파일 `greeter_server_test.go`를 만들고 다음을 추가하세요.

```go
package main_test

import (
	"testing"

	"github.com/quii/go-specs-greet/specifications"
)

func TestGreeterServer(t *testing.T) {
	specifications.GreetSpecification(t, nil)
}
```

Go 테스트에서 명세를 실행하려고 합니다. 이미 `*testing.T`에 접근할 수 있으므로 첫 번째 인수이지만 두 번째는?

`specifications.Greeter`는 인터페이스이며, 새 TestGreeterServer 코드를 다음과 같이 변경하여 `Driver`로 구현할 것입니다:

```go
import (
	go_specs_greet "github.com/quii/go-specs-greet"
)

func TestGreeterServer(t *testing.T) {
	driver := go_specs_greet.Driver{BaseURL: "http://localhost:8080"}
	specifications.GreetSpecification(t, driver)
}
```

`Driver`가 로컬을 포함한 서로 다른 환경에 대해 실행할 수 있도록 구성 가능하면 좋을 것이므로 `BaseURL` 필드를 추가했습니다.

## 테스트 실행 시도

```
./greeter_server_test.go:46:12: undefined: go_specs_greet.Driver
```

여기서도 여전히 TDD를 연습하고 있습니다! 첫 번째 단계가 큽니다; 몇 개의 `go` 파일을 만들고 일반적으로 익숙한 것보다 더 많은 코드를 작성해야 하지만, 처음 시작할 때 종종 그렇습니다. 빨간 단계의 규칙을 기억하려고 노력하는 것이 매우 중요합니다.

> 테스트를 통과시키기 위해 필요한 모든 죄를 저지르세요

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

코를 막으세요; 테스트가 통과하면 리팩토링할 수 있다는 것을 기억하세요. 프로젝트 루트에 배치할 `driver.go`의 드라이버 코드입니다:

```go
package go_specs_greet

import (
	"io"
	"net/http"
)

type Driver struct {
	BaseURL string
}

func (d Driver) Greet() (string, error) {
	res, err := http.Get(d.BaseURL + "/greet")
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	greeting, err := io.ReadAll(res.Body)
	if err != nil {
		return "", err
	}
	return string(greeting), nil
}
```

참고:

- 다양한 `if err != nil`을 도출하기 위해 테스트를 작성해야 한다고 주장할 수 있지만, 제 경험에 따르면 `err`로 아무것도 하지 않는 한 "받은 오류를 반환한다"라고 말하는 테스트는 상대적으로 가치가 낮습니다.
- **기본 HTTP 클라이언트를 사용해서는 안 됩니다**. 나중에 타임아웃 등으로 구성하기 위해 HTTP 클라이언트를 전달할 것이지만, 지금은 테스트를 통과시키려고 하는 것뿐입니다.

테스트를 다시 실행하면 이제 컴파일되지만 통과하지 않아야 합니다.

```
Get "http://localhost:8080/greet": dial tcp [::1]:8080: connect: connection refused
```

`Driver`가 있지만 아직 애플리케이션을 시작하지 않았으므로 HTTP 요청을 수행할 수 없습니다. 테스트가 실행되도록 시스템을 빌드, 실행 및 최종적으로 종료하는 것을 조정하는 인수 테스트가 필요합니다.

### 애플리케이션 실행

팀이 배포하기 위해 시스템의 Docker 이미지를 빌드하는 것은 일반적이므로 테스트에서도 같은 작업을 수행할 것입니다

테스트에서 Docker를 사용하는 데 도움이 되도록 [Testcontainers](https://golang.testcontainers.org)를 사용할 것입니다. Testcontainers는 Docker 이미지를 빌드하고 컨테이너 수명 주기를 관리하는 프로그래밍 방식을 제공합니다.

`go get github.com/testcontainers/testcontainers-go`

이제 `cmd/httpserver/greeter_server_test.go`를 다음과 같이 편집할 수 있습니다:

```go
package main_test

import (
	"context"
	"testing"

	"github.com/alecthomas/assert/v2"
	go_specs_greet "github.com/quii/go-specs-greet"
	"github.com/quii/go-specs-greet/specifications"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

func TestGreeterServer(t *testing.T) {
	ctx := context.Background()

	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:    "../../.",
			Dockerfile: "./cmd/httpserver/Dockerfile",
			// 스팸을 줄이려면 false로 설정하지만 문제가 있으면 도움이 됩니다
			PrintBuildLog: true,
		},
		ExposedPorts: []string{"8080:8080"},
		WaitingFor:   wait.ForHTTP("/").WithPort("8080"),
	}
	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	assert.NoError(t, err)
	t.Cleanup(func() {
		assert.NoError(t, container.Terminate(ctx))
	})

	driver := go_specs_greet.Driver{BaseURL: "http://localhost:8080"}
	specifications.GreetSpecification(t, driver)
}
```

테스트를 실행해 보세요.

```
=== RUN   TestGreeterHandler
2022/09/10 18:49:44 Starting container id: 03e8588a1be4 image: docker.io/testcontainers/ryuk:0.3.3
2022/09/10 18:49:45 Waiting for container id 03e8588a1be4 image: docker.io/testcontainers/ryuk:0.3.3
2022/09/10 18:49:45 Container is ready id: 03e8588a1be4 image: docker.io/testcontainers/ryuk:0.3.3
    greeter_server_test.go:32: Did not expect an error but got:
        Error response from daemon: Cannot locate specified Dockerfile: ./cmd/httpserver/Dockerfile: failed to create container
--- FAIL: TestGreeterHandler (0.59s)
```

프로그램을 위한 Dockerfile을 만들어야 합니다. `httpserver` 폴더 안에 `Dockerfile`을 만들고 다음을 추가하세요.

```dockerfile
# go.mod 파일과 동일한 Go 버전을 지정하세요.
# 예: golang:1.22.1-alpine.
FROM golang:1.18-alpine

WORKDIR /app

COPY go.mod ./

RUN go mod download

COPY . .

RUN go build -o svr cmd/httpserver/*.go

EXPOSE 8080
CMD [ "./svr" ]
```

여기서 세부 사항에 대해 너무 걱정하지 마세요; 나중에 개선하고 최적화할 수 있지만 이 예제에서는 충분합니다. 여기서 우리 접근 방식의 장점은 나중에 Dockerfile을 개선하고 의도한 대로 작동하는지 증명하는 테스트를 가질 수 있다는 것입니다. 이것이 블랙박스 테스트의 진정한 강점입니다!

테스트를 다시 실행해 보세요; 이미지를 빌드할 수 없다고 불평할 것입니다. 물론 빌드할 프로그램을 아직 작성하지 않았기 때문입니다!

테스트를 완전히 실행하려면 `8080`에서 수신하는 프로그램을 만들어야 하지만 **그게 전부입니다**. TDD 규율을 고수하고, 예상대로 테스트가 실패하는지 확인할 때까지 테스트를 통과시킬 프로덕션 코드를 작성하지 마세요.

`httpserver` 폴더 안에 다음과 같이 `main.go`를 만드세요

```go
package main

import (
	"log"
	"net/http"
)

func main() {
	handler := http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
	})
	if err := http.ListenAndServe(":8080", handler); err != nil {
		log.Fatal(err)
	}
}
```

테스트를 다시 실행하면 다음과 같이 실패해야 합니다.

```
    greet.go:16: Expected values to be equal:
        +Hello, World
        \ No newline at end of file
--- FAIL: TestGreeterHandler (2.09s)
```

## 테스트를 통과시키기 위한 충분한 코드 작성

명세가 원하는 대로 동작하도록 핸들러를 업데이트하세요

```go
import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		fmt.Fprint(w, "Hello, world")
	})
	if err := http.ListenAndServe(":8080", handler); err != nil {
		log.Fatal(err)
	}
}
```

## 리팩토링

기술적으로 이것은 리팩토링이 아니지만, 기본 HTTP 클라이언트에 의존해서는 안 되므로 테스트에서 제공할 클라이언트를 공급할 수 있도록 Driver를 변경합시다.

```go
import (
	"io"
	"net/http"
)

type Driver struct {
	BaseURL string
	Client  *http.Client
}

func (d Driver) Greet() (string, error) {
	res, err := d.Client.Get(d.BaseURL + "/greet")
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	greeting, err := io.ReadAll(res.Body)
	if err != nil {
		return "", err
	}
	return string(greeting), nil
}
```

`cmd/httpserver/greeter_server_test.go`의 테스트에서 클라이언트를 전달하도록 드라이버 생성을 업데이트하세요.

```go
client := http.Client{
	Timeout: 1 * time.Second,
}

driver := go_specs_greet.Driver{BaseURL: "http://localhost:8080", Client: &client}
specifications.GreetSpecification(t, driver)
```

`main.go`를 가능한 한 단순하게 유지하는 것이 좋은 관행입니다; 만들어둔 빌딩 블록을 애플리케이션으로 조립하는 것만 담당해야 합니다.

프로젝트 루트에 `handler.go`라는 파일을 만들고 코드를 거기로 이동하세요.

```go
package go_specs_greet

import (
	"fmt"
	"net/http"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "Hello, world")
}
```

대신 핸들러를 가져와서 사용하도록 `main.go`를 업데이트하세요.

```go
package main

import (
	"net/http"

	go_specs_greet "github.com/quii/go-specs-greet"
)

func main() {
	handler := http.HandlerFunc(go_specs_greet.Handler)
	http.ListenAndServe(":8080", handler)
}
```

## 반성

첫 번째 단계는 노력이 필요했습니다. 하드코딩된 문자열을 반환하는 HTTP 핸들러를 만들고 테스트하기 위해 여러 `go` 파일을 만들었습니다. 이 "반복 0" 의식과 설정은 추가 반복에 도움이 될 것입니다.

기능을 변경하는 것은 명세를 통해 구동하고 강제하는 변경 사항을 처리하여 간단하고 통제되어야 합니다. 이제 `DockerFile`과 `testcontainers`가 인수 테스트를 위해 설정되었으므로 애플리케이션 구성 방식이 변경되지 않는 한 이러한 파일을 변경할 필요가 없어야 합니다.

다음 요구 사항인 특정 사람에게 인사하기에서 이것을 볼 것입니다.

## 먼저 테스트 작성

명세를 편집하세요

```go
package specifications

import (
	"testing"

	"github.com/alecthomas/assert/v2"
)

type Greeter interface {
	Greet(name string) (string, error)
}

func GreetSpecification(t testing.TB, greeter Greeter) {
	got, err := greeter.Greet("Mike")
	assert.NoError(t, err)
	assert.Equal(t, got, "Hello, Mike")
}
```

특정 사람에게 인사할 수 있도록 시스템에 대한 인터페이스를 `name` 매개변수를 받도록 변경해야 합니다.

## 테스트 실행 시도

```
./greeter_server_test.go:48:39: cannot use driver (variable of type go_specs_greet.Driver) as type specifications.Greeter in argument to specifications.GreetSpecification:
	go_specs_greet.Driver does not implement specifications.Greeter (wrong type for Greet method)
		have Greet() (string, error)
		want Greet(name string) (string, error)
```

명세의 변경으로 드라이버를 업데이트해야 합니다.

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

특정 `name`을 인사하도록 요청하기 위해 요청에 `name` 쿼리 값을 지정하도록 드라이버를 업데이트하세요.

```go
import "io"

func (d Driver) Greet(name string) (string, error) {
	res, err := d.Client.Get(d.BaseURL + "/greet?name=" + name)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	greeting, err := io.ReadAll(res.Body)
	if err != nil {
		return "", err
	}
	return string(greeting), nil
}
```

테스트가 이제 실행되고 실패해야 합니다.

```
    greet.go:16: Expected values to be equal:
        -Hello, world
        \ No newline at end of file
        +Hello, Mike
        \ No newline at end of file
--- FAIL: TestGreeterHandler (1.92s)
```

## 테스트를 통과시키기 위한 충분한 코드 작성

요청에서 `name`을 추출하고 인사하세요.

```go
import (
	"fmt"
	"net/http"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s", r.URL.Query().Get("name"))
}
```

테스트가 이제 통과해야 합니다.

## 리팩토링

[HTTP Handlers Revisited](http-handlers-revisited.md)에서 HTTP 핸들러는 HTTP 관심사만 담당해야 한다고 논의했습니다; 어떤 "도메인 로직"도 핸들러 외부에 있어야 합니다. 이렇게 하면 HTTP와 분리하여 도메인 로직을 개발할 수 있어 테스트하고 이해하기가 더 쉬워집니다.

이러한 관심사를 분리합시다.

`./handler.go`의 핸들러를 다음과 같이 업데이트하세요:

```go
func Handler(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	fmt.Fprint(w, Greet(name))
}
```

새 파일 `./greet.go`를 만드세요:
```go
package go_specs_greet

import "fmt"

func Greet(name string) string {
	return fmt.Sprintf("Hello, %s", name)
}
```

## "어댑터" 디자인 패턴으로의 약간의 우회

이제 사람들에게 인사하는 도메인 로직을 별도의 함수로 분리했으므로 greet 함수에 대한 단위 테스트를 작성할 수 있습니다. 이것은 드라이버를 통해 웹 서버에 도달하는 명세를 통해 테스트하는 것보다 의심할 여지 없이 훨씬 간단합니다!

여기서도 명세를 재사용할 수 있다면 좋지 않을까요? 결국 명세의 요점은 구현 세부 정보에서 분리되었다는 것입니다. 명세가 **본질적 복잡성**을 캡처하고 "도메인" 코드가 그것을 모델링해야 한다면 함께 사용할 수 있어야 합니다.

`./greet_test.go`를 다음과 같이 만들어 시도해 봅시다:

```go
package go_specs_greet_test

import (
	"testing"

	go_specs_greet "github.com/quii/go-specs-greet"
	"github.com/quii/go-specs-greet/specifications"
)

func TestGreet(t *testing.T) {
	specifications.GreetSpecification(t, go_specs_greet.Greet)
}

```

좋겠지만 작동하지 않습니다

```
./greet_test.go:11:39: cannot use go_specs_greet.Greet (value of type func(name string) string) as type specifications.Greeter in argument to specifications.GreetSpecification:
	func(name string) string does not implement specifications.Greeter (missing Greet method)
```

명세는 함수가 아닌 `Greet()` 메서드가 있는 것을 원합니다.

컴파일 오류가 답답합니다; `Greeter`라고 "알고 있는" 것이 있지만 컴파일러가 사용할 수 있는 올바른 **형태**가 아닙니다. 이것이 **어댑터** 패턴이 해결하는 것입니다.

> [소프트웨어 엔지니어링](https://en.wikipedia.org/wiki/Software_engineering)에서 **어댑터 패턴**은 기존 [클래스](https://en.wikipedia.org/wiki/Class_(computer_science))의 [인터페이스](https://en.wikipedia.org/wiki/Interface_(computer_science))를 다른 인터페이스로 사용할 수 있게 해주는 [소프트웨어 디자인 패턴](https://en.wikipedia.org/wiki/Software_design_pattern)입니다.

디자인 패턴의 경우 종종 그렇듯이 비교적 간단한 것에 대한 많은 멋진 단어입니다. 그래서 사람들이 눈을 굴리는 경향이 있습니다. 디자인 패턴의 가치는 특정 구현이 아니라 엔지니어들이 직면하는 일반적인 문제에 대한 특정 솔루션을 설명하는 언어입니다.

`./specifications/adapters.go`에 이 코드를 추가하세요

```go
type GreetAdapter func(name string) string

func (g GreetAdapter) Greet(name string) (string, error) {
	return g(name), nil
}
```

이제 테스트에서 어댑터를 사용하여 `Greet` 함수를 명세에 연결할 수 있습니다.

```go
func TestGreet(t *testing.T) {
	specifications.GreetSpecification(
		t,
		specifications.GreetAdapter(gospecsgreet.Greet),
	)
}
```

어댑터 패턴은 인터페이스가 원하는 동작을 보여주지만 올바른 형태가 아닌 타입이 있을 때 유용합니다.

## 반성

동작 변경이 간단하게 느껴졌죠? 좋아요, 문제의 특성 때문일 수도 있지만, 이 작업 방법은 시스템을 위에서 아래로 변경하는 규율과 간단하고 반복 가능한 방법을 제공합니다:

- 문제를 분석하고 올바른 방향으로 밀어주는 시스템에 대한 약간의 개선 식별
- 명세에서 새로운 본질적 복잡성 캡처
- AT가 실행될 때까지 컴파일 오류 따르기
- 명세에 따라 시스템이 동작하도록 구현 업데이트
- 리팩토링

첫 번째 반복의 고통 후에 명세, 드라이버 및 구현의 분리가 있기 때문에 인수 테스트 코드를 편집할 필요가 없었습니다. 명세를 변경하려면 드라이버를 업데이트하고 마지막으로 구현을 업데이트해야 했지만, 시스템을 컨테이너로 스핀업하는 _방법_에 대한 보일러플레이트 코드는 영향을 받지 않았습니다.

**전체** 애플리케이션을 테스트하기 위해 Docker 이미지를 빌드하고 컨테이너를 스핀업하는 오버헤드가 있더라도 피드백 루프는 매우 빡빡합니다:

```
quii@Chriss-MacBook-Pro go-specs-greet % go test ./...
ok  	github.com/quii/go-specs-greet	0.181s
ok  	github.com/quii/go-specs-greet/cmd/httpserver	2.221s
?   	github.com/quii/go-specs-greet/specifications	[no test files]
```

이제 CTO가 gRPC가 _미래_라고 결정했다고 상상해 보세요. 기존 HTTP 서버를 유지하면서 gRPC 서버를 통해 동일한 기능을 노출하기를 원합니다.

이것은 **우발적 복잡성**의 예입니다. 기억하세요, 우발적 복잡성은 네트워크, 디스크, API 등 컴퓨터로 작업하기 때문에 처리해야 하는 복잡성입니다. **본질적 복잡성은 변경되지 않았으므로** 명세를 변경할 필요가 없습니다.

많은 리포지토리 구조와 디자인 패턴은 주로 복잡성 유형을 분리하는 것을 다룹니다. 예를 들어, "포트와 어댑터"는 도메인 코드를 우발적 복잡성과 관련된 것에서 분리하도록 요청합니다; 해당 코드는 "어댑터" 폴더에 있습니다.

### 변경을 쉽게 만들기

때때로 변경하기 _전에_ 리팩토링을 하는 것이 합리적입니다.

> 먼저 변경을 쉽게 만들고, 그런 다음 쉬운 변경을 하세요

~Kent Beck

그 이유로 `http` 코드 - `driver.go`와 `handler.go` - 를 `adapters` 폴더 내의 `httpserver`라는 패키지로 이동하고 패키지 이름을 `httpserver`로 변경합시다.

프로젝트 트리는 이제 다음과 같아야 합니다:

```
quii@Chriss-MacBook-Pro go-specs-greet % tree
.
├── Makefile
├── README.md
├── adapters
│   └── httpserver
│       ├── driver.go
│       └── handler.go
├── cmd
│   └── httpserver
|       ├── Dockerfile
│       ├── greeter_server_test.go
│       └── main.go
├── domain
│   └── interactions
│       ├── greet.go
│       └── greet_test.go
├── go.mod
├── go.sum
└── specifications
    └── adapters.go
    └── greet.go

```

도메인 코드인 **본질적 복잡성**은 Go 모듈의 루트에 있고, "실제 세계"에서 사용할 수 있게 해주는 코드는 **어댑터**로 구성됩니다. `cmd` 폴더는 이러한 논리적 그룹을 모두 작동하는지 확인하는 블랙박스 테스트가 있는 실제 애플리케이션으로 구성할 수 있는 곳입니다. 좋습니다!

마지막으로, 인수 테스트를 약간 정리할 수 있습니다. 인수 테스트의 상위 수준 단계를 고려하면:

- Docker 이미지 빌드
- _어떤_ 포트에서 수신 대기할 때까지 대기
- DSL을 시스템별 호출로 변환하는 방법을 이해하는 드라이버 만들기
- 드라이버를 명세에 연결

... gRPC 서버에 대한 인수 테스트에도 동일한 요구 사항이 있다는 것을 깨닫게 됩니다!

`adapters` 폴더가 적절한 장소 같으므로, `docker.go`라는 파일 안에 다음에 재사용할 처음 두 단계를 캡슐화하세요.

```go
package adapters

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/alecthomas/assert/v2"
	"github.com/docker/go-connections/nat"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

func StartDockerServer(
	t testing.TB,
	port string,
	dockerFilePath string,
) {
	ctx := context.Background()
	t.Helper()
	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:       "../../.",
			Dockerfile:    dockerFilePath,
			PrintBuildLog: true,
		},
		ExposedPorts: []string{fmt.Sprintf("%s:%s", port, port)},
		WaitingFor:   wait.ForListeningPort(nat.Port(port)).WithStartupTimeout(5 * time.Second),
	}
	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	assert.NoError(t, err)
	t.Cleanup(func() {
		assert.NoError(t, container.Terminate(ctx))
	})
}
```

이것은 인수 테스트를 약간 정리할 수 있는 기회를 제공합니다

```go
func TestGreeterServer(t *testing.T) {
	var (
		port           = "8080"
		dockerFilePath = "./cmd/httpserver/Dockerfile"
		baseURL        = fmt.Sprintf("http://localhost:%s", port)
		driver         = httpserver.Driver{BaseURL: baseURL, Client: &http.Client{
			Timeout: 1 * time.Second,
		}}
	)

	adapters.StartDockerServer(t, port, dockerFilePath)
	specifications.GreetSpecification(t, driver)
}
```

이것은 _다음_ 테스트 작성을 더 간단하게 만들어야 합니다.

## 먼저 테스트 작성

이 새로운 기능은 도메인 코드와 상호 작용하기 위한 새 `adapter`를 만들어 수행할 수 있습니다. 그 이유로:

- 명세를 변경할 필요가 없어야 합니다;
- 명세를 재사용할 수 있어야 합니다;
- 도메인 코드를 재사용할 수 있어야 합니다.

새 프로그램과 해당 인수 테스트를 담을 `cmd` 안에 새 폴더 `grpcserver`를 만드세요. `cmd/grpc_server/greeter_server_test.go` 안에 HTTP 서버 테스트와 매우 유사한 인수 테스트를 추가하세요. 이것은 우연이 아니라 설계에 의한 것입니다.

```go
package main_test

import (
	"fmt"
	"testing"

	"github.com/quii/go-specs-greet/adapters"
	"github.com/quii/go-specs-greet/adapters/grpcserver"
	"github.com/quii/go-specs-greet/specifications"
)

func TestGreeterServer(t *testing.T) {
	var (
		port           = "50051"
		dockerFilePath = "./cmd/grpcserver/Dockerfile"
		driver         = grpcserver.Driver{Addr: fmt.Sprintf("localhost:%s", port)}
	)

	adapters.StartDockerServer(t, port, dockerFilePath)
	specifications.GreetSpecification(t, &driver)
}
```

유일한 차이점은:

- 다른 Docker 파일을 사용합니다. 다른 프로그램을 빌드하기 때문입니다
- 이것은 새 `Driver`가 필요하다는 것을 의미합니다. `gRPC`를 사용하여 새 프로그램과 상호 작용합니다

## 테스트 실행 시도

```
./greeter_server_test.go:26:12: undefined: grpcserver
```

아직 `Driver`를 만들지 않았으므로 컴파일되지 않습니다.

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

`adapters` 안에 `grpcserver` 폴더를 만들고 그 안에 `driver.go`를 만드세요

```go
package grpcserver

type Driver struct {
	Addr string
}

func (d Driver) Greet(name string) (string, error) {
	return "", nil
}
```

다시 실행하면 이제 _컴파일_되지만 Dockerfile과 해당 프로그램을 만들지 않았기 때문에 통과하지 않습니다.

`cmd/grpcserver` 안에 새 `Dockerfile`을 만드세요.

```dockerfile
FROM golang:1.18-alpine

WORKDIR /app

COPY go.mod ./

RUN go mod download

COPY . .

RUN go build -o svr cmd/grpcserver/*.go

EXPOSE 50051
CMD [ "./svr" ]
```

그리고 `main.go`

```go
package main

import "fmt"

func main() {
	fmt.Println("implement me")
}
```

이제 서버가 포트에서 수신하지 않기 때문에 테스트가 실패하는 것을 확인할 수 있습니다. 이제 gRPC로 클라이언트와 서버를 빌드할 시간입니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

### gRPC

gRPC에 익숙하지 않다면 [gRPC 웹사이트](https://grpc.io)를 먼저 살펴보는 것이 좋습니다. 하지만 이 챕터에서는 시스템에 대한 또 다른 종류의 어댑터일 뿐입니다. 다른 시스템이 우리의 훌륭한 도메인 코드를 호출(**r**emote **p**rocedure **c**all)할 수 있는 방법입니다.

특이한 점은 Protocol Buffers를 사용하여 "서비스 정의"를 정의한다는 것입니다. 그런 다음 정의에서 서버 및 클라이언트 코드를 생성합니다. 이것은 Go뿐만 아니라 대부분의 주류 언어에도 작동합니다. 이것은 Go를 작성하지 않을 수도 있는 회사의 다른 팀과 정의를 공유하고 여전히 서비스 간 통신을 원활하게 수행할 수 있음을 의미합니다.

이전에 gRPC를 사용하지 않았다면 **Protocol buffer 컴파일러**와 일부 **Go 플러그인**을 설치해야 합니다. [gRPC 웹사이트에 이를 수행하는 방법에 대한 명확한 지침이 있습니다](https://grpc.io/docs/languages/go/quickstart/).

새 드라이버와 같은 폴더 안에 다음과 함께 `greet.proto` 파일을 추가하세요

```protobuf
syntax = "proto3";

option go_package = "github.com/quii/adapters/grpcserver";

package grpcserver;

service Greeter {
  rpc Greet (GreetRequest) returns (GreetReply) {}
}

message GreetRequest {
  string name = 1;
}

message GreetReply {
  string message = 1;
}
```

이 정의를 이해하기 위해 Protocol Buffers 전문가가 될 필요는 없습니다. Greet 메서드가 있는 서비스를 정의한 다음 들어오는 메시지 유형과 나가는 메시지 유형을 설명합니다.

`adapters/grpcserver` 안에서 다음을 실행하여 클라이언트 및 서버 코드를 생성하세요

```
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    greet.proto
```

작동했다면 사용할 코드가 생성되었을 것입니다. `Driver` 안의 생성된 클라이언트 코드를 사용하여 시작합시다.

```go
package grpcserver

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type Driver struct {
	Addr string
}

func (d Driver) Greet(name string) (string, error) {
	conn, err := grpc.Dial(d.Addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return "", err
	}
	defer conn.Close()

	client := NewGreeterClient(conn)
	greeting, err := client.Greet(context.Background(), &GreetRequest{
		Name: name,
	})
	if err != nil {
		return "", err
	}

	return greeting.Message, nil
}
```

이제 클라이언트가 있으므로 서버를 만들기 위해 `main.go`를 업데이트해야 합니다. 기억하세요, 이 시점에서는 테스트를 통과시키려고 하는 것뿐이며 코드 품질에 대해 걱정하지 않습니다.

```go
package main

import (
	"context"
	"log"
	"net"

	"github.com/quii/go-specs-greet/adapters/grpcserver"
	"google.golang.org/grpc"
)

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal(err)
	}
	s := grpc.NewServer()
	grpcserver.RegisterGreeterServer(s, &GreetServer{})

	if err := s.Serve(lis); err != nil {
		log.Fatal(err)
	}
}

type GreetServer struct {
	grpcserver.UnimplementedGreeterServer
}

func (g GreetServer) Greet(ctx context.Context, request *grpcserver.GreetRequest) (*grpcserver.GreetReply, error) {
	return &grpcserver.GreetReply{Message: "fixme"}, nil
}
```

테스트가 이제 통과해야 합니다! 분명히 `"fixme"`는 메시지에 보내고 싶은 것이 아니므로 도메인 코드를 호출합시다

```go
func (g GreetServer) Greet(ctx context.Context, request *grpcserver.GreetRequest) (*grpcserver.GreetReply, error) {
	return &grpcserver.GreetReply{Message: interactions.Greet(request.Name)}, nil
}
```

마침내 통과합니다! gRPC greet 서버가 원하는 대로 동작한다는 것을 증명하는 인수 테스트가 있습니다.

## 리팩토링

테스트를 통과시키기 위해 여러 죄를 저질렀지만 이제 통과했으므로 리팩토링할 안전망이 있습니다.

### main 단순화

이전처럼 `main` 안에 너무 많은 코드를 넣고 싶지 않습니다. 새 `GreetServer`를 `adapters/grpcserver`로 이동할 수 있습니다. 응집성 측면에서 서비스 정의를 변경하면 코드의 해당 영역에 변경의 "폭발 반경"을 제한하고 싶습니다.

### 드라이버에서 매번 다시 연결하지 마세요

테스트가 하나뿐이지만 명세를 확장하면(확장할 것입니다) 매 RPC 호출마다 Driver가 다시 연결하는 것은 의미가 없습니다.

```go
package grpcserver

import (
	"context"
	"sync"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type Driver struct {
	Addr string

	connectionOnce sync.Once
	conn           *grpc.ClientConn
	client         GreeterClient
}

func (d *Driver) Greet(name string) (string, error) {
	client, err := d.getClient()
	if err != nil {
		return "", err
	}

	greeting, err := client.Greet(context.Background(), &GreetRequest{
		Name: name,
	})
	if err != nil {
		return "", err
	}

	return greeting.Message, nil
}

func (d *Driver) getClient() (GreeterClient, error) {
	var err error
	d.connectionOnce.Do(func() {
		d.conn, err = grpc.Dial(d.Addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
		d.client = NewGreeterClient(d.conn)
	})
	return d.client, err
}
```

여기서 [`sync.Once`](https://pkg.go.dev/sync#Once)를 사용하여 `Driver`가 서버에 대한 연결을 한 번만 만들려고 하도록 합니다.

계속 진행하기 전에 현재 프로젝트 구조 상태를 살펴봅시다.

```
quii@Chriss-MacBook-Pro go-specs-greet % tree
.
├── Makefile
├── README.md
├── adapters
│   ├── docker.go
│   ├── grpcserver
│   │   ├── driver.go
│   │   ├── greet.pb.go
│   │   ├── greet.proto
│   │   ├── greet_grpc.pb.go
│   │   └── server.go
│   └── httpserver
│       ├── driver.go
│       └── handler.go
├── cmd
│   ├── grpcserver
│   │   ├── Dockerfile
│   │   ├── greeter_server_test.go
│   │   └── main.go
│   └── httpserver
│       ├── Dockerfile
│       ├── greeter_server_test.go
│       └── main.go
├── domain
│   └── interactions
│       ├── greet.go
│       └── greet_test.go
├── go.mod
├── go.sum
└── specifications
    └── greet.go
```

- `adapters`는 응집력 있는 기능 단위를 함께 그룹화합니다
- `cmd`는 애플리케이션과 해당 인수 테스트를 담습니다
- 코드는 우발적 복잡성과 완전히 분리됩니다

### `Dockerfile` 통합

두 `Dockerfiles`가 거의 동일하다는 것을 알았을 것입니다. 빌드하려는 바이너리 경로를 제외하고요.

`Dockerfiles`는 다른 컨텍스트에서 재사용할 수 있도록 인수를 받을 수 있습니다. 완벽하게 들립니다. 2개의 Dockerfile을 삭제하고 대신 프로젝트 루트에 다음과 같은 하나를 가질 수 있습니다

```dockerfile
FROM golang:1.18-alpine

WORKDIR /app

ARG bin_to_build

COPY go.mod ./

RUN go mod download

COPY . .

RUN go build -o svr cmd/${bin_to_build}/main.go

CMD [ "./svr" ]
```

이미지를 빌드할 때 인수를 전달하려면 `StartDockerServer` 함수를 업데이트해야 합니다

```go
func StartDockerServer(
	t testing.TB,
	port string,
	binToBuild string,
) {
	ctx := context.Background()
	t.Helper()
	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:    "../../.",
			Dockerfile: "Dockerfile",
			BuildArgs: map[string]*string{
				"bin_to_build": &binToBuild,
			},
			PrintBuildLog: true,
		},
		ExposedPorts: []string{fmt.Sprintf("%s:%s", port, port)},
		WaitingFor:   wait.ForListeningPort(nat.Port(port)).WithStartupTimeout(5 * time.Second),
	}
	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	assert.NoError(t, err)
	t.Cleanup(func() {
		assert.NoError(t, container.Terminate(ctx))
	})
}
```

마지막으로, 빌드할 이미지를 전달하도록 테스트를 업데이트하세요 (다른 테스트에도 이것을 하고 `grpcserver`를 `httpserver`로 변경하세요).

```go
func TestGreeterServer(t *testing.T) {
	var (
		port   = "50051"
		driver = grpcserver.Driver{Addr: fmt.Sprintf("localhost:%s", port)}
	)

	adapters.StartDockerServer(t, port, "grpcserver")
	specifications.GreetSpecification(t, &driver)
}
```

### 다른 종류의 테스트 분리

인수 테스트는 전체 시스템이 순수하게 사용자 관점, 동작적 POV에서 작동하는지 테스트한다는 점에서 훌륭하지만 단위 테스트에 비해 단점이 있습니다:

- 느림
- 피드백 품질이 종종 단위 테스트만큼 집중되지 않음
- 내부 품질이나 설계에 도움이 되지 않음

[테스트 피라미드](https://martinfowler.com/articles/practical-test-pyramid.html)는 테스트 스위트에 원하는 종류의 믹스에 대해 안내합니다. 자세한 내용은 Fowler의 게시물을 읽어보세요. 하지만 이 게시물의 매우 단순화된 요약은 "많은 단위 테스트와 약간의 인수 테스트"입니다.

그 이유로 프로젝트가 성장하면 인수 테스트가 실행하는 데 몇 분이 걸릴 수 있는 상황에 자주 처할 수 있습니다. 프로젝트를 체크아웃하는 사람들에게 친숙한 개발자 경험을 제공하려면 개발자가 다른 종류의 테스트를 별도로 실행할 수 있도록 할 수 있습니다.

`go test ./...`를 실행하면 Go 컴파일러(물론)와 아마도 Docker와 같은 몇 가지 핵심 종속성 외에 엔지니어의 추가 설정 없이 실행할 수 있는 것이 바람직합니다.

Go는 엔지니어가 [short 플래그](https://pkg.go.dev/testing#Short)로 "짧은" 테스트만 실행할 수 있는 메커니즘을 제공합니다

`go test -short ./...`

플래그 값을 검사하여 사용자가 인수 테스트를 실행하려는지 확인하기 위해 인수 테스트에 추가할 수 있습니다

```go
if testing.Short() {
	t.Skip()
}
```

이 사용법을 보여주기 위해 `Makefile`을 만들었습니다

```makefile
build:
	golangci-lint run
	go test ./...

unit-tests:
	go test -short ./...
```

### 언제 인수 테스트를 작성해야 할까요?

모범 사례는 빠르게 실행되는 많은 단위 테스트와 몇 가지 인수 테스트를 선호하는 것이지만 단위 테스트 대 인수 테스트를 작성해야 할 때 어떻게 결정합니까?

구체적인 규칙을 제공하기 어렵지만 제가 일반적으로 스스로에게 묻는 질문은:

- 이것이 엣지 케이스입니까? 단위 테스트를 선호합니다
- 이것이 비컴퓨터 사람들이 많이 이야기하는 것입니까? 핵심적인 것이 "정말로" 작동한다는 많은 확신을 갖고 싶으므로 인수 테스트를 추가하겠습니다
- 특정 함수가 아닌 사용자 여정을 설명하고 있습니까? 인수 테스트
- 단위 테스트가 충분한 확신을 줄까요? 때때로 이미 인수 테스트가 있는 기존 여정을 취하지만 다른 입력으로 인해 다른 시나리오를 처리하기 위해 다른 기능을 추가하고 있습니다. 이 경우 다른 인수 테스트를 추가하면 비용이 추가되지만 가치는 거의 없으므로 일부 단위 테스트를 선호합니다.

## 작업 반복

이 모든 노력으로 시스템을 확장하는 것이 이제 간단해지기를 바랍니다. 작업하기 쉬운 시스템을 만드는 것이 반드시 쉬운 것은 아니지만 시간을 들일 가치가 있으며 프로젝트를 시작할 때 하기가 훨씬 쉽습니다.

API를 확장하여 "curse" 기능을 포함하도록 합시다.

## 먼저 테스트 작성

이것은 완전히 새로운 동작이므로 인수 테스트로 시작해야 합니다. 명세 파일에 다음을 추가하세요

```go
type MeanGreeter interface {
	Curse(name string) (string, error)
}

func CurseSpecification(t *testing.T, meany MeanGreeter) {
	got, err := meany.Curse("Chris")
	assert.NoError(t, err)
	assert.Equal(t, got, "Go to hell, Chris!")
}
```

인수 테스트 중 하나를 선택하고 명세를 사용하려고 하세요

```go
func TestGreeterServer(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	var (
		port   = "50051"
		driver = grpcserver.Driver{Addr: fmt.Sprintf("localhost:%s", port)}
	)

	t.Cleanup(driver.Close)
	adapters.StartDockerServer(t, port, "grpcserver")
	specifications.GreetSpecification(t, &driver)
	specifications.CurseSpecification(t, &driver)
}
```

## 테스트 실행 시도

```
# github.com/quii/go-specs-greet/cmd/grpcserver_test [github.com/quii/go-specs-greet/cmd/grpcserver.test]
./greeter_server_test.go:27:39: cannot use &driver (value of type *grpcserver.Driver) as type specifications.MeanGreeter in argument to specifications.CurseSpecification:
	*grpcserver.Driver does not implement specifications.MeanGreeter (missing Curse method)
```

`Driver`가 아직 `Curse`를 지원하지 않습니다.

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

테스트를 실행하려는 것이므로 `Driver`에 메서드를 추가하세요

```go
func (d *Driver) Curse(name string) (string, error) {
	return "", nil
}
```

다시 시도하면 테스트가 컴파일되고 실행되고 실패해야 합니다

```
greet.go:26: Expected values to be equal:
+Go to hell, Chris!
\ No newline at end of file
```

## 테스트를 통과시키기 위한 충분한 코드 작성

Protocol Buffer 명세를 업데이트하여 `Curse` 메서드를 추가한 다음 코드를 다시 생성해야 합니다.

```protobuf
service Greeter {
  rpc Greet (GreetRequest) returns (GreetReply) {}
  rpc Curse (GreetRequest) returns (GreetReply) {}
}
```

`adapters/grpcserver` 안에서 코드를 다시 생성하세요.

```
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    greet.proto
```

### 드라이버 업데이트

이제 클라이언트 코드가 업데이트되었으므로 `Driver`에서 `Curse`를 호출할 수 있습니다

```go
func (d *Driver) Curse(name string) (string, error) {
	client, err := d.getClient()
	if err != nil {
		return "", err
	}

	greeting, err := client.Curse(context.Background(), &GreetRequest{
		Name: name,
	})
	if err != nil {
		return "", err
	}

	return greeting.Message, nil
}
```

### 서버 업데이트

마지막으로 `Server`에 `Curse` 메서드를 추가해야 합니다

```go
func (g GreetServer) Curse(ctx context.Context, request *GreetRequest) (*GreetReply, error) {
	return &GreetReply{Message: fmt.Sprintf("Go to hell, %s!", request.Name)}, nil
}
```

테스트가 이제 통과해야 합니다.

## 리팩토링

직접 시도해 보세요.

- `Greet`에서 했던 것처럼 `Curse` "도메인 로직"을 gRPC 서버에서 추출하세요. 도메인 로직에 대한 단위 테스트로 명세를 사용하세요
- protobuf에서 다른 타입을 사용하여 `Greet`와 `Curse`의 메시지 타입이 분리되도록 하세요.

## HTTP 서버에 `Curse` 구현

다시 말하지만, 독자를 위한 연습입니다. 도메인 수준 명세와 도메인 수준 로직이 깔끔하게 분리되어 있습니다. 이 챕터를 따라왔다면 매우 간단해야 합니다.

- HTTP 서버의 기존 인수 테스트에 명세 추가
- `Driver` 업데이트
- 서버에 새 엔드포인트를 추가하고 도메인 코드를 재사용하여 기능 구현. 별도의 엔드포인트로 라우팅을 처리하려면 `http.NewServeMux`를 사용하는 것이 좋습니다.

작은 단계로 작업하고, 자주 커밋하고 테스트를 실행하는 것을 기억하세요. 정말 막히면 [GitHub에서 내 구현을 찾을 수 있습니다](https://github.com/quii/go-specs-greet).

## 단위 테스트로 도메인 로직을 업데이트하여 두 시스템 모두 향상

언급했듯이 시스템에 대한 모든 변경이 인수 테스트를 통해 구동되어야 하는 것은 아닙니다. 비즈니스 규칙의 순열과 엣지 케이스는 관심사를 잘 분리한 경우 단위 테스트를 통해 간단하게 구동해야 합니다.

`name`이 비어 있으면 `name`을 `World`로 기본 설정하는 `Greet` 함수에 단위 테스트를 추가하세요. 이것이 얼마나 간단한지 알 수 있으며, 비즈니스 규칙이 두 애플리케이션에 "무료로" 반영됩니다.

## 마무리

합리적인 변경 비용으로 시스템을 구축하려면 AT가 유지 관리 부담이 아닌 도움이 되도록 엔지니어링해야 합니다. GOOS가 말하듯이 체계적으로 소프트웨어를 안내하거나 "성장"시키는 수단으로 사용될 수 있습니다.

이 예제를 통해 변경을 구동하는 예측 가능하고 체계적인 워크플로와 작업에 사용할 수 있는 방법을 볼 수 있기를 바랍니다.

작업하는 시스템을 어떤 방식으로 확장하려는 이해 관계자와 대화하는 것을 상상할 수 있습니다. 도메인 중심, 구현에 구애받지 않는 방식으로 명세에 캡처하고 노력의 북극성으로 사용하세요. Riya와 저는 [GopherconUK 강연](https://www.youtube.com/watch?v=ZMWJCk_0WrY)에서 "Example Mapping"과 같은 BDD 기법을 활용하여 본질적 복잡성을 더 깊이 이해하고 더 자세하고 의미 있는 명세를 작성할 수 있도록 하는 것을 설명합니다.

본질적 복잡성과 우발적 복잡성 관심사를 분리하면 작업이 덜 임시적이고 더 체계적이고 신중해집니다; 이것은 인수 테스트의 탄력성을 보장하고 유지 관리 부담이 덜 됩니다.

Dave Farley는 훌륭한 팁을 제공합니다:

> 문제 도메인을 이해하는 가장 기술적이지 않은 사람이 인수 테스트를 읽는 것을 상상하세요. 테스트가 그 사람에게 말이 되어야 합니다.

명세는 문서로도 두 배가 되어야 합니다. 시스템이 어떻게 동작해야 하는지 명확하게 지정해야 합니다. 이 아이디어는 [Cucumber](https://cucumber.io)와 같은 도구의 원리입니다. 동작을 코드로 캡처하기 위한 DSL을 제공하고 여기서 했던 것처럼 해당 DSL을 시스템 호출로 변환합니다.

### 다룬 내용

- 추상 명세를 작성하면 해결하려는 문제의 본질적 복잡성을 표현하고 우발적 복잡성을 제거할 수 있습니다. 이렇게 하면 다른 컨텍스트에서 명세를 재사용할 수 있습니다.
- [Testcontainers](https://golang.testcontainers.org)를 사용하여 AT용 시스템 수명 주기를 관리하는 방법. 이렇게 하면 컴퓨터에서 배송하려는 이미지를 철저히 테스트하고 빠른 피드백과 확신을 얻을 수 있습니다.
- Docker로 애플리케이션 컨테이너화에 대한 간략한 소개
- gRPC
- 정형화된 폴더 구조를 쫓기보다는 개발 접근 방식을 사용하여 자신의 필요에 따라 애플리케이션 구조를 자연스럽게 도출할 수 있습니다

### 추가 자료

- 이 예제에서 "DSL"은 별거 아닙니다; 명세를 실제 세계에서 분리하고 도메인 로직을 깔끔하게 표현할 수 있도록 인터페이스를 사용했습니다. 시스템이 성장하면 이 추상화 수준이 투박하고 불명확해질 수 있습니다. 명세를 구조화하는 방법에 대한 더 많은 아이디어를 원하면 ["Screenplay Pattern"에 대해 읽어보세요](https://cucumber.io/blog/bdd/understanding-screenplay-(part-1)/).
- 강조하자면, [Growing Object-Oriented Software, Guided by Tests](http://www.growing-object-oriented-software.com)는 고전입니다. "런던 스타일", "하향식" 접근 방식을 소프트웨어 작성에 적용하는 것을 보여줍니다. Learn Go with Tests를 즐긴 사람은 GOOS를 읽어서 많은 가치를 얻어야 합니다.
- [예제 코드 리포지토리](https://github.com/quii/go-specs-greet)에는 여기서 작성하지 않은 더 많은 코드와 아이디어가 있습니다. 예를 들어 멀티 스테이지 Docker 빌드 등을 확인하고 싶을 수 있습니다.
  - 특히 *재미로* **세 번째 프로그램**, `Greet`와 `Curse`를 위한 HTML 폼이 있는 웹사이트를 만들었습니다. `Driver`는 훌륭해 보이는 [https://github.com/go-rod/rod](https://github.com/go-rod/rod) 모듈을 활용하여 사용자처럼 브라우저로 웹사이트와 작업할 수 있게 합니다. git 히스토리를 보면 "작동하게 만들기" 위해 템플릿 도구를 사용하지 않고 시작한 것을 볼 수 있습니다. 그런 다음 인수 테스트를 통과하면 두려움 없이 자유롭게 그렇게 할 수 있었습니다.



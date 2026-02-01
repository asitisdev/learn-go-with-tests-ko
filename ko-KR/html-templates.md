# HTML 템플릿

**[이 챕터의 모든 코드는 여기에서 확인할 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/blogrenderer)**

우리는 모든 사람이 기가바이트의 트랜스파일된 JavaScript 위에 구축된 이달의 최신 프론트엔드 프레임워크로 웹 애플리케이션을 구축하고 싶어하는 세상에 살고 있습니다. 비잔틴식 빌드 시스템으로 작업하지만; [그것이 항상 필요한 것은 아닐 수 있습니다](https://quii.dev/The_Web_I_Want).

대부분의 Go 개발자는 간단하고 안정적이며 빠른 도구 체인을 중요시하지만 프론트엔드 세계는 종종 이 측면에서 실패합니다.

많은 웹사이트가 [SPA](https://en.wikipedia.org/wiki/Single-page_application)일 필요가 없습니다. **HTML과 CSS는 콘텐츠를 전달하는 환상적인 방법**이며 Go를 사용하여 HTML을 전달하는 웹사이트를 만들 수 있습니다.

여전히 일부 동적 요소를 원한다면 클라이언트 측 JavaScript를 약간 뿌릴 수 있으며, 서버 측 접근 방식으로 동적 경험을 제공할 수 있는 [Hotwire](https://hotwired.dev)를 실험해 볼 수도 있습니다.

[`fmt.Fprintf`](https://pkg.go.dev/fmt#Fprintf)의 정교한 사용으로 Go에서 HTML을 생성할 수 있지만, 이 챕터에서는 Go의 표준 라이브러리에 HTML을 더 간단하고 유지 관리하기 쉬운 방식으로 생성하는 도구가 있다는 것을 배울 것입니다. 또한 이전에 경험하지 못했을 수 있는 이러한 종류의 코드를 테스트하는 더 효과적인 방법을 배울 것입니다.

## 만들 것

[파일 읽기](/reading-files.md) 챕터에서 [`fs.FS`](https://pkg.go.dev/io/fs) (파일 시스템)을 받아 발견한 각 마크다운 파일에 대해 `Post` 슬라이스를 반환하는 코드를 작성했습니다.

```go
posts, err := blogposts.NewPostsFromFS(os.DirFS("posts"))
```

다음은 `Post`를 정의한 방법입니다

```go
type Post struct {
	Title, Description, Body string
	Tags                     []string
}
```

다음은 파싱할 수 있는 마크다운 파일의 예입니다.

```markdown
Title: Welcome to my blog
Description: Introduction to my blog
Tags: cooking, family, live-laugh-love
---
# First recipe!
Welcome to my **amazing recipe blog**. I am going to write about my family recipes, and make sure I write a long, irrelevant and boring story about my family before you get to the actual instructions.
```

블로그 소프트웨어 작성 여정을 계속한다면, 이 데이터를 가져와서 HTTP 요청에 대한 응답으로 웹 서버가 반환할 HTML을 생성할 것입니다.

블로그를 위해 두 종류의 페이지를 생성하고 싶습니다:

1. **게시물 보기**. 특정 게시물을 렌더링합니다. `Post`의 `Body` 필드는 마크다운이 포함된 문자열이므로 HTML로 변환해야 합니다.
2. **인덱스**. 모든 게시물을 나열하고 특정 게시물을 볼 수 있는 하이퍼링크가 있습니다.

또한 사이트 전체에서 일관된 모양과 느낌을 원하므로 각 페이지에는 CSS 스타일시트에 대한 링크와 원하는 다른 것들이 포함된 `<html>` 및 `<head>`와 같은 일반적인 HTML 요소가 있을 것입니다.

블로그 소프트웨어를 구축할 때 사용자의 브라우저에 HTML을 빌드하고 보내는 방법에 대한 몇 가지 옵션이 있습니다.

`io.Writer`를 받아들이도록 코드를 설계할 것입니다. 이것은 코드 호출자에게 유연성을 제공합니다:

- [os.File](https://pkg.go.dev/os#File)에 작성하여 정적으로 제공될 수 있도록 합니다
- HTML을 [`http.ResponseWriter`](https://pkg.go.dev/net/http#ResponseWriter)에 직접 작성합니다
- 또는 무엇이든 작성합니다! `io.Writer`를 구현하기만 하면 사용자는 `Post`에서 일부 HTML을 생성할 수 있습니다

## 먼저 테스트 작성

항상 그렇듯이 너무 빨리 뛰어들기 전에 요구 사항에 대해 생각하는 것이 중요합니다. 이 상당히 큰 요구 사항 세트를 가져다가 집중할 수 있는 작고 달성 가능한 단계로 어떻게 분해할 수 있을까요?

제 관점에서 실제로 콘텐츠를 보는 것이 인덱스 페이지보다 우선 순위가 높습니다. 우리는 이 제품을 출시하고 훌륭한 콘텐츠에 대한 직접 링크를 공유할 수 있습니다. 실제 콘텐츠에 연결할 수 없는 인덱스 페이지는 유용하지 않습니다.

그래도 앞서 설명한 대로 게시물을 렌더링하는 것은 여전히 크게 느껴집니다. 모든 HTML 요소, 본문 마크다운을 HTML로 변환, 태그 나열 등.

이 단계에서는 특정 마크업에 대해 지나치게 걱정하지 않으며, 쉬운 첫 번째 단계는 게시물의 제목을 `<h1>`으로 렌더링할 수 있는지 확인하는 것입니다. 이것은 우리를 앞으로 조금 움직일 수 있는 가장 작은 첫 번째 단계처럼 *느껴집니다*.

```go
package blogrenderer_test

import (
	"bytes"
	"github.com/quii/learn-go-with-tests/blogrenderer"
	"testing"
)

func TestRender(t *testing.T) {
	var (
		aPost = blogrenderer.Post{
			Title:       "hello world",
			Body:        "This is a post",
			Description: "This is a description",
			Tags:        []string{"go", "tdd"},
		}
	)

	t.Run("it converts a single post into HTML", func(t *testing.T) {
		buf := bytes.Buffer{}
		err := blogrenderer.Render(&buf, aPost)

		if err != nil {
			t.Fatal(err)
		}

		got := buf.String()
		want := `<h1>hello world</h1>`
		if got != want {
			t.Errorf("got '%s' want '%s'", got, want)
		}
	})
}
```

`io.Writer`를 받아들이기로 한 결정은 테스트도 간단하게 만듭니다. 이 경우 [`bytes.Buffer`](https://pkg.go.dev/bytes#Buffer)에 쓰고 나중에 내용을 검사할 수 있습니다.

## 테스트 실행 시도

이 책의 이전 챕터를 읽었다면 지금쯤 이것에 익숙해졌을 것입니다. 패키지가 정의되어 있지 않거나 `Render` 함수가 없기 때문에 테스트를 실행할 수 없습니다. 컴파일러 메시지를 직접 따라가면서 테스트를 실행하고 명확한 메시지와 함께 실패하는 상태로 만들어 보세요.

테스트 실패를 연습하는 것이 정말 중요합니다. 6개월 후에 실수로 테스트를 실패하게 했을 때 *지금* 명확한 메시지와 함께 실패하는지 확인하는 노력을 기울인 것에 감사할 것입니다.

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

이것은 테스트를 실행하기 위한 최소한의 코드입니다

```go
package blogrenderer

// 파일 읽기 챕터에서 계속하는 경우 이것을 재정의할 필요가 없습니다
type Post struct {
	Title, Description, Body string
	Tags                     []string
}

func Render(w io.Writer, p Post) error {
	return nil
}
```

테스트는 빈 문자열이 원하는 것과 같지 않다고 불평해야 합니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func Render(w io.Writer, p Post) error {
	_, err := fmt.Fprintf(w, "<h1>%s</h1>", p.Title)
	return err
}
```

기억하세요, 소프트웨어 개발은 주로 학습 활동입니다. 작업하면서 발견하고 배우기 위해서는 빈번하고 고품질의 피드백 루프를 제공하는 방식으로 작업해야 하며, 이를 수행하는 가장 쉬운 방법은 작은 단계로 작업하는 것입니다.

그래서 지금은 템플릿 라이브러리 사용에 대해 걱정하지 않습니다. "일반" 문자열 템플릿만으로도 HTML을 만들 수 있으며, 템플릿 부분을 건너뛰면 작은 유용한 동작을 검증할 수 있고 패키지 API에 대한 작은 디자인 작업을 수행했습니다.

## 리팩토링

아직 리팩토링할 것이 많지 않으므로 다음 반복으로 이동합시다

## 먼저 테스트 작성

이제 매우 기본적인 버전이 작동하므로 테스트를 반복하여 기능을 확장할 수 있습니다. 이 경우 `Post`에서 더 많은 정보를 렌더링합니다.

```go
	t.Run("it converts a single post into HTML", func(t *testing.T) {
		buf := bytes.Buffer{}
		err := blogrenderer.Render(&buf, aPost)

		if err != nil {
			t.Fatal(err)
		}

		got := buf.String()
		want := `<h1>hello world</h1>
<p>This is a description</p>
Tags: <ul><li>go</li><li>tdd</li></ul>`

		if got != want {
			t.Errorf("got '%s' want '%s'", got, want)
		}
	})
```

이것을 작성하면 *어색하게 느껴집니다*. 테스트에서 모든 마크업을 보는 것은 나쁘게 느껴지며, 본문이나 모든 `<head>` 콘텐츠와 필요한 페이지 요소가 있는 실제 HTML을 아직 넣지도 않았습니다.

그럼에도 불구하고 *지금은* 고통을 참읍시다.

## 테스트 실행 시도

설명과 태그를 렌더링하지 않으므로 예상한 문자열이 없다고 불평하면서 실패해야 합니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

코드를 복사하는 대신 직접 시도해 보세요. 이 테스트를 통과시키는 것이 _조금 짜증난다_는 것을 알게 될 것입니다! 처음 시도했을 때 이 오류가 발생했습니다

```
=== RUN   TestRender
=== RUN   TestRender/it_converts_a_single_post_into_HTML
    renderer_test.go:32: got '<h1>hello world</h1><p>This is a description</p><ul><li>go</li><li>tdd</li></ul>' want '<h1>hello world</h1>
        <p>This is a description</p>
        Tags: <ul><li>go</li><li></li></ul>'
```

줄 바꿈! 누가 신경 쓰나요? 글쎄요, 우리 테스트는 정확한 문자열 값에 일치하기 때문에 신경 씁니다. 그래야 할까요? 지금은 테스트를 통과시키기 위해 줄 바꿈을 제거했습니다.

```go
func Render(w io.Writer, p Post) error {
	_, err := fmt.Fprintf(w, "<h1>%s</h1><p>%s</p>", p.Title, p.Description)
	if err != nil {
		return err
	}

	_, err = fmt.Fprint(w, "Tags: <ul>")
	if err != nil {
		return err
	}

	for _, tag := range p.Tags {
		_, err = fmt.Fprintf(w, "<li>%s</li>", tag)
		if err != nil {
			return err
		}
	}

	_, err = fmt.Fprint(w, "</ul>")
	if err != nil {
		return err
	}

	return nil
}
```

**이런**. 제가 쓴 가장 좋은 코드는 아니며, 마크업의 매우 초기 구현에 불과합니다. 페이지에 훨씬 더 많은 콘텐츠와 항목이 필요하며, 이 접근 방식이 적절하지 않다는 것을 빠르게 알 수 있습니다.

그러나 결정적으로 통과하는 테스트가 있습니다; 작동하는 소프트웨어가 있습니다.

## 리팩토링

작동하는 코드에 대한 통과 테스트의 안전망을 통해 이제 리팩토링 단계에서 구현 접근 방식을 변경하는 것에 대해 생각할 수 있습니다.

### 템플릿 소개

Go에는 [text/template](https://pkg.go.dev/text/template)과 [html/template](https://pkg.go.dev/html/template) 두 개의 템플릿 패키지가 있으며 동일한 인터페이스를 공유합니다. 둘 다 하는 일은 템플릿과 일부 데이터를 결합하여 문자열을 생성하는 것입니다.

HTML 버전의 차이점은 무엇일까요?

> 패키지 template (html/template)은 코드 주입에 대해 안전한 HTML 출력을 생성하기 위한 데이터 기반 템플릿을 구현합니다. text/template 패키지와 동일한 인터페이스를 제공하며 출력이 HTML일 때마다 text/template 대신 사용해야 합니다.

템플릿 언어는 [Mustache](https://mustache.github.io)와 매우 유사하며 관심사의 깔끔한 분리와 함께 매우 깨끗한 방식으로 콘텐츠를 동적으로 생성할 수 있습니다. 사용해 본 다른 템플릿 언어와 비교하면 매우 제한적이거나 Mustache가 좋아하는 대로 "logic-less"입니다. 이것은 중요하고 **의도적인** 디자인 결정입니다.

여기서는 HTML 생성에 초점을 맞추고 있지만, 프로젝트에서 복잡한 문자열 연결과 주문을 수행하는 경우 `text/template`을 사용하여 코드를 정리할 수 있습니다.

### 코드로 돌아가기

블로그용 템플릿입니다:

`<h1>{{.Title}}</h1><p>{{.Description}}</p>Tags: <ul>{{range .Tags}}<li>{{.}}</li>{{end}}</ul>`

이 문자열을 어디에 정의할까요? 글쎄요, 몇 가지 옵션이 있지만 단계를 작게 유지하기 위해 일반 문자열로 시작합시다

```go
package blogrenderer

import (
	"html/template"
	"io"
)

const (
	postTemplate = `<h1>{{.Title}}</h1><p>{{.Description}}</p>Tags: <ul>{{range .Tags}}<li>{{.}}</li>{{end}}</ul>`
)

func Render(w io.Writer, p Post) error {
	templ, err := template.New("blog").Parse(postTemplate)
	if err != nil {
		return err
	}

	if err := templ.Execute(w, p); err != nil {
		return err
	}

	return nil
}
```

이름으로 새 템플릿을 만든 다음 템플릿 문자열을 파싱합니다. 그런 다음 데이터(이 경우 `Post`)를 전달하여 `Execute` 메서드를 사용할 수 있습니다.

템플릿은 `{{.Description}}`과 같은 것을 `p.Description`의 내용으로 대체합니다. 템플릿은 또한 값을 루프하는 `range`와 `if`와 같은 프로그래밍 기본 요소를 제공합니다. [text/template 문서](https://pkg.go.dev/text/template)에서 자세한 내용을 찾을 수 있습니다.

*이것은 순수한 리팩토링이어야 합니다.* 테스트를 변경할 필요가 없으며 계속 통과해야 합니다. 중요하게도 코드는 읽기 쉽고 처리해야 할 성가신 오류 처리가 훨씬 적습니다.

사람들은 종종 Go의 오류 처리의 장황함에 대해 불평하지만, 여기처럼 처음부터 오류가 덜 발생하는 코드를 작성하는 더 나은 방법을 찾을 수 있습니다.

### 더 많은 리팩토링

`html/template` 사용은 분명히 개선되었지만 코드에 문자열 상수로 있는 것은 좋지 않습니다:

- 여전히 읽기 어렵습니다.
- IDE/편집기 친화적이지 않습니다. 구문 강조, 다시 포맷하는 기능, 리팩토링 등이 없습니다.
- HTML처럼 보이지만 "일반" HTML 파일처럼 실제로 작업할 수 없습니다

템플릿이 별도의 파일에 있어서 더 잘 구성하고 HTML 파일인 것처럼 작업할 수 있기를 원합니다.

"templates"라는 폴더를 만들고 그 안에 `blog.gohtml`이라는 파일을 만들고 템플릿을 붙여넣습니다.

이제 [go 1.16에 포함된 임베딩 기능](https://pkg.go.dev/embed)을 사용하여 파일 시스템을 임베드하도록 코드를 변경합니다.

```go
package blogrenderer

import (
	"embed"
	"html/template"
	"io"
)

var (
	//go:embed "templates/*"
	postTemplates embed.FS
)

func Render(w io.Writer, p Post) error {
	templ, err := template.ParseFS(postTemplates, "templates/*.gohtml")
	if err != nil {
		return err
	}

	if err := templ.Execute(w, p); err != nil {
		return err
	}

	return nil
}
```

"파일 시스템"을 코드에 임베딩하면 여러 템플릿을 자유롭게 로드하고 결합할 수 있습니다. 이것은 HTML 페이지 상단의 헤더와 푸터와 같이 다른 템플릿 간에 렌더링 로직을 공유하고 싶을 때 유용해집니다.

### 임베드?

임베드는 [파일 읽기](reading-files.md)에서 가볍게 다루었습니다. [표준 라이브러리의 문서가 설명합니다](https://pkg.go.dev/embed)

> 패키지 embed는 실행 중인 Go 프로그램에 임베드된 파일에 대한 액세스를 제공합니다.
>
> "embed"를 가져오는 Go 소스 파일은 //go:embed 지시어를 사용하여 컴파일 시 패키지 디렉토리 또는 하위 디렉토리에서 읽은 파일의 내용으로 string, []byte 또는 FS 유형의 변수를 초기화할 수 있습니다.

왜 이것을 사용하고 싶을까요? 대안은 "일반" 파일 시스템에서 템플릿을 로드할 수 있다는 것입니다. 그러나 이것은 이 소프트웨어를 사용하려는 곳마다 템플릿이 올바른 파일 경로에 있는지 확인해야 한다는 것을 의미합니다. 직장에서는 개발, 스테이징 및 라이브와 같은 다양한 환경이 있을 수 있습니다. 이것이 작동하려면 템플릿이 올바른 위치에 복사되었는지 확인해야 합니다.

embed를 사용하면 빌드할 때 파일이 Go 프로그램에 포함됩니다. 이것은 프로그램을 빌드하면 (한 번만 수행해야 함) 파일을 항상 사용할 수 있다는 것을 의미합니다.

편리한 점은 개별 파일뿐만 아니라 파일 시스템도 임베드할 수 있다는 것입니다; 그리고 해당 파일 시스템은 [io/fs](https://pkg.go.dev/io/fs)를 구현하므로 코드가 어떤 종류의 파일 시스템으로 작업하는지 신경 쓸 필요가 없습니다.

그러나 구성에 따라 다른 템플릿을 사용하려면 더 일반적인 방법으로 디스크에서 템플릿을 로드하는 것을 유지할 수 있습니다.

## 다음: 템플릿을 "멋지게" 만들기

템플릿이 한 줄 문자열로 정의되는 것을 원하지 않습니다. 쉽게 읽고 작업할 수 있도록 공간을 두고 싶습니다. 다음과 같이:

```handlebars
<h1>{{.Title}}</h1>

<p>{{.Description}}</p>

Tags: <ul>{{range .Tags}}<li>{{.}}</li>{{end}}</ul>
```

그러나 이렇게 하면 테스트가 실패합니다. 테스트가 반환될 매우 구체적인 문자열을 기대하기 때문입니다.

그러나 실제로 공백에 대해서는 신경 쓰지 않습니다. 마크업을 약간 변경할 때마다 어설션 문자열을 계속 고통스럽게 업데이트해야 한다면 이 테스트를 유지하는 것이 악몽이 될 것입니다. 템플릿이 성장함에 따라 이러한 종류의 편집은 관리하기 어려워지고 작업 비용이 통제를 벗어날 것입니다.

## 승인 테스트 소개

[Go Approval Tests](https://github.com/approvals/go-approval-tests)

> ApprovalTests는 파일에 저장할 수 있는 더 큰 객체, 문자열 및 기타 모든 것 (이미지, 사운드, CSV 등...)을 쉽게 테스트할 수 있게 합니다

아이디어는 "골든" 파일 또는 스냅샷 테스트와 유사합니다. 테스트 파일 내에서 문자열을 어색하게 유지하는 대신 승인 도구가 생성한 "승인된" 파일과 출력을 비교할 수 있습니다. 그런 다음 승인하면 새 버전을 복사하기만 하면 됩니다. 테스트를 다시 실행하면 녹색으로 돌아갑니다.

프로젝트에 `"github.com/approvals/go-approval-tests"`에 대한 의존성을 추가하고 테스트를 다음과 같이 편집합니다

```go
func TestRender(t *testing.T) {
	var (
		aPost = blogrenderer.Post{
			Title:       "hello world",
			Body:        "This is a post",
			Description: "This is a description",
			Tags:        []string{"go", "tdd"},
		}
	)

	t.Run("it converts a single post into HTML", func(t *testing.T) {
		buf := bytes.Buffer{}

		if err := blogrenderer.Render(&buf, aPost); err != nil {
			t.Fatal(err)
		}

		approvals.VerifyString(t, buf.String())
	})
}
```

처음 실행하면 아직 아무것도 승인하지 않았기 때문에 실패합니다

```
=== RUN   TestRender
=== RUN   TestRender/it_converts_a_single_post_into_HTML
    renderer_test.go:29: Failed Approval: received does not match approved.
```

두 개의 파일이 생성됩니다

- `renderer_test.TestRender.it_converts_a_single_post_into_HTML.received.txt`
- `renderer_test.TestRender.it_converts_a_single_post_into_HTML.approved.txt`

received 파일에는 새로운 승인되지 않은 버전의 출력이 있습니다. 그것을 빈 approved 파일에 복사하고 테스트를 다시 실행합니다.

새 버전을 복사함으로써 변경을 "승인"했으며 이제 테스트가 통과합니다.

워크플로를 실제로 보려면 읽기 쉽게 논의한 대로 템플릿을 편집하세요 (의미적으로는 동일합니다).

```handlebars
<h1>{{.Title}}</h1>

<p>{{.Description}}</p>

Tags: <ul>{{range .Tags}}<li>{{.}}</li>{{end}}</ul>
```

테스트를 다시 실행합니다. 코드의 출력이 승인된 버전과 다르기 때문에 새 "received" 파일이 생성됩니다. 확인하고 변경 사항에 만족하면 새 버전을 복사하고 테스트를 다시 실행합니다. 승인된 파일을 소스 컨트롤에 커밋해야 합니다.

이 접근 방식은 HTML과 같은 크고 못생긴 것들에 대한 변경 관리를 훨씬 간단하게 만듭니다. diff 도구를 사용하여 차이점을 보고 관리할 수 있으며 테스트 코드를 더 깔끔하게 유지합니다.

![Use diff tool to manage changes](https://i.imgur.com/0MoNdva.png)

이것은 실제로 승인 테스트의 상당히 사소한 사용이며, 테스팅 무기에서 매우 유용한 도구입니다. [Emily Bache](https://twitter.com/emilybache)는 [승인 테스트를 사용하여 테스트가 전혀 없는 복잡한 코드베이스에 매우 광범위한 테스트 세트를 추가하는 흥미로운 비디오](https://www.youtube.com/watch?v=zyM2Ep28ED8)가 있습니다. "조합 테스트"는 분명히 살펴볼 가치가 있습니다.

이제 이 변경을 수행했으므로 코드가 잘 테스트되는 이점을 여전히 누리지만 마크업을 수정할 때 테스트가 너무 방해가 되지 않습니다.

### 우리는 여전히 TDD를 하고 있나요?

이 접근 방식의 흥미로운 부작용은 TDD에서 멀어지게 한다는 것입니다. 물론 원하는 상태로 승인된 파일을 수동으로 편집하고 테스트를 실행한 다음 정의한 내용을 출력하도록 템플릿을 수정할 수 _있습니다_.

하지만 그것은 어리석습니다! TDD는 작업을 수행하는 방법, 특히 설계입니다; 그러나 **모든 것에** 대해 독단적으로 사용해야 한다는 의미는 아닙니다.

중요한 것은 올바른 일을 했고 TDD를 **디자인 도구**로 사용하여 패키지의 API를 설계했다는 것입니다. 템플릿 변경의 경우 프로세스는 다음과 같을 수 있습니다:

- 템플릿을 약간 변경
- 승인 테스트 실행
- 출력을 눈으로 확인하여 올바르게 보이는지 확인
- 승인하기
- 반복

우리는 여전히 작고 달성 가능한 단계에서 작업하는 가치를 포기해서는 안 됩니다. 변경을 작게 만들고 테스트를 계속 다시 실행하여 하고 있는 것에 대한 실제 피드백을 받는 방법을 찾으십시오.

템플릿 _주변_의 코드를 변경하는 것과 같은 일을 시작하면 물론 TDD 작업 방법으로 돌아가야 할 수 있습니다.

## 마크업 확장

대부분의 웹사이트는 현재 가지고 있는 것보다 더 풍부한 HTML을 가지고 있습니다. 우선 `html` 요소와 함께 `head`, 아마도 `nav`도 있습니다. 일반적으로 footer에 대한 아이디어도 있습니다.

사이트에 다른 페이지가 있는 경우 사이트가 일관되게 보이도록 한 곳에서 이러한 항목을 정의하고 싶습니다. Go 템플릿은 다른 템플릿으로 가져올 수 있는 섹션을 정의하는 것을 지원합니다.

기존 템플릿을 편집하여 상단 및 하단 템플릿을 가져옵니다

```handlebars
{{template "top" .}}
<h1>{{.Title}}</h1>

<p>{{.Description}}</p>

Tags: <ul>{{range .Tags}}<li>{{.}}</li>{{end}}</ul>
{{template "bottom" .}}
```

그런 다음 다음과 같이 `top.gohtml`을 만듭니다

```handlebars
{{define "top"}}
<!DOCTYPE html>
<html lang="en">
<head>
    <title>My amazing blog!</title>
    <meta charset="UTF-8"/>
    <meta name="description" content="Wow, like and subscribe, it really helps the channel guys" lang="en"/>
</head>
<body>
<nav role="navigation">
    <div>
        <h1>Budding Gopher's blog</h1>
        <ul>
            <li><a href="/">home</a></li>
            <li><a href="about">about</a></li>
            <li><a href="archive">archive</a></li>
        </ul>
    </div>
</nav>
<main>
{{end}}
```

그리고 `bottom.gohtml`

```handlebars
{{define "bottom"}}
</main>
<footer>
    <ul>
        <li><a href="https://twitter.com/quii">Twitter</a></li>
        <li><a href="https://github.com/quii">GitHub</a></li>
    </ul>
</footer>
</body>
</html>
{{end}}
```

(물론 원하는 마크업을 자유롭게 넣으세요!)

이제 실행할 특정 템플릿을 지정해야 합니다. 블로그 렌더러에서 `Execute` 명령을 `ExecuteTemplate`으로 변경합니다

```go
if err := templ.ExecuteTemplate(w, "blog.gohtml", p); err != nil {
	return err
}
```

테스트를 다시 실행합니다. 새 "received" 파일이 만들어지고 테스트가 실패해야 합니다. 확인하고 만족하면 이전 버전 위에 복사하여 승인합니다. 테스트를 다시 실행하면 통과해야 합니다.

## 벤치마킹을 다룰 핑계

진행하기 전에 코드가 무엇을 하는지 생각해 봅시다.

```go
func Render(w io.Writer, p Post) error {
	templ, err := template.ParseFS(postTemplates, "templates/*.gohtml")
	if err != nil {
		return err
	}

	if err := templ.ExecuteTemplate(w, "blog.gohtml", p); err != nil {
		return err
	}

	return nil
}
```

- 템플릿 파싱
- 템플릿을 사용하여 `io.Writer`에 게시물 렌더링

대부분의 경우 각 게시물에 대해 템플릿을 다시 파싱하는 성능 영향은 상당히 무시할 수 있지만, 이것을 *하지 않는* 노력도 상당히 무시할 수 있으며 코드도 약간 정리해야 합니다.

이 파싱을 반복하지 않는 영향을 보려면 벤치마킹 도구를 사용하여 함수가 얼마나 빠른지 확인할 수 있습니다.

```go
func BenchmarkRender(b *testing.B) {
	var (
		aPost = blogrenderer.Post{
			Title:       "hello world",
			Body:        "This is a post",
			Description: "This is a description",
			Tags:        []string{"go", "tdd"},
		}
	)

	for b.Loop() {
		blogrenderer.Render(io.Discard, aPost)
	}
}
```

제 컴퓨터에서 결과는 다음과 같습니다

```
BenchmarkRender-8 22124 53812 ns/op
```

템플릿을 반복해서 다시 파싱하는 것을 중지하기 위해 파싱된 템플릿을 보유할 타입을 만들고 렌더링을 수행하는 메서드를 갖게 합니다

```go
type PostRenderer struct {
	templ *template.Template
}

func NewPostRenderer() (*PostRenderer, error) {
	templ, err := template.ParseFS(postTemplates, "templates/*.gohtml")
	if err != nil {
		return nil, err
	}

	return &PostRenderer{templ: templ}, nil
}

func (r *PostRenderer) Render(w io.Writer, p Post) error {

	if err := r.templ.ExecuteTemplate(w, "blog.gohtml", p); err != nil {
		return err
	}

	return nil
}
```

이것은 코드의 인터페이스를 변경하므로 테스트를 업데이트해야 합니다

```go
func TestRender(t *testing.T) {
	var (
		aPost = blogrenderer.Post{
			Title:       "hello world",
			Body:        "This is a post",
			Description: "This is a description",
			Tags:        []string{"go", "tdd"},
		}
	)

	postRenderer, err := blogrenderer.NewPostRenderer()

	if err != nil {
		t.Fatal(err)
	}

	t.Run("it converts a single post into HTML", func(t *testing.T) {
		buf := bytes.Buffer{}

		if err := postRenderer.Render(&buf, aPost); err != nil {
			t.Fatal(err)
		}

		approvals.VerifyString(t, buf.String())
	})
}
```

그리고 벤치마크

```go
func BenchmarkRender(b *testing.B) {
	var (
		aPost = blogrenderer.Post{
			Title:       "hello world",
			Body:        "This is a post",
			Description: "This is a description",
			Tags:        []string{"go", "tdd"},
		}
	)

	postRenderer, err := blogrenderer.NewPostRenderer()

	if err != nil {
		b.Fatal(err)
	}

	for b.Loop() {
		postRenderer.Render(io.Discard, aPost)
	}
}
```

테스트는 계속 통과해야 합니다. 벤치마크는 어떻습니까?

`BenchmarkRender-8 362124 3131 ns/op`. 이전 연산당 NS는 `53812 ns/op`였으므로 이것은 괜찮은 개선입니다! 인덱스 페이지와 같은 다른 렌더링 메서드를 추가하면 템플릿 파싱을 복제할 필요가 없으므로 코드가 단순화됩니다.

## 실제 작업으로 돌아가기

게시물 렌더링 측면에서 중요한 부분은 실제로 `Body`를 렌더링하는 것입니다. 기억하시다시피 작성자가 작성한 마크다운이어야 하므로 HTML로 변환해야 합니다.

독자 여러분을 위한 연습으로 남겨두겠습니다. 이것을 수행하는 Go 라이브러리를 찾을 수 있어야 합니다. 승인 테스트를 사용하여 하고 있는 것을 검증하세요.

### 3rd-party 라이브러리 테스트에 대해

**참고**. 단위 테스트에서 3rd party 라이브러리의 동작을 명시적으로 테스트하는 것에 대해 너무 걱정하지 마세요.

제어할 수 없는 코드에 대해 테스트를 작성하는 것은 낭비이며 유지 관리 오버헤드를 추가합니다. 때로는 [의존성 주입](./dependency-injection.md)을 사용하여 의존성을 제어하고 테스트를 위해 동작을 모킹할 수 있습니다.

이 경우에는 마크다운을 HTML로 변환하는 것을 렌더링의 구현 세부 사항으로 보며 승인 테스트가 충분한 확신을 줄 것입니다.

### 인덱스 렌더링

다음으로 수행할 기능은 게시물을 HTML 순서 목록으로 나열하는 인덱스를 렌더링하는 것입니다.

API를 확장하고 있으므로 TDD 모자를 다시 씁니다.

## 먼저 테스트 작성

표면적으로 인덱스 페이지는 간단해 보이지만 테스트를 작성하면 여전히 일부 디자인 선택을 내리도록 촉구합니다

```go
t.Run("it renders an index of posts", func(t *testing.T) {
	buf := bytes.Buffer{}
	posts := []blogrenderer.Post{{Title: "Hello World"}, {Title: "Hello World 2"}}

	if err := postRenderer.RenderIndex(&buf, posts); err != nil {
		t.Fatal(err)
	}

	got := buf.String()
	want := `<ol><li><a href="/post/hello-world">Hello World</a></li><li><a href="/post/hello-world-2">Hello World 2</a></li></ol>`

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
})
```

1. URL 경로의 일부로 `Post`의 title 필드를 사용하고 있지만 URL에 공백을 원하지 않으므로 하이픈으로 바꿉니다.
2. `io.Writer`와 `Post` 슬라이스를 다시 받는 `RenderIndex` 메서드를 `PostRenderer`에 추가했습니다.

여기서 테스트 후, 승인 테스트 접근 방식을 고수했다면 제어된 환경에서 이러한 질문에 답하지 않았을 것입니다. **테스트는 우리에게 생각할 공간을 줍니다**.

## 테스트 실행 시도

```
./renderer_test.go:41:13: undefined: blogrenderer.RenderIndex
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

```go
func (r *PostRenderer) RenderIndex(w io.Writer, posts []Post) error {
	return nil
}
```

위의 코드는 다음 테스트 실패를 가져와야 합니다

```
=== RUN   TestRender
=== RUN   TestRender/it_renders_an_index_of_posts
    renderer_test.go:49: got "" want "<ol><li><a href=\"/post/hello-world\">Hello World</a></li><li><a href=\"/post/hello-world-2\">Hello World 2</a></li></ol>"
--- FAIL: TestRender (0.00s)
```

## 테스트를 통과시키기 위한 충분한 코드 작성

이것이 _쉬워야_ 하는 것처럼 느껴지지만 조금 어색합니다. 여러 단계로 수행했습니다

```go
func (r *PostRenderer) RenderIndex(w io.Writer, posts []Post) error {
	indexTemplate := `<ol>{{range .}}<li><a href="/post/{{.Title}}">{{.Title}}</a></li>{{end}}</ol>`

	templ, err := template.New("index").Parse(indexTemplate)
	if err != nil {
		return err
	}

	if err := templ.Execute(w, posts); err != nil {
		return err
	}

	return nil
}
```

처음에는 별도의 템플릿 파일을 다루고 싶지 않았습니다. 그냥 작동하게 만들고 싶었습니다. 선행 템플릿 파싱과 분리를 나중에 할 수 있는 리팩토링으로 봅니다.

이것은 통과하지 않지만 가깝습니다.

```
=== RUN   TestRender
=== RUN   TestRender/it_renders_an_index_of_posts
    renderer_test.go:49: got "<ol><li><a href=\"/post/Hello%20World\">Hello World</a></li><li><a href=\"/post/Hello%20World%202\">Hello World 2</a></li></ol>" want "<ol><li><a href=\"/post/hello-world\">Hello World</a></li><li><a href=\"/post/hello-world-2\">Hello World 2</a></li></ol>"
--- FAIL: TestRender (0.00s)
    --- FAIL: TestRender/it_renders_an_index_of_posts (0.00s)
```

템플릿 코드가 `href` 속성에서 공백을 이스케이프하는 것을 볼 수 있습니다. 공백을 하이픈으로 문자열 교체하는 방법이 필요합니다. `[]Post`를 루프하고 메모리 내에서 교체할 수는 없습니다. 앵커에서 사용자에게 공백이 표시되기를 원하기 때문입니다.

몇 가지 옵션이 있습니다. 첫 번째로 탐색할 것은 템플릿에 함수를 전달하는 것입니다.

### 템플릿에 함수 전달

```go
func (r *PostRenderer) RenderIndex(w io.Writer, posts []Post) error {
	indexTemplate := `<ol>{{range .}}<li><a href="/post/{{sanitiseTitle .Title}}">{{.Title}}</a></li>{{end}}</ol>`

	templ, err := template.New("index").Funcs(template.FuncMap{
		"sanitiseTitle": func(title string) string {
			return strings.ToLower(strings.Replace(title, " ", "-", -1))
		},
	}).Parse(indexTemplate)
	if err != nil {
		return err
	}

	if err := templ.Execute(w, posts); err != nil {
		return err
	}

	return nil
}
```

_템플릿을 파싱하기 전에_ 템플릿에 `template.FuncMap`을 추가하여 템플릿 내에서 호출할 수 있는 함수를 정의할 수 있습니다. 이 경우 `sanitiseTitle` 함수를 만들었고 `{{sanitiseTitle .Title}}`로 템플릿 내에서 호출합니다.

이것은 강력한 기능입니다. 템플릿에 함수를 보낼 수 있으면 매우 멋진 것을 할 수 있습니다. 하지만 해야 할까요? Mustache의 원칙과 logic-less 템플릿으로 돌아가서, 왜 logic-less를 옹호했을까요? **템플릿에서 로직의 문제점은 무엇입니까?**

보여주었듯이 템플릿을 테스트하려면 *완전히 다른 종류의 테스트를 도입해야 했습니다*.

몇 가지 다른 동작 순열과 엣지 케이스가 있는 템플릿에 함수를 도입한다고 상상해 보세요. **어떻게 테스트할 것입니까**? 이 현재 설계로 이 로직을 테스트하는 유일한 방법은 _HTML을 렌더링하고 문자열을 비교하는 것_입니다. 이것은 로직을 테스트하는 쉽거나 훌륭한 방법이 아니며 _중요한_ 비즈니스 로직에 원하는 것이 분명히 아닙니다.

승인 테스트 기술이 이러한 테스트 유지 비용을 줄였지만 작성하는 대부분의 단위 테스트보다 유지 비용이 여전히 더 비쌉니다. 마크업을 약간 변경하면 여전히 민감합니다. 관리하기 쉽게 만들었을 뿐입니다. 템플릿 주변에 많은 테스트를 작성할 필요가 없도록 코드를 설계하고 렌더링 코드 내에 있을 필요가 없는 로직이 제대로 분리되도록 노력해야 합니다.

Mustache의 영향을 받은 템플릿 엔진이 제공하는 것은 유용한 제약입니다. 너무 자주 회피하려고 하지 마세요; **결을 거스르지 마세요**. 대신 [뷰 모델](https://stackoverflow.com/a/11064506/3193)의 아이디어를 받아들이세요. 템플릿 언어에 편리한 방식으로 렌더링하는 데 필요한 데이터를 포함하는 특정 타입을 구성합니다.

이렇게 하면 해당 데이터 백을 생성하는 데 사용하는 중요한 비즈니스 로직을 HTML과 템플릿의 지저분한 세계와 별도로 단위 테스트할 수 있습니다.

### 관심사 분리

그래서 대신 무엇을 할 수 있을까요?

#### `Post`에 메서드를 추가하고 템플릿에서 호출

템플릿 코드에서 보내는 타입에 대해 메서드를 호출할 수 있으므로 `Post`에 `SanitisedTitle` 메서드를 추가할 수 있습니다. 이것은 템플릿을 단순화하고 원한다면 이 로직을 별도로 쉽게 단위 테스트할 수 있습니다. 이것은 아마도 가장 쉬운 솔루션이지만 가장 간단한 것은 아닐 수 있습니다.

이 접근 방식의 단점은 이것이 여전히 _뷰_ 로직이라는 것입니다. 시스템의 나머지 부분에는 관심이 없지만 이제 핵심 도메인 객체에 대한 API의 일부가 됩니다. 이러한 접근 방식은 시간이 지남에 따라 [God Objects](https://en.wikipedia.org/wiki/God_object)를 만들게 할 수 있습니다.

#### 필요한 데이터만 있는 전용 뷰 모델 타입 생성, 예: `PostViewModel`

렌더링 코드가 도메인 객체 `Post`에 결합되는 대신 뷰 모델을 받습니다.

```go
type PostViewModel struct {
	Title, SanitisedTitle, Description, Body string
	Tags                                     []string
}
```

코드 호출자는 `[]Post`에서 `[]PostView`로 매핑하고 `SanitizedTitle`을 생성해야 합니다. 이것을 깨끗하게 유지하는 방법은 매핑을 캡슐화하는 `func NewPostView(p Post) PostView`를 갖는 것입니다.

이것은 렌더링 코드를 logic-less로 유지하고 우리가 할 수 있는 가장 엄격한 관심사 분리일 것이지만 트레이드 오프는 게시물을 렌더링하기 위한 약간 더 복잡한 프로세스입니다.

두 옵션 모두 괜찮지만 이 경우 첫 번째로 가는 것이 유혹적입니다. 시스템을 발전시킬 때 렌더링의 바퀴에 기름을 바르기 위해 점점 더 많은 임시 메서드를 추가하는 것에 주의해야 합니다; 전용 뷰 모델은 도메인 객체와 뷰 간의 변환이 더 복잡해질 때 더 유용해집니다.

그래서 `Post`에 메서드를 추가할 수 있습니다

```go
func (p Post) SanitisedTitle() string {
	return strings.ToLower(strings.Replace(p.Title, " ", "-", -1))
}
```

그런 다음 렌더링 코드에서 더 간단한 세계로 돌아갈 수 있습니다

```go
func (r *PostRenderer) RenderIndex(w io.Writer, posts []Post) error {
	indexTemplate := `<ol>{{range .}}<li><a href="/post/{{.SanitisedTitle}}">{{.Title}}</a></li>{{end}}</ol>`

	templ, err := template.New("index").Parse(indexTemplate)
	if err != nil {
		return err
	}

	if err := templ.Execute(w, posts); err != nil {
		return err
	}

	return nil
}
```

## 리팩토링

마침내 테스트가 통과해야 합니다. 이제 템플릿을 파일(`templates/index.gohtml`)로 이동하고 렌더러를 구성할 때 한 번 로드할 수 있습니다.

```go
package blogrenderer

import (
	"embed"
	"html/template"
	"io"
)

var (
	//go:embed "templates/*"
	postTemplates embed.FS
)

type PostRenderer struct {
	templ *template.Template
}

func NewPostRenderer() (*PostRenderer, error) {
	templ, err := template.ParseFS(postTemplates, "templates/*.gohtml")
	if err != nil {
		return nil, err
	}

	return &PostRenderer{templ: templ}, nil
}

func (r *PostRenderer) Render(w io.Writer, p Post) error {
	return r.templ.ExecuteTemplate(w, "blog.gohtml", p)
}

func (r *PostRenderer) RenderIndex(w io.Writer, posts []Post) error {
	return r.templ.ExecuteTemplate(w, "index.gohtml", posts)
}
```

`templ`에 둘 이상의 템플릿을 파싱함으로써 이제 `ExecuteTemplate`을 호출하고 적절하게 렌더링할 _어떤_ 템플릿을 지정해야 하지만 도착한 코드가 훌륭하게 보인다는 데 동의할 것입니다.

누군가가 템플릿 파일 중 하나의 이름을 바꾸면 버그가 발생할 수 있는 _약간의_ 위험이 있지만 빠르게 실행되는 단위 테스트가 이것을 빠르게 잡을 것입니다.

이제 패키지의 API 디자인에 만족하고 TDD로 일부 기본 동작을 이끌어냈으므로 승인을 사용하도록 테스트를 변경합시다.

```go
	t.Run("it renders an index of posts", func(t *testing.T) {
		buf := bytes.Buffer{}
		posts := []blogrenderer.Post{{Title: "Hello World"}, {Title: "Hello World 2"}}

		if err := postRenderer.RenderIndex(&buf, posts); err != nil {
			t.Fatal(err)
		}

		approvals.VerifyString(t, buf.String())
	})
```

테스트를 실행하여 실패하는 것을 확인한 다음 변경을 승인해야 합니다.

마지막으로 인덱스 페이지에 페이지 요소를 추가할 수 있습니다:

```handlebars
{{template "top" .}}
<ol>{{range .}}<li><a href="/post/{{.SanitisedTitle}}">{{.Title}}</a></li>{{end}}</ol>
{{template "bottom" .}}
```

테스트를 다시 실행하고 변경을 승인하면 인덱스가 완료됩니다!

## 마크다운 본문 렌더링

직접 시도해 보라고 권장했습니다. 제가 결국 취한 접근 방식은 다음과 같습니다.

```go
package blogrenderer

import (
	"embed"
	"github.com/gomarkdown/markdown"
	"github.com/gomarkdown/markdown/parser"
	"html/template"
	"io"
)

var (
	//go:embed "templates/*"
	postTemplates embed.FS
)

type PostRenderer struct {
	templ    *template.Template
	mdParser *parser.Parser
}

func NewPostRenderer() (*PostRenderer, error) {
	templ, err := template.ParseFS(postTemplates, "templates/*.gohtml")
	if err != nil {
		return nil, err
	}

	extensions := parser.CommonExtensions | parser.AutoHeadingIDs
	parser := parser.NewWithExtensions(extensions)

	return &PostRenderer{templ: templ, mdParser: parser}, nil
}

func (r *PostRenderer) Render(w io.Writer, p Post) error {
	return r.templ.ExecuteTemplate(w, "blog.gohtml", newPostVM(p, r))
}

func (r *PostRenderer) RenderIndex(w io.Writer, posts []Post) error {
	return r.templ.ExecuteTemplate(w, "index.gohtml", posts)
}

type postViewModel struct {
	Post
	HTMLBody template.HTML
}

func newPostVM(p Post, r *PostRenderer) postViewModel {
	vm := postViewModel{Post: p}
	vm.HTMLBody = template.HTML(markdown.ToHTML([]byte(p.Body), r.mdParser, nil))
	return vm
}
```

희망대로 정확히 작동하는 훌륭한 [gomarkdown](https://github.com/gomarkdown/markdown) 라이브러리를 사용했습니다.

직접 시도했다면 본문 렌더링에 HTML이 이스케이프되었을 수 있습니다. 이것은 악의적인 3rd-party HTML이 출력되는 것을 방지하기 위한 Go의 html/template 패키지의 보안 기능입니다.

이것을 우회하려면 렌더에 보내는 타입에서 신뢰할 수 있는 HTML을 [template.HTML](https://pkg.go.dev/html/template#HTML)로 래핑해야 합니다

> HTML은 알려진 안전한 HTML 문서 조각을 캡슐화합니다. 3rd-party의 HTML이나 닫히지 않은 태그 또는 주석이 있는 HTML에는 사용해서는 안 됩니다. 건전한 HTML 새니타이저의 출력과 이 패키지에 의해 이스케이프된 템플릿은 HTML과 함께 사용해도 괜찮습니다.
>
> 이 타입을 사용하면 보안 위험이 있습니다: 캡슐화된 콘텐츠는 템플릿 출력에 그대로 포함되므로 신뢰할 수 있는 소스에서 가져와야 합니다.

그래서 **내보내지 않는** 뷰 모델(`postViewModel`)을 만들었습니다. 이것을 여전히 렌더링의 내부 구현 세부 사항으로 보았기 때문입니다. 이것을 별도로 테스트할 필요가 없고 API를 오염시키고 싶지 않습니다.

렌더링할 때 하나를 구성하여 `Body`를 `HTMLBody`로 파싱한 다음 템플릿에서 해당 필드를 사용하여 HTML을 렌더링합니다.

## 마무리

[파일 읽기](reading-files.md) 챕터와 이 챕터의 학습을 결합하면 잘 테스트되고 간단한 정적 사이트 생성기를 편안하게 만들고 자신만의 블로그를 시작할 수 있습니다. CSS 튜토리얼을 찾으면 멋지게 보이게 만들 수도 있습니다.

이 접근 방식은 블로그를 넘어 확장됩니다. 데이터베이스, API 또는 파일 시스템 등 모든 소스에서 데이터를 가져와 HTML로 변환하고 서버에서 반환하는 것은 수십 년에 걸친 간단한 기술입니다. 사람들은 현대 웹 개발의 복잡성에 대해 한탄하지만 스스로 복잡성을 부과하고 있지는 않은지 확인해 보셨습니까?

Go는 웹 개발에 훌륭합니다. 특히 만드는 웹사이트의 실제 요구 사항에 대해 명확하게 생각할 때 그렇습니다. 서버에서 HTML을 생성하는 것은 종종 React와 같은 기술로 "웹 애플리케이션"을 만드는 것보다 더 좋고 더 간단하며 더 성능이 좋은 접근 방식입니다.

### 배운 것

- HTML 템플릿을 만들고 렌더링하는 방법.
- 템플릿을 함께 구성하고 관련 마크업을 [DRY](https://en.wikipedia.org/wiki/Don't_repeat_yourself)하여 일관된 모양과 느낌을 유지하는 데 도움이 되는 방법.
- 템플릿에 함수를 전달하는 방법과 왜 두 번 생각해야 하는지.
- 템플릿 렌더러와 같은 크고 못생긴 출력을 테스트하는 데 도움이 되는 "승인 테스트"를 작성하는 방법.

### logic-less 템플릿에 대해

항상 그렇듯이 이것은 모두 **관심사 분리**에 관한 것입니다. 시스템의 다양한 부분의 책임이 무엇인지 고려하는 것이 중요합니다. 너무 자주 사람들이 중요한 비즈니스 로직을 템플릿에 누출하여 관심사를 혼합하고 시스템을 이해하고 유지 관리하고 테스트하기 어렵게 만듭니다.

### HTML만을 위한 것이 아님

Go에는 템플릿에서 다른 종류의 데이터를 생성하는 `text/template`이 있다는 것을 기억하세요. 데이터를 어떤 종류의 구조화된 출력으로 변환해야 하는 경우 이 챕터에서 설명한 기술이 유용할 수 있습니다.

### 참고 자료 및 추가 자료

- [John Calhoun의 'Learn Web Development with Go'](https://www.calhoun.io/intro-to-templates-p1-contextual-encoding/)에는 템플릿에 대한 훌륭한 기사가 많이 있습니다.
- [Hotwire](https://hotwired.dev) - 이러한 기술을 사용하여 Hotwire 웹 애플리케이션을 만들 수 있습니다. 주로 Ruby on Rails 샵인 Basecamp에서 구축했지만 서버 측이기 때문에 Go와 함께 사용할 수 있습니다.

# 파일 읽기

* [**이 챕터의 모든 코드는 여기에서 확인할 수 있습니다**](https://github.com/quii/learn-go-with-tests/tree/main/reading-files)
* [문제를 해결하고 Twitch 스트림에서 질문을 받는 영상은 여기 있습니다](https://www.youtube.com/watch?v=nXts4dEJnkU)

이 챕터에서는 일부 파일을 읽고, 데이터를 추출하고, 유용한 것을 수행하는 방법을 배울 것입니다.

친구와 함께 블로그 소프트웨어를 만들고 있다고 가정해 보세요. 아이디어는 작성자가 파일 상단에 일부 메타데이터와 함께 마크다운으로 게시물을 작성하는 것입니다. 시작 시 웹 서버는 폴더를 읽어 일부 `Post`를 만든 다음 별도의 `NewHandler` 함수가 해당 `Post`를 블로그의 웹서버에 대한 데이터 소스로 사용합니다.

주어진 블로그 게시물 파일 폴더를 `Post` 컬렉션으로 변환하는 패키지를 만들라는 요청을 받았습니다.

### 예제 데이터

hello world.md

```markdown
Title: Hello, TDD world!
Description: First post on our wonderful blog
Tags: tdd, go
---
Hello world!

The body of posts starts after the `---`
```

### 예상 데이터

```go
type Post struct {
	Title, Description, Body string
	Tags                     []string
}
```

## 반복적인 테스트 주도 개발

목표를 향해 항상 간단하고 안전한 단계를 밟는 반복적인 접근 방식을 취할 것입니다.

이것은 작업을 분할해야 하지만, ["바텀업"](https://en.wikipedia.org/wiki/Top-down_and_bottom-up_design) 접근 방식을 취하는 함정에 빠지지 않도록 주의해야 합니다.

작업을 시작할 때 과잉 활동적인 상상력을 신뢰해서는 안 됩니다. 모든 것을 함께 붙일 때만 검증되는 `BlogPostFileParser`와 같은 일종의 추상화를 만들고 싶을 수 있습니다.

이것은 반복적이지 **않으며** TDD가 우리에게 가져다 주어야 할 긴밀한 피드백 루프를 놓치고 있습니다.

Kent Beck은 다음과 같이 말합니다:

> 낙관주의는 프로그래밍의 직업병입니다. 피드백이 치료법입니다.

대신, 우리의 접근 방식은 가능한 빨리 **실제** 소비자 가치를 제공하는 데 가깝도록 노력해야 합니다 (종종 "행복한 경로"라고 함). 일단 소량의 소비자 가치를 엔드투엔드로 제공하면, 나머지 요구 사항의 추가 반복은 보통 간단합니다.

## 보고 싶은 테스트의 종류에 대해 생각하기

시작할 때 마음가짐과 목표를 상기합시다:

* **보고 싶은 테스트를 작성하세요**. 소비자의 관점에서 작성하려는 코드를 어떻게 사용하고 싶은지 생각하세요.
* **무엇**과 **왜**에 집중하되 **어떻게**에 산만해지지 마세요.

패키지는 폴더를 가리키고 일부 게시물을 반환할 수 있는 함수를 제공해야 합니다.

```go
var posts []blogposts.Post
posts = blogposts.NewPostsFromFS("some-folder")
```

이것에 대한 테스트를 작성하려면 예제 게시물이 있는 일종의 테스트 폴더가 필요합니다. **이것은 별로 문제가 되지 않지만** 몇 가지 트레이드오프를 만들고 있습니다:

* 각 테스트에 대해 특정 동작을 테스트하기 위해 새 파일을 만들어야 할 수 있습니다
* 파일 로드 실패와 같은 일부 동작은 테스트하기 어려울 것입니다
* 파일 시스템에 액세스해야 하므로 테스트가 약간 더 느리게 실행됩니다

또한 파일 시스템의 특정 구현에 불필요하게 결합하고 있습니다.

### Go 1.16에서 도입된 파일 시스템 추상화

Go 1.16은 파일 시스템에 대한 추상화를 도입했습니다; [io/fs](https://golang.org/pkg/io/fs/) 패키지.

> 패키지 fs는 파일 시스템에 대한 기본 인터페이스를 정의합니다. 파일 시스템은 호스트 운영 체제에서 제공할 수 있지만 다른 패키지에서도 제공할 수 있습니다.

이것은 특정 파일 시스템에 대한 결합을 느슨하게 할 수 있게 하며, 필요에 따라 다른 구현을 주입할 수 있습니다.

> [인터페이스의 생산자 측면에서, 새로운 embed.FS 타입은 zip.Reader와 마찬가지로 fs.FS를 구현합니다. 새로운 os.DirFS 함수는 운영 체제 파일 트리에 의해 지원되는 fs.FS 구현을 제공합니다.](https://golang.org/doc/go1.16#fs)

이 인터페이스를 사용하면 패키지 사용자는 표준 라이브러리에 기본 제공되는 여러 옵션을 사용할 수 있습니다. Go의 표준 라이브러리에 정의된 인터페이스 (예: `io.fs`, [`io.Reader`](https://golang.org/pkg/io/#Reader), [`io.Writer`](https://golang.org/pkg/io/#Writer))를 활용하는 방법을 배우는 것은 느슨하게 결합된 패키지를 작성하는 데 필수적입니다. 이러한 패키지는 소비자의 최소한의 번거로움으로 상상한 것과 다른 컨텍스트에서 재사용할 수 있습니다.

우리의 경우, 소비자가 "실제" 파일 시스템의 파일이 아닌 Go 바이너리에 게시물이 임베딩되기를 원할 수 있습니다. 어느 쪽이든 **코드는 신경 쓸 필요가 없습니다**.

테스트를 위해 [testing/fstest](https://golang.org/pkg/testing/fstest/) 패키지는 [net/http/httptest](https://golang.org/pkg/net/http/httptest/)에서 익숙한 도구와 유사하게 사용할 [io/FS](https://golang.org/pkg/io/fs/#FS)의 구현을 제공합니다.

이 정보를 감안하면 다음이 더 나은 접근 방식인 것 같습니다,

```go
var posts []blogposts.Post
posts = blogposts.NewPostsFromFS(someFS)
```

## 먼저 테스트 작성

범위를 가능한 작고 유용하게 유지해야 합니다. 디렉토리의 모든 파일을 읽을 수 있다는 것을 증명하면 좋은 출발이 될 것입니다. 이것은 우리가 작성하는 소프트웨어에 대한 자신감을 줄 것입니다. 반환된 `[]Post`의 수가 가짜 파일 시스템의 파일 수와 같은지 확인할 수 있습니다.

이 챕터를 진행할 새 프로젝트를 만듭니다.

* `mkdir blogposts`
* `cd blogposts`
* `go mod init github.com/{your-name}/blogposts`
* `touch blogposts_test.go`

```go
package blogposts_test

import (
	"testing"
	"testing/fstest"
)

func TestNewBlogPosts(t *testing.T) {
	fs := fstest.MapFS{
		"hello world.md":  {Data: []byte("hi")},
		"hello-world2.md": {Data: []byte("hola")},
	}

	posts := blogposts.NewPostsFromFS(fs)

	if len(posts) != len(fs) {
		t.Errorf("got %d posts, wanted %d posts", len(posts), len(fs))
	}
}
```

테스트 패키지가 `blogposts_test`임을 주목하세요. 기억하세요, TDD가 잘 실행되면 **소비자 주도** 접근 방식을 취합니다: **소비자**가 관심을 갖지 않기 때문에 내부 세부 사항을 테스트하고 싶지 않습니다. 의도된 패키지 이름에 `_test`를 추가하면 실제 패키지 사용자처럼 패키지에서 내보낸 멤버에만 액세스합니다.

[`fstest.MapFS`](https://golang.org/pkg/testing/fstest/#MapFS) 타입에 대한 액세스를 제공하는 [`testing/fstest`](https://golang.org/pkg/testing/fstest/)를 가져왔습니다. 가짜 파일 시스템은 `fstest.MapFS`를 패키지에 전달합니다.

> MapFS는 경로 이름 (Open에 대한 인자)에서 파일이나 디렉토리에 대한 정보로의 맵으로 표현되는 테스트에 사용할 간단한 인메모리 파일 시스템입니다.

이것은 테스트 파일 폴더를 유지하는 것보다 더 간단하게 느껴지며 더 빨리 실행됩니다.

마지막으로 소비자의 관점에서 API 사용을 코드화한 다음 올바른 수의 게시물을 생성하는지 확인했습니다.

## 테스트 실행 시도

```
./blogpost_test.go:15:12: undefined: blogposts
```

## 테스트가 실행되고 **실패한 테스트 출력을 확인**하기 위한 최소한의 코드 작성

패키지가 존재하지 않습니다. 새 파일 `blogposts.go`를 만들고 그 안에 `package blogposts`를 넣으세요. 그런 다음 해당 패키지를 테스트로 가져와야 합니다. 저에게 imports는 이제 다음과 같습니다:

```go
import (
	blogposts "github.com/quii/learn-go-with-tests/reading-files"
	"testing"
	"testing/fstest"
)
```

이제 새 패키지에 일종의 컬렉션을 반환하는 `NewPostsFromFS` 함수가 없기 때문에 테스트가 컴파일되지 않습니다.

```
./blogpost_test.go:16:12: undefined: blogposts.NewPostsFromFS
```

이것은 테스트를 실행하기 위해 함수의 스켈레톤을 만들도록 강요합니다. 이 시점에서 코드를 과도하게 생각하지 마세요; 실행 중인 테스트를 얻고 예상대로 실패하는지 확인하려고만 합니다. 이 단계를 건너뛰면 가정을 건너뛰고 유용하지 않은 테스트를 작성할 수 있습니다.

```go
package blogposts

import "testing/fstest"

type Post struct {
}

func NewPostsFromFS(fileSystem fstest.MapFS) []Post {
	return nil
}
```

테스트가 이제 올바르게 실패해야 합니다

```
=== RUN   TestNewBlogPosts
    blogposts_test.go:48: got 0 posts, wanted 2 posts
```

## 테스트를 통과시키기 위한 충분한 코드 작성

통과시키기 위해 ["slime"](https://deniseyu.github.io/leveling-up-tdd/)할 **수** 있습니다:

```go
func NewPostsFromFS(fileSystem fstest.MapFS) []Post {
	return []Post{{}, {}}
}
```

하지만 Denise Yu가 썼듯이:

> Sliming은 객체에 "스켈레톤"을 제공하는 데 유용합니다. 인터페이스를 설계하고 로직을 실행하는 것은 두 가지 관심사이며, 전략적으로 sliming 테스트를 사용하면 한 번에 하나에 집중할 수 있습니다.

이미 구조가 있습니다. 그래서 대신 무엇을 해야 하나요?

범위를 줄였으므로 디렉토리를 읽고 발견한 각 파일에 대해 게시물을 만드는 것만 하면 됩니다. 아직 파일을 열고 파싱하는 것에 대해 걱정할 필요가 없습니다.

```go
func NewPostsFromFS(fileSystem fstest.MapFS) []Post {
	dir, _ := fs.ReadDir(fileSystem, ".")
	var posts []Post
	for range dir {
		posts = append(posts, Post{})
	}
	return posts
}
```

[`fs.ReadDir`](https://golang.org/pkg/io/fs/#ReadDir)은 주어진 `fs.FS` 내의 디렉토리를 읽어 [`[]DirEntry`](https://golang.org/pkg/io/fs/#DirEntry)를 반환합니다.

이미 세상에 대한 이상화된 관점이 좌절되었습니다. 오류가 발생할 수 있기 때문이지만, 지금 우리의 초점은 **테스트 통과시키기**이지 디자인 변경이 아니므로 지금은 오류를 무시합니다.

나머지 코드는 간단합니다: 항목을 반복하고, 각각에 대해 `Post`를 만들고, 슬라이스를 반환합니다.

## 리팩토링

테스트가 통과하더라도 구체적인 구현 `fstest.MapFS`에 결합되어 있기 때문에 이 컨텍스트 외부에서 새 패키지를 사용할 수 없습니다. 하지만 그럴 필요는 없습니다. `NewPostsFromFS` 함수의 인자를 표준 라이브러리의 인터페이스를 받아들이도록 변경하세요.

```go
func NewPostsFromFS(fileSystem fs.FS) []Post {
	dir, _ := fs.ReadDir(fileSystem, ".")
	var posts []Post
	for range dir {
		posts = append(posts, Post{})
	}
	return posts
}
```

테스트를 다시 실행하세요: 모든 것이 작동해야 합니다.

### 오류 처리

행복한 경로가 작동하도록 만드는 데 집중할 때 오류 처리를 잠시 미뤄뒀습니다. 기능을 계속 반복하기 전에 파일 작업 시 오류가 발생할 수 있음을 인정해야 합니다. 디렉토리를 읽는 것 외에도 개별 파일을 열 때 문제가 발생할 수 있습니다. 자연스럽게 먼저 테스트를 통해 API를 변경하여 `error`를 반환할 수 있도록 합시다.

```go
func TestNewBlogPosts(t *testing.T) {
	fs := fstest.MapFS{
		"hello world.md":  {Data: []byte("hi")},
		"hello-world2.md": {Data: []byte("hola")},
	}

	posts, err := blogposts.NewPostsFromFS(fs)

	if err != nil {
		t.Fatal(err)
	}

	if len(posts) != len(fs) {
		t.Errorf("got %d posts, wanted %d posts", len(posts), len(fs))
	}
}
```

테스트를 실행하세요: 잘못된 반환 값 수에 대해 불평해야 합니다. 코드 수정은 간단합니다.

```go
func NewPostsFromFS(fileSystem fs.FS) ([]Post, error) {
	dir, err := fs.ReadDir(fileSystem, ".")
	if err != nil {
		return nil, err
	}
	var posts []Post
	for range dir {
		posts = append(posts, Post{})
	}
	return posts, nil
}
```

이것은 테스트를 통과시킵니다. 당신 안의 TDD 실천자는 `fs.ReadDir`에서 오류를 전파하는 코드를 작성하기 전에 실패하는 테스트를 보지 못했다는 것에 짜증이 날 수 있습니다. 이것을 "제대로" 하려면 `fs.ReadDir`이 `error`를 반환하도록 실패하는 `fs.FS` 테스트 더블을 주입하는 새 테스트가 필요합니다.

```go
type StubFailingFS struct {
}

func (s StubFailingFS) Open(name string) (fs.File, error) {
	return nil, errors.New("oh no, i always fail")
}
```

```go
// 나중에
_, err := blogposts.NewPostsFromFS(StubFailingFS{})
```

이것은 우리 접근 방식에 자신감을 줄 것입니다. 사용하는 인터페이스에는 하나의 메서드가 있어 다양한 시나리오를 테스트하기 위한 테스트 더블을 만드는 것이 간단합니다.

어떤 경우에는 오류 처리를 테스트하는 것이 실용적인 것이지만, 우리의 경우 오류로 **흥미로운** 것을 하지 않고 그냥 전파하고 있으므로 새 테스트를 작성하는 번거로움의 가치가 없습니다.

논리적으로 다음 반복은 유용한 데이터를 갖도록 `Post` 타입을 확장하는 것입니다.

## 먼저 테스트 작성

제안된 블로그 게시물 스키마의 첫 번째 줄인 제목 필드부터 시작하겠습니다.

지정된 것과 일치하도록 테스트 파일의 내용을 변경한 다음 올바르게 파싱되었다고 어설션할 수 있습니다.

```go
func TestNewBlogPosts(t *testing.T) {
	fs := fstest.MapFS{
		"hello world.md":  {Data: []byte("Title: Post 1")},
		"hello-world2.md": {Data: []byte("Title: Post 2")},
	}

	// 간결함을 위해 나머지 테스트 코드 생략
	got := posts[0]
	want := blogposts.Post{Title: "Post 1"}

	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %+v, want %+v", got, want)
	}
}
```

## 테스트 실행 시도

```
./blogpost_test.go:58:26: unknown field 'Title' in struct literal of type blogposts.Post
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

테스트가 실행되도록 `Post` 타입에 새 필드를 추가합니다

```go
type Post struct {
	Title string
}
```

테스트를 다시 실행하면 명확하게 실패하는 테스트를 얻어야 합니다

```
=== RUN   TestNewBlogPosts
=== RUN   TestNewBlogPosts/parses**the**post
    blogpost_test.go:61: got {Title:}, want {Title:Post 1}
```

## 테스트를 통과시키기 위한 충분한 코드 작성

각 파일을 연 다음 제목을 추출해야 합니다

```go
func NewPostsFromFS(fileSystem fs.FS) ([]Post, error) {
	dir, err := fs.ReadDir(fileSystem, ".")
	if err != nil {
		return nil, err
	}
	var posts []Post
	for _, f := range dir {
		post, err := getPost(fileSystem, f)
		if err != nil {
			return nil, err //todo: 명확화 필요, 하나의 파일이 실패하면 완전히 실패해야 하나요? 아니면 무시?
		}
		posts = append(posts, post)
	}
	return posts, nil
}

func getPost(fileSystem fs.FS, f fs.DirEntry) (Post, error) {
	postFile, err := fileSystem.Open(f.Name())
	if err != nil {
		return Post{}, err
	}
	defer postFile.Close()

	postData, err := io.ReadAll(postFile)
	if err != nil {
		return Post{}, err
	}

	post := Post{Title: string(postData)[7:]}
	return post, nil
}
```

이 시점에서 우리의 초점은 우아한 코드를 작성하는 것이 아니라 작동하는 소프트웨어를 얻는 것임을 기억하세요.

이것이 작은 전진처럼 느껴지더라도 상당한 양의 코드를 작성하고 오류 처리와 관련하여 몇 가지 가정을 해야 했습니다. 이것은 동료와 이야기하고 최선의 접근 방식을 결정해야 하는 시점입니다.

반복적인 접근 방식은 요구 사항에 대한 이해가 불완전하다는 빠른 피드백을 제공했습니다.

`fs.FS`는 `Open` 메서드로 그 안에 있는 파일을 이름으로 여는 방법을 제공합니다. 거기서 파일의 데이터를 읽고 지금은 정교한 파싱이 필요하지 않습니다. 문자열을 슬라이싱하여 `Title:` 텍스트를 잘라내기만 합니다.

## 리팩토링

'파일 여는 코드'를 '파일 내용 파싱 코드'에서 분리하면 코드를 더 쉽게 이해하고 작업할 수 있습니다.

```go
func getPost(fileSystem fs.FS, f fs.DirEntry) (Post, error) {
	postFile, err := fileSystem.Open(f.Name())
	if err != nil {
		return Post{}, err
	}
	defer postFile.Close()
	return newPost(postFile)
}

func newPost(postFile fs.File) (Post, error) {
	postData, err := io.ReadAll(postFile)
	if err != nil {
		return Post{}, err
	}

	post := Post{Title: string(postData)[7:]}
	return post, nil
}
```

새로운 함수나 메서드를 리팩토링할 때 인자에 주의하고 생각하세요. 테스트가 통과하기 때문에 여기서 설계하고 있으며 무엇이 적절한지 깊이 생각할 수 있습니다. 결합과 응집에 대해 생각하세요. 이 경우 자신에게 물어야 합니다:

> `newPost`가 `fs.File`에 결합되어야 하나요? 이 타입의 모든 메서드와 데이터를 사용하나요? 우리가 **정말로** 필요로 하는 것은 무엇인가요?

우리의 경우 `io.Reader`가 필요한 `io.ReadAll`의 인자로만 사용합니다. 따라서 함수에서 결합을 느슨하게 하고 `io.Reader`를 요청해야 합니다.

```go
func newPost(postFile io.Reader) (Post, error) {
	postData, err := io.ReadAll(postFile)
	if err != nil {
		return Post{}, err
	}

	post := Post{Title: string(postData)[7:]}
	return post, nil
}
```

`fs.DirEntry` 인자를 받는 `getPost` 함수에 대해서도 비슷한 주장을 할 수 있습니다. 그것은 단순히 `Name()`을 호출하여 파일 이름을 가져옵니다. 우리는 그 모든 것이 필요하지 않습니다; 해당 타입에서 분리하고 파일 이름을 문자열로 전달합시다. 완전히 리팩토링된 코드는 다음과 같습니다:

```go
func NewPostsFromFS(fileSystem fs.FS) ([]Post, error) {
	dir, err := fs.ReadDir(fileSystem, ".")
	if err != nil {
		return nil, err
	}
	var posts []Post
	for _, f := range dir {
		post, err := getPost(fileSystem, f.Name())
		if err != nil {
			return nil, err //todo: 명확화 필요, 하나의 파일이 실패하면 완전히 실패해야 하나요? 아니면 무시?
		}
		posts = append(posts, post)
	}
	return posts, nil
}

func getPost(fileSystem fs.FS, fileName string) (Post, error) {
	postFile, err := fileSystem.Open(fileName)
	if err != nil {
		return Post{}, err
	}
	defer postFile.Close()
	return newPost(postFile)
}

func newPost(postFile io.Reader) (Post, error) {
	postData, err := io.ReadAll(postFile)
	if err != nil {
		return Post{}, err
	}

	post := Post{Title: string(postData)[7:]}
	return post, nil
}
```

이제부터 대부분의 노력은 `newPost` 내에서 깔끔하게 포함될 수 있습니다. 파일을 열고 반복하는 것에 대한 관심사는 완료되었으며, 이제 `Post` 타입에 대한 데이터 추출에 집중할 수 있습니다. 기술적으로 필요하지는 않지만, 파일은 관련된 것들을 논리적으로 그룹화하는 좋은 방법이므로 `Post` 타입과 `newPost`를 새 `post.go` 파일로 옮겼습니다.

### 테스트 헬퍼

테스트도 관리해야 합니다. `Post`에 대해 많이 어설션할 것이므로 도움이 되는 코드를 작성해야 합니다

```go
func assertPost(t *testing.T, got blogposts.Post, want blogposts.Post) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %+v, want %+v", got, want)
	}
}
```

```go
assertPost(t, posts[0], blogposts.Post{Title: "Post 1"})
```

## 먼저 테스트 작성

파일에서 다음 줄인 설명을 추출하기 위해 테스트를 더 확장합시다. 통과시키기까지는 이제 편안하고 익숙하게 느껴져야 합니다.

```go
func TestNewBlogPosts(t *testing.T) {
	const (
		firstBody = `Title: Post 1
Description: Description 1`
		secondBody = `Title: Post 2
Description: Description 2`
	)

	fs := fstest.MapFS{
		"hello world.md":  {Data: []byte(firstBody)},
		"hello-world2.md": {Data: []byte(secondBody)},
	}

	// 간결함을 위해 나머지 테스트 코드 생략
	assertPost(t, posts[0], blogposts.Post{
		Title:       "Post 1",
		Description: "Description 1",
	})

}
```

## 테스트 실행 시도

```
./blogpost_test.go:47:58: unknown field 'Description' in struct literal of type blogposts.Post
```

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`Post`에 새 필드를 추가합니다.

```go
type Post struct {
	Title       string
	Description string
}
```

테스트가 이제 컴파일되고 실패해야 합니다.

```
=== RUN   TestNewBlogPosts
    blogpost_test.go:47: got {Title:Post 1
        Description: Description 1 Description:}, want {Title:Post 1 Description:Description 1}
```

## 테스트를 통과시키기 위한 충분한 코드 작성

표준 라이브러리에는 데이터를 줄 단위로 스캔하는 데 도움이 되는 편리한 라이브러리가 있습니다; [`bufio.Scanner`](https://golang.org/pkg/bufio/#Scanner)

> Scanner는 줄바꿈으로 구분된 텍스트 줄 파일과 같은 데이터를 읽기 위한 편리한 인터페이스를 제공합니다.

```go
func newPost(postFile io.Reader) (Post, error) {
	scanner := bufio.NewScanner(postFile)

	scanner.Scan()
	titleLine := scanner.Text()

	scanner.Scan()
	descriptionLine := scanner.Text()

	return Post{Title: titleLine[7:], Description: descriptionLine[13:]}, nil
}
```

편리하게도 읽을 `io.Reader`도 받습니다 (다시 한번 감사합니다, 느슨한 결합), 함수 인자를 변경할 필요가 없습니다.

`Scan`을 호출하여 줄을 읽은 다음 `Text`를 사용하여 데이터를 추출합니다.

이 함수는 절대로 `error`를 반환할 수 없습니다. 이 시점에서 반환 타입에서 제거하고 싶을 수 있지만 나중에 잘못된 파일 구조를 처리해야 한다는 것을 알고 있으므로 그대로 둘 수 있습니다.

## 리팩토링

줄을 스캔한 다음 텍스트를 읽는 것에 대한 반복이 있습니다. 이 작업을 최소한 한 번 더 수행할 것이라는 것을 알고 있으므로 DRY하기 위한 간단한 리팩토링을 시작합시다.

```go
func newPost(postFile io.Reader) (Post, error) {
	scanner := bufio.NewScanner(postFile)

	readLine := func() string {
		scanner.Scan()
		return scanner.Text()
	}

	title := readLine()[7:]
	description := readLine()[13:]

	return Post{Title: title, Description: description}, nil
}
```

이것은 거의 코드 줄을 줄이지 않았지만 그것은 거의 리팩토링의 요점이 아닙니다. 여기서 하려는 것은 코드를 독자에게 조금 더 선언적으로 만들기 위해 줄을 읽는 **무엇**을 **어떻게**에서 분리하는 것입니다.

7과 13의 매직 넘버가 작업을 완료하지만 그다지 설명적이지 않습니다.

```go
const (
	titleSeparator       = "Title: "
	descriptionSeparator = "Description: "
)

func newPost(postFile io.Reader) (Post, error) {
	scanner := bufio.NewScanner(postFile)

	readLine := func() string {
		scanner.Scan()
		return scanner.Text()
	}

	title := readLine()[len(titleSeparator):]
	description := readLine()[len(descriptionSeparator):]

	return Post{Title: title, Description: description}, nil
}
```

창의적인 리팩토링 마인드로 코드를 바라보니, readLine 함수가 태그 제거를 처리하도록 만들고 싶습니다. `strings.TrimPrefix` 함수로 문자열에서 접두사를 제거하는 더 읽기 쉬운 방법도 있습니다.

```go
func newPost(postBody io.Reader) (Post, error) {
	scanner := bufio.NewScanner(postBody)

	readMetaLine := func(tagName string) string {
		scanner.Scan()
		return strings.TrimPrefix(scanner.Text(), tagName)
	}

	return Post{
		Title:       readMetaLine(titleSeparator),
		Description: readMetaLine(descriptionSeparator),
	}, nil
}
```

이 아이디어가 마음에 들 수도 있고 아닐 수도 있지만 저는 좋습니다. 요점은 리팩토링 상태에서 내부 세부 사항을 가지고 자유롭게 놀 수 있고 테스트를 계속 실행하여 상황이 여전히 올바르게 동작하는지 확인할 수 있다는 것입니다. 마음에 들지 않으면 항상 이전 상태로 돌아갈 수 있습니다. TDD 접근 방식은 아이디어로 자주 실험할 수 있는 라이센스를 제공하므로 훌륭한 코드를 작성할 기회가 더 많습니다.

다음 요구 사항은 게시물의 태그를 추출하는 것입니다. 따라하고 있다면 계속 읽기 전에 직접 구현해 보는 것이 좋습니다. 이제 좋은 반복 리듬이 있고 다음 줄을 추출하고 데이터를 파싱하는 것에 자신감이 있어야 합니다.

간결함을 위해 TDD 단계를 거치지 않겠지만 태그가 추가된 테스트입니다.

```go
func TestNewBlogPosts(t *testing.T) {
	const (
		firstBody = `Title: Post 1
Description: Description 1
Tags: tdd, go`
		secondBody = `Title: Post 2
Description: Description 2
Tags: rust, borrow-checker`
	)

	// 간결함을 위해 나머지 테스트 코드 생략
	assertPost(t, posts[0], blogposts.Post{
		Title:       "Post 1",
		Description: "Description 1",
		Tags:        []string{"tdd", "go"},
	})
}
```

제가 쓰는 것을 복사하여 붙여넣기만 하면 자신만 속이는 것입니다. 같은 페이지에 있는지 확인하기 위해 태그 추출을 포함한 제 코드가 있습니다.

```go
const (
	titleSeparator       = "Title: "
	descriptionSeparator = "Description: "
	tagsSeparator        = "Tags: "
)

func newPost(postBody io.Reader) (Post, error) {
	scanner := bufio.NewScanner(postBody)

	readMetaLine := func(tagName string) string {
		scanner.Scan()
		return strings.TrimPrefix(scanner.Text(), tagName)
	}

	return Post{
		Title:       readMetaLine(titleSeparator),
		Description: readMetaLine(descriptionSeparator),
		Tags:        strings.Split(readMetaLine(tagsSeparator), ", "),
	}, nil
}
```

여기에 놀라운 것은 없기를 바랍니다. 태그에 대한 다음 줄을 가져오기 위해 `readMetaLine`을 재사용한 다음 `strings.Split`을 사용하여 분할할 수 있었습니다.

행복한 경로의 마지막 반복은 본문을 추출하는 것입니다.

제안된 파일 형식을 다시 상기합니다.

```markdown
Title: Hello, TDD world!
Description: First post on our wonderful blog
Tags: tdd, go
---
Hello world!

The body of posts starts after the `---`
```

이미 처음 3줄을 읽었습니다. 그런 다음 한 줄 더 읽고 버리고 나머지 파일에 게시물의 본문이 포함됩니다.

## 먼저 테스트 작성

구분 기호와 모든 콘텐츠를 가져오는지 확인하기 위해 몇 개의 줄바꿈이 있는 본문을 갖도록 테스트 데이터를 변경합니다.

```go
	const (
		firstBody = `Title: Post 1
Description: Description 1
Tags: tdd, go
---
Hello
World`
		secondBody = `Title: Post 2
Description: Description 2
Tags: rust, borrow-checker
---
B
L
M`
	)
```

다른 것처럼 어설션에 추가합니다

```go
	assertPost(t, posts[0], blogposts.Post{
		Title:       "Post 1",
		Description: "Description 1",
		Tags:        []string{"tdd", "go"},
		Body: `Hello
World`,
	})
```

## 테스트 실행 시도

```
./blogpost_test.go:60:3: unknown field 'Body' in struct literal of type blogposts.Post
```

예상대로.

## 테스트가 실행되고 실패한 테스트 출력을 확인하기 위한 최소한의 코드 작성

`Post`에 `Body`를 추가하면 테스트가 실패해야 합니다.

```
=== RUN   TestNewBlogPosts
    blogposts_test.go:38: got {Title:Post 1 Description:Description 1 Tags:[tdd go] Body:}, want {Title:Post 1 Description:Description 1 Tags:[tdd go] Body:Hello
        World}
```

## 테스트를 통과시키기 위한 충분한 코드 작성

1. 다음 줄을 스캔하여 `---` 구분 기호를 무시합니다.
2. 더 이상 스캔할 것이 없을 때까지 계속 스캔합니다.

```go
func newPost(postBody io.Reader) (Post, error) {
	scanner := bufio.NewScanner(postBody)

	readMetaLine := func(tagName string) string {
		scanner.Scan()
		return strings.TrimPrefix(scanner.Text(), tagName)
	}

	title := readMetaLine(titleSeparator)
	description := readMetaLine(descriptionSeparator)
	tags := strings.Split(readMetaLine(tagsSeparator), ", ")

	scanner.Scan() // 한 줄 무시

	buf := bytes.Buffer{}
	for scanner.Scan() {
		fmt.Fprintln(&buf, scanner.Text())
	}
	body := strings.TrimSuffix(buf.String(), "\n")

	return Post{
		Title:       title,
		Description: description,
		Tags:        tags,
		Body:        body,
	}, nil
}
```

* `scanner.Scan()`은 스캔할 데이터가 더 있는지 나타내는 `bool`을 반환하므로 데이터 끝까지 계속 읽기 위해 `for` 루프와 함께 사용할 수 있습니다.
* 모든 `Scan()` 후에 `fmt.Fprintln`을 사용하여 버퍼에 데이터를 씁니다. 스캐너가 각 줄에서 줄바꿈을 제거하지만 유지해야 하므로 줄바꿈을 추가하는 버전을 사용합니다.
* 위의 이유로 후행이 없도록 마지막 줄바꿈을 제거해야 합니다.

## 리팩토링

나머지 데이터를 가져오는 아이디어를 함수로 캡슐화하면 미래의 독자가 구현 세부 사항에 대해 걱정하지 않고 `newPost`에서 **무엇**이 일어나고 있는지 빠르게 이해할 수 있습니다.

```go
func newPost(postBody io.Reader) (Post, error) {
	scanner := bufio.NewScanner(postBody)

	readMetaLine := func(tagName string) string {
		scanner.Scan()
		return strings.TrimPrefix(scanner.Text(), tagName)
	}

	return Post{
		Title:       readMetaLine(titleSeparator),
		Description: readMetaLine(descriptionSeparator),
		Tags:        strings.Split(readMetaLine(tagsSeparator), ", "),
		Body:        readBody(scanner),
	}, nil
}

func readBody(scanner *bufio.Scanner) string {
	scanner.Scan() // 한 줄 무시
	buf := bytes.Buffer{}
	for scanner.Scan() {
		fmt.Fprintln(&buf, scanner.Text())
	}
	return strings.TrimSuffix(buf.String(), "\n")
}
```

## 추가 반복

기능의 "스틸 스레드"를 만들었으며, 행복한 경로에 도달하기 위한 가장 짧은 경로를 취했습니다. 하지만 분명히 프로덕션 준비가 되기까지는 거리가 있습니다.

다루지 않은 것:

* 파일 형식이 올바르지 않을 때
* 파일이 `.md`가 아닐 때
* 메타데이터 필드의 순서가 다르면 어떻게 되나요? 허용되어야 하나요? 처리할 수 있어야 하나요?

결정적으로 우리는 작동하는 소프트웨어를 가지고 있고 인터페이스를 정의했습니다. 위의 것들은 단지 추가 반복, 더 많은 테스트를 작성하고 동작을 주도하는 것입니다. 위의 것을 지원하기 위해 **디자인**을 변경할 필요가 없어야 하고 구현 세부 사항만 변경해야 합니다.

목표에 집중하면 전체 디자인에 영향을 미치지 않는 문제에 빠지지 않고 중요한 결정을 내리고 원하는 동작에 대해 검증할 수 있습니다.

## 마무리

`fs.FS` 및 Go 1.16의 다른 변경 사항은 파일 시스템에서 데이터를 읽고 간단히 테스트하는 우아한 방법을 제공합니다.

코드를 "실제로" 시도해 보고 싶다면:

* 프로젝트 내에 `cmd` 폴더를 만들고 `main.go` 파일을 추가합니다
* 다음 코드를 추가합니다

```go
import (
	blogposts "github.com/quii/fstest-spike"
	"log"
	"os"
)

func main() {
	posts, err := blogposts.NewPostsFromFS(os.DirFS("posts"))
	if err != nil {
		log.Fatal(err)
	}
	log.Println(posts)
}
```

* 일부 마크다운 파일을 `posts` 폴더에 추가하고 프로그램을 실행하세요!

프로덕션 코드 간의 대칭을 주목하세요

```go
posts, err := blogposts.NewPostsFromFS(os.DirFS("posts"))
```

그리고 테스트

```go
posts, err := blogposts.NewPostsFromFS(fs)
```

이것은 소비자 주도, 탑다운 TDD가 **올바르게 느껴지는** 때입니다.

패키지 사용자는 테스트를 보고 그것이 무엇을 해야 하고 어떻게 사용하는지 빠르게 파악할 수 있습니다. 유지 관리자로서 **테스트가 소비자의 관점에서 나온 것이므로 유용하다**고 확신할 수 있습니다. 구현 세부 사항이나 다른 부수적인 세부 사항을 테스트하지 않으므로 리팩토링할 때 테스트가 방해가 아니라 도움이 될 것이라고 합리적으로 확신할 수 있습니다.

[**의존성 주입**](dependency-injection.md)과 같은 좋은 소프트웨어 엔지니어링 관행에 의존하여 코드는 테스트하고 재사용하기 쉽습니다.

패키지를 만들 때, 프로젝트 내부에만 있더라도 탑다운 소비자 주도 접근 방식을 선호하세요. 이것은 디자인을 과도하게 상상하고 필요하지 않을 수도 있는 추상화를 만드는 것을 막고 작성하는 테스트가 유용하도록 보장하는 데 도움이 됩니다.

반복적인 접근 방식은 모든 단계를 작게 유지했으며 지속적인 피드백은 다른 더 임시적인 접근 방식보다 불명확한 요구 사항을 더 빨리 발견할 수 있게 도왔습니다.

### 쓰기?

이러한 새로운 기능은 파일을 **읽는** 작업만 있다는 점을 주목하는 것이 중요합니다. 작업에 쓰기가 필요하면 다른 곳을 찾아야 합니다. 표준 라이브러리가 현재 제공하는 것에 대해 계속 생각하는 것을 기억하세요. 데이터를 쓰는 경우 코드를 느슨하게 결합하고 재사용 가능하게 유지하기 위해 `io.Writer`와 같은 기존 인터페이스를 활용하는 것을 고려해야 합니다.

### 추가 읽기

* 이것은 `io/fs`에 대한 가벼운 소개였습니다. [Ben Congdon이 훌륭한 글을 작성했으며](https://benjamincongdon.me/blog/2021/01/21/A-Tour-of-Go-116s-iofs-package/) 이 챕터를 작성하는 데 많은 도움이 되었습니다.
* [파일 시스템 인터페이스에 대한 토론](https://github.com/golang/go/issues/41190)

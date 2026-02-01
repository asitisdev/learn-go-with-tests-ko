# IO와 정렬

**[이 챕터의 모든 코드는 여기에서 찾을 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/io)**

[이전 챕터](json.md)에서 새 엔드포인트 `/league`를 추가하여 애플리케이션을 계속 반복했습니다. 그 과정에서 JSON, 임베딩 타입, 라우팅을 다루는 방법을 배웠습니다.

제품 소유자는 서버가 재시작될 때 소프트웨어가 점수를 잃는 것에 다소 불안해합니다. 이는 스토어의 구현이 인메모리이기 때문입니다. 또한 `/league` 엔드포인트가 승리 수로 정렬된 플레이어를 반환해야 한다는 것을 해석하지 않은 것에도 불만입니다!

## 지금까지의 코드

```go
// server.go
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

// PlayerStore는 플레이어에 대한 점수 정보를 저장합니다
type PlayerStore interface {
	GetPlayerScore(name string) int
	RecordWin(name string)
	GetLeague() []Player
}

// Player는 승리 수와 함께 이름을 저장합니다
type Player struct {
	Name string
	Wins int
}

// PlayerServer는 플레이어 정보를 위한 HTTP 인터페이스입니다
type PlayerServer struct {
	store PlayerStore
	http.Handler
}

const jsonContentType = "application/json"

// NewPlayerServer는 라우팅이 구성된 PlayerServer를 만듭니다
func NewPlayerServer(store PlayerStore) *PlayerServer {
	p := new(PlayerServer)

	p.store = store

	router := http.NewServeMux()
	router.Handle("/league", http.HandlerFunc(p.leagueHandler))
	router.Handle("/players/", http.HandlerFunc(p.playersHandler))

	p.Handler = router

	return p
}

func (p *PlayerServer) leagueHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", jsonContentType)
	json.NewEncoder(w).Encode(p.store.GetLeague())
}

func (p *PlayerServer) playersHandler(w http.ResponseWriter, r *http.Request) {
	player := strings.TrimPrefix(r.URL.Path, "/players/")

	switch r.Method {
	case http.MethodPost:
		p.processWin(w, player)
	case http.MethodGet:
		p.showScore(w, player)
	}
}

func (p *PlayerServer) showScore(w http.ResponseWriter, player string) {
	score := p.store.GetPlayerScore(player)

	if score == 0 {
		w.WriteHeader(http.StatusNotFound)
	}

	fmt.Fprint(w, score)
}

func (p *PlayerServer) processWin(w http.ResponseWriter, player string) {
	p.store.RecordWin(player)
	w.WriteHeader(http.StatusAccepted)
}
```

```go
// in*memory*player_store.go
package main

func NewInMemoryPlayerStore() *InMemoryPlayerStore {
	return &InMemoryPlayerStore{map[string]int{}}
}

type InMemoryPlayerStore struct {
	store map[string]int
}

func (i *InMemoryPlayerStore) GetLeague() []Player {
	var league []Player
	for name, wins := range i.store {
		league = append(league, Player{name, wins})
	}
	return league
}

func (i *InMemoryPlayerStore) RecordWin(name string) {
	i.store[name]++
}

func (i *InMemoryPlayerStore) GetPlayerScore(name string) int {
	return i.store[name]
}
```

```go
// main.go
package main

import (
	"log"
	"net/http"
)

func main() {
	server := NewPlayerServer(NewInMemoryPlayerStore())
	log.Fatal(http.ListenAndServe(":5000", server))
}
```

챕터 상단의 링크에서 해당 테스트를 찾을 수 있습니다.

## 데이터 저장

이를 위해 사용할 수 있는 수십 개의 데이터베이스가 있지만 매우 간단한 접근 방식을 사용하겠습니다. 이 애플리케이션의 데이터를 JSON으로 파일에 저장합니다.

이렇게 하면 데이터가 매우 이식 가능하고 구현하기가 비교적 간단합니다.

특히 잘 확장되지 않지만 프로토타입이므로 지금은 괜찮습니다. 상황이 변경되어 더 이상 적절하지 않으면 사용한 `PlayerStore` 추상화 덕분에 다른 것으로 쉽게 교체할 수 있습니다.

지금은 `InMemoryPlayerStore`를 유지하여 새 스토어를 개발하는 동안 통합 테스트가 계속 통과하도록 합니다. 새 구현이 통합 테스트를 통과시키기에 충분하다고 확신하면 교체한 다음 `InMemoryPlayerStore`를 삭제합니다.

## 먼저 테스트 작성

지금쯤이면 데이터를 읽는(`io.Reader`) 표준 라이브러리 주변의 인터페이스, 데이터를 쓰는(`io.Writer`) 인터페이스, 그리고 실제 파일을 사용하지 않고 이러한 함수를 테스트하기 위해 표준 라이브러리를 사용하는 방법에 익숙해야 합니다.

이 작업을 완료하려면 `PlayerStore`를 구현해야 하므로 구현해야 하는 메서드를 호출하는 스토어에 대한 테스트를 작성합니다. `GetLeague`부터 시작합니다.

```go
//file*system*store_test.go
func TestFileSystemStore(t *testing.T) {

	t.Run("league from a reader", func(t *testing.T) {
		database := strings.NewReader(`[
			{"Name": "Cleo", "Wins": 10},
			{"Name": "Chris", "Wins": 33}]`)

		store := FileSystemPlayerStore{database}

		got := store.GetLeague()

		want := []Player{
			{"Cleo", 10},
			{"Chris", 33},
		}

		assertLeague(t, got, want)
	})
}
```

`FileSystemPlayerStore`가 데이터를 읽는 데 사용할 `Reader`를 반환하는 `strings.NewReader`를 사용하고 있습니다. `main`에서는 파일을 열 것인데, 이것도 `Reader`입니다.

## 테스트 실행 시도

```
# github.com/quii/learn-go-with-tests/io/v1
./file*system*store_test.go:15:12: undefined: FileSystemPlayerStore
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

새 파일에 `FileSystemPlayerStore`를 정의합시다

```go
//file*system*store.go
type FileSystemPlayerStore struct{}
```

다시 시도

```
# github.com/quii/learn-go-with-tests/io/v1
./file*system*store_test.go:15:28: too many values in struct initializer
./file*system*store_test.go:17:15: store.GetLeague undefined (type FileSystemPlayerStore has no field or method GetLeague)
```

`Reader`를 전달하고 있지만 예상하지 않고 아직 `GetLeague`가 정의되지 않아서 불평합니다.

```go
//file*system*store.go
type FileSystemPlayerStore struct {
	database io.Reader
}

func (f *FileSystemPlayerStore) GetLeague() []Player {
	return nil
}
```

한 번 더...

```
=== RUN   TestFileSystemStore//league*from*a_reader
    --- FAIL: TestFileSystemStore//league*from*a_reader (0.00s)
        file*system*store_test.go:24: got [] want [{Cleo 10} {Chris 33}]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

이전에 reader에서 JSON을 읽었습니다

```go
//file*system*store.go
func (f *FileSystemPlayerStore) GetLeague() []Player {
	var league []Player
	json.NewDecoder(f.database).Decode(&league)
	return league
}
```

테스트가 통과해야 합니다.

## 리팩토링

이미 이것을 했습니다! 서버의 테스트 코드는 응답에서 JSON을 디코딩해야 했습니다.

이것을 함수로 DRY해 봅시다.

`league.go`라는 새 파일을 만들고 다음을 넣습니다.

```go
//league.go
func NewLeague(rdr io.Reader) ([]Player, error) {
	var league []Player
	err := json.NewDecoder(rdr).Decode(&league)
	if err != nil {
		err = fmt.Errorf("problem parsing league, %v", err)
	}

	return league, err
}
```

구현과 `server_test.go`의 테스트 헬퍼 `getLeagueFromResponse`에서 이것을 호출합니다

```go
//file*system*store.go
func (f *FileSystemPlayerStore) GetLeague() []Player {
	league, _ := NewLeague(f.database)
	return league
}
```

파싱 에러를 처리하는 전략은 아직 없지만 계속 진행합시다.

### Seeking 문제

구현에 결함이 있습니다. 먼저 `io.Reader`가 어떻게 정의되어 있는지 상기합시다.

```go
type Reader interface {
	Read(p []byte) (n int, err error)
}
```

파일을 사용하면 끝까지 바이트별로 읽는 것을 상상할 수 있습니다. 두 번째로 `Read`를 시도하면 어떻게 됩니까?

현재 테스트의 끝에 다음을 추가합니다.

```go
//file*system*store_test.go

// 다시 읽기
got = store.GetLeague()
assertLeague(t, got, want)
```

이것이 통과하기를 원하지만 테스트를 실행하면 통과하지 않습니다.

문제는 `Reader`가 끝에 도달했으므로 더 이상 읽을 것이 없다는 것입니다. 시작으로 돌아가라고 말할 방법이 필요합니다.

[ReadSeeker](https://golang.org/pkg/io/#ReadSeeker)는 도움이 될 수 있는 표준 라이브러리의 또 다른 인터페이스입니다.

```go
type ReadSeeker interface {
	Reader
	Seeker
}
```

임베딩을 기억하세요? 이것은 `Reader`와 [`Seeker`](https://golang.org/pkg/io/#Seeker)로 구성된 인터페이스입니다

```go
type Seeker interface {
	Seek(offset int64, whence int) (int64, error)
}
```

좋은 것 같습니다. `FileSystemPlayerStore`를 이 인터페이스를 대신 받도록 변경할 수 있을까요?

```go
//file*system*store.go
type FileSystemPlayerStore struct {
	database io.ReadSeeker
}

func (f *FileSystemPlayerStore) GetLeague() []Player {
	f.database.Seek(0, io.SeekStart)
	league, _ := NewLeague(f.database)
	return league
}
```

테스트를 실행해 보면 이제 통과합니다! 다행히 테스트에서 사용한 `strings.NewReader`도 `ReadSeeker`를 구현하므로 다른 변경을 할 필요가 없었습니다.

다음으로 `GetPlayerScore`를 구현합니다.

## 먼저 테스트 작성

```go
//file*system*store_test.go
t.Run("get player score", func(t *testing.T) {
	database := strings.NewReader(`[
		{"Name": "Cleo", "Wins": 10},
		{"Name": "Chris", "Wins": 33}]`)

	store := FileSystemPlayerStore{database}

	got := store.GetPlayerScore("Chris")

	want := 33

	if got != want {
		t.Errorf("got %d want %d", got, want)
	}
})
```

## 테스트 실행 시도

```
./file*system*store_test.go:38:15: store.GetPlayerScore undefined (type FileSystemPlayerStore has no field or method GetPlayerScore)
```

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

테스트를 컴파일하려면 새 타입에 메서드를 추가해야 합니다.

```go
//file*system*store.go
func (f *FileSystemPlayerStore) GetPlayerScore(name string) int {
	return 0
}
```

이제 컴파일되고 테스트가 실패합니다

```
=== RUN   TestFileSystemStore/get*player*score
    --- FAIL: TestFileSystemStore//get*player*score (0.00s)
        file*system*store_test.go:43: got 0 want 33
```

## 테스트를 통과시키기 위한 충분한 코드 작성

리그를 반복하여 플레이어를 찾고 점수를 반환할 수 있습니다

```go
//file*system*store.go
func (f *FileSystemPlayerStore) GetPlayerScore(name string) int {

	var wins int

	for _, player := range f.GetLeague() {
		if player.Name == name {
			wins = player.Wins
			break
		}
	}

	return wins
}
```

## 리팩토링

수십 개의 테스트 헬퍼 리팩토링을 보았으므로 작동하도록 남겨둡니다

```go
//file*system*store_test.go
t.Run("get player score", func(t *testing.T) {
	database := strings.NewReader(`[
		{"Name": "Cleo", "Wins": 10},
		{"Name": "Chris", "Wins": 33}]`)

	store := FileSystemPlayerStore{database}

	got := store.GetPlayerScore("Chris")
	want := 33
	assertScoreEquals(t, got, want)
})
```

마지막으로 `RecordWin`으로 점수를 기록해야 합니다.

## 먼저 테스트 작성

우리의 접근 방식은 쓰기에 대해 상당히 근시안적입니다. 파일에서 JSON의 한 "행"만 (쉽게) 업데이트할 수 없습니다. 모든 쓰기에서 데이터베이스의 *전체* 새 표현을 저장해야 합니다.

어떻게 쓸까요? 일반적으로 `Writer`를 사용하지만 이미 `ReadSeeker`가 있습니다. 잠재적으로 두 개의 종속성을 가질 수 있지만 표준 라이브러리에는 이미 파일과 함께 필요한 모든 일을 할 수 있게 해주는 `ReadWriteSeeker` 인터페이스가 있습니다.

타입을 업데이트합시다

```go
//file*system*store.go
type FileSystemPlayerStore struct {
	database io.ReadWriteSeeker
}
```

컴파일되는지 확인

```
./file*system*store_test.go:15:34: cannot use database (type *strings.Reader) as type io.ReadWriteSeeker in field value:
    *strings.Reader does not implement io.ReadWriteSeeker (missing Write method)
./file*system*store_test.go:36:34: cannot use database (type *strings.Reader) as type io.ReadWriteSeeker in field value:
    *strings.Reader does not implement io.ReadWriteSeeker (missing Write method)
```

`strings.Reader`가 `ReadWriteSeeker`를 구현하지 않는다는 것은 그리 놀랍지 않습니다. 그럼 어떻게 해야 할까요?

두 가지 선택이 있습니다

- 각 테스트에 대해 임시 파일을 만듭니다. `*os.File`은 `ReadWriteSeeker`를 구현합니다. 이것의 장점은 더 많은 통합 테스트가 된다는 것입니다, 파일 시스템에서 정말로 읽고 쓰기 때문에 매우 높은 수준의 자신감을 줄 것입니다. 단점은 더 빠르고 일반적으로 더 간단하기 때문에 단위 테스트를 선호한다는 것입니다. 또한 임시 파일을 만들고 테스트 후 제거되었는지 확인하는 더 많은 작업을 해야 합니다.
- 타사 라이브러리를 사용할 수 있습니다. [Mattetti](https://github.com/mattetti)가 필요한 인터페이스를 구현하고 파일 시스템을 건드리지 않는 [filebuffer](https://github.com/mattetti/filebuffer) 라이브러리를 작성했습니다.

여기서 특히 잘못된 답은 없는 것 같지만 타사 라이브러리를 사용하기로 선택하면 종속성 관리를 설명해야 합니다! 그래서 대신 파일을 사용합니다.

테스트를 추가하기 전에 `strings.Reader`를 `os.File`로 교체하여 다른 테스트를 컴파일해야 합니다.

임시 파일을 만들고 일부 데이터를 안에 넣는 헬퍼 함수를 만들고 점수 테스트를 추상화합시다

```go
//file*system*store_test.go
func createTempFile(t testing.TB, initialData string) (io.ReadWriteSeeker, func()) {
	t.Helper()

	tmpfile, err := os.CreateTemp("", "db")

	if err != nil {
		t.Fatalf("could not create temp file %v", err)
	}

	tmpfile.Write([]byte(initialData))

	removeFile := func() {
		tmpfile.Close()
		os.Remove(tmpfile.Name())
	}

	return tmpfile, removeFile
}

func assertScoreEquals(t testing.TB, got, want int) {
	t.Helper()
	if got != want {
		t.Errorf("got %d want %d", got, want)
	}
}
```

[CreateTemp](https://pkg.go.dev/os#CreateTemp)는 사용할 임시 파일을 만듭니다. 전달한 `"db"` 값은 생성될 임의의 파일 이름 앞에 붙는 접두사입니다. 이것은 우연히 다른 파일과 충돌하지 않도록 하기 위한 것입니다.

`ReadWriteSeeker`(파일)뿐만 아니라 함수도 반환한다는 것을 알 수 있습니다. 테스트가 완료된 후 파일이 제거되도록 해야 합니다. 오류가 발생하기 쉽고 독자에게 흥미롭지 않으므로 파일의 세부 정보를 테스트에 노출하고 싶지 않습니다. `removeFile` 함수를 반환함으로써 헬퍼에서 세부 정보를 처리하고 호출자가 해야 할 일은 `defer cleanDatabase()`를 실행하는 것입니다.

```go
//file*system*store_test.go
func TestFileSystemStore(t *testing.T) {

	t.Run("league from a reader", func(t *testing.T) {
		database, cleanDatabase := createTempFile(t, `[
			{"Name": "Cleo", "Wins": 10},
			{"Name": "Chris", "Wins": 33}]`)
		defer cleanDatabase()

		store := FileSystemPlayerStore{database}

		got := store.GetLeague()

		want := []Player{
			{"Cleo", 10},
			{"Chris", 33},
		}

		assertLeague(t, got, want)

		// 다시 읽기
		got = store.GetLeague()
		assertLeague(t, got, want)
	})

	t.Run("get player score", func(t *testing.T) {
		database, cleanDatabase := createTempFile(t, `[
			{"Name": "Cleo", "Wins": 10},
			{"Name": "Chris", "Wins": 33}]`)
		defer cleanDatabase()

		store := FileSystemPlayerStore{database}

		got := store.GetPlayerScore("Chris")
		want := 33
		assertScoreEquals(t, got, want)
	})
}
```

테스트를 실행하면 통과해야 합니다! 꽤 많은 변경이 있었지만 이제 인터페이스 정의가 완료된 것 같고 이제부터 새 테스트를 추가하는 것이 매우 쉬울 것입니다.

기존 플레이어에 대한 승리 기록의 첫 번째 반복을 얻어봅시다

```go
//file*system*store_test.go
t.Run("store wins for existing players", func(t *testing.T) {
	database, cleanDatabase := createTempFile(t, `[
		{"Name": "Cleo", "Wins": 10},
		{"Name": "Chris", "Wins": 33}]`)
	defer cleanDatabase()

	store := FileSystemPlayerStore{database}

	store.RecordWin("Chris")

	got := store.GetPlayerScore("Chris")
	want := 34
	assertScoreEquals(t, got, want)
})
```

## 테스트 실행 시도

`./file*system*store_test.go:67:8: store.RecordWin undefined (type FileSystemPlayerStore has no field or method RecordWin)`

## 테스트를 실행하고 실패하는 테스트 출력을 확인하기 위한 최소한의 코드 작성

새 메서드 추가

```go
//file*system*store.go
func (f *FileSystemPlayerStore) RecordWin(name string) {

}
```

```
=== RUN   TestFileSystemStore/store*wins*for*existing*players
    --- FAIL: TestFileSystemStore/store*wins*for*existing*players (0.00s)
        file*system*store_test.go:71: got 33 want 34
```

구현이 비어 있으므로 이전 점수가 반환됩니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
//file*system*store.go
func (f *FileSystemPlayerStore) RecordWin(name string) {
	league := f.GetLeague()

	for i, player := range league {
		if player.Name == name {
			league[i].Wins++
		}
	}

	f.database.Seek(0, io.SeekStart)
	json.NewEncoder(f.database).Encode(league)
}
```

왜 `player.Wins++`가 아니라 `league[i].Wins++`를 하는지 궁금할 수 있습니다.

슬라이스를 `range`하면 루프의 현재 인덱스(우리의 경우 `i`)와 해당 인덱스의 요소 *복사본*을 반환합니다. 복사본의 `Wins` 값을 변경해도 반복하는 `league` 슬라이스에는 영향을 주지 않습니다. 그래서 `league[i]`를 수행하여 실제 값에 대한 참조를 가져와서 대신 해당 값을 변경해야 합니다.

테스트를 실행하면 이제 통과해야 합니다.

## 리팩토링

`GetPlayerScore`와 `RecordWin`에서 이름으로 플레이어를 찾기 위해 `[]Player`를 반복하고 있습니다.

`FileSystemStore` 내부에서 이 공통 코드를 리팩토링할 수 있지만 제게는 다른 개발자가 이해하기 쉬운 새 타입으로 올릴 수 있는 유용한 코드처럼 느껴집니다. 지금까지 "League"로 작업하는 것은 항상 `[]Player`였지만 `League`라는 새 타입을 만들 수 있습니다. 그러면 다른 개발자가 이해하기 쉽고 사용할 수 있는 유용한 메서드를 해당 타입에 첨부할 수 있습니다.

`league.go` 안에 다음을 추가합니다

```go
//league.go
type League []Player

func (l League) Find(name string) *Player {
	for i, p := range l {
		if p.Name == name {
			return &l[i]
		}
	}
	return nil
}
```

이제 `League`를 가진 사람이라면 주어진 플레이어를 쉽게 찾을 수 있습니다.

`[]Player` 대신 `League`를 반환하도록 `PlayerStore` 인터페이스를 변경합니다. 테스트를 다시 실행해 보면 인터페이스를 변경했기 때문에 컴파일 문제가 발생하지만 수정하기 매우 쉽습니다; `[]Player`에서 `League`로 반환 타입을 변경하면 됩니다.

이렇게 하면 `file*system*store`의 메서드를 단순화할 수 있습니다.

```go
//file*system*store.go
func (f *FileSystemPlayerStore) GetPlayerScore(name string) int {

	player := f.GetLeague().Find(name)

	if player != nil {
		return player.Wins
	}

	return 0
}

func (f *FileSystemPlayerStore) RecordWin(name string) {
	league := f.GetLeague()
	player := league.Find(name)

	if player != nil {
		player.Wins++
	}

	f.database.Seek(0, io.SeekStart)
	json.NewEncoder(f.database).Encode(league)
}
```

훨씬 좋아 보이고 리팩토링할 수 있는 `League` 주변의 다른 유용한 기능을 찾을 수 있는 방법을 볼 수 있습니다.

이제 새 플레이어의 승리 기록 시나리오를 처리해야 합니다.

## 먼저 테스트 작성

```go
//file*system*store_test.go
t.Run("store wins for new players", func(t *testing.T) {
	database, cleanDatabase := createTempFile(t, `[
		{"Name": "Cleo", "Wins": 10},
		{"Name": "Chris", "Wins": 33}]`)
	defer cleanDatabase()

	store := FileSystemPlayerStore{database}

	store.RecordWin("Pepper")

	got := store.GetPlayerScore("Pepper")
	want := 1
	assertScoreEquals(t, got, want)
})
```

## 테스트 실행 시도

```
=== RUN   TestFileSystemStore/store*wins*for*new*players#01
    --- FAIL: TestFileSystemStore/store*wins*for*new*players#01 (0.00s)
        file*system*store_test.go:86: got 0 want 1
```

## 테스트를 통과시키기 위한 충분한 코드 작성

플레이어를 찾을 수 없어서 `Find`가 `nil`을 반환하는 시나리오를 처리하면 됩니다.

```go
//file*system*store.go
func (f *FileSystemPlayerStore) RecordWin(name string) {
	league := f.GetLeague()
	player := league.Find(name)

	if player != nil {
		player.Wins++
	} else {
		league = append(league, Player{name, 1})
	}

	f.database.Seek(0, io.SeekStart)
	json.NewEncoder(f.database).Encode(league)
}
```

해피 경로가 괜찮아 보이므로 이제 통합 테스트에서 새 `Store`를 사용해 볼 수 있습니다. 이것은 소프트웨어가 작동한다는 더 많은 자신감을 줄 것이고 그 다음 중복된 `InMemoryPlayerStore`를 삭제할 수 있습니다.

`TestRecordingWinsAndRetrievingThem`에서 이전 스토어를 교체합니다.

```go
//server*integration*test.go
database, cleanDatabase := createTempFile(t, "")
defer cleanDatabase()
store := &FileSystemPlayerStore{database}
```

테스트를 실행하면 통과해야 하고 이제 `InMemoryPlayerStore`를 삭제할 수 있습니다. `main.go`에 컴파일 문제가 발생하여 이제 "실제" 코드에서 새 스토어를 사용하도록 동기 부여합니다.

```go
// main.go
package main

import (
	"log"
	"net/http"
	"os"
)

const dbFileName = "game.db.json"

func main() {
	db, err := os.OpenFile(dbFileName, os.O*RDWR|os.O*CREATE, 0666)

	if err != nil {
		log.Fatalf("problem opening %s %v", dbFileName, err)
	}

	store := &FileSystemPlayerStore{db}
	server := NewPlayerServer(store)

	if err := http.ListenAndServe(":5000", server); err != nil {
		log.Fatalf("could not listen on port 5000 %v", err)
	}
}
```

- 데이터베이스용 파일을 만듭니다.
- `os.OpenFile`의 두 번째 인수는 파일을 열기 위한 권한을 정의할 수 있습니다, 우리의 경우 `O*RDWR`은 읽고 쓰기를 원한다는 것을 의미하고 *그리고_ `os.O_CREATE`는 존재하지 않으면 파일을 만든다는 것을 의미합니다.
- 세 번째 인수는 파일에 대한 권한을 설정합니다, 우리의 경우 모든 사용자가 파일을 읽고 쓸 수 있습니다. [(더 자세한 설명은 superuser.com 참조)](https://superuser.com/questions/295591/what-is-the-meaning-of-chmod-666).

이제 프로그램을 실행하면 재시작 사이에 데이터가 파일에 유지됩니다, 만세!

## 더 많은 리팩토링과 성능 문제

누군가가 `GetLeague()` 또는 `GetPlayerScore()`를 호출할 때마다 전체 파일을 읽고 JSON으로 파싱합니다. `FileSystemStore`가 리그 상태를 완전히 담당하기 때문에 그렇게 할 필요가 없습니다; 프로그램이 시작될 때만 파일을 읽고 데이터가 변경될 때만 파일을 업데이트하면 됩니다.

이 초기화 중 일부를 수행하고 읽기에서 사용할 `FileSystemStore`에 값으로 리그를 저장할 수 있는 생성자를 만들 수 있습니다.

```go
//file*system*store.go
type FileSystemPlayerStore struct {
	database io.ReadWriteSeeker
	league   League
}

func NewFileSystemPlayerStore(database io.ReadWriteSeeker) *FileSystemPlayerStore {
	database.Seek(0, io.SeekStart)
	league, _ := NewLeague(database)
	return &FileSystemPlayerStore{
		database: database,
		league:   league,
	}
}
```

이렇게 하면 디스크에서 한 번만 읽으면 됩니다. 이제 디스크에서 리그를 가져오는 모든 이전 호출을 대신 `f.league`를 사용하여 교체할 수 있습니다.

```go
//file*system*store.go
func (f *FileSystemPlayerStore) GetLeague() League {
	return f.league
}

func (f *FileSystemPlayerStore) GetPlayerScore(name string) int {

	player := f.league.Find(name)

	if player != nil {
		return player.Wins
	}

	return 0
}

func (f *FileSystemPlayerStore) RecordWin(name string) {
	player := f.league.Find(name)

	if player != nil {
		player.Wins++
	} else {
		f.league = append(f.league, Player{name, 1})
	}

	f.database.Seek(0, io.SeekStart)
	json.NewEncoder(f.database).Encode(f.league)
}
```

테스트를 실행하려고 하면 이제 `FileSystemPlayerStore` 초기화에 대해 불평하므로 새 생성자를 호출하여 수정하면 됩니다.

### 또 다른 문제

파일을 다루는 방식에 더 순진한 부분이 있어 나중에 매우 불쾌한 버그를 만들 *수* 있습니다.

`RecordWin`할 때 파일의 시작으로 `Seek`한 다음 새 데이터를 씁니다—하지만 새 데이터가 이전에 있던 것보다 작으면 어떻게 됩니까?

현재 경우에는 불가능합니다. 점수를 편집하거나 삭제하지 않으므로 데이터는 커질 수만 있습니다. 그러나 코드를 이대로 두는 것은 무책임합니다; 삭제 시나리오가 나타날 수 있다는 것은 상상할 수 없는 일이 아닙니다.

그런데 이것을 어떻게 테스트할까요? 해야 할 일은 먼저 *쓰는 데이터의 종류를 쓰기에서* 분리하도록 코드를 리팩토링하는 것입니다. 그런 다음 그것을 별도로 테스트하여 원하는 대로 작동하는지 확인할 수 있습니다.

"시작에서 쓰면" 기능을 캡슐화하는 새 타입을 만들겠습니다. `Tape`라고 부르겠습니다. 다음을 포함하는 새 파일을 만듭니다:

```go
// tape.go
package main

import "io"

type tape struct {
	file io.ReadWriteSeeker
}

func (t *tape) Write(p []byte) (n int, err error) {
	t.file.Seek(0, io.SeekStart)
	return t.file.Write(p)
}
```

`Seek` 부분을 캡슐화하므로 이제 `Write`만 구현하고 있습니다. 이것은 `FileSystemStore`가 이제 `Writer`에 대한 참조만 가질 수 있다는 것을 의미합니다.

```go
//file*system*store.go
type FileSystemPlayerStore struct {
	database io.Writer
	league   League
}
```

`Tape`를 사용하도록 생성자 업데이트

```go
//file*system*store.go
func NewFileSystemPlayerStore(database io.ReadWriteSeeker) *FileSystemPlayerStore {
	database.Seek(0, io.SeekStart)
	league, _ := NewLeague(database)

	return &FileSystemPlayerStore{
		database: &tape{database},
		league:   league,
	}
}
```

마지막으로 `RecordWin`에서 `Seek` 호출을 제거하여 원했던 놀라운 결과를 얻을 수 있습니다. 예, 별거 아닌 것 같지만 적어도 다른 종류의 쓰기를 하면 필요한 대로 동작하는 `Write`를 신뢰할 수 있다는 것을 의미합니다. 게다가 이제 잠재적으로 문제가 있는 코드를 별도로 테스트하고 수정할 수 있습니다.

원본 내용보다 작은 것으로 파일의 전체 내용을 업데이트하려는 테스트를 작성합시다.

## 먼저 테스트 작성

테스트는 일부 내용으로 파일을 만들고 `tape`를 사용하여 쓰고 파일에 무엇이 있는지 보기 위해 다시 모두 읽습니다. `tape_test.go`에서:

```go
//tape_test.go
func TestTape_Write(t *testing.T) {
	file, clean := createTempFile(t, "12345")
	defer clean()

	tape := &tape{file}

	tape.Write([]byte("abc"))

	file.Seek(0, io.SeekStart)
	newFileContents, _ := io.ReadAll(file)

	got := string(newFileContents)
	want := "abc"

	if got != want {
		t.Errorf("got %q want %q", got, want)
	}
}
```

## 테스트 실행 시도

```
=== RUN   TestTape_Write
--- FAIL: TestTape_Write (0.00s)
    tape_test.go:23: got 'abc45' want 'abc'
```

생각한 대로입니다! 원하는 데이터를 쓰지만 원본 데이터의 나머지를 남깁니다.

## 테스트를 통과시키기 위한 충분한 코드 작성

`os.File`에는 파일을 효과적으로 비울 수 있는 truncate 함수가 있습니다. 원하는 것을 얻기 위해 이것을 호출하면 됩니다.

`tape`를 다음으로 변경:

```go
//tape.go
type tape struct {
	file *os.File
}

func (t *tape) Write(p []byte) (n int, err error) {
	t.file.Truncate(0)
	t.file.Seek(0, io.SeekStart)
	return t.file.Write(p)
}
```

`io.ReadWriteSeeker`를 예상하지만 `*os.File`을 보내는 여러 곳에서 컴파일러가 실패합니다. 지금쯤이면 이러한 문제를 직접 수정할 수 있어야 하지만 막히면 소스 코드를 확인하세요.

리팩토링을 완료하면 `TestTape_Write` 테스트가 통과해야 합니다!

### 또 다른 작은 리팩토링

`RecordWin`에서 `json.NewEncoder(f.database).Encode(f.league)` 줄이 있습니다.

쓸 때마다 새 인코더를 만들 필요가 없습니다, 생성자에서 초기화하고 대신 사용할 수 있습니다.

타입에 `Encoder`에 대한 참조를 저장하고 생성자에서 초기화:

```go
//file*system*store.go
type FileSystemPlayerStore struct {
	database *json.Encoder
	league   League
}

func NewFileSystemPlayerStore(file *os.File) *FileSystemPlayerStore {
	file.Seek(0, io.SeekStart)
	league, _ := NewLeague(file)

	return &FileSystemPlayerStore{
		database: json.NewEncoder(&tape{file}),
		league:   league,
	}
}
```

`RecordWin`에서 사용.

```go
func (f *FileSystemPlayerStore) RecordWin(name string) {
	player := f.league.Find(name)

	if player != nil {
		player.Wins++
	} else {
		f.league = append(f.league, Player{name, 1})
	}

	f.database.Encode(f.league)
}
```

## 거기서 규칙을 어기지 않았나요? private 것 테스트? 인터페이스 없음?

### private 타입 테스트에 대해

*일반적으로* private 것을 테스트하지 않는 것을 선호하는 것이 사실입니다. 그러면 테스트가 구현에 너무 긴밀하게 결합되어 나중에 리팩토링을 방해할 수 있습니다.

그러나 테스트가 *자신감*을 줘야 한다는 것을 잊지 않아야 합니다.

편집 또는 삭제 기능을 추가하면 구현이 작동할 것이라고 자신하지 못했습니다. 특히 초기 접근 방식의 단점을 인식하지 못할 수 있는 둘 이상의 사람이 작업하는 경우 코드를 그대로 두고 싶지 않았습니다.

마지막으로 그냥 하나의 테스트입니다! 작동 방식을 변경하기로 결정하면 테스트를 삭제하는 것이 재앙이 아니지만 적어도 미래 유지 관리자를 위한 요구 사항을 캡처했습니다.

### 인터페이스

새 `PlayerStore`를 단위 테스트하는 가장 쉬운 경로였기 때문에 `io.Reader`를 사용하여 코드를 시작했습니다. 코드를 개발하면서 `io.ReadWriter`로 이동한 다음 `io.ReadWriteSeeker`로 이동했습니다. 그런 다음 `*os.File` 외에는 표준 라이브러리에 이를 실제로 구현하는 것이 없다는 것을 발견했습니다. 자체 인터페이스를 작성하거나 오픈 소스를 사용할 수도 있었지만 테스트에 임시 파일을 만드는 것이 실용적으로 느껴졌습니다.

마지막으로 `*os.File`에도 있는 `Truncate`가 필요했습니다. 이러한 요구 사항을 캡처하는 자체 인터페이스를 만드는 것이 옵션이었습니다.

```go
type ReadWriteSeekTruncate interface {
	io.ReadWriteSeeker
	Truncate(size int64) error
}
```

하지만 이것이 정말로 무엇을 주나요? 우리는 *모킹하지 않고* **파일 시스템** 스토어가 `*os.File` 외에 다른 타입을 받는 것은 비현실적이므로 인터페이스가 주는 다형성이 필요하지 않습니다.

여기서 한 것처럼 타입을 자르고 바꾸고 실험하는 것을 두려워하지 마세요. 정적으로 타입이 지정된 언어를 사용하는 좋은 점은 컴파일러가 모든 변경에 도움을 줄 것입니다.

## 에러 처리

정렬 작업을 시작하기 전에 현재 코드에 만족하고 가질 수 있는 기술 부채를 제거해야 합니다. 가능한 빨리 작동하는 소프트웨어에 도달하는 것이 중요한 원칙이지만(빨간색 상태 밖으로 나가기) 에러 케이스를 무시해서는 안 됩니다!

`FileSystemStore.go`로 돌아가면 생성자에 `league, _ := NewLeague(f.database)`가 있습니다.

`NewLeague`는 제공하는 `io.Reader`에서 리그를 파싱할 수 없으면 에러를 반환할 수 있습니다.

당시에는 실패하는 테스트가 이미 있었기 때문에 그것을 무시하는 것이 실용적이었습니다. 동시에 해결하려고 했다면 한 번에 두 가지를 저글링했을 것입니다.

생성자가 에러를 반환할 수 있도록 합시다.

```go
//file*system*store.go
func NewFileSystemPlayerStore(file *os.File) (*FileSystemPlayerStore, error) {
	file.Seek(0, io.SeekStart)
	league, err := NewLeague(file)

	if err != nil {
		return nil, fmt.Errorf("problem loading player store from file %s, %v", file.Name(), err)
	}

	return &FileSystemPlayerStore{
		database: json.NewEncoder(&tape{file}),
		league:   league,
	}, nil
}
```

도움이 되는 에러 메시지를 제공하는 것이 매우 중요하다는 것을 기억하세요(테스트처럼). 인터넷에서 사람들은 대부분의 Go 코드가:

```go
if err != nil {
	return err
}
```

라고 농담으로 말합니다.

**그것은 100% 관용적이지 않습니다.** 에러 메시지에 컨텍스트 정보(예: 에러를 일으킨 일)를 추가하면 소프트웨어 운영이 훨씬 쉬워집니다.

컴파일하려고 하면 몇 가지 에러가 발생합니다.

```
./main.go:18:35: multiple-value NewFileSystemPlayerStore() in single-value context
./file*system*store_test.go:35:36: multiple-value NewFileSystemPlayerStore() in single-value context
./file*system*store_test.go:57:36: multiple-value NewFileSystemPlayerStore() in single-value context
./file*system*store_test.go:70:36: multiple-value NewFileSystemPlayerStore() in single-value context
./file*system*store_test.go:85:36: multiple-value NewFileSystemPlayerStore() in single-value context
./server*integration*test.go:12:35: multiple-value NewFileSystemPlayerStore() in single-value context
```

main에서 에러를 출력하고 프로그램을 종료하고 싶습니다.

```go
//main.go
store, err := NewFileSystemPlayerStore(db)

if err != nil {
	log.Fatalf("problem creating file system player store, %v ", err)
}
```

테스트에서 에러가 없다고 어설션해야 합니다. 이를 돕는 헬퍼를 만들 수 있습니다.

```go
//file*system*store_test.go
func assertNoError(t testing.TB, err error) {
	t.Helper()
	if err != nil {
		t.Fatalf("didn't expect an error but got one, %v", err)
	}
}
```

이 헬퍼를 사용하여 다른 컴파일 문제를 해결합니다. 마지막으로 실패하는 테스트가 있어야 합니다:

```
=== RUN   TestRecordingWinsAndRetrievingThem
--- FAIL: TestRecordingWinsAndRetrievingThem (0.00s)
    server*integration*test.go:14: didn't expect an error but got one, problem loading player store from file /var/folders/nj/r_ccbj5d7flds0sf63yy4vb80000gn/T/db841037437, problem parsing league, EOF
```

파일이 비어 있어서 리그를 파싱할 수 없습니다. 에러를 항상 무시했기 때문에 이전에는 에러가 발생하지 않았습니다.

유효한 JSON을 넣어 큰 통합 테스트를 수정합시다:

```go
//server*integration*test.go
func TestRecordingWinsAndRetrievingThem(t *testing.T) {
	database, cleanDatabase := createTempFile(t, `[]`)
	//etc...
}
```

이제 모든 테스트가 통과하므로 파일이 비어 있는 시나리오를 처리해야 합니다.

## 먼저 테스트 작성

```go
//file*system*store_test.go
t.Run("works with an empty file", func(t *testing.T) {
	database, cleanDatabase := createTempFile(t, "")
	defer cleanDatabase()

	_, err := NewFileSystemPlayerStore(database)

	assertNoError(t, err)
})
```

## 테스트 실행 시도

```
=== RUN   TestFileSystemStore/works*with*an*empty*file
    --- FAIL: TestFileSystemStore/works*with*an*empty*file (0.00s)
        file*system*store*test.go:108: didn't expect an error but got one, problem loading player store from file /var/folders/nj/r*ccbj5d7flds0sf63yy4vb80000gn/T/db019548018, problem parsing league, EOF
```

## 테스트를 통과시키기 위한 충분한 코드 작성

생성자를 다음으로 변경

```go
//file*system*store.go
func NewFileSystemPlayerStore(file *os.File) (*FileSystemPlayerStore, error) {

	file.Seek(0, io.SeekStart)

	info, err := file.Stat()

	if err != nil {
		return nil, fmt.Errorf("problem getting file info from file %s, %v", file.Name(), err)
	}

	if info.Size() == 0 {
		file.Write([]byte("[]"))
		file.Seek(0, io.SeekStart)
	}

	league, err := NewLeague(file)

	if err != nil {
		return nil, fmt.Errorf("problem loading player store from file %s, %v", file.Name(), err)
	}

	return &FileSystemPlayerStore{
		database: json.NewEncoder(&tape{file}),
		league:   league,
	}, nil
}
```

`file.Stat`는 파일의 통계를 반환하여 파일 크기를 확인할 수 있습니다. 비어 있으면 빈 JSON 배열을 `Write`하고 나머지 코드를 위해 시작으로 다시 `Seek`합니다.

## 리팩토링

생성자가 이제 좀 지저분하므로 초기화 코드를 함수로 추출합시다:

```go
//file*system*store.go
func initialisePlayerDBFile(file *os.File) error {
	file.Seek(0, io.SeekStart)

	info, err := file.Stat()

	if err != nil {
		return fmt.Errorf("problem getting file info from file %s, %v", file.Name(), err)
	}

	if info.Size() == 0 {
		file.Write([]byte("[]"))
		file.Seek(0, io.SeekStart)
	}

	return nil
}
```

```go
//file*system*store.go
func NewFileSystemPlayerStore(file *os.File) (*FileSystemPlayerStore, error) {

	err := initialisePlayerDBFile(file)

	if err != nil {
		return nil, fmt.Errorf("problem initialising player db file, %v", err)
	}

	league, err := NewLeague(file)

	if err != nil {
		return nil, fmt.Errorf("problem loading player store from file %s, %v", file.Name(), err)
	}

	return &FileSystemPlayerStore{
		database: json.NewEncoder(&tape{file}),
		league:   league,
	}, nil
}
```

## 정렬

제품 소유자는 `/league`가 최고에서 최저 순으로 점수별로 정렬된 플레이어를 반환하기를 원합니다.

여기서 내리는 주요 결정은 소프트웨어에서 이것이 어디서 발생해야 하는지입니다. "실제" 데이터베이스를 사용했다면 `ORDER BY`와 같은 것을 사용하여 정렬이 매우 빠릅니다. 그런 이유로 `PlayerStore`의 구현이 책임져야 할 것 같습니다.

## 먼저 테스트 작성

`TestFileSystemStore`의 첫 번째 테스트에서 어설션을 업데이트할 수 있습니다:

```go
//file*system*store_test.go
t.Run("league sorted", func(t *testing.T) {
	database, cleanDatabase := createTempFile(t, `[
		{"Name": "Cleo", "Wins": 10},
		{"Name": "Chris", "Wins": 33}]`)
	defer cleanDatabase()

	store, err := NewFileSystemPlayerStore(database)

	assertNoError(t, err)

	got := store.GetLeague()

	want := League{
		{"Chris", 33},
		{"Cleo", 10},
	}

	assertLeague(t, got, want)

	// 다시 읽기
	got = store.GetLeague()
	assertLeague(t, got, want)
})
```

들어오는 JSON의 순서가 잘못되었고 `want`는 호출자에게 올바른 순서로 반환되는지 확인합니다.

## 테스트 실행 시도

```
=== RUN   TestFileSystemStore/league*from*a*reader,*sorted
    --- FAIL: TestFileSystemStore/league*from*a*reader,*sorted (0.00s)
        file*system*store_test.go:46: got [{Cleo 10} {Chris 33}] want [{Chris 33} {Cleo 10}]
        file*system*store_test.go:51: got [{Cleo 10} {Chris 33}] want [{Chris 33} {Cleo 10}]
```

## 테스트를 통과시키기 위한 충분한 코드 작성

```go
func (f *FileSystemPlayerStore) GetLeague() League {
	sort.Slice(f.league, func(i, j int) bool {
		return f.league[i].Wins > f.league[j].Wins
	})
	return f.league
}
```

[`sort.Slice`](https://golang.org/pkg/sort/#Slice)

> Slice는 제공된 less 함수가 주어진 슬라이스를 정렬합니다.

쉽습니다!

## 마무리

### 다룬 내용

- `Seeker` 인터페이스와 `Reader` 및 `Writer`와의 관계.
- 파일 작업.
- 모든 지저분한 것을 숨기는 파일 테스트를 위한 사용하기 쉬운 헬퍼 만들기.
- 슬라이스 정렬을 위한 `sort.Slice`.
- 컴파일러를 사용하여 애플리케이션에 안전하게 구조적 변경을 수행.

### 규칙 어기기

- 소프트웨어 엔지니어링의 대부분의 규칙은 실제로 규칙이 아니라 80%의 시간에 작동하는 모범 사례입니다.
- 내부 함수를 테스트하지 않는 이전 "규칙" 중 하나가 도움이 되지 않는 시나리오를 발견하여 규칙을 어겼습니다.
- 규칙을 어길 때 트레이드오프를 이해하는 것이 중요합니다. 우리의 경우 하나의 테스트이고 그렇지 않으면 시나리오를 실행하기가 매우 어려웠을 것이기 때문에 괜찮았습니다.
- 규칙을 어길 수 있으려면 **먼저 이해해야 합니다**. 비유는 기타를 배우는 것입니다. 얼마나 창의적이라고 생각하든 기본을 이해하고 연습해야 합니다.

### 소프트웨어의 현재 상태

- 플레이어를 만들고 점수를 증가시킬 수 있는 HTTP API가 있습니다.
- 모든 사람의 점수를 JSON으로 반환하는 리그를 반환할 수 있습니다.
- 데이터는 JSON 파일로 유지됩니다.

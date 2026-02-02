# HTTP 핸들러 재방문

[**여기에서 모든 코드를 찾을 수 있습니다**](https://github.com/quii/learn-go-with-tests/tree/main/q-and-a/http-handlers-revisited)

이 책에는 이미 [HTTP 핸들러 테스트](http-server.md)에 대한 챕터가 있지만, 이것은 테스트하기 쉽도록 설계하는 것에 대한 더 넓은 논의를 다룹니다.

단일 책임 원칙과 관심사 분리와 같은 원칙을 적용하여 실제 예제를 살펴보고 설계를 개선하는 방법을 알아보겠습니다. 이러한 원칙은 [인터페이스](structs-methods-and-interfaces.md)와 [의존성 주입](dependency-injection.md)을 사용하여 실현할 수 있습니다. 이렇게 하면 핸들러 테스트가 실제로 얼마나 간단한지 보여드리겠습니다.

![Go 커뮤니티에서 자주 묻는 질문 그림](.gitbook/assets/amazing-art.png)

HTTP 핸들러 테스트는 Go 커뮤니티에서 반복되는 질문인 것 같으며, 사람들이 설계 방법을 오해하고 있다는 더 넓은 문제를 지적한다고 생각합니다.

사람들의 테스트 어려움은 실제로 테스트를 작성하는 것보다 코드 설계에서 비롯되는 경우가 많습니다. 이 책에서 자주 강조하듯이:

> 테스트가 고통을 주고 있다면, 그 신호에 귀 기울이고 코드 설계에 대해 생각하세요.

## 예제

[Santosh Kumar가 저에게 트윗했습니다](https://twitter.com/sntshk/status/1255559003339284481)

> mongodb 종속성이 있는 http 핸들러를 어떻게 테스트하나요?

여기 코드가 있습니다

```go
func Registration(w http.ResponseWriter, r *http.Request) {
	var res model.ResponseResult
	var user model.User

	w.Header().Set("Content-Type", "application/json")

	jsonDecoder := json.NewDecoder(r.Body)
	jsonDecoder.DisallowUnknownFields()
	defer r.Body.Close()

	// 적절한 json 본문이 있는지 또는 오류인지 확인
	if err := jsonDecoder.Decode(&user); err != nil {
		res.Error = err.Error()
		// 400 상태 코드 반환
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(res)
		return
	}

	// mongodb에 연결
	client, _ := mongo.NewClient(options.Client().ApplyURI("mongodb://127.0.0.1:27017"))
	ctx, _ := context.WithTimeout(context.Background(), 10*time.Second)
	err := client.Connect(ctx)
	if err != nil {
		panic(err)
	}
	defer client.Disconnect(ctx)
	// 사용자명이 users 데이터스토어에 이미 존재하는지 확인, 그렇다면 400
	// 그렇지 않으면 바로 사용자 삽입
	collection := client.Database("test").Collection("users")
	filter := bson.D{{"username", user.Username}}
	var foundUser model.User
	err = collection.FindOne(context.TODO(), filter).Decode(&foundUser)
	if foundUser.Username == user.Username {
		res.Error = UserExists
		// 400 상태 코드 반환
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(res)
		return
	}

	pass, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		res.Error = err.Error()
		// 400 상태 코드 반환
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(res)
		return
	}
	user.Password = string(pass)

	insertResult, err := collection.InsertOne(context.TODO(), user)
	if err != nil {
		res.Error = err.Error()
		// 400 상태 코드 반환
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(res)
		return
	}

	// 200 반환
	w.WriteHeader(http.StatusOK)
	res.Result = fmt.Sprintf("%s: %s", UserCreated, insertResult.InsertedID)
	json.NewEncoder(w).Encode(res)
	return
}
```

이 하나의 함수가 해야 할 모든 것을 나열해 봅시다:

1. HTTP 응답 작성, 헤더, 상태 코드 등 전송
2. 요청 본문을 `User`로 디코딩
3. 데이터베이스에 연결(및 그 주변의 모든 세부 정보)
4. 데이터베이스를 쿼리하고 결과에 따라 일부 비즈니스 로직 적용
5. 비밀번호 생성
6. 레코드 삽입

이것은 너무 많습니다.

## HTTP 핸들러란 무엇이고 무엇을 해야 하나요?

잠시 Go의 특정 세부 사항을 잊고, 어떤 언어로 작업했든 항상 저에게 도움이 된 것은 [관심사 분리](https://en.wikipedia.org/wiki/Separation_of_concerns)와 [단일 책임 원칙](https://en.wikipedia.org/wiki/Single-responsibility_principle)에 대해 생각하는 것입니다.

해결하려는 문제에 따라 적용하기가 꽤 까다로울 수 있습니다. 책임이 정확히 **무엇**입니까?

얼마나 추상적으로 생각하느냐에 따라 경계가 흐려질 수 있고 때로는 첫 번째 추측이 맞지 않을 수 있습니다.

다행히 HTTP 핸들러의 경우 작업한 프로젝트에 관계없이 무엇을 해야 하는지에 대해 꽤 좋은 생각이 있습니다:

1. HTTP 요청을 수락하고, 파싱하고 검증합니다.
2. 1단계에서 얻은 데이터로 `ImportantBusinessLogic`을 수행하기 위해 일부 `ServiceThing`을 호출합니다.
3. `ServiceThing`이 반환하는 것에 따라 적절한 `HTTP` 응답을 보냅니다.

모든 HTTP 핸들러가 **항상** 대략 이 모양을 가져야 한다고 말하는 것은 아니지만, 100번 중 99번은 저에게 그런 것 같습니다.

이러한 관심사를 분리하면:

* 핸들러 테스트가 쉬워지고 적은 수의 관심사에 집중합니다.
* 중요하게도 `ImportantBusinessLogic` 테스트는 더 이상 `HTTP`와 관련될 필요가 없으며, 비즈니스 로직을 깔끔하게 테스트할 수 있습니다.
* 다른 컨텍스트에서 수정하지 않고도 `ImportantBusinessLogic`을 사용할 수 있습니다.
* `ImportantBusinessLogic`이 하는 일이 변경되더라도 인터페이스가 동일하게 유지되는 한 핸들러를 변경할 필요가 없습니다.

## Go의 핸들러

[`http.HandlerFunc`](https://golang.org/pkg/net/http/#HandlerFunc)

> HandlerFunc 타입은 일반 함수를 HTTP 핸들러로 사용할 수 있게 하는 어댑터입니다.

`type HandlerFunc func(ResponseWriter, *Request)`

독자여, 숨을 쉬고 위의 코드를 보세요. 무엇이 보입니까?

**일부 인수를 받는 함수입니다**

프레임워크 마법, 어노테이션, 마법 빈, 아무것도 없습니다.

그냥 함수이며, **함수를 테스트하는 방법을 알고 있습니다**.

위의 해설과 잘 맞습니다:

* 검사하고, 파싱하고 검증할 데이터 묶음인 [`http.Request`](https://golang.org/pkg/net/http/#Request)를 받습니다.
* > [`http.ResponseWriter` 인터페이스는 HTTP 핸들러가 HTTP 응답을 구성하는 데 사용됩니다.](https://golang.org/pkg/net/http/#ResponseWriter)

### 매우 기본적인 예제 테스트

```go
func Teapot(res http.ResponseWriter, req *http.Request) {
	res.WriteHeader(http.StatusTeapot)
}

func TestTeapotHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	res := httptest.NewRecorder()

	Teapot(res, req)

	if res.Code != http.StatusTeapot {
		t.Errorf("got status %d but wanted %d", res.Code, http.StatusTeapot)
	}
}
```

함수를 테스트하기 위해 **호출**합니다.

테스트를 위해 `http.ResponseWriter` 인수로 `httptest.ResponseRecorder`를 전달하고, 함수는 이를 사용하여 `HTTP` 응답을 작성합니다. 레코더는 전송된 것을 기록(또는 **스파이**)하고, 그런 다음 어설션을 할 수 있습니다.

## 핸들러에서 `ServiceThing` 호출하기

TDD 튜토리얼에 대한 일반적인 불만은 항상 "너무 간단"하고 "현실 세계가 아니다"라는 것입니다. 이에 대한 제 대답은:

> 언급한 예제처럼 모든 코드가 읽고 테스트하기 쉬우면 좋지 않을까요?

이것은 우리가 직면하는 가장 큰 도전 중 하나이지만 계속 노력해야 합니다. 좋은 소프트웨어 엔지니어링 원칙을 연습하고 적용하면 코드를 읽고 테스트하기 쉽게 설계하는 것이 **가능합니다**(반드시 쉽지는 않지만).

이전 핸들러가 하는 일을 요약하면:

1. HTTP 응답 작성, 헤더, 상태 코드 등 전송
2. 요청 본문을 `User`로 디코딩
3. 데이터베이스에 연결(및 그 주변의 모든 세부 정보)
4. 데이터베이스를 쿼리하고 결과에 따라 일부 비즈니스 로직 적용
5. 비밀번호 생성
6. 레코드 삽입

더 이상적인 관심사 분리 아이디어를 적용하면 다음과 같이 되기를 원합니다:

1. 요청 본문을 `User`로 디코딩
2. `UserService.Register(user)` 호출(이것이 `ServiceThing`입니다)
3. 오류가 있으면 그에 따라 행동(예제는 항상 `400 BadRequest`를 보내는데 이것이 맞지 않다고 생각합니다), **지금은** 모든 오류에 대해 `500 Internal Server Error`의 포괄적인 핸들러를 갖겠습니다. 모든 오류에 대해 `500`을 반환하면 끔찍한 API가 된다는 것을 강조해야 합니다! 나중에 [에러 타입](error-types.md)을 사용하여 에러 처리를 더 정교하게 만들 수 있습니다.
4. 오류가 없으면 응답 본문으로 ID와 함께 `201 Created`(다시 간결함/게으름을 위해)

간결함을 위해 일반적인 TDD 프로세스를 거치지 않겠습니다. 다른 챕터에서 예제를 확인하세요.

### 새 설계

```go
type UserService interface {
	Register(user User) (insertedID string, err error)
}

type UserServer struct {
	service UserService
}

func NewUserServer(service UserService) *UserServer {
	return &UserServer{service: service}
}

func (u *UserServer) RegisterUser(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	// 요청 파싱 및 검증
	var newUser User
	err := json.NewDecoder(r.Body).Decode(&newUser)

	if err != nil {
		http.Error(w, fmt.Sprintf("could not decode user payload: %v", err), http.StatusBadRequest)
		return
	}

	// 어려운 작업을 처리할 서비스 thing 호출
	insertedID, err := u.service.Register(newUser)

	// 돌아온 것에 따라 적절히 응답
	if err != nil {
		//todo: 다른 종류의 오류를 다르게 처리
		http.Error(w, fmt.Sprintf("problem registering new user: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	fmt.Fprint(w, insertedID)
}
```

`RegisterUser` 메서드는 `http.HandlerFunc`의 모양과 일치하므로 사용할 준비가 되었습니다. 인터페이스로 캡처된 `UserService`에 대한 종속성을 포함하는 새 타입 `UserServer`에 메서드로 첨부했습니다.

인터페이스는 `HTTP` 관심사가 특정 구현에서 분리되도록 하는 환상적인 방법입니다; 종속성의 메서드를 호출하기만 하면 되고 사용자가 **어떻게** 등록되는지 신경 쓸 필요가 없습니다.

TDD를 따라 이 접근 방식을 더 자세히 탐구하려면 [의존성 주입](dependency-injection.md) 챕터와 ["애플리케이션 구축" 섹션의 HTTP 서버 챕터](http-server.md)를 읽으세요.

이제 등록에 관한 특정 구현 세부 정보에서 분리했으므로 핸들러 코드를 작성하는 것이 간단하고 이전에 설명한 책임을 따릅니다.

### 테스트!

이 단순함은 테스트에 반영됩니다.

```go
type MockUserService struct {
	RegisterFunc    func(user User) (string, error)
	UsersRegistered []User
}

func (m *MockUserService) Register(user User) (insertedID string, err error) {
	m.UsersRegistered = append(m.UsersRegistered, user)
	return m.RegisterFunc(user)
}

func TestRegisterUser(t *testing.T) {
	t.Run("can register valid users", func(t *testing.T) {
		user := User{Name: "CJ"}
		expectedInsertedID := "whatever"

		service := &MockUserService{
			RegisterFunc: func(user User) (string, error) {
				return expectedInsertedID, nil
			},
		}
		server := NewUserServer(service)

		req := httptest.NewRequest(http.MethodGet, "/", userToJSON(user))
		res := httptest.NewRecorder()

		server.RegisterUser(res, req)

		assertStatus(t, res.Code, http.StatusCreated)

		if res.Body.String() != expectedInsertedID {
			t.Errorf("expected body of %q but got %q", res.Body.String(), expectedInsertedID)
		}

		if len(service.UsersRegistered) != 1 {
			t.Fatalf("expected 1 user added but got %d", len(service.UsersRegistered))
		}

		if !reflect.DeepEqual(service.UsersRegistered[0], user) {
			t.Errorf("the user registered %+v was not what was expected %+v", service.UsersRegistered[0], user)
		}
	})

	t.Run("returns 400 bad request if body is not valid user JSON", func(t *testing.T) {
		server := NewUserServer(nil)

		req := httptest.NewRequest(http.MethodGet, "/", strings.NewReader("trouble will find me"))
		res := httptest.NewRecorder()

		server.RegisterUser(res, req)

		assertStatus(t, res.Code, http.StatusBadRequest)
	})

	t.Run("returns a 500 internal server error if the service fails", func(t *testing.T) {
		user := User{Name: "CJ"}

		service := &MockUserService{
			RegisterFunc: func(user User) (string, error) {
				return "", errors.New("couldn't add new user")
			},
		}
		server := NewUserServer(service)

		req := httptest.NewRequest(http.MethodGet, "/", userToJSON(user))
		res := httptest.NewRecorder()

		server.RegisterUser(res, req)

		assertStatus(t, res.Code, http.StatusInternalServerError)
	})
}
```

이제 핸들러가 특정 스토리지 구현에 결합되지 않으므로 가지고 있는 특정 책임을 실행하기 위한 간단하고 빠른 단위 테스트를 작성하는 데 도움이 되는 `MockUserService`를 작성하는 것이 간단합니다.

### 데이터베이스 코드는요? 속이고 있잖아요!

이것은 모두 매우 의도적입니다. HTTP 핸들러가 비즈니스 로직, 데이터베이스, 연결 등에 관심을 갖는 것을 원하지 않습니다.

이렇게 하면 핸들러를 지저분한 세부 정보에서 해방시켰고, 지속성 레이어와 비즈니스 로직도 관련 없는 HTTP 세부 정보에 더 이상 결합되지 않으므로 테스트하기 쉬워졌습니다.

이제 원하는 데이터베이스를 사용하여 `UserService`를 구현하기만 하면 됩니다

```go
type MongoUserService struct {
}

func NewMongoUserService() *MongoUserService {
	//todo: DB URL을 이 함수에 인수로 전달
	//todo: db에 연결, 연결 풀 생성
	return &MongoUserService{}
}

func (m MongoUserService) Register(user User) (insertedID string, err error) {
	// m.mongoConnection을 사용하여 쿼리 수행
	panic("implement me")
}
```

이것을 별도로 테스트할 수 있고 만족하면 `main`에서 이 두 유닛을 작동하는 애플리케이션으로 함께 스냅할 수 있습니다.

```go
func main() {
	mongoService := NewMongoUserService()
	server := NewUserServer(mongoService)
	http.ListenAndServe(":8000", http.HandlerFunc(server.RegisterUser))
}
```

### 적은 노력으로 더 강력하고 확장 가능한 설계

이러한 원칙은 단기적으로 우리의 삶을 더 쉽게 만들 뿐만 아니라 향후 시스템을 확장하기 더 쉽게 만듭니다.

이 시스템의 추가 반복에서 사용자에게 등록 확인 이메일을 보내고 싶어하는 것은 놀랍지 않습니다.

이전 설계에서는 핸들러 **와** 주변 테스트를 변경해야 했습니다. 이것이 종종 코드의 일부가 유지 관리할 수 없게 되는 방법입니다, 점점 더 많은 기능이 이미 그렇게 **설계**되어 있기 때문에 들어옵니다; "HTTP 핸들러"가 모든 것을 처리하도록!

인터페이스를 사용하여 관심사를 분리하면 등록에 대한 비즈니스 로직과 관련이 없으므로 핸들러를 **전혀** 편집할 필요가 없습니다.

## 마무리

Go의 HTTP 핸들러 테스트는 어렵지 않지만 좋은 소프트웨어 설계는 어려울 수 있습니다!

사람들은 HTTP 핸들러가 특별하다고 생각하고 작성할 때 좋은 소프트웨어 엔지니어링 관행을 버려 테스트를 어렵게 만듭니다.

다시 반복합니다; **Go의 http 핸들러는 그냥 함수입니다**. 명확한 책임과 좋은 관심사 분리로 다른 함수처럼 작성하면 테스트하는 데 문제가 없을 것이고 코드베이스가 더 건강해질 것입니다.

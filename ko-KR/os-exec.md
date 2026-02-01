# OS Exec

**[여기에서 모든 코드를 찾을 수 있습니다](https://github.com/quii/learn-go-with-tests/tree/main/q-and-a/os-exec)**

[keith6014](https://www.reddit.com/user/keith6014)가 [reddit](https://www.reddit.com/r/golang/comments/aaz8ji/testdata_and_function_setup_help/)에서 질문합니다

> os/exec.Command()를 사용하여 XML 데이터를 생성하는 명령을 실행하고 있습니다. 명령은 GetData()라는 함수에서 실행됩니다.

> GetData()를 테스트하기 위해 생성한 테스트 데이터가 있습니다.

> _test.go에서 TestGetData가 GetData()를 호출하지만 os.exec를 사용하는 대신 테스트 데이터를 사용하고 싶습니다.

> 이를 달성하는 좋은 방법은 무엇입니까? GetData를 호출할 때 파일을 읽도록 "test" 플래그 모드가 있어야 합니까? 예: GetData(mode string)?

몇 가지 사항

- 테스트하기 어려운 것은 종종 관심사 분리가 올바르지 않기 때문입니다
- 코드에 "테스트 모드"를 추가하지 마세요. 대신 [의존성 주입](./dependency-injection.md)을 사용하여 종속성을 모델링하고 관심사를 분리할 수 있습니다.

코드가 어떻게 생겼을지 추측하는 자유를 취했습니다

```go
type Payload struct {
	Message string `xml:"message"`
}

func GetData() string {
	cmd := exec.Command("cat", "msg.xml")

	out, _ := cmd.StdoutPipe()
	var payload Payload
	decoder := xml.NewDecoder(out)

	// 이 3개는 오류를 반환할 수 있지만 간결함을 위해 무시합니다
	cmd.Start()
	decoder.Decode(&payload)
	cmd.Wait()

	return strings.ToUpper(payload.Message)
}
```

- 프로세스에 외부 명령을 실행할 수 있는 `exec.Command`를 사용합니다
- `cmd.StdoutPipe`에서 출력을 캡처하고 이것은 `io.ReadCloser`를 반환합니다 (이것이 중요해질 것입니다)
- 나머지 코드는 [훌륭한 문서](https://golang.org/pkg/os/exec/#example_Cmd_StdoutPipe)에서 대부분 복사하여 붙여넣었습니다.
    - stdout의 모든 출력을 `io.ReadCloser`로 캡처한 다음 명령을 `Start`하고 `Wait`을 호출하여 모든 데이터를 읽을 때까지 기다립니다. 두 호출 사이에서 데이터를 `Payload` 구조체로 디코딩합니다.

`msg.xml` 안에 포함된 내용입니다

```xml
<payload>
    <message>Happy New Year!</message>
</payload>
```

작동하는 것을 보여주기 위해 간단한 테스트를 작성했습니다

```go
func TestGetData(t *testing.T) {
	got := GetData()
	want := "HAPPY NEW YEAR!"

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

## 테스트 가능한 코드

테스트 가능한 코드는 분리되어 있고 단일 목적을 갖습니다. 저에게 이 코드에는 두 가지 주요 관심사가 있는 것 같습니다

1. 원시 XML 데이터 검색
2. XML 데이터 디코딩 및 비즈니스 로직 적용 (이 경우 `<message>`에 `strings.ToUpper`)

첫 번째 부분은 표준 라이브러리의 예제를 복사하는 것입니다.

두 번째 부분은 비즈니스 로직이 있는 곳이며 코드를 보면 로직의 "틈새"가 어디서 시작하는지 볼 수 있습니다; `io.ReadCloser`를 얻는 곳입니다. 이 기존 추상화를 사용하여 관심사를 분리하고 코드를 테스트 가능하게 만들 수 있습니다.

**GetData의 문제는 비즈니스 로직이 XML을 얻는 수단과 결합되어 있다는 것입니다. 설계를 개선하려면 분리해야 합니다**

`TestGetData`는 두 관심사 사이의 통합 테스트 역할을 할 수 있으므로 계속 작동하는지 확인하기 위해 유지하겠습니다.

새로 분리된 코드는 다음과 같습니다

```go
type Payload struct {
	Message string `xml:"message"`
}

func GetData(data io.Reader) string {
	var payload Payload
	xml.NewDecoder(data).Decode(&payload)
	return strings.ToUpper(payload.Message)
}

func getXMLFromCommand() io.Reader {
	cmd := exec.Command("cat", "msg.xml")
	out, _ := cmd.StdoutPipe()

	cmd.Start()
	data, _ := io.ReadAll(out)
	cmd.Wait()

	return bytes.NewReader(data)
}

func TestGetDataIntegration(t *testing.T) {
	got := GetData(getXMLFromCommand())
	want := "HAPPY NEW YEAR!"

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
```

이제 `GetData`가 단순히 `io.Reader`에서 입력을 받으므로 테스트 가능하게 만들었고 데이터가 어떻게 검색되는지 더 이상 관심이 없습니다; 사람들은 `io.Reader`를 반환하는 모든 것으로 함수를 재사용할 수 있습니다 (매우 일반적임). 예를 들어 커맨드 라인 대신 URL에서 XML을 가져오기 시작할 수 있습니다.

```go
func TestGetData(t *testing.T) {
	input := strings.NewReader(`
<payload>
    <message>Cats are the best animal</message>
</payload>`)

	got := GetData(input)
	want := "CATS ARE THE BEST ANIMAL"

	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

```

`GetData`에 대한 단위 테스트의 예입니다.

Go 내에서 기존 추상화를 사용하여 관심사를 분리함으로써 중요한 비즈니스 로직을 테스트하는 것은 식은 죽 먹기입니다.

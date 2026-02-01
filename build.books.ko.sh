#!/usr/bin/env bash

# 한국어 버전 PDF/EPUB 빌드 스크립트
# Korean version PDF/EPUB build script

set -e

# safer separator for sed
sep=$'\001'

if [ -n "${GITHUB_REF_NAME:-}" ]; then
    sed "s${sep}%%FOOTER_VERSION%%${sep}${GITHUB_REF_NAME}${sep}" meta.tmpl.tex > meta.tex
else
    sed "s${sep}%%FOOTER_VERSION%%${sep}UNDEFINED VERSION${sep}" meta.tmpl.tex > meta.tex
fi

# PDF 빌드 (CJK 한글 지원 Docker 이미지 사용)
# uppalabharath/pandoc-latex-cjk 이미지는 한글 폰트를 포함하고 있음
# --platform linux/amd64: M1/M2 Mac (ARM) 호환성을 위해 필요
docker run --rm --platform linux/amd64 -v `pwd`:/data uppalabharath/pandoc-latex-cjk:latest --from=gfm+rebase_relative_paths -o learn-go-with-tests-ko.pdf \
    -H meta.tex --pdf-engine=xelatex --variable urlcolor=blue --toc --toc-depth=1 \
    -V mainfont="Noto Sans CJK KR" \
    -V sansfont="Noto Sans CJK KR" \
    -V monofont="Noto Sans Mono CJK KR" \
    -B pdf-cover.tex \
    ko-KR/gb-readme.md \
    ko-KR/why.md \
    ko-KR/hello-world.md \
    ko-KR/integers.md \
    ko-KR/iteration.md \
    ko-KR/arrays-and-slices.md \
    ko-KR/structs-methods-and-interfaces.md \
    ko-KR/pointers-and-errors.md \
    ko-KR/maps.md \
    ko-KR/dependency-injection.md \
    ko-KR/mocking.md \
    ko-KR/concurrency.md \
    ko-KR/select.md \
    ko-KR/reflection.md \
    ko-KR/sync.md \
    ko-KR/context.md \
    ko-KR/roman-numerals.md \
    ko-KR/math.md \
    ko-KR/reading-files.md \
    ko-KR/html-templates.md \
    ko-KR/generics.md \
    ko-KR/revisiting-arrays-and-slices-with-generics.md \
    ko-KR/intro-to-acceptance-tests.md \
    ko-KR/scaling-acceptance-tests.md \
    ko-KR/working-without-mocks.md \
    ko-KR/refactoring-checklist.md \
    ko-KR/app-intro.md \
    ko-KR/http-server.md \
    ko-KR/json.md \
    ko-KR/io.md \
    ko-KR/command-line.md \
    ko-KR/time.md \
    ko-KR/websockets.md \
    ko-KR/os-exec.md \
    ko-KR/error-types.md \
    ko-KR/context-aware-reader.md \
    ko-KR/http-handlers-revisited.md \
    ko-KR/anti-patterns.md

# EPUB 빌드
# --platform linux/amd64: M1/M2 Mac (ARM) 호환성을 위해 필요
docker run --rm --platform linux/amd64 -v `pwd`:/data pandoc/latex:latest --from=gfm+rebase_relative_paths --to=epub --file-scope title.txt -o learn-go-with-tests-ko.epub --pdf-engine=xelatex --toc --toc-depth=1 \
    ko-KR/gb-readme.md \
    ko-KR/why.md \
    ko-KR/hello-world.md \
    ko-KR/integers.md \
    ko-KR/iteration.md \
    ko-KR/arrays-and-slices.md \
    ko-KR/structs-methods-and-interfaces.md \
    ko-KR/pointers-and-errors.md \
    ko-KR/maps.md \
    ko-KR/dependency-injection.md \
    ko-KR/mocking.md \
    ko-KR/concurrency.md \
    ko-KR/select.md \
    ko-KR/reflection.md \
    ko-KR/sync.md \
    ko-KR/context.md \
    ko-KR/roman-numerals.md \
    ko-KR/math.md \
    ko-KR/reading-files.md \
    ko-KR/html-templates.md \
    ko-KR/generics.md \
    ko-KR/revisiting-arrays-and-slices-with-generics.md \
    ko-KR/intro-to-acceptance-tests.md \
    ko-KR/scaling-acceptance-tests.md \
    ko-KR/working-without-mocks.md \
    ko-KR/refactoring-checklist.md \
    ko-KR/app-intro.md \
    ko-KR/http-server.md \
    ko-KR/json.md \
    ko-KR/io.md \
    ko-KR/command-line.md \
    ko-KR/time.md \
    ko-KR/websockets.md \
    ko-KR/os-exec.md \
    ko-KR/error-types.md \
    ko-KR/context-aware-reader.md \
    ko-KR/http-handlers-revisited.md \
    ko-KR/anti-patterns.md

echo "✅ 한국어 버전 빌드 완료!"
echo "   - PDF: learn-go-with-tests-ko.pdf"
echo "   - EPUB: learn-go-with-tests-ko.epub"

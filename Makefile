SHELL := /bin/bash
VERSION=$(shell cat VERSION)
CMAKE_VERSION=$(shell sed 's/-alpha//g' VERSION)

ifeq ($(shell uname -s),Darwin)
CONFIG_DARWIN=y
else ifeq ($(OS),Windows_NT)
CONFIG_WINDOWS=y
else
CONFIG_LINUX=y
endif

LIBRARY_PREFIX=lib
ifdef CONFIG_DARWIN
LOADABLE_EXTENSION=dylib
endif

ifdef CONFIG_LINUX
LOADABLE_EXTENSION=so
endif

ifdef CONFIG_WINDOWS
LOADABLE_EXTENSION=dll
LIBRARY_PREFIX=
endif

ifdef IS_MACOS_ARM
RENAME_WHEELS_ARGS=--is-macos-arm
else
RENAME_WHEELS_ARGS=
endif

ifdef python
PYTHON=$(python)
else
PYTHON=python3
endif

PREFIX=dist

# Loadable Output
TARGET_LOADABLE_FILE=$(PREFIX)/debug/rot13.$(LOADABLE_EXTENSION)
TARGET_LOADABLE=$(TARGET_LOADABLE_FILE)
TARGET_LOADABLE_RELEASE_FILE=$(PREFIX)/release/rot13.$(LOADABLE_EXTENSION)
TARGET_LOADABLE_RELEASE=$(TARGET_LOADABLE_RELEASE_FILE)

# Static Output
TARGET_STATIC_FILE=$(PREFIX)/debug/libsqlite_rot13.a
TARGET_STATIC_VECTOR_H=$(PREFIX)/debug/rot13.h
TARGET_STATIC=$(TARGET_STATIC_FILE) $(TARGET_STATIC_VECTOR_H)
TARGET_STATIC_RELEASE_FILE=$(PREFIX)/release/libsqlite_rot13.a
TARGET_STATIC_RELEASE_VECTOR_H=$(PREFIX)/release/rot13.h
TARGET_STATIC_RELEASE=$(TARGET_STATIC_RELEASE_FILE) $(TARGET_STATIC_RELEASE_VECTOR_H)

# WASM Output
WASM_DIRS = api bld common fiddle jaccwabyt jswasm sql tests
WASM_RELEASE_DIRS = common jswasm
WASM_EXTS = js html mjs
TARGET_WASM = $(foreach ext,$(WASM_EXTS),$(wildcard build/wasm/*.$(ext))) $(foreach dir,$(WASM_DIRS),$(wildcard build/wasm/$(dir)))
TARGET_WASM_RELEASE = $(foreach ext,$(WASM_EXTS),$(wildcard build_release/wasm/*.$(ext))) $(foreach dir,$(WASM_RELEASE_DIRS),$(wildcard build_release/wasm/$(dir)))

# Python Output
INTERMEDIATE_PYPACKAGE_EXTENSION=bindings/python/sqlite_rot13/
TARGET_WHEELS=$(PREFIX)/debug/wheels
TARGET_WHEELS_RELEASE=$(PREFIX)/release/wheels

$(PREFIX):
	mkdir -p $(PREFIX)/debug
	mkdir -p $(PREFIX)/release

$(TARGET_LOADABLE): export SQLITE_CMAKE_VERSION = $(CMAKE_VERSION)
$(TARGET_LOADABLE_RELEASE): export SQLITE_CMAKE_VERSION = $(CMAKE_VERSION)

$(TARGET_LOADABLE): $(PREFIX) src/rot13.c
	cmake -B build; make -C build
	cp build/rot13.$(LOADABLE_EXTENSION) $(TARGET_LOADABLE_FILE)

$(TARGET_LOADABLE_RELEASE): $(PREFIX) src/rot13.c
	cmake -DCMAKE_BUILD_TYPE=Release -B build_release; make -C build_release
	cp build_release/rot13.$(LOADABLE_EXTENSION) $(TARGET_LOADABLE_RELEASE_FILE)

$(TARGET_STATIC): export SQLITE_CMAKE_VERSION = $(CMAKE_VERSION)
$(TARGET_STATIC_RELEASE): export SQLITE_CMAKE_VERSION = $(CMAKE_VERSION)

$(TARGET_STATIC): $(prefix) VERSION src/rot13.c
	cmake -B build; make -C build
	cp build/libsqlite_rot13.a $(TARGET_STATIC_FILE)
	cp build/rot13.h $(TARGET_STATIC_VECTOR_H)

$(TARGET_STATIC_RELEASE): $(prefix) VERSION src/rot13.c
	cmake -DCMAKE_BUILD_TYPE=Release -B build_release; make -C build_release
	cp build_release/libsqlite_rot13.a $(TARGET_STATIC_RELEASE_FILE)
	cp build_release/rot13.h $(TARGET_STATIC_RELEASE_VECTOR_H)

$(TARGET_WHEELS): $(PREFIX)
	mkdir -p $(TARGET_WHEELS)

$(TARGET_WHEELS_RELEASE): $(PREFIX)
	mkdir -p $(TARGET_WHEELS_RELEASE)

loadable: $(TARGET_LOADABLE)
loadable-release: $(TARGET_LOADABLE_RELEASE)

static: $(TARGET_STATIC)
static-release: $(TARGET_STATIC_RELEASE)

clean: 
	rm -r dist/*

wasm: $(TARGET_LOADABLE)
	make -C build wasm
	mkdir -p dist/debug/wasm
	cp -r ${TARGET_WASM} dist/debug/wasm/
	echo "✅ generated wasm"

wasm-release: $(TARGET_LOADABLE_RELEASE)
	make -C build_release wasm
	mkdir -p dist/release/wasm
	cp -r ${TARGET_WASM_RELEASE} dist/release/wasm/
	cp dist/release/wasm/index-dist.html dist/release/wasm/index.html
	echo "✅ generated release wasm"

python: $(TARGET_WHEELS) $(TARGET_LOADABLE) bindings/python/setup.py bindings/python/sqlite_rot13/__init__.py scripts/rename-wheels.py
	cp $(TARGET_LOADABLE_FILE) $(INTERMEDIATE_PYPACKAGE_EXTENSION)
	rm $(TARGET_WHEELS)/sqlite_rot13* || true
	pip3 wheel bindings/python/ -w $(TARGET_WHEELS)
	python3 scripts/rename-wheels.py $(TARGET_WHEELS) $(RENAME_WHEELS_ARGS)
	echo "✅ generated python wheel"

python-release: $(TARGET_WHEELS_RELEASE) $(TARGET_LOADABLE_RELEASE) bindings/python/setup.py bindings/python/sqlite_rot13/__init__.py scripts/rename-wheels.py
	cp $(TARGET_LOADABLE_RELEASE_FILE) $(INTERMEDIATE_PYPACKAGE_EXTENSION)
	rm $(TARGET_WHEELS_RELEASE)/sqlite_rot13* || true
	pip3 wheel bindings/python/ -w $(TARGET_WHEELS_RELEASE)
	python3 scripts/rename-wheels.py $(TARGET_WHEELS_RELEASE) $(RENAME_WHEELS_ARGS)
	echo "✅ generated release python wheel"

python-versions: bindings/python/version.py.tmpl
	VERSION=$(VERSION) envsubst < bindings/python/version.py.tmpl > bindings/python/sqlite_rot13/version.py
	echo "✅ generated bindings/python/sqlite_rot13/version.py"

test-loadable:
	$(PYTHON) tests/test-loadable.py

test-python:
	$(PYTHON) tests/test-python.py

test:
	make test-loadable
	make test-python

.PHONY: clean test \
	loadable loadable-release static static-release \
	wasm wasm-release \
	python python-release python-versions version
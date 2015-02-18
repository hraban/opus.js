EXPORTED_FUNCTIONS := _opus_decoder_create _opus_decode_float _opus_decoder_destroy
EMCCFLAGS := -O3 --pre-js pre.js --post-js post.js


noop =
space = $(noop) $(noop)
comma = ,
FULL_EMCCFLAGS := $(EMCCFLAGS) -Llibopusbuild/lib -lopus -s EXPORTED_FUNCTIONS=$(subst $(space),$(comma),"[$(foreach func,$(EXPORTED_FUNCTIONS),'$(func)')]")

default: build/libopus.js

build/libopus.js: libopus
	mkdir -p build
	emcc $(FULL_EMCCFLAGS) -o $@
	@# emcc does not always exit with status false on error, so ensure previous line succeeded
	[ -f build/libopus.js ]

libopus/config.h: libopus/autogen.sh
	(cd libopus; ./autogen.sh)
	(cd libopus; emconfigure ./configure --prefix="$$PWD/../libopusbuild" --enable-fixed-point)

libopus/autogen.sh:
	git submodule init
	git submodule update

libopus: libopus/config.h
	emmake $(MAKE) -C libopus
	emmake $(MAKE) -C libopus install

browser: src/*.js build/libopus.js
	mkdir -p build/
	./node_modules/.bin/browserify \
		--global-transform browserify-shim \
		--bare \
		--no-detect-globals \
		. \
		> build/opus.js
		
clean:
	$(MAKE) -C libopus clean
	rm -f libopus/configure
	rm -rf build libopusbuild

.PHONY: libopus clean browser default

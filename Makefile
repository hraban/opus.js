OPUS_ENCODER_EXPORTS := opus_encoder_create opus_encode opus_encode_float opus_encoder_ctl opus_encoder_destroy
OPUS_DECODER_EXPORTS := opus_decoder_create opus_decode opus_decode_float opus_decoder_ctl opus_decoder_destroy
OPUS_FUNC_EXPORTS := opus_get_version_string $(OPUS_ENCODER_EXPORTS) $(OPUS_DECODER_EXPORTS)

EMCCFLAGS := -s INVOKE_RUN=0 -O3 --llvm-lto 1 --memory-init-file 0 --pre-js pre.js --post-js post.js


noop =
space = $(noop) $(noop)
comma = ,
EXPORT_FUNCS_ARG = -s EXPORTED_FUNCTIONS=$(subst $(space),$(comma),"[$(foreach func,$(OPUS_FUNC_EXPORTS),'_$(func)')]")
FULL_EMCCFLAGS := $(EMCCFLAGS) -Llibopusbuild/lib -lopus  $(EXPORT_FUNCS_ARG)

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

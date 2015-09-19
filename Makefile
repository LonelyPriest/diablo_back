DEPS_FILE=deps.mk
ERL_LIBS=deps
SOURCE_DIR=src
EBIN_DIR=ebin
INCLUDE_DIR=include

INCLUDES=$(wildcard $(INCLUDE_DIR)/*.hrl)
SOURCES=$(wildcard $(SOURCE_DIR)/*.erl)
BEAM_TARGETS=$(patsubst $(SOURCE_DIR)/%.erl, $(EBIN_DIR)/%.beam, $(SOURCES))
TARGETS=$(EBIN_DIR)/knife.app 	$(BEAM_TARGETS)

ifndef USE_SPECS
# our type specs rely on callback specs, which are available in R15B
# upwards.
USE_SPECS:=$(shell erl -noshell -eval 'io:format([list_to_integer(X) || X <- string:tokens(erlang:system_info(version), ".")] >= [5,9]), halt().')
endif

#other args: +native +"{hipe,[o3,verbose]}" -Ddebug=true +debug_info +no_strict_record_tests
ERLC_OPTS=-I $(INCLUDE_DIR) -o $(EBIN_DIR) -Wall -v +debug_info $(call boolean_macro,$(USE_SPECS),use_specs) $(call boolean_macro,$(USE_PROPER_QC),use_proper_qc)

all: $(TARGETS)

$(DEPS_FILE): $(SOURCES) $(INCLUDES)
	rm -f $@
	echo $(subst : ,:,$(foreach FILE,$^,$(FILE):)) | escript generate_deps $@ $(EBIN_DIR)

$(EBIN_DIR)/knife.app: $(SOURCE_DIR)/knife_app.in $(SOURCES) generate_app
	escript generate_app $< $@ $(SOURCE_DIR)

$(EBIN_DIR)/%.beam: $(SOURCE_DIR)/%.erl | $(DEPS_FILE)
	ERL_LIBS=${ERL_LIBS} erlc $(ERLC_OPTS) $<

clean:
	rm -f $(EBIN_DIR)/*.beam
	rm -f $(EBIN_DIR)/knife.app $(EBIN_DIR)/knife.boot $(EBIN_DIR)/knife.script $(EBIN_DIR)/knife.rel
	rm -f $(DEPS_FILE)


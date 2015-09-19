DEPS_FILE=deps.mk
ERL_LIBS=deps
SOURCE_DIR=src
TEST_DIR=test
EBIN_DIR=ebin
INCLUDE_DIR=include
RELEASE_DIR=release
PACKAGE_NAME=forest_agent
VERSION=0.0.0

INCLUDES=$(wildcard $(INCLUDE_DIR)/*.hrl)
SOURCES=$(wildcard $(SOURCE_DIR)/*.erl)
TEST_SOURCE=$(wildcard $(TEST_DIR)/*.erl)

BEAM_TARGETS=$(patsubst $(SOURCE_DIR)/%.erl, $(EBIN_DIR)/%.beam, $(SOURCES))
TEST_TARGETS=$(patsubst $(TEST_DIR)/%.erl, $(TEST_DIR)/%.beam, $(TEST_SOURCE))

TARGETS=$(EBIN_DIR)/forest_agent.app $(BEAM_TARGETS)


## test package
KNIFE_FRME_DIR=../..
TEST_PACKAGE_DIR=../../../package_test

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

$(EBIN_DIR)/forest_agent.app: $(SOURCE_DIR)/forest_agent_app.in $(SOURCES) generate_app
	escript generate_app $< $@ $(SOURCE_DIR)

$(EBIN_DIR)/%.beam: $(SOURCE_DIR)/%.erl | $(DEPS_FILE)
	ERL_LIBS=${ERL_LIBS} erlc $(ERLC_OPTS) $<


release: $(TARGETS)
	mkdir -p ${RELEASE_DIR}/${PACKAGE_NAME}
	cp -r ${EBIN_DIR} ${INCLUDE_DIR} ${RELEASE_DIR}/${PACKAGE_NAME}/
	cd ${RELEASE_DIR};tar -zcf ${PACKAGE_NAME}-${VERSION}.tar.gz ${PACKAGE_NAME};cd -

test: $(TEST_TARGETS)

$(TEST_DIR)/%.beam: $(TEST_DIR)/%.erl
	ERL_LIBS=${ERL_LIBS} erlc -o $(TEST_DIR) +debug_info  $<

clean:
	rm -f $(EBIN_DIR)/*.beam
	rm -f $(EBIN_DIR)/*.app $(EBIN_DIR)/forest_agent.boot $(EBIN_DIR)/forest_agent.script $(EBIN_DIR)/forest_agent.rel
	rm -rf ${RELEASE_DIR}/${PACKAGE_NAME}
	rm -f $(DEPS_FILE)


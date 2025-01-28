SPHINXOPTS   ?=
SPHINXBUILD  ?= sphinx-build
LANGUAGES    ?= en ru
BUILDDIR     ?= build
BUILDER      ?= singlehtml

TEMPLATE_SUBDIR ?= _static_template
TOOLS_DIR        = $(TEMPLATE_SUBDIR)/tools

BUILD_IN_DOCKER ?= on

# URL_NAME      =

ifeq ($(URL_NAME),)
    URL_NAME=UnknownDoc
    $(warning "URL_NAME is not set!")
endif

ifeq ($(BUILD_IN_DOCKER),on)

all build: force
init_container:
	$(TOOLS_DIR)/init_container.sh
%:
	$(TOOLS_DIR)/build_in_container.sh BUILD_IN_DOCKER=off $@
.PHONY: force
else

BUILD_DATE   := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
ifeq ($(shell command -v git;),)
    COMMIT_HASH := $(CI_COMMIT_SHA)
else
    COMMIT_HASH := $(shell git rev-parse --short HEAD)
endif
$(info "$(shell pwd), BUILD_DATE=$(BUILD_DATE), COMMIT_HASH=$(COMMIT_HASH)")

all: build
build: $(BUILDDIR)/version.json $(BUILDER)
define __build_targets
$1: $(LANGUAGES:%=$1-%)
$(foreach lang,$(LANGUAGES),
$1-$(lang):
	@$(SPHINXBUILD) -M $1 $(lang) $(BUILDDIR)/$(lang) $(SPHINXOPTS) $(O)
)
endef

TARGETS_WITH_LANG = html singlehtml clean
$(eval $(foreach target,$(TARGETS_WITH_LANG),$(call __build_targets,$(target))))

clean: $(LANGUAGES:%=cleanApps-%)
cleanApps-%: ;


################################################################################
# Functions and rules for using tools
################################################################################
GEN_VERSION     := $(TOOLS_DIR)/gen_version.sh
$(BUILDDIR)/version.json: force
	@mkdir -p $(BUILDDIR)
	@[ -x "$(GEN_VERSION)" ] && "$(GEN_VERSION)" "$(BUILD_DATE)" "$(COMMIT_HASH)" >$@


# Function for generating common prebuild rules. This is for internal usage.
define _common_prebuild_rules
$(if $(_common_prebuild_rules_once),,
  _common_prebuild_rules_once := true
  $(foreach variable,PREBUILD_OUTPUT_DIR PREBUILD_SOURCE_LOCALES_DIR,
    $(if $(value $(variable)),,$(error $(variable) is not set!)))
$(foreach lang,$(LANGUAGES),
clean-$(lang): cleanGenerates-$(lang)
cleanGenerates-$(lang):
	@rm -rf $(PREBUILD_OUTPUT_DIR)/$(lang)
))
endef

# Generate *.rst* table from *.yml* locales that are in Boro Rails application.
# This function requires two variables to be set:
#   * PREBUILD_OUTPUT_DIR - directory where *.rst* files will be created;
#   * PREBUILD_SOURCE_LOCALES_DIR - directory with Boro Rails application locales.
#
# Params:
#   1. *.rst* generated file name;
#       NOTE: `.rst` extension will add automatically;
#   2. YAML-filename without `(ru|en).yml` postfix;
#   3. subkey in YAML-file, this will pass to script as _tableType_ argument.
define YAML_TO_TABLE_RULE
$(eval
$(call _common_prebuild_rules)
$(foreach lang,$(LANGUAGES),
$(BUILDER)-$(lang): $(PREBUILD_OUTPUT_DIR)/$(lang)/$(strip $(1)).rst
$(PREBUILD_OUTPUT_DIR)/$(lang)/$(strip $(1)).rst: $(PREBUILD_SOURCE_LOCALES_DIR)/$(strip $(2))$(lang).yml
	@mkdir -p "$(PREBUILD_OUTPUT_DIR)/$(lang)"
	$(TOOLS_DIR)/TablesYaml2ReST.py -i "$$<" -o "$$@" --tableType $(3) --schemePath $(4)
))
endef

# Replace macros in xxx_template.rst files with locales from Boro Rails application and put result to PREBUILD_OUTPUT_DIR
# This function requires two variables to be set:
#   * PREBUILD_OUTPUT_DIR - directory where *.rst* files will be created;
#   * PREBUILD_SOURCE_LOCALES_DIR - directory with Boro Rails application locales.
#
# Params:
#   1. *.rst* generated file name;
#       NOTE: `.rst` extension will add automatically;
#   2. Path to template in Sphinx project;
#   3. Model from Boro Rails application. Used to get default values of settings.
define MACRO_REPLACEMENT_RULE
$(eval
$(call _common_prebuild_rules)
$(foreach lang,$(LANGUAGES),
$(BUILDER)-$(lang): $(PREBUILD_OUTPUT_DIR)/$(lang)/$(strip $(1)).rst
$(PREBUILD_OUTPUT_DIR)/$(lang)/$(strip $(1)).rst: $(lang)/$(strip $(2)) $(strip $(3))
$(PREBUILD_OUTPUT_DIR)/$(lang)/$(strip $(1)).rst: $(PREBUILD_SOURCE_LOCALES_DIR)/$(lang).yml
	@mkdir -p "$(PREBUILD_OUTPUT_DIR)/$(lang)"
	$(TOOLS_DIR)/TablesYaml2ReST.py -i "$$<" -o "$$@" --template "$(lang)/$(strip $(2))" --model "$(strip $(3))" --tableType macro_replacement
))
endef

################################################################################
# Install rules
################################################################################
SERVER_DOC_DIR = /opt/elecard/docs
upload_to_%:
	@echo "• Uploading to $* ..."
	ssh $* "mkdir -p $(SERVER_DOC_DIR)/.$(URL_NAME)"
	scp -prq $(BUILDDIR) $*:$(SERVER_DOC_DIR)/.$(URL_NAME)/$(BUILD_DATE)
	ssh $* "$(foreach lang, $(LANGUAGES), \
                  mkdir -p $(SERVER_DOC_DIR)/$(lang); \
                  ln -Tfs ../.$(URL_NAME)/$(BUILD_DATE)/$(lang)/$(BUILDER) $(SERVER_DOC_DIR)/$(lang)/$(URL_NAME); \
                )"

################################################################################
# CI/CD rules
################################################################################
SERVER_CICD_DIR = /Boro_components/Docs/cicd/boro
BRANCH_NAME ?= noname
COMMIT_HASH ?= noname
upload_artifacts_to_%:
	@echo "• Uploading artifacts to $* ..."
	ssh $* "mkdir -p $(SERVER_CICD_DIR)/$(URL_NAME)/$(BRANCH_NAME)/builds"
	scp -pr $(BUILDDIR) $*:$(SERVER_CICD_DIR)/$(URL_NAME)/$(BRANCH_NAME)/builds/$(COMMIT_HASH)
	ssh $* "$(foreach lang, $(LANGUAGES), \
                  rm -rf $(SERVER_CICD_DIR)/$(URL_NAME)/$(BRANCH_NAME)/$(lang); \
                  ln -Tfs ../$(BRANCH_NAME)/builds/$(COMMIT_HASH)/$(lang)/$(BUILDER) $(SERVER_CICD_DIR)/$(URL_NAME)/$(BRANCH_NAME)/$(lang); \
                )"

-include Makefile.local.mk

phony_targets_with_lang := $(foreach lang,$(LANGUAGES),$(foreach target,$(TARGETS_WITH_LANG),$(target)-$(lang)))
.PHONY: all build force $(TARGETS_WITH_LANG) $(phony_targets_with_lang)

endif

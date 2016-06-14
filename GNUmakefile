################################################################################
BIN_DIR               = $(HOME)/bin

################################################################################
# Set to YES to install configuration files as well.
INSTALL_CONFIG_FILES ?= NO

################################################################################
GPG_FILES = etc/gpg.conf etc/gpg-agent.conf etc/scdaemon.conf
GPG_DEST  = ~/.gnupg

################################################################################
define INSTALL_BIN
all: $(BIN_DIR)/$(notdir $(1))
$(BIN_DIR)/$(notdir $(1)): $(1)
	@ mkdir -p $(BIN_DIR)
	install -m 0755 $$< $$@
endef

################################################################################
define INSTALL_FILE
all: $(1)/$(notdir $(2))
$(1)/$(notdir $(2)): $(2)
	@ mkdir -p $(1)
	install -m 0640 $$< $$@
endef

################################################################################
# Install everything in the `bin' directory.
$(foreach f,$(wildcard bin/*),$(eval $(call INSTALL_BIN,$(f))))

################################################################################
ifeq ($(INSTALL_CONFIG_FILES),YES)
$(foreach f,$(GPG_FILES),$(eval $(call INSTALL_FILE,$(GPG_DEST),$(f))))
endif

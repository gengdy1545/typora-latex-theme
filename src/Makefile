base_dir = $(shell pwd)

target_dir = $(base_dir)/latex-theme
working_dir = $(base_dir)/build
windows = windows
macos = macos
linux = linux
typora = typora
pandoc = pandoc
SASS ?= dart-sass
FONT_MODE ?= portable
font_script = $(base_dir)/scripts/prepare-fonts.sh
font_root = $(base_dir)/../resources/fonts

$(shell mkdir -p $(working_dir))
$(shell mkdir -p $(working_dir)/scss)
$(shell mkdir -p $(working_dir)/headers)
$(shell mkdir -p $(target_dir))

$(shell cp -r $(base_dir)/scss/. $(working_dir)/scss)
$(shell cp -r $(base_dir)/headers/. $(working_dir)/headers)

# $(1) is the name of operating system, $(2) is typora or pandoc, $(3) is light or dark theme
define build
	mkdir -p $(target_dir)/$(1)-$(2)
	mkdir -p $(target_dir)/$(1)-$(2)/target
	if [ "$(3)" = "light" ]; then \
		"$(SASS)" --no-source-map --style expanded $(working_dir)/headers/$(1)/$(3).scss $(target_dir)/$(1)-$(2)/target/latex.css; \
	else \
		"$(SASS)" --no-source-map --style expanded $(working_dir)/headers/$(1)/$(3).scss $(target_dir)/$(1)-$(2)/target/latex-$(3).css; \
	fi
endef

# $(1) is the name of operating system
define build-typora
	$(call build,$(1),$(typora),light)
	$(call build,$(1),$(typora),dark)
	sh "$(font_script)" "$(1)" "$(target_dir)/$(1)-$(typora)/target/latex_fonts" "$(FONT_MODE)"
	if [ "$(1)" = "$(windows)" ]; then \
		cp $(base_dir)/scripts/install.ps1 $(target_dir)/$(1)-$(typora); \
	else \
		cp $(base_dir)/scripts/install.sh $(target_dir)/$(1)-$(typora); \
	fi;
	cp $(base_dir)/README.md $(target_dir)/$(1)-$(typora)
	cp $(base_dir)/../LICENSE $(target_dir)/$(1)-$(typora)
	cp $(base_dir)/../credits.md $(target_dir)/$(1)-$(typora)
	mkdir -p $(target_dir)/$(1)-$(typora)/font-licenses
	cp $(font_root)/licenses/*.txt $(target_dir)/$(1)-$(typora)/font-licenses/
	cp $(font_root)/external/README.md $(target_dir)/$(1)-$(typora)/font-licenses/RESTRICTED-FONTS.md
endef

define build-pandoc
	$(call build,$(linux),$(pandoc),light)
	$(call build,$(linux),$(pandoc),dark)
	sh "$(font_script)" "$(linux)" "$(target_dir)/$(linux)-$(pandoc)/target/latex_fonts" "$(FONT_MODE)"
	mkdir -p $(target_dir)/$(linux)-$(pandoc)/font-licenses
	cp $(font_root)/licenses/*.txt $(target_dir)/$(linux)-$(pandoc)/font-licenses/
	cp $(font_root)/external/README.md $(target_dir)/$(linux)-$(pandoc)/font-licenses/RESTRICTED-FONTS.md
endef

.PHONY: all
all: windows macos linux

.PHONY: all-and-compress
all-and-compress: all
	cd $(target_dir)/$(windows)-$(typora); zip -r -FS $(target_dir)/latex-theme-$(windows).zip ./*
	cd $(target_dir)/$(macos)-$(typora); zip -r -FS $(target_dir)/latex-theme-$(macos).zip ./*
	cd $(target_dir)/$(linux)-$(typora); zip -r -FS $(target_dir)/latex-theme-$(linux).zip ./*

.PHONY: windows
windows:
	$(call build-typora,$(windows))

.PHONY: macos
macos:
	$(call build-typora,$(macos))

.PHONY: linux
linux:
	$(call build-typora,$(linux))

.PHONY: pandoc
pandoc:
	$(call build-pandoc,$(linux))

.PHONY: clean
clean:
	rm -rf $(target_dir) $(working_dir) $(base_dir)/.sass-cache

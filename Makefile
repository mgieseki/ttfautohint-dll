# Makefile to build a statically linked DLL of ttfautohint
# https://www.freetype.org/ttfautohint

FREETYPE_VER   := 2.9.1
HARFBUZZ_VER   := 2.1.1
TTFAUTOHINT_VER:= 1.8.2

FREETYPE_FNAME := freetype-$(FREETYPE_VER)
HARFBUZZ_FNAME := harfbuzz-$(HARFBUZZ_VER)
TTFAUTOHINT_FNAME := ttfautohint-$(TTFAUTOHINT_VER)

ifeq ($(XCOMPILE), mingw32)
	HOST := i686-w64-mingw32
else ifeq ($(XCOMPILE), mingw64)
	HOST := x86_64-w64-mingw32
endif

CONFIGURE := configure
ifndef HOST
	CPP := cpp
	DLLWRAP := dllwrap
	STRIP := strip
else
	CPP := $(HOST)-cpp
	DLLWRAP := $(HOST)-dllwrap
	STRIP := $(HOST)-strip
	CONFIGURE += --host=$(HOST)
endif

ARCH := $(shell $(CPP) -dumpmachine | sed 's/-.*$$//')
ifeq ($(ARCH), x86_64)
	ARCHBITS := 64
else
	ARCHBITS := 32
endif

ROOT := $(shell pwd)
PREFIX := $(ROOT)/local$(ARCHBITS)
BUILDDIR := $(ROOT)/build$(ARCHBITS)
SRCDIR := $(ROOT)/src
LIBDIR := $(PREFIX)/lib

CFLAGS := -g -O2
CPPFLAGS := -I$(PREFIX)/include
LDFLAGS := -L$(LIBDIR)

LIBS := $(LIBDIR)/libttfautohint.a $(LIBDIR)/libharfbuzz.a $(LIBDIR)/libfreetype.a

all: $(PREFIX)/bin/ttfautohint.dll

# create zip archive containing the DLL and the development files
dist: $(PREFIX)/bin/ttfautohint.dll
	$(eval TA_VER:=$(shell grep "PACKAGE_VERSION='.*'" $(SRCDIR)/$(TTFAUTOHINT_FNAME)/configure|sed "s/^.*'\(.*\)'.*$$/\1/"))
	rm -f $(ROOT)/ttfautohint-$(TA_VER)-dll$(ARCHBITS)
	cp -p COPYING-dll $(PREFIX)/COPYING
	cd $(PREFIX); \
	zip -q $(ROOT)/ttfautohint-$(TA_VER)-dll$(ARCHBITS).zip \
		COPYING \
		bin/ttfautohint.dll \
		include/ttfautohint* \
		lib/ttfautohint.dll.a

#------------------------------------------------------------------------------
# create ttfautohint.dll and the corresponding import library ttfautohint.dll.a
#------------------------------------------------------------------------------

$(PREFIX)/bin/ttfautohint.dll: ttfautohint.def $(LIBS)
	$(DLLWRAP) --def $< --dllname $(notdir $@) --output-lib $(notdir $@).a $(LIBS)
	mv $(notdir $@) $@
	mv $(notdir $@).a $(LIBDIR)
	$(STRIP) $@

# --------------------
# build libfreetype.a
# --------------------

$(LIBDIR)/libfreetype.a: $(BUILDDIR)/$(FREETYPE_FNAME)/Makefile
	$(MAKE) -C $(BUILDDIR)/$(FREETYPE_FNAME)
	$(MAKE) -C $(BUILDDIR)/$(FREETYPE_FNAME) install

$(BUILDDIR)/$(FREETYPE_FNAME)/Makefile: src/$(FREETYPE_FNAME)/configure
	mkdir -p $(dir $@)
	cd $(dir $@); \
	$(ROOT)/src/$(FREETYPE_FNAME)/$(CONFIGURE) \
		--without-bzip2 \
		--without-png \
		--without-zlib \
		--without-harfbuzz \
		--prefix="$(PREFIX)" \
		--enable-static \
		--disable-shared \
		PKG_CONFIG=" " \
		CFLAGS="$(CPPFLAGS) $(CFLAGS)" \
		CXXFLAGS="$(CPPFLAGS) $(CXXFLAGS)" \
		LDFLAGS="$(LDFLAGS)"

src/$(FREETYPE_FNAME)/configure:
	wget https://download.savannah.gnu.org/releases/freetype/$(FREETYPE_FNAME).tar.bz2
	mkdir -p src
	tar xjf $(FREETYPE_FNAME).tar.bz2 -C src
	rm -f $(FREETYPE_FNAME).tar.bz2

# -------------------
# build libharfbuzz.a
# -------------------

$(LIBDIR)/libharfbuzz.a: $(BUILDDIR)/$(HARFBUZZ_FNAME)/Makefile
	$(MAKE) -C $(BUILDDIR)/$(HARFBUZZ_FNAME)
	$(MAKE) -C $(BUILDDIR)/$(HARFBUZZ_FNAME) install

$(BUILDDIR)/$(HARFBUZZ_FNAME)/Makefile: $(LIBDIR)/libfreetype.a src/$(HARFBUZZ_FNAME)/configure
	mkdir -p $(dir $@)
	cd $(dir $@); \
	$(ROOT)/src/$(HARFBUZZ_FNAME)/$(CONFIGURE) \
		--disable-dependency-tracking \
		--disable-gtk-doc-html \
		--with-glib=no \
		--with-cairo=no \
		--with-fontconfig=no \
		--with-icu=no \
		--prefix=$(PREFIX) \
		--enable-static \
		--disable-shared \
		CFLAGS="$(CPPFLAGS) $(CFLAGS)" \
		CXXFLAGS="$(CPPFLAGS) $(CXXFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		PKG_CONFIG=true \
		FREETYPE_CFLAGS="$(CPPFLAGS)/freetype2" \
		FREETYPE_LIBS="$(LDFLAGS) -lfreetype"

src/$(HARFBUZZ_FNAME)/configure:
	wget https://www.freedesktop.org/software/harfbuzz/release/$(HARFBUZZ_FNAME).tar.bz2
	tar xjf $(HARFBUZZ_FNAME).tar.bz2 -C src
	rm -f $(HARFBUZZ_FNAME).tar.bz2

# ----------------------
# build libttfautohint.a
# ----------------------

$(LIBDIR)/libttfautohint.a: $(LIBDIR)/libfreetype.a $(LIBDIR)/libharfbuzz.a $(BUILDDIR)/$(TTFAUTOHINT_FNAME)/Makefile
	$(MAKE) -C $(BUILDDIR)/$(TTFAUTOHINT_FNAME)
	$(MAKE) -C $(BUILDDIR)/$(TTFAUTOHINT_FNAME) install
	strip $(PREFIX)/bin/ttfautohint.exe

$(BUILDDIR)/$(TTFAUTOHINT_FNAME)/Makefile: src/$(TTFAUTOHINT_FNAME)/configure
	mkdir -p $(dir $@)
	cd $(dir $@); \
	$(ROOT)/src/$(TTFAUTOHINT_FNAME)/$(CONFIGURE) \
		--disable-dependency-tracking \
		--disable-shared \
		--enable-static \
		--without-qt \
		--without-doc \
		--prefix="$(PREFIX)" \
		--with-freetype-config="$(PREFIX)/bin/freetype-config" \
		CFLAGS="$(CPPFLAGS) $(CFLAGS)" \
		CXXFLAGS="$(CPPFLAGS) $(CXXFLAGS) -I$(BUILDDIR)/$(TTFAUTOHINT_FNAME)/lib" \
		LDFLAGS="$(LDFLAGS)" \
		PKG_CONFIG=true \
		HARFBUZZ_CFLAGS="$(CPPFLAGS)/harfbuzz" \
		HARFBUZZ_LIBS="$(LDFLAGS) -lharfbuzz"

src/$(TTFAUTOHINT_FNAME)/configure: src/ttfautohint/bootstrap
	wget https://download.savannah.gnu.org/releases/freetype/$(TTFAUTOHINT_FNAME).tar.gz
	tar xzf $(TTFAUTOHINT_FNAME).tar.gz -C src
	rm -f $(TTFAUTOHINT_FNAME).tar.gz

clean:
	rm -rf $(BUILDDIR)


libexec_PROGRAMS = ibus-engine-kkc ibus-setup-kkc
noinst_LTLIBRARIES = libutil.la

libutil_la_VALAFLAGS =				\
	-H libutil.h --vapi ibus-kkc.vapi	\
	--vapidir=.				\
	--pkg config				\
	--pkg gee-1.0				\
	--pkg kkc-1.0				\
	--pkg ibus-1.0				\
	--library ibus-kkc			\
	$(VALAFLAGS)
libutil_la_SOURCES =				\
	preferences.vala			\
	plist.vala
libutil_la_CFLAGS =				\
	$(COMMON_CFLAGS)

BUILT_SOURCES = ibus-kkc.vapi

# force include config.h before gi18n.h.
AM_CPPFLAGS = -include $(CONFIG_HEADER)

COMMON_CFLAGS =					\
	$(IBUS_CFLAGS)				\
	$(LIBKKC_CFLAGS)			\
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\"	\
	-DLOCALEDIR=\"$(datadir)/locale\"	\
	-DSETUPDIR=\"$(setupdir)\"		\
	-DLIBEXECDIR=\"$(libexecdir)\"		\
	-DDATADIR=\"$(datadir)\"

COMMON_LIBS =					\
	$(IBUS_LIBS)				\
	$(LIBKKC_LIBS)

ibus_engine_kkc_VALAFLAGS =			\
	--vapidir=.				\
	--pkg config --pkg ibus-kkc		\
	$(VALAFLAGS)

ibus_engine_kkc_CFLAGS =			\
	$(COMMON_CFLAGS)

ibus_engine_kkc_LDADD =				\
	$(COMMON_LIBS)				\
	libutil.la

ibus_engine_kkc_SOURCES =			\
	engine.vala

ibus_setup_kkc_VALAFLAGS =			\
	--vapidir=.				\
	--pkg config				\
	--pkg ibus-kkc				\
	--pkg gtk+-3.0				\
	$(VALAFLAGS)

ibus_setup_kkc_CFLAGS =				\
	$(COMMON_CFLAGS)			\
	$(GTK_CFLAGS)

ibus_setup_kkc_LDADD =				\
	$(COMMON_LIBS)				\
	$(GTK_LIBS)				\
	libutil.la

ibus_setup_kkc_SOURCES =			\
	setup.vala

setupdir = $(pkgdatadir)/setup
setup_DATA = ibus-kkc-preferences.ui

desktop_in_in_files = ibus-setup-kkc.desktop.in.in
desktop_in_files = $(desktop_in_in_files:.in.in=.in)

$(desktop_in_files): %.desktop.in: %.desktop.in.in Makefile
	$(AM_V_GEN) sed \
	       -e "s|\@libexecdir\@|$(libexecdir)|" \
	       -e "s|\@pkgdatadir\@|$(pkgdatadir)|" \
	       $< > $@.tmp && mv $@.tmp $@

desktopdir=$(datadir)/applications
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)

@INTLTOOL_DESKTOP_RULE@

component_DATA = kkc.xml
componentdir = $(datadir)/ibus/component

edit = sed \
	-e 's|@LIBEXECDIR[@]|$(libexecdir)|g' \
	-e 's|@PKGDATADIR[@]|$(pkgdatadir)|g'

kkc.xml.in: kkc.xml.in.in
	$(AM_V_GEN) ( \
		rm -rf $@ $@.tmp; \
		srcdir=''; \
		  test -f ./$@.in || srcdir=$(srcdir)/; \
		  $(edit) $${srcdir}$@.in >$@.tmp; \
		mv $@.tmp $@ )

@INTLTOOL_XML_NOMERGE_RULE@

GITIGNOREFILES =				\
        $(libutil_la_SOURCES:.vala=.c)		\
        $(ibus_engine_kkc_SOURCES:.vala=.c)	\
        $(ibus_setup_kkc_SOURCES:.vala=.c)	\
	libutil_la_vala.stamp			\
	ibus_engine_kkc_vala.stamp		\
	ibus_setup_kkc_vala.stamp		\
	libutil.h				\
        $(NULL)

CLEANFILES =					\
	ibus-kkc.vapi				\
	$(desktop_DATA)				\
	$(desktop_in_files)			\
	kkc.xml.in				\
	kkc.xml					\
	$(NULL)

EXTRA_DIST =					\
	config.vapi				\
	ibus-kkc.deps				\
	ibus-1.0.vapi				\
	ibus-1.0.deps				\
	ibus-kkc-preferences.ui.in		\
	$(desktop_in_in_files)			\
	kkc.xml.in.in.in			\
	$(NULL)

DISTCLEANFILES =				\
	ibus-kkc-preferences.ui			\
	kkc.xml.in.in				\
	$(NULL)

-include $(top_srcdir)/git.mk

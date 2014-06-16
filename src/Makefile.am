# ibus-kkc - The Japanese Kana Kanji engine for IBus
#
# Copyright (C) 2012-2013 Daiki Ueno <ueno@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

libexec_PROGRAMS = ibus-engine-kkc ibus-setup-kkc
noinst_LTLIBRARIES = libutil.la

libutil_la_VALAFLAGS =				\
	-H libutil.h --vapi ibus-kkc.vapi	\
	--vapidir=.				\
	--pkg config				\
	--pkg gee-0.8				\
	--pkg kkc-1.0				\
	--pkg ibus-1.0				\
	--library ibus-kkc			\
	$(VALAFLAGS)
libutil_la_SOURCES =				\
	preferences.vala			\
	dictionary.vala				\
	$(NULL)
libutil_la_CFLAGS =				\
	$(COMMON_CFLAGS)
libutil_la_LIBADD =				\
	$(COMMON_LIBS)

BUILT_SOURCES =					\
	ibus-kkc.vapi				\
	ibus-kkc-preferences.ui			\
	ibus-engine-kkc.gresource.xml		\
	ibus-setup-kkc.gresource.xml		\
	ibus-engine-kkc-resources.c		\
	ibus-setup-kkc-resources.c		\
	$(NULL)

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
	--pkg config				\
	--pkg ibus-kkc				\
	--pkg gtk+-3.0				\
	$(VALAFLAGS)

if IBUS_1_5
ibus_engine_kkc_VALAFLAGS += -D IBUS_1_5
endif

ibus_engine_kkc_CFLAGS =			\
	$(COMMON_CFLAGS)			\
	$(GTK_CFLAGS)

ibus_engine_kkc_LDADD =				\
	$(COMMON_LIBS)				\
	$(GTK_LIBS)				\
	libutil.la

ibus_engine_kkc_SOURCES =			\
	engine.vala				\
	ibus-engine-kkc-resources.c		\
	$(NULL)

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
	setup.vala				\
	ibus-setup-kkc-resources.c		\
	$(NULL)

SUFFIXES = .json .json.in

json_edit = sed \
	-e 's|\(^ *"[^"]*": *\)_(\("[^"]*"\))|\1\2|g' \
	-e 's|@skkdicdir[@]|$(skkdicdir)|g'

.json.in.json:
	$(AM_V_GEN) rm -f $@ $@.tmp; \
	srcdir=''; \
	  test -f ./$< || srcdir=$(srcdir)/; \
	  $(json_edit) $${srcdir}$< >$@.tmp; \
	mv $@.tmp $@

ibus-engine-kkc-resources.c: ibus-engine-kkc.gresource.xml ibus-kkc-dictionaries.json
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) ibus-engine-kkc.gresource.xml \
		--target=$@ --sourcedir=$(builddir) --c-name ibus_kkc \
		--generate-source

ibus-setup-kkc-resources.c: ibus-setup-kkc.gresource.xml ibus-kkc-preferences.ui ibus-kkc-dictionaries.json $(top_srcdir)/icons/ibus-kkc.svg
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) ibus-setup-kkc.gresource.xml \
		--target=$@ --sourcedir=$(builddir) --c-name ibus_kkc \
		--generate-source

edit = sed \
	-e 's|@VERSION[@]|$(VERSION)|g' \
	-e 's|@libexecdir[@]|$(libexecdir)|g' \
	-e 's|@pkgdatadir[@]|$(pkgdatadir)|g' \
	-e 's|@top_srcdir[@]|$(top_srcdir)|g'

desktop_in_in_files = ibus-setup-kkc.desktop.in.in
desktop_in_files = $(desktop_in_in_files:.in.in=.in)

$(desktop_in_files): %.desktop.in: %.desktop.in.in Makefile
	$(AM_V_GEN) $(edit) $< > $@.tmp && mv $@.tmp $@

desktopdir=$(datadir)/applications
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)

@INTLTOOL_DESKTOP_RULE@

component_DATA = kkc.xml
componentdir = $(datadir)/ibus/component

kkc.xml.in: kkc.xml.in.in
	$(AM_V_GEN) $(edit) $< > $@.tmp && mv $@.tmp $@

ibus-kkc-preferences.ui: ibus-kkc-preferences.ui.in
	$(AM_V_GEN) $(edit) $< > $@.tmp && mv $@.tmp $@

ibus-engine-kkc.gresource.xml: ibus-engine-kkc.gresource.xml.in
	$(AM_V_GEN) $(edit) $< > $@.tmp && mv $@.tmp $@

ibus-setup-kkc.gresource.xml: ibus-setup-kkc.gresource.xml.in
	$(AM_V_GEN) $(edit) $< > $@.tmp && mv $@.tmp $@

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
	ibus-engine-kkc-resources.c		\
	ibus-setup-kkc-resources.c		\
	$(desktop_DATA)				\
	$(desktop_in_files)			\
	kkc.xml.in				\
	kkc.xml					\
	ibus-kkc-preferences.ui			\
	ibus-kkc-dictionaries.json		\
	ibus-engine-kkc.gresource.xml		\
	ibus-setup-kkc.gresource.xml		\
	$(NULL)

EXTRA_DIST =					\
	config.vapi				\
	ibus-kkc.vapi				\
	ibus-kkc.deps				\
	ibus-1.0.vapi				\
	ibus-1.0.deps				\
	ibus-kkc-preferences.ui.in		\
	ibus-kkc-dictionaries.json.in		\
	$(desktop_in_in_files)			\
	kkc.xml.in.in				\
	ibus-engine-kkc.gresource.xml.in	\
	ibus-setup-kkc.gresource.xml.in		\
	$(NULL)

MAINTAINERCLEANFILES =				\
	ibus-kkc.vapi				\
	$(NULL)

-include $(top_srcdir)/git.mk

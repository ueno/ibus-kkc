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
libutil_la_LIBADD =				\
	$(COMMON_LIBS)

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
	setup.vala				\
	ibus-kkc-resources.c

ibus-kkc-resources.c: ibus-kkc.gresource.xml ibus-kkc-preferences.ui
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) $(srcdir)/ibus-kkc.gresource.xml \
		--target=$@ --sourcedir=$(srcdir) --c-name ibus_kkc \
		--generate-source

edit = sed \
	-e 's|@VERSION[@]|$(VERSION)|g' \
	-e 's|@libexecdir[@]|$(libexecdir)|g' \
	-e 's|@pkgdatadir[@]|$(pkgdatadir)|g'

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
	kkc.xml.in.in				\
	ibus-kkc.gresource.xml			\
	$(NULL)

DISTCLEANFILES =				\
	ibus-kkc-preferences.ui			\
	$(NULL)

-include $(top_srcdir)/git.mk

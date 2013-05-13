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

SUBDIRS =					\
	src					\
	icons					\
	m4					\
	po					\
	$(NULL)

# As of now (May 2013) IBus 1.4 is still widely used.  For the tarball
# distribution, generate C code which uses 1.4 API only.
DISTCHECK_CONFIGURE_FLAGS = --with-ibus=1.4

ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST =					\
	autogen.sh				\
	ibus-kkc.spec.in			\
	$(NULL)

GITIGNOREFILES =				\
	INSTALL					\
	aclocal.m4				\
	compile					\
	config.guess				\
	config.h.in				\
	config.sub				\
	depcomp					\
	install-sh				\
	ltmain.sh				\
	missing					\
	mkinstalldirs				\
	$(NULL)

DISTCLEANFILES =				\
	po/stamp-it				\
	$(NULL)

dist-hook:
	if test -d .git ; then \
		git log --name-status --date=iso > $(distdir)/ChangeLog ; \
	fi

-include $(top_srcdir)/git.mk

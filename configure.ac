# vim:set et ts=4:
#
# ibus-kkc - The Japanese Kana Kanji engine for IBus
#
# Copyright (c) 2007-2008 Huang Peng <shawn.p.huang@gmail.com>
# Copyright (C) 2009-2013 Daiki Ueno <ueno@gnu.org>
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

# if not 1, append datestamp to the version number.
m4_define([package_name], [ibus-kkc])
m4_define([ibus_released], [1])
m4_define([ibus_major_version], [1])
m4_define([ibus_minor_version], [5])
m4_define([ibus_micro_version], [19])
m4_define(ibus_maybe_datestamp,
    m4_esyscmd([if test x]ibus_released[ != x1; then date +.%Y%m%d | tr -d '\n\r'; fi]))

m4_define([ibus_version],
    ibus_major_version.ibus_minor_version.ibus_micro_version[]ibus_maybe_datestamp)

AC_INIT([package_name], [ibus_version], [https://bitbucket.org/libkkc/libkkc/issues], [package_name])
AM_INIT_AUTOMAKE([silent-rules])
AC_GNU_SOURCE

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

# define PACKAGE_VERSION_* variables
AM_SANITY_CHECK
AM_MAINTAINER_MODE
AM_DISABLE_STATIC
AC_PROG_CC
AC_PROG_CXX
AM_PROG_CC_C_O
AC_ISC_POSIX
AC_HEADER_STDC
IT_PROG_INTLTOOL([0.35.0])
AM_PROG_LIBTOOL

# For dislpay Date
m4_define(ibus_maybe_datedisplay,
    m4_esyscmd([if test x]ibus_released[ != x1; then date '+%a %b %d %Y' | tr -d '\n\r'; fi]))
m4_define([ibus_datedisplay], ibus_maybe_datedisplay)
DATE_DISPLAY="ibus_datedisplay"
AC_SUBST(DATE_DISPLAY)

# check ibus
AC_ARG_WITH([ibus],
  [AS_HELP_STRING([--with-ibus],
    [IBus version to compile with @<:@default=auto@:>@])],
  [],
  [with_ibus=auto])

IBUS_1_4_REQUIRED=1.4.0
IBUS_1_5_REQUIRED=1.5.0

AS_CASE([$with_ibus],
  [1.4], [PKG_CHECK_MODULES(IBUS, [ibus-1.0 >= $IBUS_1_4_REQUIRED], ,
    AC_MSG_ERROR([can't find ibus 1.4]))],
  [1.5], [PKG_CHECK_MODULES(IBUS, [ibus-1.0 >= $IBUS_1_5_REQUIRED], ,
    AC_MSG_ERROR([can't find ibus 1.5]))],
  [auto], [PKG_CHECK_MODULES(IBUS, [ibus-1.0 >= $IBUS_1_4_REQUIRED], ,
    AC_MSG_ERROR([can't find ibus 1.4 or later]))
    PKG_CHECK_EXISTS([ibus-1.0 >= $IBUS_1_5_REQUIRED],
      [with_ibus=1.5],
      [with_ibus=1.4])],
  [AC_MSG_ERROR([invalid ibus version])])

AM_CONDITIONAL([IBUS_1_5], [test x$with_ibus = x1.5])

# check skkdic
AC_ARG_WITH([skkdic],
  [AS_HELP_STRING([--with-skkdic],
    [location of skkdic @<:@default=DATAROOTDIR/skk@:>@])],
  [],
  [with_skkdic='${datarootdir}/skk'])
AC_SUBST([skkdicdir], [$with_skkdic])

# check libkkc
PKG_CHECK_MODULES(LIBKKC, [kkc-1.0 >= 0.3.2], ,
  AC_MSG_ERROR([can't find libkkc]))

# check gtk+
PKG_CHECK_MODULES(GTK, [gtk+-3.0 >= 3.4], ,
  AC_MSG_ERROR([can't find gtk+-3.0]))

# check vala
AM_PROG_VALAC([0.10.0])

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
AC_SUBST(VALAFLAGS)

# define GETTEXT_* variables
GETTEXT_PACKAGE=ibus-kkc
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [Define to the read-only architecture-independent data directory.])
AM_GLIB_GNU_GETTEXT

# check glib-compile-resources
GLIB_COMPILE_RESOURCES=`$PKG_CONFIG --variable glib_compile_resources gio-2.0`
AC_SUBST(GLIB_COMPILE_RESOURCES)

# OUTPUT files
AC_CONFIG_FILES([ po/Makefile.in
Makefile
ibus-kkc.spec
src/Makefile
icons/Makefile
m4/Makefile
])

AC_OUTPUT

#
#  type "make help" for help
#
# TODO: examples
#       add rpm to dist package, man page
#
# Changes:
# - be sure that configure is called after untgz, tar original file attributes
# - suggestion of Marcel Pol 6Dec2001:
#      make install DESTDIR=$RPM_BUILD_ROOT
#

prefix = /usr/local
#bindir = $(prefix)/bin
bindir = /usr/local${exec_prefix}/bin

SHELL = /bin/sh
# this does not work on SuSE 6.0, why? (autoconf 2.12 do not set /bin/sh ?)
#SHELL = bash #
INSTALL = /usr/bin/install -c
CC = gcc
CFLAGS = -g -O2
# following DEFs are not used, but I play with it for training
CPPFLAGS = 
DEFS = -DHAVE_CONFIG_H
includedir = ${prefix}/include
#
# -pedantic -ansi -Wall
LDFLAGS = -lm 
LIBS = -lnetpbm 

# RANLIB = @RANLIB@
# AR = @AR@


# files for devel.tgz
FILES = \
 AUTHORS Makefile Makefile.in bin/ doc/ include/ examples/ man/ src/\
 BUGS README make.bat CREDITS READMEde.txt REMARK.txt\
 HISTORY REVIEW configure gpl.html INSTALL TODO configure.in\
 install-sh gocr.spec .cvsignore

# files for distribution
AFILES = $(FILES) lib/

DIRS = doc/ include/ man/ examples/ bin/ src/ lib/

# export all make-variables to submakes - said to be not working on IRIS

# default rule
default: all

.PHONY : src doc examples help clean proper distclean dist tgz rpm libs

# example file generation takes lot of memory and time, do it explicitely
# by make examples
all:	src Makefile
	@echo " --- for help do: make help ---"
	@echo " --- for documentation do: make doc ---"
	@echo " --- for examples do: make examples ---"

include/config.h: include/config.h.in configure
	./configure

configure: configure.in
	autoconf

Makefile: Makefile.in configure
	./configure

src/Makefile: src/Makefile.in configure
	./configure

src:	src/Makefile
	$(MAKE) -C src all

libs:	src/Makefile
	$(MAKE) -C src libs

man:
	$(MAKE) -C man all

doc:
	$(MAKE) -C doc all

examples:
	$(MAKE) -C examples all

help:
	@printf "make            - compile all\n"
	@printf "make libs       - compile libraries libPgm2asc.{a,so}\n"
	@printf "make src        - build lib and gocr\n"
	@printf "make man        - build manual\n"
	@printf "make doc        - make documentation\n"
	@printf "make examples   - create examples ./examples/\n"
	@printf "make clean      - erase temporary files\n"
	@printf "make proper     - erase all created files\n"
	@printf "make install    - Really? Its development version!\n"
	@printf "make uninstall  - remove installed files from the system\n"


# you can override this variable by: make install DESTDIR=yourpath
DESTDIR=/usr/local
.PHONY : install uninstall test examples
install:
	$(MAKE) -C src install
	$(MAKE) -C man install
	# following steps are not needed for end users, but cost dependencies
	# therefore removed in 0.48
	# $(MAKE) -C doc install
	# $(MAKE) -C examples install
	# $(MAKE) -C frontend install

uninstall:
	$(MAKE) -C src uninstall
	$(MAKE) -C man uninstall
	# $(MAKE) -C doc uninstall
	# $(MAKE) -C examples uninstall
	# $(MAKE) -C frontend uninstall

# generate version file before packaging (most up to date)
#  release is the date of the last modified src file (for bug reports)
#  to distinguish different developper versions of same version number
include/version.h: src/*.[ch] Makefile
	echo "#define version_string \"0.50\"" > $@
	echo "#define release_string \"`date +%Y%m%d`\"" >> $@

dist: include/version.h
	echo gocr-0.50 > .fname
	-rm -rf `cat .fname`
	mkdir `cat .fname`
	# create subdirs, because cp -r bin/gocr.tcl jocr => jocr/gocr.tcl
	(cd `cat .fname`; mkdir $(DIRS))
	cp -r -p -d $(AFILES) `cat .fname`
	$(MAKE) -C `cat .fname` proper
	# for Win, DOS and Mac no configure available, reset config.h
	cp `cat .fname`/include/config.h.in `cat .fname`/include/config.h
	touch `cat .fname`/configure   # Makefile will be updated
	tar chzf ../`cat .fname`.tar.gz `cat .fname`
	-gpg -ab --default-key 0x53BDFBE3 ../`cat .fname`.tar.gz # .asc
	ls -l ../`cat .fname`.tar.gz{,.asc}
	-rm -rf `cat .fname` .fname


# the tgz-option is only for the author, to carry the sources home
tgz: include/version.h
	mkdir jocr		# causes an error if exist
	# create subdirs, because cp -r bin/gocr.tcl jocr => jocr/gocr.tcl
	(cd jocr; mkdir $(DIRS))
	-cp -rup -d $(FILES) CVS jocr
	$(MAKE) -C jocr proper
	if test -d jocr/src/api; then echo "--- rm -r jocr/src/api ---"; fi
	-rm -rf jocr/src/api
	# -rm -rf jocr/CVS jocr/*/CVS jocr/*/*/CVS # CVS tree
	-rm -rf jocr/Makefile jocr/src/Makefile jocr/include/config.h
	tar chzf ../jocr.tgz jocr
	-gpg -ab --default-key 0x53BDFBE3 ../jocr.tgz # .asc
	-cp ../jocr.tgz ../jocr.tgz.`date +%y%m%d` # backup, remove later
	ls -l ../jocr.tgz{,.asc}
	-rm -rf jocr

# the rpm option is for the author, to create simple rpm packages
TRPM = $(HOME)/tmp_gocr_build
# only gocr?
#VERSION=$(shell sed -e '/version_string/!d' -e 's/[^0-9.]*\([0-9.]*\).*/\1/' -e q src/gocr.c)
rpm:
	echo "%_topdir $(TRPM)" > ~/.rpmmacros
	mkdir -p $(TRPM)/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
	sed "s/version.*[0-9]\.[0-9]*/version 0.50/"\
	 gocr.spec >$(TRPM)/SPECS/gocr.spec
	cp ../gocr-0.50.tar.gz $(TRPM)/SOURCES
	#rpmbuild -ba --nobuild gocr.spec  # bin+src-rpm
	(cd $(TRPM)/SPECS; rpmbuild -bb gocr.spec)
	rpm -qil -p $(TRPM)/RPMS/i?86/gocr-0.50-*.i?86.rpm

# PHONY = don't look at file clean, -rm = start rm and ignore errors
.PHONY : clean proper
clean:
	-rm -f config.cache config.status config.log
	-rm -f *.aux *.log *.dvi *.ps *.lj *~ gocr.ini out.txt
	-rm -f convert.cc convert convert.o	# remove v0.2.4 rests
	$(MAKE) -C src clean
	$(MAKE) -C doc clean
	$(MAKE) -C examples/ clean


distclean: proper

proper: clean
	$(MAKE) -C src/ proper
	$(MAKE) -C doc proper
	$(MAKE) -C examples/ proper
	-rm -f gocr bin/gocr libPgm2asc.* out??.bmp

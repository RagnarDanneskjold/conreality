PACKAGE_NAME    = consensus
PACKAGE_TARNAME = $(PACKAGE_NAME)
PACKAGE_VERSION = $(shell cat VERSION)

OCAMLBUILD      = ocamlbuild
OCAMLC          = ocamlfind ocamlc
OCAMLOPT        = ocamlfind ocamlopt
OPAM_INSTALLER  = opam-installer
COREBUILD	= corebuild

CHECKSEDSCRIPT  = ''

BENCHABLE_ARCHITECTURES := x86_|i686
IS_BENCHABLE_ARCHITECTURE := $(shell \
  uname -m | \
  egrep "($(BENCHABLE_ARCHITECTURES))" 2>&1 >/dev/null && \
  echo true || echo false)

ifeq ($(V),1)
OCAMLBUILD      = ocamlbuild -verbose 1 -cflag -verbose -lflag -verbose
CHECKSEDSCRIPT  = 's/$$/ --verbose/'
endif

BINARIES = \
  _build/src/consensus.otarget

all: build

META: META.in Makefile VERSION
	sed -e 's:@PACKAGE_NAME@:$(PACKAGE_NAME):'       \
	    -e 's:@PACKAGE_TARNAME@:$(PACKAGE_TARNAME):' \
	    -e 's:@PACKAGE_VERSION@:$(PACKAGE_VERSION):' \
	    META.in > META

_build/src/consensus.otarget: src/consensus.itarget src/consensus.mlpack _tags
	$(OCAMLBUILD) -Is src src/consensus.otarget

build: META $(BINARIES)

check:
	CAML_LD_LIBRARY_PATH=src/consensus:$(CAML_LD_LIBRARY_PATH) \
	  $(OCAMLBUILD) -Is test,src test/check.otarget && \
	  cp -p test/check_all.sh _build/test/ && \
	  sed -i -e $(CHECKSEDSCRIPT) _build/test/check_all.sh && \
	  _build/test/check_all.sh

ifeq "$(IS_BENCHABLE_ARCHITECTURE)" "true"
bench:
	CAML_LD_LIBRARY_PATH=src/consensus:$(CAML_LD_LIBRARY_PATH) \
	  $(COREBUILD) -Is bench,src bench/bench.otarget && \
	  cp -p bench/bench_all.sh _build/bench/ && \
	  _build/bench/bench_all.sh
else
bench:
	echo -n "Benchmarking is currently supported only on these \
	  architectures: $(BENCHABLE_ARCHITECTURES)"
endif

install: consensus.install build
	$(OPAM_INSTALLER) consensus.install

uninstall: consensus.install
	$(OPAM_INSTALLER) -u consensus.install

clean:
	$(OCAMLBUILD) -clean
	rm -rf _build META *~ src/*~ src/*.{a,cma,cmi,cmo,cmp,cmx,cmxa,ml.depends,mli.depends,o}

.PHONY: all build check bench install uninstall clean

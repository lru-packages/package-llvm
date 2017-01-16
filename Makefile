NAME=llvm
VERSION=3.9.1
EPOCH=1
ITERATION=1
PREFIX=/usr/local
LICENSE=NCSA
VENDOR="LLVM Team"
MAINTAINER="Ryan Parman"
DESCRIPTION="The LLVM Project is a collection of modular and reusable compiler and toolchain technologies."
URL=https://llvm.org
RHEL=$(shell rpm -q --queryformat '%{VERSION}' centos-release)

COMMIT=$(shell echo "$(VERSION)" | sed -e "s/\.//g")

#-------------------------------------------------------------------------------

all: info clean install-deps fetch compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "EPOCH:       $(EPOCH)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* llvm*

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:

	yum -y install \
		bison \
		flex \
		bc \
		boost-atomic \
		boost-chrono \
		boost-context \
		boost-date-time \
		boost-devel \
		boost-filesystem \
		boost-graph \
		boost-graph-mpich \
		boost-graph-openmpi \
		boost-iostreams \
		boost-jam \
		boost-locale \
		boost-math \
		boost-mpich-devel \
		boost-mpich-python \
		boost-openmpi-devel \
		boost-openmpi-python \
		boost-program-options \
		boost-python \
		boost-random \
		boost-regex \
		boost-serialization \
		boost-signals \
		boost-static \
		boost-system \
		boost-test \
		boost-thread \
		boost-timer \
		boost-wave \
		bzip2 \
		cmake \
		doxygen \
		gcc \
		git \
		golang \
		gzip \
		libcap-devel \
		libedit-devel \
		libxml2-devel \
		make \
		ncurses-devel \
		python-devel \
		python27 \
		sed \
		subversion \
		swig \
		unzip \
		valgrind-devel \
		zip \
		zlib-devel \
	;

#-------------------------------------------------------------------------------

.PHONY: fetch
fetch:
	wget http://releases.llvm.org/$(VERSION)/llvm-$(VERSION).src.tar.xz
	tar -xvf llvm-$(VERSION).src.tar.xz
	cd llvm* && \
		cd tools && \
			svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_$(COMMIT)/final clang && \
		cd .. && \
		cd tools/clang/tools/ && \
			svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_$(COMMIT)/final extra && \
		cd ../../.. && \
		cd projects && \
			svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_$(COMMIT)/final compiler-rt && \
			svn co http://llvm.org/svn/llvm-project/libcxx/tags/RELEASE_$(COMMIT)/final libcxx \
	;

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	cd llvm* && \
		mkdir -p build && \
		cd build && \
			cmake -G "Unix Makefiles" \
				-DCMAKE_BUILD_TYPE=Release \
				-DLLVM_ENABLE_PROJECTS="clang;libcxx;lldb;compiler-rt;lld;polly" \
				-DLLVM_TARGETS_TO_BUILD="X86" \
				-DLLVM_BUILD_DOCS=true \
				-DLLVM_ENABLE_SPHINX=false \
				-DLLVM_ENABLE_DOXYGEN=true \
				-DLLVM_OPTIMIZED_TABLEGEN=false \
				.. && \
			make \
	;

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd llvm* && cd build && \
		make install DESTDIR=/tmp/installdir-$(NAME)-$(VERSION);

#-------------------------------------------------------------------------------

.PHONY: package
package:

	# Main package
	fpm \
		-f \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces llvm \
		--replaces llvm-devel \
		--replaces llvm-doc \
		--replaces llvm-libs \
		--replaces llvm-ocaml \
		--replaces llvm-ocaml-devel \
		--replaces llvm-ocaml-doc \
		--replaces llvm-static \
		--epoch $(EPOCH) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
		usr/local/include \
		usr/local/lib \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	mv *.rpm /vagrant/repo/

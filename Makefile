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

#-------------------------------------------------------------------------------

all: info clean install-deps compile install-tmp package move

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
		bzip2 \
		cmake \
		doxygen \
		gcc \
		golang \
		gzip \
		make \
		ncurses-devel \
		python27 \
		sed \
		unzip \
		valgrind-devel \
		zip \
		zlib-devel \
	;

	/bin/pip install --upgrade sphinx;

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	wget http://releases.llvm.org/$(VERSION)/llvm-$(VERSION).src.tar.xz
	tar -xvf llvm-$(VERSION).src.tar.xz
	cd llvm* && \
		mkdir -p ./build && \
		cd build && \
			cmake -G "Unix Makefiles" \
				-DCMAKE_BUILD_TYPE=Release \
				-DCMAKE_INSTALL_PREFIX=prefix=/tmp/installdir-llvm-$(VERSION) \
				-DLLVM_BUILD_DOCS=true \
				-DLLVM_BUILD_LLVM_DYLIB=true \
				-DLLVM_ENABLE_CXX1Y=true \
				-DLLVM_ENABLE_EH=true \
				-DLLVM_ENABLE_FFI=true \
				-DLLVM_ENABLE_PROJECTS=all \
				-DLLVM_ENABLE_RTTI=true \
				-DLLVM_ENABLE_THREADS=true \
				-DLLVM_ENABLE_ZLIB=true \
				-DLLVM_LINK_LLVM_DYLIB=true \
				-DLLVM_OPTIMIZED_TABLEGEN=true \
				-DLLVM_TARGET_ARCH=host \
				-DLLVM_TARGETS_TO_BUILD="X86" \
				-DLLVM_USE_INTEL_JITEVENTS=true \
				-DLLVM_USE_OPROFILE=true \
				.. && \
			make -j$$(nproc) && \
	;

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd CMake && \
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
		--replaces cmake \
		--replaces cmake3 \
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
	;

	# Documentation package
	fpm \
		-f \
		-d "$(NAME) = $(EPOCH):$(VERSION)-$(ITERATION).el$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-doc \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces cmake-doc \
		--replaces cmake3-doc \
		--epoch 1 \
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
		usr/local/doc \
		usr/local/share \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	mv *.rpm /vagrant/repo/

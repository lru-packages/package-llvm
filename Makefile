NAME=llvm
VERSION=5.0.0
ITERATION=1.lru
PREFIX=/usr/local
LICENSE=NCSA
VENDOR="LLVM Team"
MAINTAINER="Ryan Parman"
DESCRIPTION="The LLVM Project is a collection of modular and reusable compiler and toolchain technologies."
URL=https://llvm.org
ACTUALOS=$(shell osqueryi "select * from os_version;" --json | jq -r ".[].name")
EL=$(shell if [[ "$(ACTUALOS)" == "Amazon Linux AMI" ]]; then echo alami; else echo el; fi)
RHEL=$(shell [[ -f /etc/centos-release ]] && rpm -q --queryformat '%{VERSION}' centos-release)
COMMIT=$(shell echo "$(VERSION)" | sed -e "s/\.//g")

# https://www.vultr.com/docs/how-to-install-llvm-and-clang-on-centos-6
# http://btorpey.github.io/blog/2015/01/02/building-clang/
# http://www.linuxfromscratch.org/blfs/view/cvs/general/llvm.html

#-------------------------------------------------------------------------------

all: info clean install-deps fetch compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "OS:          $(ACTUALOS)"
	@ echo "EL:          $(EL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* llvm* clang compiler-rt libcxx libcxxabi lld lldb openmp polly

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:
	yum -y install \
		bc \
		bison \
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
		clang \
		cmake \
		doxygen \
		flex \
		gcc \
		gcc6 \
		git \
		golang \
		graphviz \
		gzip \
		libatomic \
		libcap-devel \
		libedit-devel \
		libxml2-devel \
		make \
		ncurses-devel \
		python-devel \
		python27 \
		python27-devel \
		sed \
		subversion \
		swig \
		unzip \
		valgrind-devel \
		zip \
		zlib-devel \
	;
	
	pip install sphinx;

#-------------------------------------------------------------------------------

.PHONY: fetch
fetch:
	wget http://releases.llvm.org/$(VERSION)/llvm-$(VERSION).src.tar.xz && \
	tar -xvf llvm-$(VERSION).src.tar.xz && \
	git clone -q -b svn-tags/RELEASE_$(COMMIT) https://github.com/llvm-mirror/polly.git && \
	svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_$(COMMIT)/final clang && \
	svn co http://llvm.org/svn/llvm-project/lldb/tags/RELEASE_$(COMMIT)/final lldb && \
	svn co http://llvm.org/svn/llvm-project/lld/tags/RELEASE_$(COMMIT)/final lld && \
	svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_$(COMMIT)/final compiler-rt && \
	svn co http://llvm.org/svn/llvm-project/libcxx/tags/RELEASE_$(COMMIT)/final libcxx && \
	svn co http://llvm.org/svn/llvm-project/libcxxabi/tags/RELEASE_$(COMMIT)/final libcxxabi && \
	svn co http://llvm.org/svn/llvm-project/openmp/tags/RELEASE_$(COMMIT)/final openmp && \
	cd llvm* && \
		cd tools && \
			cp -Rvf ../../clang ./clang && \
			cp -Rvf ../../lldb ./lldb && \
			cp -Rvf ../../lld ./lld && \
			cp -Rvf ../../polly/final ./polly && \
		cd .. && \
		cd tools/clang/tools/ && \
			svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_$(COMMIT)/final extra && \
		cd ../../.. && \
		cd projects && \
			cp -Rvf ../../compiler-rt ./compiler-rt && \
			cp -Rvf ../../libcxx ./libcxx && \
			cp -Rvf ../../libcxxabi ./libcxxabi && \
			cp -Rvf ../../openmp ./openmp \
	;

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	cd llvm* && \
		mkdir -p build && \
		cd build && \
			CC=/bin/gcc \
			CXX=/bin/g++ \
			cmake -G "Unix Makefiles" \
				-DCMAKE_BUILD_TYPE=Release \
				-DLLVM_BUILD_LLVM_DYLIB=ON \
				-DLLVM_LINK_LLVM_DYLIB=ON \
				-DLLVM_ENABLE_FFI=ON \
				-DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lldb;compiler-rt;lld;polly" \
				-DLLVM_TARGETS_TO_BUILD="X86" \
				-DLLVM_BUILD_DOCS=OFF \
				-DLLVM_ENABLE_DOXYGEN=OFF \
				-DLLVM_ENABLE_SPHINX=ON \
				-DSPHINX_OUTPUT_HTML=ON \
				-DSPHINX_OUTPUT_MAN=ON \
				-DSPHINX_WARNINGS_AS_ERRORS=OFF \
				-DLLVM_INCLUDE_TESTS=ON \
				-DLLVM_BUILD_TESTS=ON \
				-DLLVM_ENABLE_EH=ON \
				-DLLVM_ENABLE_RTTI=ON \
				-DLLVM_OPTIMIZED_TABLEGEN=ON \
				-Wno-dev .. && \
			make && \
			make \
				docs-llvm-html \
				docs-llvm-man \
				clang \
				docs-clang-html \
				docs-clang-man \
				docs-clang-tools-html \
				docs-clang-tools-man \
				lldb \
				lldb-cpp-doc \
				lld \
				docs-lld-html \
				omp \
				compiler-rt \
				docs-libcxx-html \
				docs-polly-html \
				docs-polly-man \
			&& \
			mv -v ./lib64/* ./lib/ \
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
		-d "$(NAME)-libs = $(VERSION)-$(ITERATION).$(EL)$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces llvm \
		--replaces lldb \
		--replaces clang \
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
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
	;

	# Libs package
	fpm \
		-s dir \
		-t rpm \
		-n $(NAME)-libs \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces llvm-libs \
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
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/lib \
		usr/local/libexec \
	;

	# Development package
	fpm \
		-f \
		-d "$(NAME) = $(VERSION)-$(ITERATION).$(EL)$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-devel \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces llvm-devel \
		--replaces lldb-devel \
		--replaces clang-devel \
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
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/include \
	;

	# Documentation package
	fpm \
		-d "$(NAME) = $(VERSION)-$(ITERATION).$(EL)$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-doc \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--replaces llvm-doc \
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
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/share \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	[[ -d /vagrant/repo ]] && mv *.rpm /vagrant/repo/

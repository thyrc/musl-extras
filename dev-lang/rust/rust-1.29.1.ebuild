# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

LLVM_MAX_SLOT=6
PYTHON_COMPAT=( python2_7 python3_{5,6} pypy )

inherit check-reqs multiprocessing python-any-r1 versionator toolchain-funcs llvm

if [[ ${PV} = *beta* ]]; then
	betaver=${PV//*beta}
	BETA_SNAPSHOT="${betaver:0:4}-${betaver:4:2}-${betaver:6:2}"
	MY_P="rustc-beta"
	SLOT="beta/${PV}"
	SRC="${BETA_SNAPSHOT}/rustc-beta-src.tar.xz"
	KEYWORDS=""
else
	ABI_VER="$(get_version_component_range 1-2)"
	SLOT="stable/${ABI_VER}"
	MY_P="rustc-${PV}"
	SRC="${MY_P}-src.tar.xz"
	KEYWORDS="~amd64 ~arm64 ~x86"
fi

toml_usex() {
	usex "$1" true false
}

rust_host() {
	case "${1}" in
		arm)
			if [[ ${1} == ${DEFAULT_ABI} ]]; then
				if [[ ${CHOST} == armv7* ]]; then
					RUSTARCH=armv7
				else
					RUSTARCH=arm
				fi
			else
				RUSTARCH=arm
			fi ;;
		amd64)
			RUSTARCH=x86_64 ;;
		arm64)
			RUSTARCH=aarch64 ;;
		x86)
			RUSTARCH=i686 ;;
	esac
	case "${1}" in
		arm)
			if [[ ${1} == ${DEFAULT_ABI} ]]; then
				if [[ ${CHOST} == armv7a-hardfloat* ]]; then
					RUSTLIBC=${ELIBC/glibc/gnu}eabihf
				else
					RUSTLIBC=${CHOST##*-}
				fi
			else
				RUSTLIBC=${ELIBC/glibc/gnu}
			fi ;;
		*)
			RUSTLIBC=${ELIBC/glibc/gnu} ;;
	esac
	RUSTHOST=${RUSTARCH}-unknown-${KERNEL}-${RUSTLIBC}
	echo "${RUSTHOST}"
}

RUSTHOST=$(rust_host ${ARCH})

STAGE0_VERSION="1.$(($(get_version_component_range 2) - 0)).2"
CARGO_DEPEND_VERSION="0.$(($(get_version_component_range 2) + 1)).0"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz"
# 	!system-rust? (
# 		amd64? (
# 			elibc_glibc? ( https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-x86_64-unknown-linux-gnu.tar.xz )
# 			elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-x86_64-unknown-linux-musl.tar.xz )
# 		)
# 		arm? (
# 			elibc_glibc? (
# 				https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-arm-unknown-linux-gnueabi.tar.xz
# 				https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-armv7-unknown-linux-gnueabihf.tar.xz
# 			)
# 			elibc_musl? (
# 				https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-arm-unknown-linux-musleabi.tar.xz
# 				https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-armv7-unknown-linux-musleabihf.tar.xz
# 			)
# 		)
# 		x86? (
# 			elibc_glibc? ( https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-i686-unknown-linux-gnu.tar.xz )
# 			elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-i686-unknown-linux-musl.tar.xz )
# 		)
# 	)
# "

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

RUST_TOOLS=( cargo rls rustfmt analysis src )

IUSE_RUST_EXTENDED_TOOLS=(
	${RUST_TOOLS[@]/#/rust_tools_}
)

IUSE="debug doc extended +jemalloc libressl system-llvm system-rust ${IUSE_RUST_EXTENDED_TOOLS[@]/#/+}"

RDEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
		jemalloc? ( >=dev-libs/jemalloc-4.5.0 )
		system-llvm? ( sys-devel/llvm )
		extended? (
			libressl? ( dev-libs/libressl:0= )
			!libressl? ( dev-libs/openssl:0= )
			net-libs/http-parser:0/2.8.0
			net-libs/libssh2:=
			net-misc/curl:=[ssl]
			sys-libs/zlib:=
			!dev-util/rustfmt
			!dev-util/cargo
		)
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	|| (
		>=sys-devel/gcc-4.7
		>=sys-devel/clang-3.5
	)
	!system-llvm? (
		dev-util/cmake
		dev-util/ninja
	)
"
PDEPEND="!extended? ( >=dev-util/cargo-${CARGO_DEPEND_VERSION} )"

PATCHES=(
	"${FILESDIR}/${PN}-1.29.1-Require-static-native-libraries-when-linking-static.patch"
	"${FILESDIR}/${PN}-1.29.1-Switch-musl-targets-to-link-dynamically-by-default.patch"
	"${FILESDIR}/${PN}-1.27.1-Prefer-libgcc_eh-over-libunwind-for-musl.patch"
	"${FILESDIR}/${PN}-1.28.0-Remove-nostdlib-and-musl_root.patch"
	"${FILESDIR}/${PN}-1.25.0-Fix-LLVM-build.patch"
	"${FILESDIR}/${PN}-1.28.0-Add-openssl-configuration-for-musl-targets.patch"
	"${FILESDIR}/${PN}-1.28.0-Don-t-pass-CFLAGS-to-the-C-compiler.patch"
	"${FILESDIR}/${PN}-1.25.0-liblibc.patch"
	"${FILESDIR}/${PN}-1.25.0-Avoid_LLVM_name_conflicts.patch"
)

S="${WORKDIR}/${MY_P}-src"

pkg_pretend() {
	# Ensure we have enough disk space to compile
	if use extended; then
		CHECKREQS_DISK_BUILD="6G"
	else
		CHECKREQS_DISK_BUILD="4G"
	fi

	check-reqs_pkg_setup
}

pkg_setup() {
	export RUST_BACKTRACE=1
	if use system-llvm; then
		llvm_pkg_setup
		local llvm_config="$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"

		export LLVM_LINK_SHARED=1
		export RUSTFLAGS="$RUSTFLAGS -L native=$("$llvm_config" --libdir)"
	fi

	python-any-r1_pkg_setup
}

src_prepare() {
	default

	if ! use system-rust; then
		"${WORKDIR}/rust-${STAGE0_VERSION}-${RUSTHOST}/install.sh" \
			--prefix="${WORKDIR}/stage0" \
			--components=rust-std-${RUSTHOST},rustc,cargo \
			--disable-ldconfig \
			|| die
	fi
}

src_configure() {
	RUST_ETOOLS=""
	local u c
	for u in ${IUSE_RUST_EXTENDED_TOOLS[@]}; do
		if ! use ${u}; then
			continue
		fi
		c=${u#rust_tools_}
		RUST_ETOOLS+="\"${c}\", "
	done
	RUST_ETOOLS="[${RUST_ETOOLS%, }]"

	cat <<- EOF > "${S}"/config.toml
		[llvm]
		targets = "X86"
		ninja = true
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		[build]
		build = "${RUSTHOST}"
		host = ["${RUSTHOST}"]
		target = ["${RUSTHOST}"]
	EOF
	use system-rust && cat <<- EOF >> "${S}"/config.toml
		cargo = "/usr/bin/cargo"
		rustc = "/usr/bin/rustc"
	EOF
	use !system-rust && cat <<- EOF >> "${S}"/config.toml
		cargo = "${WORKDIR}/stage0/bin/cargo"
		rustc = "${WORKDIR}/stage0/bin/rustc"
	EOF
	cat <<- EOF >> "${S}"/config.toml
		docs = $(toml_usex doc)
		compiler-docs = $(toml_usex doc)
		submodules = false
		python = "${EPYTHON}"
		locked-deps = true
		vendor = true
		extended = $(toml_usex extended)
		tools = ${RUST_ETOOLS}
		[install]
		prefix = "${EPREFIX}/usr"
		libdir = "$(get_libdir)"
		docdir = "share/doc/${P}"
		mandir = "share/${P}/man"
		[rust]
		optimize = $(toml_usex !debug)
		debuginfo = $(toml_usex debug)
		debug-assertions = $(toml_usex debug)
		use-jemalloc = $(toml_usex jemalloc)
		default-linker = "$(tc-getCC)"
		channel = "${SLOT%%/*}"
		rpath = false
		optimize-tests = $(toml_usex !debug)
		codegen-tests = true
		dist-src = $(toml_usex debug)
		[dist]
		src-tarball = false
		[target.${RUSTHOST}]
		cc = "$(tc-getBUILD_CC)"
		cxx = "$(tc-getBUILD_CXX)"
		linker = "$(tc-getCC)"
		ar = "$(tc-getAR)"
	EOF
	use system-llvm && cat <<- EOF >> "${S}"/config.toml
		llvm-config = "$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"
	EOF
}

src_compile() {
	./x.py build --config="${S}"/config.toml -j$(makeopts_jobs) \
		--exclude src/tools/miri --exclude src/tools/clippy || die
}

src_install() {
	env DESTDIR="${D}" ./x.py install || die

	rm "${D}/usr/$(get_libdir)/rustlib/components" || die
	rm "${D}/usr/$(get_libdir)/rustlib/install.log" || die
	rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-std-${RUSTHOST}" || die
	rm "${D}/usr/$(get_libdir)/rustlib/manifest-rustc" || die
	rm "${D}/usr/$(get_libdir)/rustlib/rust-installer-version" || die
	rm "${D}/usr/$(get_libdir)/rustlib/uninstall.sh" || die

	mv "${D}/usr/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die
	mv "${D}/usr/bin/rustdoc" "${D}/usr/bin/rustdoc-${PV}" || die
	mv "${D}/usr/bin/rust-gdb" "${D}/usr/bin/rust-gdb-${PV}" || die
	mv "${D}/usr/bin/rust-lldb" "${D}/usr/bin/rust-lldb-${PV}" || die

	if use rust_tools_cargo; then
		mv "${D}/usr/bin/cargo" "${D}/usr/bin/cargo-${PV}" || die
	fi
	if use rust_tools_rls; then
		mv "${D}/usr/bin/rls" "${D}/usr/bin/rls-${PV}" || die
	fi
	if use rust_tools_rustfmt; then
		mv "${D}/usr/bin/rustfmt" "${D}/usr/bin/rustfmt-${PV}" || die
		mv "${D}/usr/bin/cargo-fmt" "${D}/usr/bin/cargo-fmt-${PV}" || die
	fi

	if use doc; then
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-docs" || die
	fi

	if use extended; then
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-cargo" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rls-preview" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-analysis-${RUSTHOST}" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-src" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rustfmt-preview" || die

		rm "${D}/usr/share/doc/${P}/LICENSE-APACHE.old" || die
		rm "${D}/usr/share/doc/${P}/LICENSE-MIT.old" || die
	fi

	rm "${D}/usr/share/doc/${P}/LICENSE-APACHE" || die
	rm "${D}/usr/share/doc/${P}/LICENSE-MIT" || die

	docompress "/usr/share/${P}/man"
	dodoc COPYRIGHT

	cat <<-EOF > "${T}"/50${P}
		MANPATH="/usr/share/${P}/man"
	EOF
	doenvd "${T}"/50${P}

	cat <<-EOF > "${T}/provider-${P}"
		/usr/bin/rustdoc
		/usr/bin/rust-gdb
		/usr/bin/rust-lldb
	EOF
	if use rust_tools_cargo; then
		echo /usr/bin/cargo >> "${T}/provider-${P}"
	fi
	if use rust_tools_rls; then
		echo /usr/bin/rls >> "${T}/provider-${P}"
	fi
	if use rust_tools_rustfmt; then
		echo /usr/bin/rustfmt >> "${T}/provider-${P}"
		echo /usr/bin/cargo-fmt >> "${T}/provider-${P}"
	fi
	dodir /etc/env.d/rust
	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
}

pkg_postinst() {
	eselect rust update --if-unset

	elog "Rust installs a helper script for calling GDB and LLDB,"
	elog "for your convenience it is installed under /usr/bin/rust-{gdb,lldb}-${PV}."

	if has_version app-editors/emacs || has_version app-editors/emacs-vcs; then
		elog "install app-emacs/rust-mode to get emacs support for rust."
	fi

	if has_version app-editors/gvim || has_version app-editors/vim; then
		elog "install app-vim/rust-vim to get vim support for rust."
	fi

	if has_version 'app-shells/zsh'; then
		elog "install app-shells/rust-zshcomp to get zsh completion for rust."
	fi
}

pkg_postrm() {
	eselect rust unset --if-invalid
}

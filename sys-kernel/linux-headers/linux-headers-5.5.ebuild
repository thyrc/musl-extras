# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

ETYPE="headers"
H_SUPPORTEDARCH="alpha amd64 arc arm arm64 avr32 cris frv hexagon hppa ia64 m32r m68k metag microblaze mips mn10300 nios2 openrisc ppc ppc64 riscv s390 score sh sparc x86 xtensa"
inherit kernel-2
detect_version

PATCH_VER="rc6"
SRC_URI="https://git.kernel.org/torvalds/t/linux-5.5-${PATCH_VER}.tar.gz"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"

DEPEND="app-arch/xz-utils
	dev-lang/perl"
RDEPEND=""

S=${WORKDIR}/linux-${PV}-${PATCH_VER}

PATCHES=(
	"${FILESDIR}"/5.5/00_all_0001-linux-stat.h-remove-__GLIBC__-checks.patch
	"${FILESDIR}"/5.5/00_all_0002-netfilter-pull-in-limits.h.patch
	"${FILESDIR}"/5.5/00_all_0003-convert-PAGE_SIZE-usage.patch
	"${FILESDIR}"/5.5/00_all_0004-asm-generic-fcntl.h-namespace-kernel-file-structs.patch
	"${FILESDIR}"/5.5/00_all_0005-unifdef-drop-unused-errno.h-include.patch
	"${FILESDIR}"/5.5/00_all_0006-x86-do-not-build-relocs-tool-when-installing-headers.patch
	"${FILESDIR}"/5.5/00_all_0007-netlink-drop-int-cast-on-length-arg-in-NLMSG_OK.patch
	"${FILESDIR}"/5.5/00_all_0008-uapi-fix-System-V-buf-header-includes.patch
	"${FILESDIR}"/5.5/00_all_0009_glibc-specific-inclusion-of-sysinfo.h-in-kernel.h.patch
)

src_unpack() {
	unpack ${A}
}

src_prepare() {
	default
}

src_install() {
	kernel-2_src_install

	# hrm, build system sucks
	find "${ED}" '(' -name '.install' -o -name '*.cmd' ')' -delete
	find "${ED}" -depth -type d -delete 2>/dev/null
}

src_test() {
	emake ARCH=$(tc-arch-kernel) headers_check
}

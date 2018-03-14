# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit eutils

DESCRIPTION="tool to manipulate Intel X86 and X86-64 processor microcode update collections"
HOMEPAGE="https://gitlab.com/iucode-tool/"
SRC_URI="https://gitlab.com/iucode-tool/releases/raw/master/${PN/_/-}_${PV}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""

S="${WORKDIR}/${PN/_/-}-${PV}"

DEPEND="sys-libs/argp-standalone"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.1.1_include_fix.patch
	eapply_user
}


# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit meson

DESCRIPTION="Launcher/menu for wlroots based wayland compositors such as sway"
HOMEPAGE=""https://hg.sr.ht/~scoopta/wofi

SRC_URI="https://hg.sr.ht/~scoopta/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
KEYWORDS="amd64 ~arm64"

LICENSE="GPL-3"
SLOT="0"
IUSE="+dmenu drun +run"

DEPEND="
	dev-libs/wayland
	x11-libs/gtk+:3[wayland]"

RDEPEND="${DEPEND}"

BDEPEND="virtual/pkgconfig"

PATCHES=( "${FILESDIR}"/fix-mode-thread.patch )

S="${WORKDIR}"/${PN}-v${PV}

src_configure() {
	local emesonargs=(
		$(meson_feature run)
		$(meson_feature drun)
		$(meson_feature dmenu)
		"-Dwerror=false"
	)
	meson_src_configure
}

# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit vim-plugin vcs-snapshot

MY_PN="${PN/-/.}"
REF="b6d88adcf9867aa69f4d20d45d49bb54979842a4"

DESCRIPTION="Vim configuration for Rust"
HOMEPAGE="http://www.rust-lang.org/"
SRC_URI="https://github.com/rust-lang/${MY_PN}/archive/${REF}.tar.gz -> ${P}.tar.gz"

LICENSE="|| ( MIT Apache-2.0 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"

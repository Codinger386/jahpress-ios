#!/bin/sh

#  runlinter.sh
#  JahPress
#
#  Created by Benjamin Ludwig on 17.12.17.
#  Copyright © 2017 Benjamin Ludwig. All rights reserved.

function run_swiftlint () {
	if which swiftlint >/dev/null; then
		swiftlint #autocorrect --format --use-tabs
	else
		return 99
	fi
}

swiftlint_pkg=$TMPDIR"/swiftlint.pkg"

function install_swiftlint () {

	echo Installing SwiftLint via latest Package from GitHub
	url=$( curl -fsSL https://api.github.com/repos/realm/swiftlint/releases/latest | grep browser_download_url | grep pkg | cut -d '"' -f 4 )
	curl -fsSL $url >$swiftlint_pkg
	open -W $swiftlint_pkg
}

run_swiftlint

if [ $? -eq 99 ]
then
	install_swiftlint
	if [ $? -eq 0 ]
	then
		run_swiftlint
	else
		echo "warning: SwiftLint is not installed"
	fi
fi

if [ -e $swiftlint_pkg ]
then
	rm $swiftlint_pkg
fi


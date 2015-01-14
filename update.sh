#!/bin/bash

set -e

if [[ "$1" != "test" ]]; then
	if ! git remote show upstream &> /dev/null; then
		echo "adding remote upstream..."
		git remote add upstream https://github.com/KateAdams/LuaFlare.git
	fi

	git fetch upstream
	# returns error code if it fails (and thus terminates this bash script).
	if ! git merge upstream/master; then
		echo $?
		echo "error: merge conflict; re-run \`$0 $@\` after resolving the merge conflict."
		exit 1
	fi
fi

update_versions () {
	CHANGELOG_VERSION=`dpkg-parsechangelog | sed -n 's/^Version: //p' | egrep -om 1 "[0-9\.]+" | head -1`
	VERSION=`git describe upstream/master --tags --always | egrep -om 1 "[0-9\.\-]+[0-9]" | head -1 | tr - .`
}

update_versions

if [[ $CHANGELOG_VERSION != $VERSION ]]; then
	echo "Version mismatch: changelog is at $CHANGELOG_VERSION, source is at $VERSION"

	if [[ "$1" != "test" ]]; then

		# Update service files
		echo "updating service files..."
		./configure
		cp thirdparty/luaflare.systemd.post debian/luaflare-service.luaflare.service
		cp thirdparty/luaflare.sysvinit.post debian/luaflare-service.luaflare.init
		cp thirdparty/luaflare.upstart.post debian/luaflare-service.luaflare.upstart
		make clean

		echo "updating changelog..."
		dch --newversion="$VERSION" --urgency low
		update_versions
		if [[ $CHANGELOG_VERSION != $VERSION ]]; then
			echo "changelog version mismatch still"
			exit 1
		else
			echo "changelog version matches, ready for build."
			exit 0
		fi
	fi

	exit 1
fi

echo "everything is up-to-date..."

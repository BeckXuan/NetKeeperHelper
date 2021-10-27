#!/usr/bin/sh
dir="$(dirname "$(readlink -f "${0}")")"
sh "$dir/NetKeeperHelper.sh" &
#kstart5 "$dir/NetKeeperHelper.sh"

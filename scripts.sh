# smart|staged docker-compose
s-d-c () (
	set -eux
	local proj=$1
	local stage=$2
	shift
	shift
	STAGE="${stage}" docker-compose -p "${proj}_${stage}" -f docker-compose.yml -f docker-compose-"${stage}".yml "$@"
)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/dckvol.sh"

# vim:ts=2:sw=2:filetype=sh:
# -*- mode: bash; tab-width: 2 -*-
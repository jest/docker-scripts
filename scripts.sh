# smart|staged docker-compose
s-d-c () (
	set -eux
	local proj=$1
	local stage=$2
	shift
	shift
	STAGE="${stage}" docker-compose -p "${proj}_${stage}" -f docker-compose.yml -f docker-compose-"${stage}".yml "$@"
)

# Finds ALL rancher service container ID given its Rancher service name
# if no name is given, returns IDs of all Rancher service contaiers
__find_rancher_service_container () {
	local srv=$1
	if [[ -n "$srv" ]]; then
		srv="=$srv"
	fi
	docker ps -f label=io.rancher.project_service.name"$srv" -q
}


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR"/dckvol.sh

# vim:ts=2:sw=2:filetype=sh:
# -*- mode: bash; tab-width: 2 -*-
# Utilities for managing docker volumes

__dckvol_export_functions () {
	export -f dckvol_ls dckvol_clone dckvol_backup dckvol_restore __dckvol_recreate_confirming __dckvol_run_and_remove
}

dckvol_ls () (
	set -eu
	[[ $# > 0 ]] || { echo "Usage: dckvol_ls container ... " >&2 && exit 1; }
	local fmt=$(perl -p0e 's/\n\s*//g' <<-'EOM'
		{{ $c := .}}
		{{ range $m := .Mounts  }}
			{{ print $c.Id "\t" }}
			{{ if .Name }}
				{{ print "V\t" .Name }}
			{{ else }}
				{{ print "H\t" .Source }}
			{{ end }}
			{{ print "\t" .Destination "\n"}}
		{{ end }}
		EOM
	)
	docker inspect -f "$fmt" "$@"
)

dckvol_clone () (
	set -eu
	[[ $# = 2 ]] || { echo "Usage: dckvol_clone src dest" >&2 && exit 1; }

	local vsrc=$1
	local vdst=$2

	__dckvol_recreate_confirming "$vdst" "Do you want to remove existing volume:\n\n    $vdst\n\nand replace it with the copy of the volume:\n\n    $vsrc" || exit 2
	__dckvol_run_and_remove -v "$vsrc":/v_src -v "$vdst":/v_dst debian:jessie cp -a /v_src/. /v_dst
)

dckvol_backup () (
	set -eu
	[[ $# > 0 && $# < 3 ]] || { echo "Usage: dckvol_backup vol [ dir | file.tgz ]" >&2; exit 1; }

	local vsrc=$1
	local ar_fname=''
	if [[ $# > 1 ]]; then
		ar_fname=$2
	fi
	[[ "$ar_fname" == /* ]] || ar_fname="$(pwd)/$ar_fname"
	if [ -d "$ar_fname" ]; then
		ar_fname="$ar_fname/$vsrc-$(date +%Y%m%d%H%M%S).tgz"
	fi
	touch "$ar_fname"

	__dckvol_run_and_remove -v "$vsrc":/v_src -v "$ar_fname":/backup.tgz debian:jessie tar czf /backup.tgz -C /v_src .
)

dckvol_restore () (
	set -eu
	[[ $# = 2 ]] || { echo "Usage: dckvol_restore file.tgz vol" >&2 && exit 1; }

	local ar_fname=$1
	local vdst=$2
	[[ "$ar_fname" == /* ]] || ar_fname="$(pwd)/$ar_fname"
	[[ -r "$ar_fname" ]] || { echo "File '$ar_fname' is not readable" >&2 && exit 1; }

	__dckvol_recreate_confirming "$vdst" "Do you want to remove existing volume:\n\n    $vdst\n\nand replace it with the content of the archive:\n\n    $ar_fname" || exit 2
	__dckvol_run_and_remove -v "$ar_fname":/backup.tgz:ro -v "$vdst":/v_dst debian:jessie tar xzf /backup.tgz -C /v_dst
)

__dckvol_recreate_confirming() {
	local vol=$1
	local msg=$2
	if docker volume inspect "$vol" >/dev/null 2>&1; then
		if ! whiptail --yesno "$msg" 0 0; then
			exit 2
		fi
		docker volume rm "$vdst"
	fi
	docker volume create --name "$vdst"
}

__dckvol_run_and_remove() {
	local CID=$(docker run -itd "$@")
	docker attach --no-stdin=true $CID
	docker rm $CID
}

# vim:ts=2:sw=2:filetype=sh:
# -*- mode: bash; tab-width: 2 -*-

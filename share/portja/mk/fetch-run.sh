#/bin/sh
set -e

cwd=$(dirname "$(realpath "$0")")
. "${cwd}/functions.sh"

blake2s256 () {
    if [ "$2" != "$(openssl blake2s256 -r "${1}" | head -c64)" ]; then
        msg "===> Failed to verify checksum of $(basename "$1")"
        exit 1
    fi
}

gpg_home() {
    printf '%s' "${dp_WRKDIRPREFIX}/.gnupg.${hash}"
}

gpg() {
    local dir=$(gpg_home)
    if [ ! -e "${dir}" ]; then
        ${dp_MKDIR} -p -m 0700 "${dir}"
    fi
    /usr/local/bin/gpg --homedir "${dir}" "$@"
}

gpg_recv() {
    gpg --keyserver hkps://keyserver.ubuntu.com --recv "$1"
    gpg --list-keys --fingerprint --with-colons "$1" | \
        sed -En 's/^fpr:::::::::([0-9A-F]+):$/\1:6:/p' | \
        gpg --import-ownertrust
}

fetch_http() {
    msg "=> Attempting to fetch $1"
    dir="${2%/*}"
    [ "${dir}" != "${2}" ] && ${dp_MKDIR} -p "${dir}"
    ${dp_FETCH_CMD} ${dp_FETCH_BEFORE_ARGS} -o "$2" "$1" ${dp_FETCH_AFTER_ARGS}
}

check_blake() {
    if hash=$(get_keyword "blake"); then
        msg "===> Checking Blake2b256 against ${hash}."
        if [ "${hash}" != "$(b2sum -a blake2b -l 256 "$1" | head -c64)" ]; then
            msg "===> Failed to verify checksum of $(basename "$1")"
            exit 1
        fi
    fi
}

check_md5() {
    if hash=$(get_keyword "md5"); then
        msg "===> Checking MD5 against ${hash}."
        if [ "${hash}" != "$(md5 -q "$1")" ]; then
	    msg "===> Failed to verify checksum of $(basename "$1")"
	    exit 1
        fi
    fi
}

hash="$1"
type="$2"
keywords="${3:-}"
shift $(( $# < 3 ? $# : 3 ))

case "${type}" in
    github)
        dir="${dp_WRKDIRPREFIX}/.gitclone.${hash}"
        if [ ! -e "${dir}" ]; then
	    ${dp_MKDIR} -p "${dir}"
            git -C "${dir}" -c init.defaultBranch=main init
            git -C "${dir}" remote add origin "https://github.com/${1}/${2}.git"
            git -C "${dir}" fetch --depth 1 origin \
                $(fetch -qo- "https://api.github.com/repos/${1}/${2}/commits/${3}" | \
                      jq -r '.sha')
            git -C "${dir}" -c advice.detachedHead=false checkout FETCH_HEAD
            if fp=$(get_keyword "verify-commit"); then
                gpg_recv "${fp}"
	        GNUPGHOME="$(gpg_home)" git -C "${dir}" verify-commit FETCH_HEAD
            fi
        fi
        ;;
    pypi)
        filename="${dp_DISTNAME}.tar.gz"
        if [ ! -e "${dp_DISTDIR}/${filename}" ]; then
            url="https://files.pythonhosted.org/packages/source"
            url="${url}/$(printf '%s' "${dp_DISTNAME}" | cut -c1)"
            s=$((${#dp_DISTNAME} - ${#dp_DISTVERSIONFULL}))
            if [ "$(printf '%s' "${dp_DISTNAME}" | cut -c${s}-)" == \
                 "-${dp_DISTVERSIONFULL}" ]; then
                url="${url}/$(printf '%s' "${dp_DISTNAME}" | cut -c-$((${s} - 1)))"
            else
                url="${url}/${dp_DISTNAME}"
            fi
            fetch_http "${url}/${filename}" "${dp_DISTDIR}/${filename}"
        fi
        check_blake "${dp_DISTDIR}/${filename}"
        ;;
    cran)
        filename="${dp_DISTNAME}.tar.gz"
        if [ ! -e "${dp_DISTDIR}/${filename}" ]; then
            fetch_http "https://cran.r-project.org/src/contrib/${filename}" \
                       "${dp_DISTDIR}/${filename}"
        fi
        check_blake "${dp_DISTDIR}/${filename}"
        check_md5 "${dp_DISTDIR}/${filename}"
        ;;
    http|https)
        filename="${2:-${1##*/}}"
        if [ ! -e "${dp_DISTDIR}/${filename}" ]; then
            fetch_http "${type}://$1" "${dp_DISTDIR}/${filename}"
        fi
        check_blake "${dp_DISTDIR}/${filename}"
        ;;
    repository)
        blake2s256 \
            "${dp_PJ_PORTDIR}/repo.tar.xz" \
            $(${dp_CAT} "${dp_PJ_PORTDIR}/repo.tar.xz.blake2s256")
        ;;
    *)
        msg "===> Unknown PJ.DISTFILES type ${type}."
        exit 1
        ;;
esac

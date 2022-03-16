#/bin/sh
set -e

cwd=$(dirname "$(realpath "$0")")
. "${cwd}/functions.sh"

hash="$1"
type="$2"
keywords="${3:-}"
shift $(( $# < 3 ? $# : 3 ))

do_extract() {
    if has_keyword "noextract"; then
        msg "===>  Skipping extract due to keyword."
        return 1
    fi
}

extract_tar() {
    if do_extract; then
        if ! ( cd ${dp_EXTRACT_WRKDIR} &&
               ${dp_EXTRACT_CMD} ${dp_EXTRACT_BEFORE_ARGS} "$1" \
                   ${dp_EXTRACT_AFTER_ARGS} ); then
            msg "===>  Failed to extract ${1##*/}"
            exit 1
        fi
    fi
}

case "${type}" in
    github)
        if do_extract; then
	    git -C "${dp_WRKDIRPREFIX}/.gitclone.${hash}" \
                checkout-index -a --prefix=${dp_WRKSRC}/
            find ${dp_WRKSRC}
        fi
        ;;
    cran|pypi)
        extract_tar "${dp_DISTDIR}/${dp_DISTNAME}.tar.gz"
        ;;
    http|https)
        extract_tar "${dp_DISTDIR}/${2:-${1##*/}}"
        ;;
    repository)
        extract_tar "${dp_PJ_PORTDIR}/repo.tar.xz"
        ;;
    *)
        msg "===> Unknown PJ.DISTFILES type ${type}."
        exit 1
        ;;
esac

if [ ${dp_UID} = 0 ]; then
    ${dp_CHMOD} -R ug-s ${dp_WRKDIR}
    ${dp_CHOWN} -R 0:0 ${dp_WRKDIR}
fi

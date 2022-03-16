#/bin/sh
set -e

cwd=$(dirname "$(realpath "$0")")
. "${cwd}/functions.sh"

items=
type="$2"
keywords="${3:-}"
shift $(( $# < 3 ? $# : 3 ))

if has_keyword "blake"; then
    items="${items} b2sum:sysutils/b2sum"
fi

case "${type}" in
    github)
        items="git:devel/git jq:textproc/jq"
        if has_keyword "verify-commit"; then
            items="${items} gpg2:security/gnupg"
        fi
        ;;
esac

if [ -n "${items}" ]; then
    printf ' %s ' ${items}
fi

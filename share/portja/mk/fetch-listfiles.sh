#/bin/sh
set -e

cwd=$(dirname "$(realpath "$0")")
. "${cwd}/functions.sh"

items=
type="$2"
keywords="${3:-}"
shift $(( $# < 3 ? $# : 3 ))

case "${type}" in
    pypi|cran)  items="${items} ${dp_DISTNAME}.tar.gz" ;;
    http|https) items="${items} ${2:-${1##*/}}"        ;;
esac

if [ -n "${items}" ]; then
    printf ' %s ' ${items}
fi

#/bin/sh
set -e

cwd=$(dirname "$(realpath "$0")")
. "${cwd}/functions.sh"

items=
type="$2"
keywords="${3:-}"
shift $(( $# < 3 ? $# : 3 ))

case "${type}" in
    github) items="git:devel/git" ;;
esac

if [ -n "${items}" ]; then
    printf ' %s ' ${items}
fi

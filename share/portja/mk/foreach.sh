#!/bin/sh
set -e

while [ "$1" != "--" ]; do
    set -- "$@" "$1"
    shift
done

rest=$2
shift 2
cmdlen=$#

while [ -n "${rest}" ]; do
    cur=$(printf '%s' "${rest}" | sed 's/\([^\\][[:blank:]][[:blank:]]*\).*/\1/')
    rest=$(printf '%s' "${rest}" | cut -c $((${#cur} + 1))-)
    cur=$(printf '%s' "${cur}" | sed -e 's/\([^\\]\)[[:blank:]][[:blank:]]*/\1/g' \
                                     -e 's/\\\([[:blank:]]\)/\1/g')

    set -- "$@" $(printf '%s' "${cur}" | md5 -q)

    while [ -n "${cur}" ]; do
        arg=$(printf '%s' "${cur}" | sed 's/\([^\\]\):.*/\1/')
        cur=$(printf '%s' "${cur}" | cut -c $((${#arg} + 2))-)
        arg=$(printf '%s' "${arg}" | sed 's/\\:/:/g')
        set -- "$@" "${arg}"
    done

    "$@"

    for _ in $(seq ${cmdlen}); do
        set -- "$@" "$1"
        shift
    done
    shift $(($# - ${cmdlen}))
done

msg () {
    ${dp_ECHO_MSG} "$@"
}

get_keyword() {
    local kws
    kws="${keywords}"
    while [ -n "${kws}" ]; do
        kw=$(printf '%s' "${kws}" | sed 's/\([^\\]\),.*/\1/')
        kws=$(printf '%s' "${kws}" | cut -c $((${#kw} + 2))-)
        kw=$(printf '%s' "${kw}" | sed 's/\\,/,/g')
        [ $(printf '%s' "${kw}" | cut -d= -f1) = "$1" ] || continue
        printf '%s' "${kw}" | cut -d= -f2-
        return 0
    done
    return 1
}

has_keyword() {
    get_keyword "$1" >/dev/null
}

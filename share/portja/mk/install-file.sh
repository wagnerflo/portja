#!/bin/sh
set -e

type=$2
shift 2

case ${type} in
    dir)
        dest=$1
        keywords=${2:-,,}
        ;;
    symlink)
        dest=$1
        src=$1
        ;;
    *)
        src=$1
        dest=$2
        flags=$3
        ;;
esac

# ---- prepare variables ----
add_prefix () {
    case $1 in
        /*) printf '%s' "$1" ;;
        *)  printf '%s' "${dp_PREFIX}/$1" ;;
    esac
}

case ${type} in
    symlink) src_prefixed=$(add_prefix ${src}) ;;
esac

case ${type} in
    man)
        [ -z "${dest}" ] && dest=$(basename "${src}")
        num=$(printf '%s' "${dest}" | rev | cut -d. -f1)
        dest=man/man${num}/${dest}
        eval dest_prefixed=\${dp_MAN${num}PREFIX}/${dest}
        ;;
    *)
        dest_prefixed=$(add_prefix ${dest})
        ;;
esac

# ---- apply substitutions ----
case ${type} in
    script|data|man)
        case ${flags} in
            *S*)
                ( cd ${dp_WRKSRC}; \
                  ${dp_SED} ${dp_SUB_LIST_TEMP} ${src} > ${dp_WRKDIR}/pj.tmp )
                ;;
            *)
                ( cd ${dp_WRKSRC}; \
                  cp ${src} ${dp_WRKDIR}/pj.tmp )
                ;;
        esac
        ;;
esac

# ---- create directories ----
case ${type} in
    dir)     ${dp_MKDIR} -p ${dp_STAGEDIR}${dest_prefixed}             ;;
    symlink) ${dp_MKDIR} -p ${dp_STAGEDIR}$(dirname ${src_prefixed}) \
                            ${dp_STAGEDIR}$(dirname ${dest_prefixed})  ;;
    *)       ${dp_MKDIR} -p ${dp_STAGEDIR}$(dirname ${dest_prefixed})  ;;
esac

# ---- install files ----
case ${type} in
    script|data|program|man)
        eval install=\${dp_INSTALL_${type}}
	( cd ${dp_WRKSRC}; \
          ${install} ${dp_WRKDIR}/pj.tmp ${dp_STAGEDIR}${dest_prefixed} )
        ;;
    symlink)
        ${dp_RLN} ${dp_STAGEDIR}${src_prefixed} ${dp_STAGEDIR}${dest_prefixed}
        ;;
esac

# ---- extend pkg-plist ----
case ${type} in
    man) plist="${dest}.gz"                ;;
    dir) plist="@dir(${keywords}) ${dest}" ;;
    *)   plist="${dest}"                   ;;
esac

printf '%s\n' "${plist}" >> ${dp_TMPPLIST}

# ----------------------------------------------------------------------
# Directories
#
_PJ.BASEDIR:=	${.PARSEDIR}/mk
_PJ.PORTDIR:=	${.INCLUDEDFROMDIR}


# ----------------------------------------------------------------------
# PJ.TEMPLATE
#
.if !empty(PJ.TEMPLATE)
.  if !exists(${_PJ.BASEDIR}/template.${PJ.TEMPLATE}.mk)
.    error PJ.TEMPLATE=${PJ.TEMPLATE} unknown.
.  else
.    include "${_PJ.BASEDIR}/template.${PJ.TEMPLATE}.mk"
.  endif
.endif


# ----------------------------------------------------------------------
# PORTNAME, CATEGORIES, PJ.ORIGIN
#
.if !empty(PJ.ORIGIN)
PORTNAME?=	${PJ.ORIGIN:S@/@ @g:[2]}
CATEGORIES?=	${PJ.ORIGIN:S@/@ @g:[1]}
.endif

.if empty(PORTNAME) || empty(CATEGORIES)
.error PORTNAME and CATEGORIES or PJ.ORIGIN needs to be set.
.endif

.if empty(PJ.ORIGIN)
PJ.ORIGIN=	${CATEGORIES:[1]}/${PORTNAME}
.endif

# ----------------------------------------------------------------------
# PJ.MAINTAINER, PJ.COMMENT, PJ.DESCR
#
MAINTAINER?=	${PJ.MAINTAINER}
COMMENT?=	${PJ.COMMENT}
PJ.DESCR?=	${PJ.COMMENT}.


# ----------------------------------------------------------------------
# load port/repo info
#
PORTINFO?=	${_PJ.PORTDIR}/info

PJ.REPO_TARGET!=	cat ${PORTINFO}/target
PJ.REPO_REVISION!=	cat ${PORTINFO}/revision
PJ.REPO_MAINTAINER!=	cat ${PORTINFO}/maintainer


# ----------------------------------------------------------------------
# PJ.VERSION, PORTVERSION, PJ.REVISION, PORTREVISION
#
.if !empty(PJ.VERSION)
PORTVERSION=	${PJ.VERSION}
.endif

PORTREVISION?=	${PJ.REVISION:U0}

# ----------------------------------------------------------------------
# PJ.DISTFILES, DISTFILES
#
.if !empty(PJ.DISTFILES)
DISTFILES=
.endif


# ----------------------------------------------------------------------
# PKG_NOTES
#
PKG_NOTES+=		portja_target
PKG_NOTE_portja_target=	${PJ.REPO_TARGET}


# ----------------------------------------------------------------------
# implicit USES
#
USES+=	${PJ.USES}


# ----------------------------------------------------------------------
# implicit USES
#
.for type in BUILD EXTRACT FETCH PATCH PKG RUN TEST
.  for item in ${PJ.${type}_DEPENDS}
.    if ${item:S/:/ /g:[1]} == "PY" && empty(USES:Mpython*)
USES+=	python:3.8+,build
.    elif ${item:S/:/ /g:[1]} == "LUA" && empty(USES:Mlua*)
USES+=	lua
.    endif
.  endfor
.endfor


# ----------------------------------------------------------------------
# bsd.port.pre.mk
#
.include <bsd.port.pre.mk>


# ----------------------------------------------------------------------
# DEPENDS
#
.for type in BUILD EXTRACT FETCH PATCH PKG RUN TEST
.  for item in ${PJ.${type}_DEPENDS}
.    if ${item:S/:/ /g:[1]} == "PY"
${type}_DEPENDS+=	${PYTHON_PKGNAMEPREFIX}${item:S/:/ /g:[2..-1]:[*]:S/ /:/g}@${PY_FLAVOR}
.    elif ${item:S/:/ /g:[1]} == "LUA"
${type}_DEPENDS+=	${LUA_PKGNAMEPREFIX}${item:S/:/ /g:[2..-1]:[*]:S/ /:/g}@${LUA_FLAVOR}
.    elif ${item:S/:/ /g:[#]} == "1"
.      if ${item:C@[<=>]@ @g:[#]} == "2"
${type}_DEPENDS+=	${item:S@/@ @g:[2]}:${item:C/[<=>]/ /g:[1]}
.      else
${type}_DEPENDS+=	${item:S@/@ @g:[2]}>=0:${item}
.      endif
.    else
${type}_DEPENDS+=	${item}
.    endif
.  endfor
.endfor

LIB_DEPENDS+=		${PJ.LIB_DEPENDS}


# ----------------------------------------------------------------------
# TARGETS
#
# This is a bit hackish: The default targets as well as their
# dependencies get dynamically constructed when bsd.port.post.mk is
# loaded. We want to extend the fetch, extract and install sequences
# but can't modify _[TYPE]_SEQ since this is overwritten (=). We use
# the _USES_[TYPE] variable instead gets included in the sequence.
#

# ----------------------------------------------------------------------
# repository package
#
.if !empty(PJ.DISTFILES)
_PJ.FETCH_LISTFILES_CMD= \
	${SETENV} \
	     dp_DISTNAME="${DISTNAME}" \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/fetch-listfiles.sh -- "${PJ.DISTFILES}"

_PJ.FETCH_DEPENDS_CMD= \
	${SETENV} \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/fetch-depends.sh -- "${PJ.DISTFILES}"

_PJ.EXTRACT_DEPENDS_CMD= \
	${SETENV} \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/extract-depends.sh -- "${PJ.DISTFILES}"

_CKSUMFILES=
ALLFILES+=		${_PJ.FETCH_LISTFILES_CMD:sh}
FETCH_DEPENDS+=		${_PJ.FETCH_DEPENDS_CMD:sh}
EXTRACT_DEPENDS+=	${_PJ.EXTRACT_DEPENDS_CMD:sh}

_USES_fetch+=		900:pj-fetch
_USES_extract+=		900:pj-extract

pj-fetch:
	@${SETENV} \
	     dp_ECHO_MSG="${ECHO_MSG}" \
	     dp_CAT="${CAT}" \
	     dp_MKDIR="${MKDIR}" \
	     dp_PJ_PORTDIR="${_PJ.PORTDIR}" \
	     dp_WRKDIRPREFIX="${WRKDIRPREFIX}" \
	     dp_DISTNAME="${DISTNAME}" \
	     dp_DISTVERSIONFULL="${DISTVERSIONFULL}" \
	     dp_DISTDIR="${DISTDIR}" \
	     dp_FETCH_CMD="${FETCH_CMD}" \
	     dp_FETCH_BEFORE_ARGS="${FETCH_BEFORE_ARGS}" \
	     dp_FETCH_AFTER_ARGS="${FETCH_AFTER_ARGS}" \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/fetch-run.sh -- "${PJ.DISTFILES}"

pj-extract:
	@${SETENV} \
	     dp_ECHO_MSG="${ECHO_MSG}" \
	     dp_CAT="${CAT}" \
	     dp_CHMOD="${CHMOD}" \
	     dp_CHOWN="${CHOWN}" \
	     dp_PJ_PORTDIR="${_PJ.PORTDIR}" \
	     dp_WRKDIRPREFIX="${WRKDIRPREFIX}" \
	     dp_EXTRACT_WRKDIR="${EXTRACT_WRKDIR}" \
	     dp_WRKDIR="${WRKDIR}" \
	     dp_WRKSRC="${WRKSRC}" \
	     dp_DISTDIR="${DISTDIR}" \
	     dp_DISTNAME="${DISTNAME}" \
	     dp_EXTRACT_CMD="${EXTRACT_CMD}" \
	     dp_EXTRACT_BEFORE_ARGS="${EXTRACT_BEFORE_ARGS}" \
	     dp_EXTRACT_AFTER_ARGS="${EXTRACT_AFTER_ARGS}" \
	     dp_UID="${UID}" \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/extract-run.sh -- "${PJ.DISTFILES}"
.endif


# ----------------------------------------------------------------------
# file installation
#
.if !empty(PJ.INSTALL)
_USES_install+=	690:pj-install-files

.for item in ${PJ.INSTALL}
# ---- valid type? ----
.  if ${item:S/:/ /g:[1]:C/^(dir|script|data|man|program|symlink)$//} != ""
.    error "Unknown PJ.INSTALL type ${item:S/:/ /g:[1]}."
.  endif
.endfor

pj-install-files:
	@${SETENV} \
	     dp_PREFIX="${PREFIX}" \
	     dp_STAGEDIR="${STAGEDIR}" \
	     dp_WRKSRC="${WRKSRC}" \
	     dp_WRKDIR="${WRKDIR}" \
	     dp_MAN1PREFIX="${MAN1PREFIX}" \
	     dp_MAN2PREFIX="${MAN2PREFIX}" \
	     dp_MAN3PREFIX="${MAN3PREFIX}" \
	     dp_MAN4PREFIX="${MAN4PREFIX}" \
	     dp_MAN5PREFIX="${MAN5PREFIX}" \
	     dp_MAN6PREFIX="${MAN6PREFIX}" \
	     dp_MAN7PREFIX="${MAN7PREFIX}" \
	     dp_MAN8PREFIX="${MAN8PREFIX}" \
	     dp_MAN9PREFIX="${MAN9PREFIX}" \
	     dp_MKDIR="${MKDIR}" \
	     dp_SED="${SED}" \
	     dp_SUB_LIST_TEMP="${_SUB_LIST_TEMP}" \
	     dp_INSTALL_script="${INSTALL_SCRIPT}" \
	     dp_INSTALL_data="${INSTALL_DATA}" \
	     dp_INSTALL_program="${INSTALL_PROGRAM}" \
	     dp_INSTALL_man="${INSTALL_MAN}" \
	     dp_RLN="${RLN}" \
	     dp_TMPPLIST="${TMPPLIST}" \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/install-file.sh -- "${PJ.INSTALL}"
.endif


# ----------------------------------------------------------------------
# groups & users
#
.if !empty(PJ.GROUPS)
_PJ.GROUPS_INSTALL=	${WRKDIR}/pj-groups-preinstall
_PJ.GROUPS_REMOVE=	${WRKDIR}/pj-groups-postdeinstall
_USES_install+=		710:pj-install-groups

pj-install-groups:
	@${SETENV} \
	     dp_GROUPS_INSTALL="${_PJ.GROUPS_INSTALL}" \
	     dp_GROUPS_REMOVE="${_PJ.GROUPS_REMOVE}" \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/install-group.sh -- "${PJ.GROUPS}"

PKGPREINSTALL+=		${_PJ.GROUPS_INSTALL}
.endif

.if !empty(PJ.USERS)
_PJ.USERS_INSTALL=	${WRKDIR}/pj-users-preinstall
_PJ.USERS_REMOVE=	${WRKDIR}/pj-users-postdeinstall
_USES_install+=		710:pj-install-users

pj-install-users:
	@${SETENV} \
	     dp_USERS_INSTALL="${_PJ.USERS_INSTALL}" \
	     dp_USERS_REMOVE="${_PJ.USERS_REMOVE}" \
	     ${SH} ${_PJ.BASEDIR}/foreach.sh \
	         ${SH} ${_PJ.BASEDIR}/install-user.sh -- "${PJ.USERS}"

PKGPREINSTALL+=		${_PJ.USERS_INSTALL}
PKGPOSTDEINSTALL+=	${_PJ.USERS_REMOVE}
.endif

.if !empty(PJ.GROUPS)
PKGPOSTDEINSTALL+=	${_PJ.GROUPS_REMOVE}
.endif


# ----------------------------------------------------------------------
# rc file
#
.if exists(${FILESDIR}/${PORTNAME}.in)
USE_RC_SUBR=	${PORTNAME}
.endif


# ----------------------------------------------------------------------
# bsd.port.post.mk
#
.include <bsd.port.post.mk>

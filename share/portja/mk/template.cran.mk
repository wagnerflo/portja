.if !empty(PJ.ORIGIN)
PORTNAME?=	${PJ.ORIGIN:S@/@ @g:[2]:C/^R-cran-//}
.endif

.if !empty(PJ.VERSION)
DISTVERSION:=	${PJ.VERSION}
PJ.VERSION:=
.endif

USES+=		cran:${PJ.USES_CRAN:Uauto-plist}
PJ.DISTFILES?=	cran:md5=${PJ.CRAN_MD5}
DISTNAME?=	${PORTNAME}_${DISTVERSION}

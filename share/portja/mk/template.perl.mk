.if !empty(PJ.ORIGIN)
PORTNAME?=	${PJ.ORIGIN:S@/@ @g:[2]:C/^p5-//}
.endif

PKGNAMEPREFIX=	p5-
USES+=		perl5
USE_PERL5=	${PJ.USE_PERL:Uconfigure}

_USES_install+=	710:pj-perl-post-install

pj-perl-post-install:
	@if [ -d ${STAGEDIR}${PACKLIST_DIR} ] ; then \
	     ${FIND} ${STAGEDIR}${PACKLIST_DIR} -name .packlist | while read f ; do \
	         sed -e 's|^${PREFIX}/||' \
	             -e 's|^${SITE_MAN3_REL}/.*|&.gz|' \
	             -e 's|^${SITE_MAN1_REL}/.*|&.gz|' \
	             $$f >> ${TMPPLIST}; \
	     done \
	 fi

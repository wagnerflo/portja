.PHONY: genport

.if ${.TARGETS} == "genport"
PORTDIR := ${.INCLUDEDFROMFILE:S/.portja$//}
genport:
	@echo "generate"
	@echo "  ${PORTDIR}/Makefile"
	@echo "  ${PORTDIR}/distinfo"
	@echo "  ${PORTDIR}/pkg-descr"
	@echo "  ${PORTDIR}/pkg-plist"
	@echo "  ${PORTDIR}/files/..."
.else

PORTNAME=	...
PORTVERSION=	...

# ...

.include <bsd.port.mk>

.endif

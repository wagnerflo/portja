PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
USES+=		python:3.8+
USE_PYTHON=	${PJ.USE_PYTHON:Uautoplist distutils}

_USES_install+=	710:pj-python-post-install

pj-python-post-install:
	@${FIND} ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR} \
	    -type f -name "*.so" -exec ${STRIP_CMD} {} +

#!/bin/sh
set -e

shift
name="$1"
gid="$2"

for file in ${dp_GROUPS_INSTALL} ${dp_GROUPS_REMOVE}; do
    if [ ! -e ${file} ]; then
        cat <<EOF > ${file}
#!/bin/sh
set -e
set -u
set -f

PW=/usr/sbin/pw

if [ -n "\${PKG_ROOTDIR}" ] && [ "\${PKG_ROOTDIR}" != "/" ]; then
    PW="\${PW} -R \${PKG_ROOTDIR}"
fi
EOF
    fi
done

cat <<EOF >> ${dp_GROUPS_INSTALL}

if ! \${PW} groupshow "${name}" >/dev/null 2>&1; then
    echo "===> Creating group ${name} with gid ${gid}."
    \${PW} groupadd -n "${name}" -g "${gid}"
else
    echo "===> Using existing group ${name}."
fi
EOF

cat <<EOF >> ${dp_GROUPS_REMOVE}

if \${PW} groupshow "${name}" >/dev/null 2>&1; then
    echo "==> You should manually remove the group ${name}."
fi
EOF

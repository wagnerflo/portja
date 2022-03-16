#!/bin/sh
set -e

shift
name="$1"
uid="$2"
gid="$3"
gecos="$4"
home="$5"
shell="$6"
groups="$7"

for file in ${dp_USERS_INSTALL} ${dp_USERS_REMOVE}; do
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

cat <<EOF >> ${dp_USERS_INSTALL}

if ! \${PW} usershow "${name}" >/dev/null 2>&1; then
    echo "===> Creating user ${name} with uid ${uid}."
    \${PW} useradd \\
          -n "${name}" \\
          -u "${uid}" -g "${gid}" \\
          -c "${gecos}" \\
          -d "${home}" \\
          -s "${shell}"
    for group in ${groups}; do
        \${PW} groupmod -n "\${group}" -m "${name}"
    done
else
    echo "===> Using existing user ${name}."
fi
EOF

cat <<EOF >> ${dp_USERS_REMOVE}

if \${PW} usershow "${name}" >/dev/null 2>&1; then
    echo "==> You should manually remove the user ${name}."
fi
EOF

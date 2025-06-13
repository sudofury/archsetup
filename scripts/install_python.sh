#!/bin/bash

set -e

# -----------------------------------------------------------------------------
# This script provides minimal Python installation.
# It sets up virtual environment at ~/.python_venv.
# It includes JupyterLab and some packages.
# -----------------------------------------------------------------------------

# Highlight the output.
YELLOW="\e[1;33m" && RED="\e[1;31m" && GREEN="\e[1;32m" && COLOR_OFF="\e[0m"
cprint() { echo -ne "${1}${2}${COLOR_OFF}"; }
msg() { cprint ${YELLOW} "${1}\n"; }
error() { cprint ${RED} "${1}\n"; }
success() { cprint ${GREEN} "${1}\n"; }

# Cancel installation if run as a root.
if [ "$EUID" -eq 0 ]; then
	error "Do NOT run this script as a root!"
	exit
fi

msg "Installing Python and JupyterLab ..."

# Setting up virtual environment for Python
PYDIR="${HOME}/.python_venv"
PIP="${PYDIR}/bin/pip"
JUPYTER="${PYDIR}/bin/jupyter"
mkdir ${PYDIR} && mkdir ${PYDIR}/cache
cat > ${PYDIR}/pip.conf <<EOF
  [global]
  cache-dir=${PYDIR}/cache
EOF
python -m venv ${PYDIR}
${PIP} install --upgrade pip --require-virtualenv
${PIP} install jupyterlab numpy scipy matplotlib sympy h5py \
    pandas tabulate pypdf yt-dlp --require-virtualenv

success "Successfully installed Python and JupyterLab!"

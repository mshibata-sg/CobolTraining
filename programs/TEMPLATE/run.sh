#!/bin/bash
set -Eeuo pipefail

SCRIPTDIR=$(cd $(dirname $0); pwd)

PROGRAMNAME=$(basename "${SCRIPTDIR}")
BINDIR="${SCRIPTDIR}"
PROGRAM="${BINDIR}/${PROGRAMNAME}"

export ITF="${SCRIPTDIR}/../../data/TEMPLATE_I.dat"
export OTF="${SCRIPTDIR}/../../data/TEMPLATE_O.dat"

${PROGRAM} | iconv -f cp932

#!/bin/bash

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VENV="certbot/venv"
readonly PYTHON="python3.8"
readonly CERTBOT_ARCHIVE_FOLDER=certbot/archive

cd "${SCRIPT_DIR}"

${PYTHON} -m venv "${VENV}"
source "${VENV}/bin/activate"

rm -rf ${CERTBOT_ARCHIVE_FOLDER}

pip3 install -r requirements.txt -t ${CERTBOT_ARCHIVE_FOLDER}

cp -f main.py ${CERTBOT_ARCHIVE_FOLDER}

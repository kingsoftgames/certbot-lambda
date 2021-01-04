#!/bin/bash

umask 022

set -e
declare -r python='python3.6'

declare -r script_dir=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
declare -r venv="${script_dir}/certbot/venv"
declare -r certbot_version=$( awk -F= '$1 == "certbot"{ print $NF; }' "${script_dir}/requirements.txt" )
declare -r package="${script_dir}/certbot/certbot-${certbot_version}.zip"


_err() {
    echo "err: ${*}"
}

_msg() {
    echo "info: ${*}"
}

_clean() {
    rm -rf "${script_dir}/certbot"
}

setup_venv() {
    # Create VENV and add required packages
    _msg "Setting up virtualenv and installing certbot"
    ${python} -m venv "${venv}"
    source "${venv}/bin/activate"
    pip install -q -r "${script_dir}/requirements.txt"
}

apply_patch() {
    _msg "Patching"
    (
        cd "${script_dir}" || exit 1
        patch -p1 < endpoint.patch
    )
}

package() {
    local package_file=$(basename "${package}")
    _msg "Packaging files"
    (
        cd "${venv}/lib/${python}/site-packages/" || exit 1
        zip -q -r "${package_file}" .
        mv "${package_file}" "${script_dir}/certbot/"
    )

    # Add our function to zip
    zip -g "${package}" main.py
}


if [[ $1 = clean ]] ; then
    _clean
    exit
elif [[ -n $1 ]] ; then
    _err "Invalid option"
    exit 1
fi

mkdir -p "${script_dir}/certbot"
rm -f "${package}"
setup_venv
apply_patch
package

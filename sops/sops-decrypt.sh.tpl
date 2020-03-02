#!/bin/bash

set -e
set -o pipefail

function decrypt_file() {
    {SOPS_BINARY_PATH} -d $1 --config {SOPS_CONFIG_FILE}
}

{DECRYPT_FILES}
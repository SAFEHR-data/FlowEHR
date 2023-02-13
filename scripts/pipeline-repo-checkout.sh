#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# Uncomment this line to see each command for debugging (careful: this will show secrets!)
# set -o xtrace

# TODO: parse config to get the list of repositories
bash ./load_env.sh

env > /tmp/env.txt
#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
exec /usr/bin/expect "$script_dir/cli-plan-percent.exp"

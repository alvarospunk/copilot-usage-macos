#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

check() {
    expected=$1
    input=$2
    actual=$(printf '%b' "$input" | /usr/bin/expect "$script_dir/cli-plan-percent.exp" --parse)
    if [ "$actual" != "$expected" ]; then
        printf 'Expected %s, got %s\n' "$expected" "$actual" >&2
        exit 1
    fi
}

check '30%' 'Plan       ######## 30% used\nSession 2% used\nWeekly 15% used\n'
check '30%' '\033[3C\033[mPlan\033[7C######## 30% used\033[116C\033[37m'
check '27.5%' 'Weekly 80% used\nPlan: 27.5% used\n'
check '100%' 'Plan 100% used\n'
check '0%' 'Plan 0% used\n'
if printf '%s\n' 'Session 4% used' | /usr/bin/expect "$script_dir/cli-plan-percent.exp" --parse >/dev/null 2>&1; then
    printf '%s\n' 'Session usage must not be mistaken for Plan usage.' >&2
    exit 1
fi
printf '%s\n' 'CLI Plan parser tests passed.'

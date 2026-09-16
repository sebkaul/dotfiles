#!/usr/bin/env bash
# common.sh — output helpers shared by bootcheck and netcheck.
# Sourced, never executed. Check functions report through these helpers and
# never exit, so tests can source the libs and inspect SC_FAILS/SC_WARNS.

# Colour only when a human is looking: piping into a file or `less` should not
# fill it with escape codes. NO_COLOR is the de-facto opt-out (no-color.org).
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    SC_RED=$'\e[31m'
    SC_GREEN=$'\e[32m'
    SC_YELLOW=$'\e[33m'
    SC_DIM=$'\e[2m'
    SC_BOLD=$'\e[1m'
    SC_RESET=$'\e[0m'
else
    SC_RED='' SC_GREEN='' SC_YELLOW='' SC_DIM='' SC_BOLD='' SC_RESET=''
fi

SC_FAILS=0
SC_WARNS=0

sc_reset_counts() {
    SC_FAILS=0
    SC_WARNS=0
}

sc_ok() {
    printf '  %s✓%s %s\n' "$SC_GREEN" "$SC_RESET" "$*"
}

sc_fail() {
    printf '  %s✗ %s%s\n' "$SC_RED$SC_BOLD" "$*" "$SC_RESET"
    SC_FAILS=$((SC_FAILS + 1))
}

sc_warn() {
    printf '  %s!%s %s\n' "$SC_YELLOW" "$SC_RESET" "$*"
    SC_WARNS=$((SC_WARNS + 1))
}

sc_info() {
    printf '  %s·%s %s\n' "$SC_DIM" "$SC_RESET" "$*"
}

# Indented follow-up line under the previous result: what to do about it.
sc_hint() {
    printf '      %s→ %s%s\n' "$SC_DIM" "$*" "$SC_RESET"
}

sc_header() {
    printf '%s%s%s\n' "$SC_BOLD" "$*" "$SC_RESET"
}

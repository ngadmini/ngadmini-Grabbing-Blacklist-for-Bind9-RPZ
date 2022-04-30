#!/usr/bin/env bash
# TAGS
#   grab_scp.sh
#   v6.3
# AUTHOR
#   ngadimin@warnet-ersa.net
# TL;DR
#   see README and LICENSE

umask 027; set -Eeuo pipefail
PATH=/bin:/usr/bin:/usr/local/bin:$PATH
_DIR=$(realpath "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")
startTime=$(date +%s)
start=$(date "+DATE: %Y-%m-%d% TIME: %H:%M:%S")

printf "\n\x1b[91m[3'th] TASKs:\x1b[0m\nStarting %s ... %s" "$(basename "$0")" "$start"
cd "$_DIR"
# shellcheck source=/dev/null
source "$_DIR"/grab_lib; trap f_trap 0 2 3 15; [ ! "$UID" -eq 0 ] || f_xcd 10
f_syn; endTime=$(date +%s); DIF=$((endTime - startTime))
printf "[INFO] Completed \x1b[93mIN %s:%s\x1b[0m\n" "$((DIF/60))" "$((DIF%60))s"
exit 0

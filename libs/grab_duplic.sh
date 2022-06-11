#!/usr/bin/env bash
# TAGS
#   grab_duplic.sh
#   v7.0
# AUTHOR
#   ngadimin@warnet-ersa.net
# TL;DR
#   don't change unless you know what you're doing
#   see README and LICENSE
# shellcheck source=/dev/null disable=SC2059 disable=SC2154

T=$(date +%s%N)
set -Eeuo pipefail
PATH=/usr/local/bin:/usr/bin:/bin:$PATH
_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${_DIR}"

readonly _LIB="${_DIR}"/grab_library
if [[ -e ${_LIB} ]]; then
   if [[ $(stat -L -c "%a" "${_LIB}") != 644 ]]; then chmod 644 "${_LIB}"; fi
   source "${_LIB}"; f_trap; f_cnf
else
   printf "[FAIL] %s notFOUND\n" "${_LIB##*/}"; exit 1
fi

printf "\n${_RED}\nstarting ${0##*/} ${_ver} at ${_CYN}" "[1'th] TASKs:" "${_lct}"
[[ ! ${UID} -eq 0 ]] || f_xcd 10

# inspecting required files <categories> first
ar_cat=(txt.adult txt.ipv4 txt.malware txt.publicite txt.redirector txt.trust+)
mapfile -t ar_CAT < <(f_fnd "txt.*")
printf -v miss_v "%s" "$(echo "${ar_cat[@]}" "${ar_CAT[@]}" | f_sed)"

if [[ ${#ar_CAT[@]} -eq "${#ar_cat[@]}"  &&  ${ar_CAT[*]} == "${ar_cat[*]}" ]]; then
   unset -v ar_cat
   ar_cat=(); ar_dmn=(); ar_tmp=()
   for B in "${!ar_CAT[@]}"; do
      ar_cat+=("${ar_CAT[B]/txt./}")
      ar_dmn+=(dmn."${ar_CAT[B]/txt./}")
      ar_tmp+=(tmr."${ar_CAT[B]/txt./}")
   done

   printf "\n${_inf} eliminating duplicate entries between CATEGORY\n"
   printf "${_inf} FOUND %s CATEGORIES: ${_CYN}\n" "${#ar_CAT[@]}" "${ar_cat[*]}"

   f_dupl "${ar_cat[0]}"   # remove duplicate domains based on ${ar_cat[0]}
   for C in {2..5}; do
      f_ddup "$C" "${ar_cat[C]}" "${ar_CAT[C]}" "${ar_CAT[0]}" "${ar_tmp[C]}" 0
      f_dawk "${ar_tmp[C]}" "${ar_CAT[C]}" "${ar_dmn[C]}"
      cp "${ar_dmn[C]}" "${ar_CAT[C]}"; f_do
   done

   # remove duplicate domains based on ${ar_cat[1]}. do nothing
   printf "eliminating duplicate entries based on ${_CYN}\t\tdo nothing\n" "${ar_cat[1]^^}"

   f_dupl "${ar_cat[2]}"   # remove duplicate domains based on ${ar_cat[2]}
   for D in {3..5}; do
      f_ddup "$D" "${ar_cat[D]}" "${ar_CAT[D]}" "${ar_CAT[2]}" "${ar_tmp[D]}" 2
      f_dawk "${ar_tmp[D]}" "${ar_CAT[D]}" "${ar_dmn[D]}"
      cp "${ar_dmn[D]}" "${ar_CAT[D]}"; f_do
   done

   f_dupl "${ar_cat[3]}"   # remove duplicate domains based on ${ar_cat[3]}
   for E in 4 5; do
      f_ddup "$E" "${ar_cat[E]}" "${ar_CAT[E]}" "${ar_CAT[3]}" "${ar_tmp[E]}" 3
      f_dawk "${ar_tmp[E]}" "${ar_CAT[E]}" "${ar_dmn[E]}"
      cp "${ar_dmn[E]}" "${ar_CAT[E]}"; f_do
   done

   f_dupl "${ar_cat[4]}"   # remove duplicate domains based on ${ar_cat[4]}
   f_ddup 5 "${ar_cat[5]}" "${ar_CAT[5]}" "${ar_CAT[4]}" "${ar_tmp[5]}" 4
   f_dawk "${ar_tmp[5]}" "${ar_CAT[5]}" "${ar_dmn[5]}"
   cp "${ar_dmn[5]}" "${ar_CAT[5]}"; f_do

   # remove duplicate domains based on ${ar_cat[5]}. do nothing
   printf "eliminating duplicate entries based on ${_CYN}\t\tdo nothing\n" "${ar_cat[5]^^}"
else
   printf "\n${_err} misMATCH file: ${_CYN}" "${miss_v}"; f_xcd 19 "${ar_cat[*]}"
fi

# display result
unset -v ar_CAT
mapfile -t ar_CAT < <(f_fnd "txt.*")
printf "\n${_inf} deduplicating domains (${_CYN}) in summary:\n" "${#ar_CAT[@]} all CATEGORIES"
for P in "${!ar_CAT[@]}"; do
   printf -v _dpl "%'d" "$(wc -l < "${ar_CAT[P]}")"
   printf "%12s: %9s entries\n" "${ar_cat[P]}" "${_dpl}"
done
printf -v _ttl "%'d" "$(wc -l "${ar_CAT[@]}" | grep "total" | cut -d' ' -f3)"
printf "%12s: %9s entries\n" "TOTAL" "${_ttl}"
T="$(($(date +%s%N)-T))"; f_time
exit 0

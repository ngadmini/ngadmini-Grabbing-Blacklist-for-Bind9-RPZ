#!/usr/bin/env bash
# TAGS
#   grab_build.sh
#   v6.2
# AUTHOR
#   ngadimin@warnet-ersa.net
# see README and LICENSE

umask 027
set -Eeu
PATH=/bin:/usr/bin:/usr/local/bin:$PATH
_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export LC_NUMERIC=id_ID.UTF-8
startTime=$(date +%s)
start=$(date "+DATE: %Y-%m-%d TIME: %H:%M:%S")
trap f_trap 0 2 3 15      # cleanUP on exit, interrupt, quit & terminate
# shellcheck source=/dev/null
source "$_DIR"/grab_lib.sh

[ ! "$UID" -eq 0 ] || f_xcd 10; cd "$_DIR"
printf "\n\x1b[91m[2'nd] TASKs:\x1b[0m\nStarting %s ... %s\n" "$(basename "$0")" "$start"

# these array is predefined and as a blanko, to counter part 'others' array
#    raw domains list
ar_raw=(txt.adult txt.ipv4 txt.malware txt.publicite txt.redirector txt.trust+)
#    raw splitted domains list
ar_split=(txt.adultaa txt.adultab txt.adultac txt.adultad txt.adultae txt.adultaf \
   txt.adultag txt.ipv4 txt.malware txt.publicite txt.redirector txt.trust+)

for y in ${ar_raw[*]}; do
   if ! [ -f "$y" ]; then
      mapfile -t ar_raw1 < <(find . -maxdepth 1 -type f -name "txt.*" | sed -e "s/\.\///" | sort)
      printf -v miss_v "%s" "$(echo "${ar_raw[@]}" "${ar_raw1[@]}" | sed "s/ /\n/g" | sort | uniq -u | tr "\n" " ")"
      f_xcd 17 "$miss_v"
      exit 1
   fi
done

mapfile -t ar_raw1 < <(find . -maxdepth 1 -type f -name "txt.*" | sed -e "s/\.\///" | sort)
if [ "${#ar_raw[@]}" -eq "${#ar_raw1[@]}" ]; then
   unset ar_raw1
   printf "[INFO] Splitting adult category to 750.000 lines/sub-category\n"
   split -l 750000 txt.adult txt.adult
   mv txt.adult /tmp
   mapfile -t ar_txt < <(find . -maxdepth 1 -type f -name "txt.*" | sed -e "s/\.\///" | sort)

   if [ "${#ar_txt[@]}" -eq "${#ar_split[@]}" ]; then
      ar_cat=(); ar_dom=()
      for Y in {0..11}; do
         ar_cat+=("${ar_txt[Y]/txt./}")
         ar_dom+=("${ar_txt[Y]/txt./db.}")
      done

      find . -maxdepth 1 -type f -name "db.*" -print0 | xargs -0 -r rm
      printf "[INFO] Rewriting all domain lists to RPZ format :\n\x1b[93m%s\x1b[0m\n" "${ar_cat[*]}"

      for X in {0..11}; do
         if [ "$X" -eq 7 ]; then
            # policy: NS-IP Trigger NXDOMAIN Action
            f_ip4 "${ar_dom[X]}" "${ar_txt[X]}" "${ar_cat[X]}"
         else
            # policy: QNAME Trigger NXDOMAIN Action
            f_rpz "${ar_dom[X]}" "${ar_txt[X]}" "${ar_cat[X]}"
         fi
      done

      printf -v ttl "%'d" "$(wc -l "${ar_dom[@]}" | grep "total" | cut -d" " -f2)"
      printf "%41s : %10s entries\n" "TOTAL" "$ttl"

   elif [ "${#ar_txt[@]}" -gt "${#ar_split[@]}" ]; then
      printf "\x1b[91m[ERROR]\x1b[0m database growth, can produce db.* files: %s exceeds from %s\n" \
         "${#ar_txt[@]}" "${#ar_split[@]}"
      printf "[HINTS] please make adjustments to your rpz.* files and your bind9-server config\n"
      exit 1
   else
      _add="database shrunk than expected. can only create"
      printf "\x1b[91m[ERROR] due to:\x1b[0m %s %s of %s db.* files:\n" "$_add" \
         "${#ar_txt[@]}" "${#ar_split[@]}"
      exit 1
   fi
else
   printf "\x1b[91m[ERROR]\x1b[0m due to: FOUND %s domain list:\n\t%s\n" "${#ar_raw1[@]}" "${ar_raw1[*]}"
   printf "[HINTS] expected %s domains list: \n\t%s\n" "${#ar_raw[@]}" "${ar_raw[*]}"
   exit 1
fi

endTime=$(date +%s)
DIF=$((endTime - startTime))
printf "[INFO] Completed \x1b[93mIN %s:%s\x1b[0m\n" "$((DIF/60))" "$((DIF%60))s"
exit 0

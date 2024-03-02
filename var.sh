LC_CTYPE=C
LANG=C
language=en
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fic_config="${SCRIPT_DIR}/config"
SCRIPT_DIR=$(dirname "$0")
NOM_SCRIPT=$(basename "$0")
# bc, jq
USER_GENEANET=""
NUMBER='^[0-9]+$'
nbAppel=0
#login=$(cat /etc/geneanet-secret/login)
#pwd=$(cat /etc/geneanet-secret/pwd)
url="https://gw.geneanet.org"

TMP_DIR="/tmp/geneanet"
TMP_DIR="/Volumes/DisqueRAM/geneanet"
mkdir -p "$TMP_DIR" >/dev/null 1>&2

fic_id="${TMP_DIR}/KeyID"
fic_id_exist="${fic_id}_exist"
fic_id_link="${fic_id}_link"
fic_fam="${TMP_DIR}/FamID"

dir_cache="${HOME}/geneanet_cache"
fic_cache="${dir_cache}/cache"

user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.71 Safari/537.36"
user_agent="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0"
user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:91.0) Gecko/20100101 Firefox/91.0"
user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 15_0_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36"
user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:122.0) Gecko/20100101 Firefox/122.0"
TRACE=false
QUI_PARENT="PARENT"
QUI_CONJOINT="PERE"
QUI_PARENT="PERE"
QUI_CONJOINT="EPOUSE"
QUI_ENFANT="ENFANT"
QUI_MERE="MERE"
TAB_LOG=""
tab=""
CHRONO="false"
portrait="Portrait"

CODE_DEJA_TRAITE="101"

init_script_var() {
   rm $fic_id $fic_id_exist $fic_id_link $fic_fam 2>/dev/null || true
   touch $fic_id $fic_id_exist $fic_id_link $fic_fam 2>/dev/null || true
}

init_script_var



gsed="/usr/local/bin/gsed"
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

declare -i optNbAsc=0 nbAsc=-1 optNbDesc=0 nbDesc=-1 

#login=$(cat /etc/geneanet-secret/login)
#pwd=$(cat /etc/geneanet-secret/pwd)
url="https://gw.geneanet.org"
cmd_gzip=$(which gzip)
cmd_gunzip=$(which gunzip)

TMP_DIR="/tmp/geneanet"w

DIR_CACHE="${HOME}/geneanet_cache"
FIC_CACHE="${DIR_CACHE}/cache"
declare -i OPT_CACHE=1 OPT_SOURCE=1 OPT_NOTE=1

user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.71 Safari/537.36"
user_agent="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0"
user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:91.0) Gecko/20100101 Firefox/91.0"
user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 15_0_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36"
user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:122.0) Gecko/20100101 Firefox/122.0"
TRACE=false
DEBUG=false
QUI_PERE="PERE"
QUI_MERE="MERE"
QUI_PARENT="PARENT"
QUI_CONJOINT="CONJOINT"
QUI_ENFANT="ENFANT"
QUI_FRERE="FRERE"
TAB_LOG=""
tab=""
CHRONO="false"
portrait="Portrait"

INDI_DEJA_TRAITE="101"
INDI_INCONNU="102"

# Variable globale pour les notes/sources )possibel car utilise tout de suite par d'impact sur fct récursive 
g_srcIndi=""
g_srcNaissance="" 
g_srcUnion="" 
g_srcDeces=""

g_noteIndi=""
g_noteNaissance=""
g_noteMariage=""
g_noteDeces=""
g_noteFamille=""
g_noteDivorce=""


# Si ce fichier existe le script se mets en pause
# Arret la pause tant que le fichier existe
pause="/tmp/geneanet.pause.$$"
# Si ce fichier existe le script execute le shell
# Le fichier est supprimé tout de suite par le script
runsh="/tmp/geneanet.runsh.$$"

init_script_var() {
   rm $fic_id $fic_id_exist $fic_id_link $fic_fam 2>/dev/null || true
   touch $fic_id $fic_id_exist $fic_id_link $fic_fam 2>/dev/null || true
}

init_script_var



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
# Pattern pour les nom de fichier
pattern="\$TMP_DIR/gen_%04d_%s"

# Mac OS, sed -i 'extention' -e .... et Linux sed -i -e
[[ "$OSTYPE" == *"arwin"* ]] && optSed="''" || optSed=''

declare -i optNbAsc=0 nbAsc=-1 optNbDesc=0 nbDesc=-1 

#login=$(cat /etc/geneanet-secret/login)
#pwd=$(cat /etc/geneanet-secret/pwd)
url="https://gw.geneanet.org"
cmd_gzip=$(which gzip)
cmd_gunzip=$(which gunzip)

TMP_DIR="/tmp/geneanet"

DIR_CACHE="${HOME}/geneanet_cache"
FIC_CACHE="${DIR_CACHE}/cache"
declare -i OPT_CACHE=1 OPT_SOURCE=1 OPT_NOTE=1 OPT_DATE=1 UPDATE_CACHE=1

DEBUG=false
FMT_TRACE="json"
QUI_PERE="PERE"
QUI_MERE="MERE"
QUI_PARENT="PARENT"
QUI_CONJOINT="CONJOINT"
QUI_ENFANT="ENFANT"
QUI_FRERE="FRERE"
TAB_LOG=""

portrait="Portrait"

INDI_DEJA_TRAITE="101"
INDI_INCONNU="102"

FAMILY_EXIST="200"
FAMILY_NO_EXIST="100"
ERROR="1"

FOUND=200
NOT_FOUND=100

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

fic_id="${TMP_DIR}/KeyID"
fic_id_exist="${fic_id}_exist"
fic_id_link="${fic_id}_link"
fic_id_parent="${fic_id}_parent"
fic_fam="${TMP_DIR}/FamID"



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



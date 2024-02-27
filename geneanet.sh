#!/bin/bash

#### ./geneanet.sh "https://gw.geneanet.org/egarciat?lang=fr&iz=0&p=maria+magdalena+rita&n=amat+mira" 24 ""
# DATE
#    ABT ==> Vers
#    AFT ==> Après
#    BEF ==> Avant
#    BET ==> Entre
#    FRON .. TO ==> de ... à .... (Pour les blocs Titre TIT)

#set -o errtrace
#trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]})' ERR

set -o pipefail

quitter() {
   exit "$1"
}

traperror() {
   local err=$1  # error status
   local line=$2 # LINENO
   local linecallfunc=$3
   local command="$4"
   local funcstack="$5"
   echo "\${FUNCNAME[@]}:[${FUNCNAME[@]}]"
   echo "err:[$err] line:[$line] linecallfunc:[$linecallfunc] command:[$command] funcstack:[$funcstack]"
   echo "<---"
   echo "ERREUR: ligne $line - commande '$command' terminé avec code erreur : $err"
   if [ "$funcstack" != "::" ]; then
      echo -n "   ... Erreur à ( ${funcstack} "
      if [ "$linecallfunc" != "" ]; then
         echo -n "Appelé ) la ligne $linecallfunc"
      fi
   else
      echo -n "   ... internal debug info from function ${FUNCNAME} (line $linecallfunc)"
   fi
   echo
   echo "--->"
   quitter 1
}

trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]})' ERR
#   local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]}

SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/var.sh"
source "${SCRIPT_DIR}/log.sh"
source "${SCRIPT_DIR}/date.sh"
source "${SCRIPT_DIR}/cherche_indi.sh"
source "${SCRIPT_DIR}/cherche_enfant.sh"
source "${SCRIPT_DIR}/get_page_html.sh"
source "${SCRIPT_DIR}/cherche_source.sh"
source "${SCRIPT_DIR}/cherche_note.sh"
source "${SCRIPT_DIR}/write_indi.sh"
source "${SCRIPT_DIR}/${language}/const.sh"

incremente_famille() {
   local famille=0
   if [[ "$1" == "famc" ]]; then
      if [[ ! -f "$fic_famc" ]]; then
         echo "le fichier n'existe pas"
         quitter 1
      else
         famille=$(cat $fic_famc)
      fi
   elif [[ "$1" == "fams" ]]; then
      if [[ ! -f "$fic_fams" ]]; then
         echo "le fichier n'existe pas"
         quitter 1
      else
         famille=$(cat $fic_fams)
      fi
   fi
   famille=$((famille + 1))
   eval "$2=\"$famille\""

}

initialise_individu() {
   echo "0" > "${fic_id}"
}

initialise_famc() {
   echo "-1" >${fic_famc}
}

initialise_fams() {
   echo "-1" >${fic_fams}
}

init_cnx(){
	log "init_cnx(): fic_config:[$fic_config]"
   USER_GENEANET=$(grep user "${fic_config}" | sed -e 's/user.*=//g' -e 's/ //g' -e "s/'//g")
   COOKIES=$(grep COOKIES "${fic_config}" | sed -e 's/^.*COOKIES=//g' -e "s/'//g")
}

#quitter 0

recupFichierFamille() {
   local rep="$1"
   local ficGCOM="$2"

   for fic in "$rep/ID_"*; do
      cat "$fic" >> "$ficGCOM"
   done

   for fic in "$rep/FAM_"*; do
      cat "$fic" >> "$ficGCOM"
   done
}


usage() {
   echo "usage: $(basename "$0")"
   echo "   -u URL        : Lien url ver la famille a récupérer"
   echo "   -i            : Initialisation du N° de l'individu"
   echo "   -s            : Initialisation du N° de la famille"
   echo "   -c            : mode verbose"
   echo "   -v            : mode verbose"
   echo "   -x            : mode verbose (timestampt)"
   echo "   -o            : fichier out"

   echo ""
   echo "   [--u[=]URL]   : Lien url ver la famille a récupérer"
   echo "   [--no-parent] : Ne recherche pas les parents"
   echo "   [--no-epoux]  : Ne recherche pas les epouses"
   echo "   [--no-frere]  : Ne recherche pas les freres/soeurs"
   echo "   [--no-enfant] : Ne recherche pas les enfant"
}

main() {
   local uri=""
   local init_individu=false
   local init_famc=false
   local init_fams=false
   local clean_tmp_dir=false
   local ch_Parent=1
   local ch_Epoux=1
   local ch_Frere=1
   local ch_Enfant=1

   local url_param=""
   local numFAMS=1
   local fic_gedcom="${SCRIPT_DIR}/geneanet.ged"
   local optchar

   optspec=":u:ic:o:snvxhv-:"
   while getopts "$optspec" optchar; do
      echo "optchar:[$optchar]"
      case "${optchar}" in
         -)
            case "${OPTARG}" in
               url)
                  url_param="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                  # echo "Option: '--${OPTARG}', url_param: '${url_param}'" >&2;
                  ;;            
               no-parent)
                  ch_Parent="0"
                  ;;
               no-enfant)
                  ch_Enfant="0"
                  ;;
               no-epoux)
                  ch_Epoux="0"
                  ;;
               no-frere)
                  ch_Frere="0"
                  ;;
               url)
                  val="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                  # echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                  ;;            
               url=*)
                  url_param=${OPTARG#*=}
                  opt=${OPTARG%=$val}
                  echo "Parsing option: '--${opt}', value: '${url_param}'" >&2;
                  ;;
               *)
                  if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                     {
                        echo "usage: $(basename "$0")"
                        echo "Option invalide --${OPTARG}"
                        echo
                     } >&2
                     quitter 2
                  fi
                  ;;
            esac;;
         h)
            usage >&2
            quitter 2
            ;;
         o)
            fic_gedcom="${OPTARG}"
            touch "$fic_gedcom"
            ;;
         x)
            TRACE=true
            CHRONO=true
            # echo "Parsing option: '-${optchar}'" >&2
            ;;
         v)
            TRACE=true
            # echo "Parsing option: '-${optchar}'" >&2
            ;;
         c)
            fic_config="$OPTARG"
            if [[ ! -f "${fic_config}" ]]; then
               {
                  echo "usage: $(basename "$0")"
                  printf "${MSG_NOT_FOUND}" "$fic_config"
               } >&2
               quitter 0
            fi
            # echo "Parsing option: '-${optchar}'" >&2
            ;;
         i)
            init_individu=true
            # echo "Parsing option: '-${optchar}'" >&2
            ;;
         s)
            init_fams=true
            # echo "Parsing option: '-${optchar}'" >&2
            ;;
         u)
            url_param="$OPTARG"
            echo "ICI url_param:[$url_param]"
            # echo "Parsing option: '-${optchar}' $OPTARG" >&2
            ;;
         *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
               echo "Non-option argument: '-${OPTARG}'" >&2
               usage >&2
               quitter 0
            fi
            ;;
      esac
   done

   if [[ "$url_param" == "" ]]; then
      echo "$(basename "$0") : -u URL Obligatoire"
      quitter 1
   fi
   if [[ "$init_individu" == "true" ]]; then
      initialise_individu
   fi

   if [[ "$clean_tmp_dir" == "true" ]]; then
      rm /${TMP_DIR}/gen_* 2>/dev/null 1>&2
   fi

   uri=$(echo "$url_param" | sed -e 's/https...gw.geneanet.org.//g' | sed -e 's/hirtrey000_w/hirtrey/g' | sed -e "s/lang=../lang=${language}/g")

   if [[ ! -f "${fic_id}" ]]; then
      echo "0" > "${fic_id}"
   fi
   echo "$numFAMS" > "${fic_fam}"

   init_cnx
   log "uri:[$uri] ch_Parent:[$ch_Parent] ch_Epoux:[$ch_Epoux] ch_Frere:[$ch_Frere] ch_Enfant:[$ch_Enfant] ch_Frere:[$ch_Frere] numFAMS:[$numFAMS]"
   ged:init "$fic_gedcom"

   cherche_indi retID "ficGedcom=[$fic_gedcom]?Qui=[${QUI_PERE}]?uri=[${uri}]?getParent=[${ch_Parent}]?getEpoux=[${ch_Epoux}]?getFrere=[${ch_Frere}]?getEnfant=[${ch_Enfant}]?numFamille=[${numFAMS}]"
   recupFichierFamille "$TMP_DIR" "$fic_gedcom"
   echo "terminé"
}

main "$@"

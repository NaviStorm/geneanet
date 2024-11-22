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

# trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]})' ERR
#   local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]}

typeset _Src_name=${0##*/}
typeset _Src_dir="${0%/*}" # dirname($0)
for _Src_file in var file log date cache cherche_html cherche_enfant cherche_indi cherche_parent cherche_source cherche_note write_indi; do
    source "${_Src_dir}/${_Src_file}.sh"
done

for _Src_file in const; do
    source "${_Src_dir}/en/${_Src_file}.sh"
done

initialise_individu() {
   echo "0" > "${fic_id}"
}

init_cnx(){
	log:info "DEB fic_config:[$fic_config]"
   USER_GENEANET=$(grep user "${fic_config}" | sed -e 's/user.*=//g' -e 's/ //g' -e "s/'//g")
   COOKIES=$(grep COOKIES "${fic_config}" | sed -e 's/^.*COOKIES=//g' -e "s/'//g")
	log:info "FIN"
}


recupFichierFamille() {
   local rep="$1"
   local ficGCOM="$2"

   for fic in "$rep/ID_"*; do
      cat "$fic" >> "$ficGCOM"
   done

   for fic in "$rep/FAM_"*; do
      cat "$fic" >> "$ficGCOM"
   done
   ged:finalize
}


_Usage() {
   printf "Usage:
   ${_Src_name} [OPTIONS] <script_file>
"
   echo "usage: $(basename "$0")"
   echo "   -u URL        : Lien url ver la famille a récupérer"
   echo "   -i            : Initialisation du N° de l'individu"
   echo "   -s            : Initialisation du N° de la famille"
   echo "   -c            : Fichier configuration"
   echo "   -v            : mode verbose"
   echo "   -d            : mode debug"
   echo "   -x            : mode verbose (timestampt)"
   echo "   -o            : fichier out"

   echo ""
   echo "   [--u[=]URL]   : Lien url ver la famille a récupérer"
   echo "   [--no-parent] : Ne recherche pas les parents"
   echo "   [--no-epoux]  : Ne recherche pas les epouses"
   echo "   [--no-frere]  : Ne recherche pas les freres/soeurs"
   echo "   [--no-enfant] : Ne recherche pas les enfant"
}

prerequis() {
   # GNU Util
   lstBin="jq bc uuidgen tr cat sed grep rm wc dirname basename"
   for bin in $lstBin; do
      which "$bin" 2>/dev/null 1>&2
#      $bin --version 2>/dev/null 1>&2
      if [[ "$?" -ne 0 ]]; then
         echo -e "usage: $(basename "$0")\n   $bin est necessaire, vous devez l'installer"
         quitter 1
      fi
   done

   lstBin="uuidgen tr"
   for bin in $lstBin; do
      which "$bin" 2>/dev/null 1>&2
      if [[ "$?" -ne 0 ]]; then
         echo -e "usage: $(basename "$0")\n   $bin est necessaire, vous devez l'installer"
         quitter 1
      fi
   done
   return 0
}


auth_tmp_dir() {
   local _tmp="$1"
   local _fic="$_tmp/testFile"
   local retCode=0

   mkdir -p "$_tmp" 2>/dev/null 1>&2
   touch "$_fic"
   retCode="$?"
   [[ "$retCode" -ne 0 ]] && return 1

   rm "$_fic" 2>/dev/null 1>&2
   TMP_DIR="$_tmp"

   fic_id="${TMP_DIR}/KeyID"
   fic_id_exist="${fic_id}_exist"
   fic_id_link="${fic_id}_link"
   fic_id_parent="${fic_id}_parent"
   fic_fam="${TMP_DIR}/FamID"
   return 0
}


save() {
   local param="$1"
   local _fic _tmp_dir _fic_ged _url

   log:info "param:[$param]"
   _fic=$(getParam "fic" "$param")
   _tmp_dir=$(getParam "tmp" "$param")
   _fic_ged=$(getParam "ged" "$param")
   _url=$(getParam "url" "$param")
   log:info "_fic:[$_fic] _tmp_dir:[$_tmp_dir] _fic_ged:[$_fic_ged] _url:[$_url]"
   echo "fic=[$bckOpt]?tmp=[$TMP_DIR]?ged=[$fic_gedcom]?url=[$url_param]" > "${_fic}"
}

instance() {
   :
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
   local fic_gedcom="${_Src_dir}/geneanet.ged"
   local optchar

   prerequis
   optspec=":u:ic:o:st:nvxhdv-:"
   while getopts "$optspec" optchar; do
      case "${optchar}" in
         -)
            case "${OPTARG}" in
               asc)
                  optNbAsc="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                  ;;
               asc=*)
                  optNbAsc=${OPTARG#*=}
                  ;;
               desc)
                  optNbDesc="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                  ;;
               desc=*)
                  optNbDesc=${OPTARG#*=}
                  ;;
               cache)
                  OPT_CACHE=1
                  ;;
               no-cache)
                  OPT_CACHE=0
                  ;;
               no-update-cache)
                  UPDATE_CACHE=0
                  ;;
               no-source)
                  OPT_SOURCE=0
                  ;;
               no-note)
                  OPT_NOTE=0
                  ;;
               no-date)
                  OPT_DATE=0
                  ;;
               cache=*)
                  DIR_CACHE=${OPTARG#*=}
                  FIC_CACHE="${DIR_CACHE}/cache"
                  mkdir -p "$DIR_CACHE" 2>/dev/null 1>&2
                  touch "$FIC_CACHE"
                  if [[ "$?" -ne 0 ]]; then
                     echo -e "usage: $(basename "$0")\n   Erreur lors de l'accès à $DIR_CACHE"
                     quitter 1
                  fi
                  ;;
               tmp)
                  TMP_DIR="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                  ;;
               tmp=*)
                  TMP_DIR=${OPTARG#*=}
                  opt=${OPTARG%=$val}
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
            _Usage >&2
            quitter 2
            ;;
         o)
            fic_gedcom="${OPTARG}"
            ;;
         d)
            log:debug:active 1
            ;;
         x)
            CHRONO=true
            ;;
         v)
            log:active 1
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
            # echo "Parsing option: '-${optchar}' $OPTARG" >&2
            ;;
         t)
            TMP_DIR="$OPTARG"
            ;;
         *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
               echo "Non-option argument: '-${OPTARG}'" >&2
               _Usage >&2
               quitter 0
            fi
            ;;
      esac
   done

   auth_tmp_dir "$TMP_DIR"
   if [[ "$?" -ne 0 ]]; then
      echo "usage: $(basename "$0")"
      echo "    Erreur d'accès sur [$OPTARG]"
      quitter 1
   fi

   if [[ "$url_param" == "" ]]; then
      echo "$(basename "$0") : -u URL Obligatoire"
      quitter 1
   fi
   if [[ "$init_individu" == "true" ]]; then
      initialise_individu
   fi


   uri=$(echo "$url_param" | sed -e 's/https...gw.geneanet.org.//g' | sed -e "s/lang=../lang=${language}/g")

   if [[ ! -f "${fic_id}" ]]; then
      echo "0" > "${fic_id}"
   fi
   echo -n "" > "$fic_id_exist"
   echo -n "" > "$fic_id_link"
   echo -n "" > "$fic_id_parent"
   echo "$numFAMS" > "${fic_fam}"
   echo -n "" > "$fic_gedcom"

   init_cnx
   log:info "uri:[$uri] ch_Parent:[$ch_Parent] ch_Epoux:[$ch_Epoux] ch_Frere:[$ch_Frere] ch_Enfant:[$ch_Enfant] ch_Frere:[$ch_Frere] numFAMS:[$numFAMS]"
   ged:init "$fic_gedcom"

   KeyID=$(individu:search "ficGedcom=[$fic_gedcom]&KeyIDApple=[0]&Qui=[${QUI_PARENT}]&uri=[${uri}]&getParent=[${ch_Parent}]&getEpoux=[${ch_Epoux}]&getFrere=[${ch_Frere}]&getEnfant=[${ch_Enfant}]&numFamille=[${numFAMS}]")
   retCode="$?"
   if [[ "$retCode" -eq 0 ]]; then
      ged:finalize "$TMP_DIR" "$fic_gedcom"
      echo "Traitement terminé"
   else
      echo "Traitement terminé en erreur"
   fi
}

main "$@"
#suf="pas01"
#url="https://gw.geneanet.org/lserranomiralle?lang=en&iz=0&p=vicente+el+menor+ou+vicent+nofre+bonaventura&n=lopez+carbonell"
#main -vdxi --tmp="$HOME/genealogie/geneanet_$suf.lopez" --cache="${HOME}/geneanet_cache" -c "/etc/secret/config" -o "$HOME/genealogie/geneanet_lopez_$suf.ged" -s -u "$url"

trace_cherche_html="true"

init_label() {
   local init_label_type_sex=$1
   local init_label_sex
   local init_label_labelNaissance
   local init_label_labelDeces
   local init_label_labelMarie
   local init_label_TypeEpoux

   log:info "init_label() PARAM init_label_type_sex:[$init_label_type_sex]"
   if [[ "$init_label_type_sex" == "0" ]]; then
      init_label_sex="M"
      init_label_labelNaissance="$LG_BORN_M"
      init_label_labelDeces="$LG_DEAD_M"
      init_label_labelMarie="$LG_MARIED_M"
      init_label_TypeEpoux="HUSB"
   elif [[ "$init_label_type_sex" == "1" ]]; then
      init_label_sex="F"
      init_label_labelNaissance="$LG_BORN_F"
      init_label_labelDeces="$LG_DEAD_F"
      init_label_labelMarie="$LG_MARIED_F"
      init_label_TypeEpoux="WIFE"
   elif [[ "$init_label_type_sex" == "2" ]]; then
      init_label_sex="U"
      init_label_labelNaissance="$LG_BORN_X"
      init_label_labelDeces="$LG_DEAD_X"
      init_label_labelMarie="$LG_MARIED_X"
      init_label_TypeEpoux="HUSB"
   fi

   log:info "init_label_type_sex:[$init_label_type_sex] init_label_sex:[$init_label_sex] init_label_labelNaissance:[$init_label_labelNaissance] init_label_labelDeces:[$init_label_labelDeces] init_label_labelMarie:[$init_label_labelMarie]"
   eval "$2=\"$init_label_sex\""
   eval "$3=\"$init_label_labelNaissance\""
   eval "$4=\"$init_label_labelDeces\""
   eval "$5=\"$init_label_labelMarie\""
   eval "$6=\"$init_label_TypeEpoux\""
   return
}


html:curl() {
   tab:inc
   local uri="$1"
   local fic_tmp_all="$2"
   local fic_error="${TMP_DIR}/curl_stderr_$$"
   local retCodeCurl=0 retCodeServer=0 nbCurl=0

   while true; do
      log:info "Appel curl($url/$uri&type=fiche)"
      curl -v -s "$url/$uri&type=fiche" \
         -H 'Referer: '"$url/$uri&type=tree" \
         -H $"Cookie: $COOKIES" \
         -H "User-Agent: $user_agent" -A "$user_agent" --user-agent "$user_agent" \
         --compressed 2>"$fic_error" |\
         sed -e "s/(.*<a href=\"#.*)//g"  |\
         sed -E "s/($LB_JOUR)//g" |\
         sed -e 's/<a  href=/<a href=/g' -e 's/\\u00e0/à/g' -e 's/\\u00e2/â/g' -e 's/\\u00e4/ä/g' -e 's/\\u00e7/ç/g' -e 's/\\u00e8/è/g' -e 's/\\u00e9/é/g' -e 's/\\u00ea/ê/g' -e 's/\\u00eb/ë/g' -e 's/\\u00ee/î/g' |\
         sed -e 's/\\u00ef/ï/g' -e 's/\\u00f4/ô/g' -e 's/\\u00f6/ö/g' -e 's/\\u00f9/ù/g' -e 's/\\u00fb/û/g' -e 's/\\u00fc/ü/g' |\
         sed '/^$/d' > "$fic_tmp_all"
      retCodeCurl="$?"

      retCodeServer=$(grep "HTTP/2 " "$fic_error" | sed -e "s/^.*HTTP\/2 //g" | tr -d $'\r' |bc)
      if [[ "$retCodeCurl" -ne 0 || "$retCodeServer" -gt 299 ]]; then
         nbCurl=$((nbCurl + 1))
         if [[ "$nbCurl" -eq 5 ]]; then
            log:info "J'ai fait 5 tentative nbCurl[$nbCurl], je sors en erreur"
            rm "$fic_error" 2>/dev/null 1>&2
            tab:dec
            return 1
         fi
         log:info "   Erreur curl, je tente encore apres une pause de 5 sec retCodeCurl:[$retCodeCurl] retCodeServer:[$retCodeServer]"
         sleep 60
      else
         if [[ "$OPT_CACHE" -eq 1 ]]; then
            log:info "Mise en cache de la page [$uri]"
            cache:put "$uri" "$fic_tmp_all" "false"
            if [[ "$?" -ne 0 ]]; then 
               log:info "Retour curl:put, erreur lors de la mise en cache de la page"
            fi
         fi
         tab:dec
         return 0
      fi
   done
   tab:dec
}


html:get() {
   html_get="true"
   local _uri=$1 uri=""
   local fic_tmp_all="$2"
   local nbRedirect=0 retCodeCurl=0 retCodeServer=0

   _uri="${1//lang=../lang=${language}}"
   
   log:info "DEB uri:[${_uri}] fic_tmp_all:[$fic_tmp_all]"
   touch "$fic_tmp_all"
   uri=$(echo "${_uri}" | sed -e 's/&type=tree//g' | sed -e 's/&type=fiche//g')

   if [[ "$OPT_CACHE" -eq 0 ]]; then
      html:curl "$uri" "$fic_tmp_all"
      if [[ "$?" -ne 0 ]]; then
         tab:dec
         return 1
      fi
   else
      cache:get "$uri" "$fic_tmp_all"
      if [[ "$?" -ne 0 ]]; then 
         log:info "Cette page [$uri] n'est pas en cache"
         html:curl "$uri" "$fic_tmp_all"
         if [[ "$?" -ne 0 ]]; then
            tab:dec
            return 1
         fi
      else
         log:debug "utilisation du cache pour [$uri]"
         return 0
      fi
   fi

   nbRedirect=$(grep "Redirecting to <a href=" "$fic_tmp_all" | wc -l | bc)
   if [[ "$nbRedirect" -eq 1 ]]; then
      rm "$fic_tmp_all" 2>/dev/null 1>&2
      log:info "ERREUR de redirection [$url/$uri&type=tree]"
      tab:dec
      return 1
   fi
   log:info "FIN"
   tab:dec
   return 0
}

htpm:getParent() {
	local fic_tmp_all=$1
   local fic_tmp_parent=$2
   local fic_tmp_parent_pere="${fic_tmp_parent}_pere"
   local fic_tmp_parent_mere="${fic_tmp_parent}_mere"
   local nb_parent=0 nom_pere="" lien_pere="" nom_mere="" lien_mere=""

   sed -e "1,/^<!-- Parents /d" -e "/^<!--  Union /,10000d" -e '/<li style=/d' "$fic_tmp_all" >$fic_tmp_parent
   grep "href=\"" "$fic_tmp_parent" | head -1 >"$fic_tmp_parent_pere"
   grep "href=\"" "$fic_tmp_parent" | tail -1 >"$fic_tmp_parent_mere"
   nb_parent=$(grep "href" "$fic_tmp_parent" | wc -l | bc)

   log:info "Nb Parent : [$nb_parent]"
   if [[ "$nb_parent" -ne 0 ]]; then
      local  nom_pere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_pere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=" | grep "^.*href" | head -1 | sed -e 's/<bdo.*$//g' | sed -e 's/^.*fiche">//' | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//' )
      local lien_pere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_pere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=" | grep "^.*href" | head -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
      local  nom_mere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_mere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=" | grep "^.*href" | tail -1 | sed -e 's/<bdo.*$//g' | sed -e 's/^.*fiche">//' | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//' )
      local lien_mere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_mere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=" | grep "^.*href" | tail -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
      log:info "nom_pere:[$nom_pere] lien_pere:[$lien_pere] nom_mere:[$nom_mere] lien_mere:[$lien_mere]"

      # Recherche le Père
      if [[ "$nom_pere" == *"? ?"* || "$nom_pere" == "" || "$nom_pere" == *"null null"* ]]; then
         log:info "($IdFct): Pas de père [$nom_pere] [$lien_pere] $nom $prenom" "$getParent" "0" "$getFrere"
         nb_parent=$((nb_parent-1))
         KeyID_Pere=0
      else
         log:info "($IdFct) Cherche le pere avec nouveau N° FAMS:[$FAMS_SUIVANTE]"
         local findID
         individu:search retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_PARENT}]?uri=[${lien_pere}]?getParent=[0]?getEpoux=[0]?getFrere=[0]?getEnfant=[0]?numFamille=[0]"
         local retCode="$?"
         if [[ "$retCode" -gt 299 ]]; then
            clean_fichier_temporaire "$KeyID"
            [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
            [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
            return "$retCode"
         fi
         [[ "$retCode" -eq "$INDI_DEJA_TRAITE" ]] && KeyID_Pere=$(KeyID:get "$retID") || KeyID_Pere=$retID
         log:info "($IdFct) I@$KeyID_Pere@ est le père de I@$KeyID@ Pour la famille FAMS:[$FAMS_SUIVANTE]"
      fi

   else
      log:info "($IdFct): Pas de Parent"
   fi
}

get_page_html_epoux() {
   local fic_tmp_all=$1
   local fic_tmp_enfant=$2

   log:info "deb get_page_html_enfant(): fic_tmp_all:[$fic_tmp_all] fic_tmp_parent:[$fic_tmp_parent]"
   IFS=''
   sed -e '1,/<!--  Union/d' -e '/^<!--  Frere/,10000d' "$fic_tmp_all" |
      sed '/^$/d' |
      sed -e "s/&nbsp;/ /g" -e "s/^ *//g" -e 's/^<img style=.* alt="H">//g' >$fic_tmp_enfant
   log:info "fin get_page_html_enfant()"
}

#!/usr/local/bin/bash

trace_get_page_html="false"

init_label() {
   local init_label_type_sex=$1
   local init_label_sex
   local init_label_labelNaissance
   local init_label_labelDeces
   local init_label_labelMarie
   local init_label_TypeEpoux

   log "init_label() PARAM init_label_type_sex:[$init_label_type_sex]"
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

   log "init_label_type_sex:[$init_label_type_sex] init_label_sex:[$init_label_sex] init_label_labelNaissance:[$init_label_labelNaissance] init_label_labelDeces:[$init_label_labelDeces] init_label_labelMarie:[$init_label_labelMarie]"
   eval "$2=\"$init_label_sex\""
   eval "$3=\"$init_label_labelNaissance\""
   eval "$4=\"$init_label_labelDeces\""
   eval "$5=\"$init_label_labelMarie\""
   eval "$6=\"$init_label_TypeEpoux\""
   return
}

cache:uri_to_link() {
   local _uri="$1"

   echo "${_uri}" | sed -e 's/&/_/g' -e 's/=/_/g' -e 's/\?/_/g' -e 's/\+/_/g' -e 's/\].*$//g'
}


cache:get(){
   local _uri="$1"
   local _fic="$2"
   local _link="" NbFicCache=0
   local _ficCache=""

   _link=$(cache:uri_to_link "$_uri")
   NbFicCache=$(grep "${_link}" "${fic_cache}" | wc -l | bc)
   [[ "$NbFicCache" -ne 1 ]] && return 1
   _ficCache=$(grep "\[${_link}\]" "${fic_cache}" | sed -e 's/^.*f:\[//g' -e 's/\].*$//g' -e "s/\$HOME/$(echo $HOME|sed -e 's/\//\\\//g')/g")
   cp "$_ficCache" "$_fic"
   if [[ "$?" -ne 0 ]]; then
      return 1
   fi
   return 0
}


cache:filename(){
   local _uri="$1"
   local _fic="$2"
   local _link="" NbFicCache=0
   local _ficCache=""

   _link=$(cache:uri_to_link "$_uri")
   NbFicCache=$(grep "\[${_link}\]" "${fic_cache}" | wc -l | bc)
   [[ "$NbFicCache" -ne 1 ]] && return 1
   _ficCache=$(grep "${_link}" "${fic_cache}" | sed -e 's/^.*f:\[//g' -e 's/\].*$//g' -e "s/\$HOME/$(echo $HOME|sed -e 's/\//\\\//g')/g")
   echo "$_ficCache"
   return 0
}


cache:exist() {
   local _uri="$1"
   local _fic=""
   local _link="" NbFicCache=0
   local _ficCache=""

   _link=$(cache:uri_to_link "$_uri")
   NbFicCache=$(grep "\[${_link}\]" "${fic_cache}" | wc -l | bc)

   if [[ "$NbFicCache" -eq 1 ]]; then
      _ficCache=$(grep "\[${_link}\]" "${fic_cache}" | sed -e 's/^.*f:\[//g' -e 's/\].*$//g' -e "s/\$HOME/$(echo $HOME|sed -e 's/\//\\\//g')/g")
      sha256sum "$_ficCache" | sed -e 's/ .*$//g'
      return 1
   else
      echo ""
      return 0
   fi
}


cache:put(){
   tab:inc
   local _uri="$1"
   local _fic="$2"
   local force="$3"
   local _link=""
   local _ficCache=$(uuidgen)

   local sha256_cache="" sha256_fic="" 
   
   nameFic="${dir_cache}/$(uuidgen | tr '[:upper:]' '[:lower:]')"
   sha256_cache=$(cache:exist "${_uri}")
   [[ "$?" -eq 1 && "$force" == "false" ]] && return 0

   if [[ -n "$sha256_cache" ]]; then
      sha256_fic=$(sha256sum "$_fic" | sed -e 's/ .*$//g')
      [[ "$sha256_cache" == "$sha256_fic" ]] && return 0
      log "sha256_cache:[$sha256_cache] sha256_fic:[$sha256_fic]"
#      cp "${_fic}" "$nameFic" 2>/dev/null 1>&2
      cp "${_fic}" "${dir_cache}/${_ficCache}" 2>/dev/null 1>&2
      [[ "$?" -ne 0 ]] && return 1
   else
      cp "${_fic}" "${nameFic}" 2>/dev/null 1>&2
      if [[ "$?" -eq 0 ]]; then
         _link=$(cache:uri_to_link "$_uri")
         echo "l:[$_link] f:[$nameFic]" >> "${fic_cache}"
      else
         return 1
      fi
   fi
   tab:dec
   return 0
}

html:get() {
   tab:inc
   local uri="$1"
   local fic_tmp_all="$2"
   local fic_error="${TMP_DIR}/curl_stderr_$$"
   local retCodeCurl=0 retCodeServer=0 nbCurl=0

   while true; do
      log "Appel curl($url/$uri&type=fiche)"
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
            log "J'ai fait 5 tentative nbCurl[$nbCurl], je sors en erreur"
            rm "$fic_error" 2>/dev/null 1>&2
            tab:dec
            return 1
         fi
         log "   Erreur curl, je tente encore apres une pause de 5 sec retCodeCurl:[$retCodeCurl] retCodeServer:[$retCodeServer]"
         sleep 5
      else
         log "Mise en cache de la page"
         cache:put "$uri" "$fic_tmp_all" "false"
         if [[ "$?" -ne 0 ]]; then 
            log "Retour curl:put, erreur lors de la mise en cache de la page"
         fi
         tab:dec
         return 0
      fi
   done
   tab:dec
}


get_page_html() {
   trace_get_page_html="true"
   local uri=$1
   local fic_tmp_all="$2"
   local fic_tmp="$3"
   local fic_tmp_parent="$4"
   local nbRedirect=0 retCodeCurl=0 retCodeServer=0

   uri="${1//lang=../lang=${language}}"
   
   log "DEB uri:[$uri] fic_tmp_all:[$fic_tmp_all] fic_tmp:[$fic_tmp] fic_tmp_parent:[$fic_tmp_parent]"
   touch "$fic_tmp_all" "$fic_tmp" "$fic_tmp_parent"
   uri=$(echo $uri | sed -e 's/&type=tree//g' | sed -e 's/&type=fiche//g')

   local optCache=1
   cache:exist "$uri" 2>/dev/null 1>&2
   enCache="$?"
   if [[ "$optCache" -eq 0 || "$enCache" -eq 0 ]]; then
      log "optCache:[$optCache] enCache:[$enCache]"
      html:get "$uri" "$fic_tmp_all"
      if [[ "$?" -ne 0 ]]; then
         tab:dec
         return 1
      fi
   else
      log "En Cache : [$uri]"
      cache:get "$uri" "$fic_tmp_all"
      if [[ "$?" -ne 0 ]]; then 
         log "Retour curl:get, cette page n'est pas en cache"
         html:get "$uri" "$fic_tmp_all"
         if [[ "$?" -ne 0 ]]; then
            tab:dec
            return 1
         fi
      fi
   fi

   nbRedirect=$(grep "Redirecting to <a href=" "$fic_tmp_all" | wc -l | bc)
   if [[ "$nbRedirect" -eq 1 ]]; then
      rm "$fic_tmp_all" "$fic_tmp" "$fic_tmp_parent" 2>/dev/null 1>&2
      log "ERREUR de redirection [$url/$uri&type=tree]"
      tab:dec
      return 1
   else
      grep -Ei "lastname|firstname" "$fic_tmp_all" | tail -1 > "$fic_tmp"
      sed '/^$/d' "$fic_tmp_all" | sed -e "s/&nbsp;/ /g" | sed -e "1,/^<!--  ${portrait} -->/d" | sed -e "/Aperçu de l'arbre/,+10000d" -e "s/&nbsp;/ /g" >> "$fic_tmp"
      log "FIN get_page_html"
   fi
   log "FIN"
   tab:dec
   return 0
}

get_page_html_parent() {
	local fic_tmp_all=$1
   local fic_tmp_parent=$2

   log "deb get_page_html_parent(): fic_tmp_all:[$fic_tmp_all] fic_tmp_parent:[$fic_tmp_parent]"
   sed -e "1,/^<!-- Parents /d" -e "/^<!--  Union /,10000d" "$fic_tmp_all" > "$fic_tmp_parent"
   log "fin get_page_html_parent()"
}

get_page_html_epoux() {
   local fic_tmp_all=$1
   local fic_tmp_enfant=$2

   log "deb get_page_html_enfant(): fic_tmp_all:[$fic_tmp_all] fic_tmp_parent:[$fic_tmp_parent]"
   IFS=''
   sed -e '1,/<!--  Union/d' -e '/^<!--  Frere/,10000d' "$fic_tmp_all" |
      sed '/^$/d' |
      sed -e "s/&nbsp;/ /g" -e "s/^ *//g" -e 's/^<img style=.* alt="H">//g' >$fic_tmp_enfant
   log "fin get_page_html_enfant()"
}

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

   log "init_label() init_label_sex:[$init_label_sex] init_label_labelNaissance:[$init_label_labelNaissance] init_label_labelDeces:[$init_label_labelDeces] init_label_labelMarie:[$init_label_labelMarie]"
   eval "$2=\"$init_label_sex\""
   eval "$3=\"$init_label_labelNaissance\""
   eval "$4=\"$init_label_labelDeces\""
   eval "$5=\"$init_label_labelMarie\""
   eval "$6=\"$init_label_TypeEpoux\""
}

get_page_html() {
   trace_get_page_html="true"
   local uri=$1
   local fic_tmp_all="$2"
   local fic_tmp="$3"
   local fic_tmp_parent="$4"
   local fic_error="/tmp/cherror$$"
   local nbRedirect

   uri="${1//lang=../lang=${language}}"
   
   log "deb get_page_html(): uri:[$uri] fic_tmp_all:[$fic_tmp_all] fic_tmp:[$fic_tmp] fic_tmp_parent:[$fic_tmp_parent]"
   touch "$fic_tmp_all" "$fic_tmp" "$fic_tmp_parent"
   uri=$(echo $uri | sed -e 's/&type=tree//g' | sed -e 's/&type=fiche//g')

   log "get_page_html() curl($url/$uri&type=fiche):"
   curl -v -s "$url/$uri&type=fiche" \
      -H 'Referer: '"$url/$uri&type=tree" \
      -H $"Cookie: $COOKIES" \
      --compressed 2>"$fic_error" |\
      sed -e "s/(.*<a href=\"#.*)//g"  |\
      sed -E "s/($LB_JOUR)//g" |\
      sed -e 's/<a  href=/<a href=/g' -e 's/\\u00e0/à/g' -e 's/\\u00e2/â/g' -e 's/\\u00e4/ä/g' -e 's/\\u00e7/ç/g' -e 's/\\u00e8/è/g' -e 's/\\u00e9/é/g' -e 's/\\u00ea/ê/g' -e 's/\\u00eb/ë/g' -e 's/\\u00ee/î/g' |\
      sed -e 's/\\u00ef/ï/g' -e 's/\\u00f4/ô/g' -e 's/\\u00f6/ö/g' -e 's/\\u00f9/ù/g' -e 's/\\u00fb/û/g' -e 's/\\u00fc/ü/g' -e 's/<em>//g' -e 's/<\/em>//g'|\
      sed '/^$/d' > "$fic_tmp_all"

   local retCode=$(grep "HTTP/2" $fic_error | sed -e "s/^.*HTTP\/2 //g" | wc -l | bc)
   if [[ "$retCode" -gt 299 ]]; then
      log "Erreur retour curl [$retCode] sur le lien [$url/$uri&type=fiche]"
      return "$retCode"
   fi
   # 
   nbRedirect=$(grep "Redirecting to <a href=" "$fic_tmp_all" | wc -l | bc)
	log "get_page_html(): nbRedirect[$nbRedirect]"
   if [[ "$nbRedirect" -eq 1 ]]; then
      rm "$fic_tmp_all" "$fic_tmp" "$fic_tmp_parent" 2>/dev/null 1>&2
      echo "ERREUR de redirection [$url/$uri&type=tree]"
      return 1
   else
      grep -Ei "lastname|firstname" "$fic_tmp_all" | tail -1 > "$fic_tmp"
      sed '/^$/d' "$fic_tmp_all" | sed -e "s/&nbsp;/ /g" | sed -e "1,/^<!--  ${portrait} -->/d" | sed -e "/Aperçu de l'arbre/,+10000d" >> "$fic_tmp"
      cat "$fic_tmp" | sed -e "s/&nbsp;/ /g"  > /tmp/toto
      log "FIN get_page_html"
   fi
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
      sed -e "s/&nbsp;/ /g" -e "s/^ *//g" -e 's/^[ \t]*//g' -e 's/^<img style=.* alt="H">//g' >$fic_tmp_enfant
   log "fin get_page_html_enfant()"
}

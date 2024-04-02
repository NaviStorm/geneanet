individu:mere() {
   parent:mere "$1"
   return "$?"
}


individu:pere() {
   parent:pere "$1"
   return "$?"
}


individu:farent:famille() {
   parent:search "$1"
   return "$?"
}


individu:parent:init() {
   parent:init "$1"
   return "$?"
}


individu:famille() {
   local _KeyID="$1"
   local _famille=""
   _famille=$(grep "p\[$_KeyID\]\|m\[$_KeyID\]" $fic_id_parent | grep "f\[" | sed -e 's/^.*f\[//g' -e 's/\].*$//g')
   if [[ -z "$_famille" ]]; then
      echo ""
      return $NOT_FOUND
   else
      echo "$_famille"
      return $FOUND
   fi
}

individu:init() {
   local KeyID="$1"   
   local fic_id_parent="${fic_id}_parent"
}

individu:get:html( ) {
   local URI=$(getParam "uri" "$1")
   local KeyID=$(KeyID:inc)
   local pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
   local fic_tmp_all=$(file:get $KeyID all_page)
   local IdFct="KeyID:($KeyID)"

   local retCode
   
   log:info "($IdFct) DEB KeyID:[$KeyID] param:[$1]"
   if [[ -z "$URI" ]]; then
      log:error " URI:[$URI] ne peux être vide Param:[$@]"
      return "$ERROR"
   fi

   html:get "$URI" "$fic_tmp_all"
   local retCode="$?"
   if [[ "$retCode" -ne 0 ]]; then
      log:info "($IdFct) Erreur retour html:get:[$retCode]"
      rm "$fic_tmp_all"
      KeyID:dec
      return "$ERROR"
   fi

   local _zone=$(sed '1,/^<\/head>/d' "$fic_tmp_all" | grep -n "extend(true, keys.elements," | sed -e 's/^.*$.extend(true, keys.elements, //g' -e 's/);$//g')
   local id_index=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.index')
   local nom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.lastname' 2>/dev/null)
   local prenom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.firstname' 2>/dev/null)
   local id_p=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.p')
   local id_n=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.n')
   local id_oc=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.oc')
   local sex=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.sex')

   # Je regarde si l'individu est déjà traité
   Index:Search "KeyID=[$KeyID]&index=[$id_index]&nom=[$nom]&prenom=[$prenom]&sex=[$sex]&p=[$id_p]&n=[$id_n]&oc=[$id_oc]"
   local retCode="$?"
   if [[ "$retCode" -eq $INDI_DEJA_TRAITE ]]; then
      rm "$fic_tmp_all"
      KeyID:dec
      findID=$(KeyID:get "$KeyID")
      log:info "($IdFct) Retourne KeyID(findID):[$findID]"
#      echo "$findID"
      echo "KeyID=[$findID]&nom=[$nom]&prenom=[$prenom]&sex=[$sex]"
   else
      log:info "($IdFct) Retourne KeyID:[$KeyID]"
#      echo "KeyID=$KeyID"
      echo "KeyID=[$KeyID]&nom=[$nom]&prenom=[$prenom]&sex=[$sex]"
   fi
   parent:search "enfant=[$KeyID]"
   individu:get:enfant:html "$KeyID"
   return $retCode
}


individu:get:enfant:html( ) {
   local KeyID="$1"
   local pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
   local fic_tmp_all=$(file:get $KeyID all_page)
   local fic_tmp_enfant_tmp=$(file:get $KeyID enfant)

   sed   -e '1,/<!--  Union/d' -e '/^<!--  Freres/,10000d' \
         -e "s/<span[^>]*>//g" \
         -e "s/<img[^>]*>//g" \
         -e "s/<a.*ref.*&i1=[^>]*>//g" \
         -e "s/<li.*style.*square[^>]*>//g" \
         -e '/^$/d' \
         -e '/^ to/,+1d' \
         -e "/=MOD_FAM/d" \
         -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_all" |\
   grep "<a href=\"" | grep -v "&m=\|&t=|&i1=\|&i2=" | grep "&p=\|&n=" | sed -e 's/^.*href=\"//g' -e 's/".*$//g' > "$fic_tmp_enfant_tmp"

   local html_ligne="" lien_enfant="" findID=""

   IFS=''
   readarray lien < $fic_tmp_enfant_tmp
   for lien_enfant in "${lien[@]}"; do
      findID=$(Index:Search:URI "URI=[$lien_enfant]")
      if [[ -z "$findID" ]]; then
         log:info "Je recherche lien dans section ($lien_enfant) findID($findID)"
         individu:get:html "uri=[${lien_enfant}]" >&2
      else
         log:info "Individu dans le base, ne recherche pas ($lien_enfant) findID($findID)"
      fi
   done
   unset lien
#   rm "$fic_tmp_enfant_tmp" 2>/dev/null 1>&2
}

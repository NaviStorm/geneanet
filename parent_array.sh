parent:search() {
   local _enfant=$(getParam "enfant" "$1")
   local _pere=$(getParam "pere" "$1")
   local _mere=$(getParam "mere" "$1")
   local _fams=""

   if [[ -n "$_enfant" ]]; then
      _pere=$(parent:pere "$_enfant")
      _mere=$(parent:mere "$_enfant")
   fi
   if [[ -n "$_pere" && -n "$_mere" ]]; then
      log:info "tb recherche $_pere $_mere"
      _fams=$(echo "${tbFamille[@]/p[$_pere] p[$_mere]//} "| cut -d/ -f1 | wc -w | tr -d ' ')
      if [[ "$_fams" -ne 0 ]]; then
         echo "$_fams"
         return $FOUND
      else
         echo ""
         return $NOT_FOUND
      fi
   else
      echo ""
      return $NOT_FOUND
   fi
}

parent:put() {
   local _KeyID=$(getParam "enfant" "$1")
   local _pere=$(getParam "pere" "$1")
   local _mere=$(getParam "mere" "$1")
   local _famille=0

   local idFct="id:$_KeyID"

   log:info "($idFct) DEB param:[$1] tbFamille[$_KeyID]:[${tbFamille[$_KeyID]}]"
   [[ -n "${tbFamille[$_KeyID]}" ]] && return $ERROR

   _famille=$(parent:search "$_pere" "$_mere")
   if [[ -z "$_famille" ]]; then
      (( maxFam++ ))
      _famille=$maxFam
      log:info "($idFct) Famille non trouvé N°famille:[$_famille]"
   fi

   log:info "($idFct) [$_KeyID] ecriture de [f[$_famille] p[$_pere] m[$_mere]]"
   tbFamille[$_KeyID]="f[$_famille] p[$_pere] m[$_mere]"
}


parent:get() {
   local _KeyID="$1"
   local idFct="id:$_KeyID"

   log:info "($idFct) DEB _KeyID:[$_KeyID]"
   local fic_tmp_all="" fic_tmp_parent=""
   local nb_parent=0
   local lien_pere="" lien_mere="" retCode=0 
   local _famille=0 KeyID_Pere=0 KeyID_Mere=0

   pre="${TMP_DIR}/gen_$(printf "%04d" "$_KeyID")"
   local fic_tmp_all="${pre}_all_page"
   local fic_tmp_parent="${pre}_parent"

   sed -e "1,/^<!-- Parents /d" -e "/^<!--  Union /,10000d" -e '/<li style=/d' "$fic_tmp_all" >$fic_tmp_parent
   local nb_parent=$(grep "href" "$fic_tmp_parent" | wc -l | bc)
   nb_parent=$((nb_parent+0))
   if [[ "$nb_parent" -ne 0 ]]; then
      grep "href=\"" "$fic_tmp_parent" | head -1 >"$fic_tmp_parent_pere"
      grep "href=\"" "$fic_tmp_parent" | tail -1 >"$fic_tmp_parent_mere"
      # Je recherche que l'ID des parent pour inscrire le N°FAM de mes parents

      # Recherche le Père
      local lien_pere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_pere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=\|&i=\|&oc=" | grep "^.*href" | head -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
      log:info "$idFct Cherche le pere [$lien_pere]"
      individu:search retID "ficGedcom=[$ficGedcom]&KeyIDApple=[$KeyID]&Qui=[${QUI_PARENT}]&uri=[${lien_pere}]&getParent=[0]&getEpoux=[0]&getFrere=[0]&getEnfant=[0]&numFamille=[-1]"
      retCode="$?"
      log:info "($idFct) Retour individu:search(Pere) retCode:[$retCode] retID:[$retID]"
      if [[ "$retCode" == "$INDI_DEJA_TRAITE" ]]; then
         KeyID_Pere=$(KeyID:get "$retID")
         log:info "($idFct) Deja traite pere, je recupere son Id Rel KeyID_Pere:[$KeyID_Pere]"
      else
         KeyID_Pere="$retID"
      fi

      # Recherche la Mère
      local lien_mere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_mere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=\|&i=\|&oc=" | grep "^.*href" | tail -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
      log:info "($idFct) Cherche la mere [$lien_mere]"
      individu:search retID "ficGedcom=[$ficGedcom]&KeyIDApple=[$KeyID]&Qui=[${QUI_PARENT}]&uri=[${lien_mere}]&getParent=[0]&getEpoux=[0]&getFrere=[0]&getEnfant=[0]&numFamille=[-1]"
      retCode="$?"
      log:info "($idFct) Retour individu:search(Mere) retCode:[$retCode] retID:[$retID]"
      if [[ "$retCode" == "$INDI_DEJA_TRAITE" ]]; then
         KeyID_Mere=$(KeyID:get "$retID")
         log:info "($idFct) Deja traite mere, je recupere son Id Rel KeyID_Mere:[$KeyID_Mere]"
      else
         KeyID_Mere="$retID"
      fi
      log:info "($idFct) Retour individu:search(Mere) retID:[$KeyID_Mere]"


      [[ -n ${tbFamille[$_KeyID]} ]] && return $FOUND

      parent:put "enfant=[$_KeyID]&pere=[$KeyID_Pere]&mere=[$KeyID_Mere]"
#      _famille=$(parent:search "pere=[$KeyID_Pere]&mere=[$KeyID_Mere]")
#      pCode="$?"
#      if [[ "$pCode" -eq $FOUND ]]; then
#         log:info "($idFct) La famille de [$_KeyID] p:[$KeyID_Pere]et de m:[$KeyID_Mere] a été trouvé"
#         parent:put "enfant=[$_KeyID]&pere=[$KeyID_Pere]&mere=[$KeyID_Mere]"
#      else
#         log:info "($idFct)  Famille non trouve KeyID:[$_KeyID] $KeyID_Mere trouvé ecriture de '$_KeyID p[$KeyID_Pere] m[$KeyID_Mere]' dans $fic_id_parent"
#         parent:put "enfant=[$_KeyID]&pere=[$KeyID_Pere]&mere=[$KeyID_Mere]"
#      fi
      return $FOUND
   else
      log:info "($idFct) Pas d Parent"
      return 1
   fi
}


parent:pere() {
   local _KeyID="$1"

   log:info "_KeyID:[$_KeyID]"
   local _nb=$(grep "^$_KeyID " "$fic_id_parent" | wc -l | bc )
   if [[ "$_nb" -eq 1 ]]; then
      local _pere=$(grep "^$_KeyID " "$fic_id_parent" | sed -e 's/^.*p\[//g' | sed -e 's/\].*$//g')
      log:info "$_KeyID Pere:[$_pere]"
      echo "$_pere"
      return $FOUND
   else
      log:info "Pere de [$_KeyID] non trouve, je lance la recherche"
      parent:get "$_KeyID"
      if [[ "$?" -eq 1 ]]; then
         echo ""
         return 1
      else
if [[ -z ${tbFamille[$_KeyID]} ]]; then
   log:info "tb[$_KeyID] Pas de pere pour l'instant"
else
   local pere=$(echo ${tbFamille[$_KeyID]}  | sed -e 's/^.*p\[//g' | sed -e 's/\].*$//g')
   log:info "tb[$_KeyID] Le pere est $pere"
fi
         local _pere=$(grep "^$_KeyID " "$fic_id_parent" | sed -e 's/^.*p\[//g' | sed -e 's/\].*$//g')
         log:info "$_KeyID Pere:[$_pere]"
         return $FOUND
      fi
   fi
}


parent:mere() {
   local _KeyID="$1"

   log:info "_KeyID:[$_KeyID]"
   local _nb=$(grep "^$_KeyID " "$fic_id_parent" | wc -l | bc )
   if [[ "$_nb" -eq 1 ]]; then
      local _mere=$(grep "^$_KeyID " "$fic_id_parent" | sed -e 's/^.*p\[//g' | sed -e 's/\].*$//g')
      log:info "$_KeyID Mere:[$_mere]"
      echo "$_mere"
      return $FOUND
   else
      log:info "Mere de [$_KeyID] non trouve, je lance la recherc"
      parent:get "$_KeyID"
      if [[ "$?" -eq 1 ]]; then
         echo ""
         return $NOT_FOUND
      else
if [[ -z ${tbFamille[$_KeyID]} ]]; then
   log:info "tb[$_KeyID] Pas de mere pour l'instant"
else
   local mere=$(echo ${tbFamille[$_KeyID]}  | sed -e 's/^.*m\[//g' | sed -e 's/\].*$//g')
   log:info "tb[$_KeyID] La mere est $mere"
fi
         local _mere=$(grep "^$_KeyID " "$fic_id_parent" | sed -e 's/^.*p\[//g' | sed -e 's/\].*$//g')
         log:info "$_KeyID Pere:[$_mere]"
         return $FOUND
      fi
   fi
}


parent:init() {
   local _KeyID="$1"
   log:info "_KeyID:[$_KeyID]"
   parent:pere "$_KeyID"
   parent:mere "$_KeyID"
}


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

tab:key:put() {
   local _id="$1"
   local _key="$2"
   local _value="$2"
   local _oldvalue=""

    [[ -z ${tbFamille[$_KeyID]} ]] && return ERROR
    _oldvalue=$(echo "${tbFamille[$_KeyID]}" | grep "$_key\[")
    if [[ -n "$_oldvalue" ]]; then
      # Si contient une valeur, je ne remplace pas la valeur exact trouvé car il peut y avoir desaractère spéciaux
      tbFamille[$_KeyID]=$(echo "$_oldvalue" | sed -e "s/$_key\[[^\]]*\]/$_key[$_value]/g")
    else
      {tbFamille[$_KeyID]="$_oldvalue $_key[$_value]"
    fi

}


tab:key:get() {
   local _id="$1"
   local _key="$2"

   [[ -z ${tbFamille[$_KeyID]} ]] && return ERROR
   local _value=$(echo ${tbFamille[$_id]} | grep "$_key" | sed -e "s/^.*$_key\[//g" | sed -e "s/\].*$//g")
   echo "_value"
}


individu:naissance:nom:put(){
   pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
   local fic_tmp_all="${pre}_all_page"

   _zone=$(sed '1,/^<\/head>/d' "$fic_tmp_all" | grep -n "extend(true, keys.elements," | sed -e 's/^.*$.extend(true, keys.elements, //g' -e 's/);$//g')
   id_index=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.index')
   nom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.lastname' 2>/dev/null)
   prenom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.firstname' 2>/dev/null)
   id_p=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.p')
   id_n=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.p')
   id_oc=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.oc')
   sex=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.sex')
   tab:key:put "$_KeyID" "&nom" "$nom"
   tab:key:put "$_KeyID" "&prenom" "$prenom"
   tab:key:put "$_KeyID" "&sex" "$sex"
}

individu:init() {
   parent:init "$1"
   individu:naissance:nom:put
}
#fic_id_parent="/Users/tandreu/genealogie/geneanet_test/KeyID_parent" 
#parent:put "enfant=[$1]&pere:[$2]&mere:[$3]"
#echo
#tail -1 $fic_id_parent
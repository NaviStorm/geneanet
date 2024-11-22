trace_individu_search="true"

clean_fichier_temporaire() {
   local _KeyID="$1"
   local allFic=$(file:get $KeyID "*")
   log:info "Doit supprimer [$allFic]"
   rm -f $allFic 2>/dev/null 1>&2
}


echo_bloc() {
   fic=$1
   if [[ -f "$fic" ]]; then
      cat "$fic"
   else
      while IFS='' read -r data; do
         echo "$data"
      done
   fi

}

supprime_bloc_div() {
   log:info "supprime_bloc_div()"
   local fic="$1"
   local bloc=false
   while IFS='' read -r html_ligne; do
      if [[ "$html_ligne" == *"<div style="* || "$html_ligne" == *"<li style="* ]]; then
         continue
      fi
      if [[ "$html_ligne" == *"<li"* && "$html_ligne" == *"</li"* ]]; then
         continue
      fi
      if [[ "$html_ligne" == "<div"* ]]; then
         bloc=true
         continue
      fi
      if [[ "$html_ligne" == *"</div>"* ]]; then
         bloc=false
         continue
      fi
      if [[ "$html_ligne" != "" ]]; then
         echo "$html_ligne" | sed -e 's/<img .*alt=\"H\"> //g' | sed -e 's/<bdo.*\/em> //g' | sed 's/<\/a>[[:space:]]*/<\/a> /g'
      fi
   done <$fic
}

incFAM() {
   local fic_fam="$1"
   local nFAM=$(($(cat "$fic_fam") + 1))
   echo $nFAM
   echo $nFAM > "$fic_fam"
   return 0
}


KeyID:dec() {   
   local _KeyID=$(($(cat $fic_id) - 1))
   echo "$_KeyID"
   echo "$_KeyID" > "$fic_id"
}


KeyID:inc() {
   local _KeyID=$(($(cat $fic_id) + 1))
   echo "$_KeyID"
   echo "$_KeyID" > "$fic_id"
}


Index:SearchOLD() {
   local KeyID="$1"
   local dbKeyID=0
   local _index="" _index_uri=""
   local retCodeC=0

   log:debug "Param: [$@]"
   _index=$(echo "${2}" | sed -e 's/&type=tree//g' | sed -e "s/lang=../lang=$language/g" -e 's/&amp;/_/g' -e 's/&type=fiche//g' -e 's/&/_/g' -e 's/=/_/g' -e 's/\?/_/g' -e 's/\+/_/g' -e 's/\].*$//g')
   log:debug "_index:[$_index]"
   grep "\[$_index\]" "$fic_id_exist" 2>/dev/null 1>&2
   if [[ "$?" -eq 0 ]]; then
      dbKeyID="$KeyID"
      KeyID=$(grep "\[$_index\]" "$fic_id_exist" | sed -e 's/ .*$//g')
      log:debug "($dbKeyID) Dejà dans fichier ID_Trouve (déjà traite avec [$KeyID] [$_index])"
      echo "$KeyID @I$dbKeyID@" >> "$fic_id_link"
      # Ajoute au vrai ID(KeyID), le nouveau doublon en fin de ligne
      sed -i $optSed "/^$KeyID / s/$/ @$dbKeyID@/" "$fic_id_exist"
      return 1
   else
      if [[ -n "$3 " ]]; then
         _index_uri=$(echo "${2}" | sed -e 's/&type=tree//g' | sed -e "s/lang=../lang=$language/g" -e 's/&amp;/_/g' -e 's/&type=fiche//g' -e 's/&/_/g' -e 's/=/_/g' -e 's/\?/_/g' -e 's/\+/_/g' -e 's/\].*$//g')
      fi
      grep "\[$_index\]" "$fic_id_exist" 2>/dev/null 1>&2
      log:debug "($_index) N'est pas dans le fichier [$KeyID] [$_index])"
      echo "$KeyID [$_index]" >> "$fic_id_exist"
      return 0
   fi
}

Index:Search:URI() {
   local _i_UniqID=""
   local _i_uri="" _i_p="" _i_n="" _i_i="" _i_oc=""

   _i_uri=$(getParam "URI" "$1")
   if [[ -z "$_i_uri" ]]; then
      echo ""
      return 1
   else
      local _i_p=$(echo "$_i_uri" | grep "&p=" | sed -e 's/^.*&p=//g' -e "s/&.*$//g")
      local _i_n=$(echo "$_i_uri" | grep "&n=" | sed -e 's/^.*&n=//g' -e "s/&.*$//g")
      local _i_i=$(echo "$_i_uri" | grep "&i=" | sed -e 's/^.*&i=//g' -e "s/&.*$//g")
      local _i_oc=$(echo "$_i_uri" | grep "&oc=" | sed -e 's/^.*&oc=//g' -e "s/&.*$//g")
      # Pour oc=0, celui ci n'apparait pas dans l'URI mais on l'a stocké car dans page HTML OC=0
      [[ -z "$_i_oc" ]] && _i_oc="0"
      if [[ -n "$_i_i" ]]; then
         _i_UniqID=$(grep " \[$_i_i\]" "$fic_id_exist" | sed "s/ .*$//g")
      elif [[ -n "$_i_p" && -n "$_i_n" ]]; then
         _i_UniqID=$(grep "p:\[$_i_p\].*n:\[$_i_n\].*oc:\[$_i_oc\]" "$fic_id_exist" | sed "s/ .*$//g")
      fi
   fi
   nb=$(echo "$_i_UniqID" | wc -l)
   [[ "$nb" -gt 1 ]] && exit 0
   echo "$_i_UniqID"
}


Index:Search() {
   local param="$1"
   local _KeyID="" _index="" _lastname="" _firstname="" _sex="" _p="" _n=$"" _oc="" _uri=""
   local UniqID=0
   local retCode=0
   local retValue=""
   local _sP="" _sN="" _sI="" 

##   log:info "param:[$param]"
   _KeyID=$(getParam "KeyID" "$param")
   _index=$(getParam "index" "$param")
   _lastname=$(getParam "nom" "$param")
   _firstname=$(getParam "prenom" "$param")
   _sex=$(getParam "sex" "$param")
   _p=$(getParam "p" "$param" | sed -e 's/ /+/g')
   _n=$(getParam "n" "$param"| sed -e 's/ /+/g')
   _oc=$(getParam "oc" "$param"| sed -e 's/ /+/g')
   _uri=$(getParam "URI" "$param")

   if [[ -n "$_KeyID" && -n "$_index" ]]; then
      grep "index:\[$_index\]" "$fic_id_exist" 2>/dev/null 1>&2
      UniqID=$(grep "index:\[$_index\]" "$fic_id_exist" | sed -e 's/ .*$//g')
      if [[ -n "$UniqID" ]]; then
         echo "$UniqID @I$_KeyID@" >> "$fic_id_link"
         # Ajoute au vrai ID(KeyID), le nouveau doublon en fin de ligne
         sed -i $optSed "/^$UniqID / s/$/ @$_KeyID@/" "$fic_id_exist"
         return $INDI_DEJA_TRAITE
      else
         echo "$_KeyID index:[$_index] _lastname:[$_lastname] _firstname:[$_firstname] p:[$_p] n:[$_n]" oc:[$_oc] sex:[$_sex] >> "$fic_id_exist"
         return 0
      fi
   elif [[ -n "$_p" && -n "$_n" ]]; then
      retValue=$(grep "p:\[$_p\].*n:\[$_n\].*oc:\[$_oc\]" "$fic_id_exist" | sed "s/ .*$//g" | wc -l)
      nb=$(echo "$retValue" | wc -l)
      [[ "$nb" -gt 1 ]] && exit 0
      echo "$retValue"
   elif [[ -n "$_index" ]]; then
      retValue=$(grep " \[$_index\]" "$fic_id_exist" | sed "s/ .*$//g")
      nb=$(echo "$retValue" | wc -l)
      [[ "$nb" -gt 1 ]] && exit 0
      echo "$retValue"
   elif [[ -n "$_uri" ]]; then
      Index:Search:URI "$_uri"
   fi
}


KeyID:get() {
   local _KeyID="$1"

   grep "@I$_KeyID@" "$fic_id_link" | sed -e 's/ .*$//g'
}

ascendance:inc() {
   [[ "$nbAsc" -lt "$optNbAsc" ]] && nbAsc=$(( nbAsc + 1 ))
}


ascendance:dec() {
   [[ "$nbAsc" -lt "$optNbAsc" ]] && nbAsc=$(( nbAsc + 1 ))
}

descendanceesc:inc() {
   :
}

descendance:dec() {
   :
}


individu:isMaried() {
   local _nbEpoux=0

   _nbEpoux=$(sed -e "1,/<!--  Union/d"  -e "/^<!--  Freres/,10000d" "$1" | grep -c "^${LB_MARIE}\|^${LB_RELATION}\|^${LB_ENFANT_AVEC_HOMME}")
   log:info "_nbEpoux:[$_nbEpoux] fic:[$1]"
   return $((_nbEpoux + 0))
}



# fontion individu:search
# Paramètre :
#   $1 : KeyID pour retour de valeur à l'appelant
#   $2 : Qui, tyep de recherche (PERE, MERE, EPOUSE)
#   $3 : uri
#   $4 : Chercher les parents
#   $5 : Chercher les epoux
#   $6 : Chercher les freres
#   $7 : Chercher les enfants
#   $8 : numero FAMS
individu:search() {
   local param="$1"
   local KeyID_Appel Lien_Appel Qui URI getParent getEpoux getFrere getEnfant FAMS KeyID_Appel
   
   pauseRunSH
   Qui=$(getParam "Qui" "$param")
   URI=$(getParam "uri" "$param")
   getParent=$(getParam "getParent" "$param")
   getEpoux=$(getParam "getEpoux" "$param")
   getFrere=$(getParam "getFrere" "$param")
   getEnfant=$(getParam "getEnfant" "$param")
   FAMS=$(getParam "numFamille" "$param")
   KeyID_Appel=$(getParam "KeyID_Appel" "$param")
   Lien_Appel=$(getParam "KeyID_Appel" "$param")


   local -r KeyID=$(KeyID:inc)

   local FAMS_SUIVANTE=0

   nbAppel=$((nbAppel + 1))
   local IdFct="$nbAppel/$KeyID/$FAMS"
#   IdFct=""
   pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"

   local fic_tmp_all=$(file:get $KeyID all_page)
   local fic_tmp=$(file:get $KeyID result)
   local fic_tmp_parent=$(file:get $KeyID parent)
   local fic_tmp_parent_pere=$(file:get $KeyID parent_pere)
   local fic_tmp_parent_mere=$(file:get $KeyID parent_mere)
   local fic_epoux_date_mariage=$(file:get $KeyID parent_epoux)
   local fic_tmp_divorce=$(file:get $KeyID parent_divorce)
   local fic_tmp_epoux_tmp=$(file:get $KeyID epoux_tmp)
   local fic_tmp_frere=$(file:get $KeyID frere)
   local fic_tmp_enfant_tmp=$(file:get $KeyID enfants)

   local labelNaissance labelBaptise labelTypeEpoux labelDeces labelMarie nb_parent

   local _retIndividu # Pour retour a l'appel de la fonction individu:search
   local id_index="" id_p="" id_n="" id_oc=""
   local _zone="" nom="" prenom="" sex="" nbEpoux=0
   local GEDCOM_naissance="" tgNaissance="" villeNaissance="" julienNaissance=""
   local GEDCOM_deces=""     tgDeces=""     villeDeces=""     julienDeces=""
   local GEDCOM_mariage=""   tgMariage=""   villeMariage=""   julienMariage=""  
   local GEDCOM_divorce=""   tgDivorce=""   villeDivorce=""   julienDivorce=""
   local GEDCOM_bapteme=""   tgBapteme=""   villeBapteme=""   julienBapteme=""
   local occupation
   local bj="" bm="" by="" bj_Fin="" bm_Fin="" by_Fin=""
   local dj="" dm="" dy="" dj_Fin="" dm_Fin="" dy_Fin=""
   local mj="" mm="" my="" mj_Fin="" mm_Fin="" my_Fin=""
   local sj="" sm="" sy="" sj_Fin="" sm_Fin="" sy_Fin=""
   local findID FamilleExist KeyID_Pere KeyID_Mere KeyID_Epouse nbEnfantEpoux KeyID_Enfant retCode
   local ref_epoux=0 lien_epoux="" ligne_precedente_marie_avec=0 lineMarried=0 numMariage=0 firstFAMS=0 SansDate=0 epoux_trouve=0 epoux_trouve=0

   log:info "($IdFct) DEB KeyID:[$KeyID] param:[$1]"
   if [[ -z "$URI" ]]; then
      log:error " URI:[$URI] ne peux être vide Param:[$@]"
      return "$ERROR"
   fi
   log:info "($IdFct) URI:[$URI] Qui:[$Qui] KeyID:[$KeyID]"

   html:get "$URI" "$fic_tmp_all"
   retCode="$?"
   if [[ "$retCode" -ne 0 ]]; then
      log:info "($IdFct): Erreur retour html:get:[$retCode]"
      clean_fichier_temporaire "$KeyID"
      return "$ERROR"
   fi

   _zone=$(sed '1,/^<\/head>/d' "$fic_tmp_all" | grep -n "extend(true, keys.elements," | sed -e 's/^.*$.extend(true, keys.elements, //g' -e 's/);$//g')
   id_index=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.index')
   nom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.lastname' 2>/dev/null)
   prenom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.firstname' 2>/dev/null)
   id_p=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.p')
   id_n=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.p')
   id_oc=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.oc')
   sex=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.sex')

   # Je regarde si l'individu est déjà traité
   log:info "id_index:[$id_index] nom:[$nom] prenom:[$prenom]"
   Index:Search "KeyID=[$KeyID]&index=[$id_index]&nom=[$nom]&prenom=[$prenom]&sex=[$sex]&p=[$id_p]&n=[$id_n]&oc=[$id_oc]"
   local retCode="$?"
   if [[ "$retCode" -eq $INDI_DEJA_TRAITE ]]; then
      findID=$(KeyID:get "$KeyID")
      echo "KeyID=[$findID]"
      (
         log:info "($IdFct): KeyID temporaire:[$KeyID] KeyID Réél:($findID) Déjà traité [$URI]"
         if [[ "$Qui" == "$CONJOINT" ]]; then
            famille:search "pere=[$findID]&mere=[$KeyID_Appel]"
            [[ "$?" -eq $FAMILY_NO_EXIST ]] && famille:write "fams=[$FAMS]&KeyID_Appel=[$KeyID_Appel]&sex=[$sex]&KeyID=[$findID]"
         fi
         clean_fichier_temporaire "$KeyID"
         rm "$fic_tmp_all" "$fic_tmp" 2>/dev/null 1>&2
      ) >&2
      return "$INDI_DEJA_TRAITE"
   fi

   if [[ "$id_p$id_n" == "" ]]; then
      findID=$(KeyID:get "$KeyID")
      log:info "($IdFct) Personne Inconnu, mais je traite quand même car peut être le/la père/mère de plusieurs enfants: \$nom\$prenom:[$nom$prenom]"
      (
         ged:write "$KeyID" "KeyID=[$KeyID]&nom=[?]&prenom=[?]&sex=[U]"
         [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
         famille:write "fams=[$FAMS]&KeyID_Appel=[$KeyID_Appel]&sex=[$sex]&KeyID=[$KeyID]&Qui=[$Qui]"
         clean_fichier_temporaire "$KeyID"
      ) 1>&2
      log:info "($IdFct) FIN Personne Inconnu"
      echo "KeyID=[$findID]"
      return "$retCode"
   fi

#   individu:init "$KeyID"

   local retLabel=$(init_label "$sex")
   sex=$(getParam "sex" $retLabel)
   labelNaissance=$(getParam "naissance" $retLabel)
   labelDeces=$(getParam "deces" $retLabel)
   labelMarie=$(getParam "epoux" $retLabel)
   labelTypeEpoux=$(getParam "type" $retLabel)
   labelBaptise=$(getParam "baptise" $retLabel)
   log:debug "($IdFct) retLabel:[$retLabel]"
   log:debug "($IdFct) sex:[$sex] labelNaissance:[$labelNaissance] labelDeces:[$labelDeces] labelMarie:[$labelMarie] labelBaptise:[$labelBaptise]"

   # Recherche des Sources pour l'individu
   if [[ "$OPT_DATE" == "1" ]]; then
      sed -e "1,/^<!--  Portrait -->/d" -e "/^<!-- Parents /,10000d" -e "s/&nbsp;/ /g" -e "/^$/d" -e "s/ Julian ([^)]*)//g" -e "s/Julian -/-/g" -e "s/ Julian,/,/g" -e "s/&nbsp;/ /g" -e "s/<em>//g" -e "s/<\/em>//g" "$fic_tmp_all" | sed -e "1,/^<ul>/d" -e "/^<\/ul>/,10000d" | grep "<li" > "$fic_tmp"
      date:get "$fic_tmp" "$labelNaissance" GEDCOM_naissance villeNaissance julienNaissance
      log:debug "($IdFct) Naissance trouvé : GEDCOM_naissance:[$GEDCOM_naissance] ville:[$villeNaissance] calJ:[$julienNaissance]"
      date:get "$fic_tmp" "$labelDeces" GEDCOM_deces villeDeces julienDeces
      log:debug "($IdFct) Décès trouvé : GEDCOM_deces:[$GEDCOM_deces] villeDeces:[$villeDeces] calJ:[$julienNaissance]"
      date:get "$fic_tmp" "$labelBaptise" GEDCOM_bapteme villeBapteme julienBapteme
      log:debug "($IdFct) Bapteme trouvé : GEDCOM_bapteme:[$GEDCOM_bapteme] villeBapteme:[$villeBapteme] calJ:[$julienBapteme]"
      occupation=$(tail -1 "$fic_tmp" | grep -v "$labelNaissance\|$labelDeces\|$labelBaptise" | sed -e 's/<li>//g' -e 's/<\/li>//g')
   fi

   famille:write "fams=[$FAMS]&KeyID_Appel=[$KeyID_Appel]&sex=[$sex]&KeyID=[$KeyID]&Qui=[$Qui]"
   ged:write "$KeyID" "KeyID=[$KeyID]&nom=[$nom]&prenom=[$prenom]&sex=[$sex]&occupation=[$occupation]"
   [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
   # Recherche des Sources pour l'individu
   if [[ "$OPT_SOURCE" == "1" ]]; then
      g_srcIndi="" g_srcNaissance="" g_srcUnion="" g_srcDeces="" g_srcBapteme=""
      source:get "$fic_tmp_all"
      log:debug "($IdFct)Retour source:get g_srcIndi=[$g_srcIndi] g_srcNaissance=[$g_srcNaissance] g_srcUnion=[$g_srcUnion] g_srcDeces=[$g_srcDeces]"
   fi

   # Recherche Note pour l'individu
   if [[ "$OPT_NOTE" == "1" ]]; then
      g_noteIndi="" g_noteNaissance="" g_noteMariage="" g_noteDeces="" g_noteFamille="" g_noteBapteme=""
      note:get "$fic_tmp_all"
      log:debug "($IdFct) Retour note:get g_noteIndi=[$g_noteIndi] g_noteNaissance=[$g_noteNaissance] g_noteMariage=[$g_noteMariage] g_noteDeces=[$g_noteDeces] g_noteFamille:[$g_noteFamille]"
   fi

   if [[ "$OPT_NOTE" == "1" || "$OPT_SOURCE" == "1" ]]; then
      retNote=$(note:get:autre "$KeyID")
      if [[ "$OPT_NOTE" == "1" ]]; then
         g_noteNaissance=$(getParam "birth" "$retNote")
         g_noteBapteme=$(getParam "baptism" "$retNote")
         g_noteDeces=$(getParam "death" "$retNote")
      else
         g_srcNaissance=$(getParam "sbirth" "$retNote")
         g_srcBapteme=$(getParam "sbaptism" "$retNote")
         g_srcDeces=$(getParam "sdeath" "$retNote")
      fi
      log:info "g_noteNaissance:[$g_noteNaissance] g_noteBapteme:[$g_noteBapteme] g_noteDeces:[$g_noteDeces] g_srcNaissance:[$g_srcNaissance] g_srcBapteme:[$g_srcBapteme] g_srcDeces:[$g_srcDeces]"
   fi
   [[ -n "$julienNaissance" ]] && note_naissance="[$julienNaissance][$note_naissance]"
   [[ -n "$julienDeces" ]] && g_noteDeces="[$julienDeces][$g_noteDeces]"

   ged:write "$KeyID" "source_individu=[$g_srcIndi]&note_individu=[$g_noteIndi]" 
      [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
   ged:write "$KeyID" "date_naissance=[$GEDCOM_naissance]&ville_naissance=[$villeNaissance]&source_naissance=[$g_srcNaissance]&note_naissance=[$g_noteNaissance]"
      [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
   ged:write "$KeyID" "date_deces=[$GEDCOM_deces]&ville_deces=[$villeDeces]&source_deces=[$g_srcDeces]&note_deces=[$g_noteDeces]"
      [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
   ged:write "$KeyID" "date_bapteme=[$GEDCOM_bapteme]&ville_bapteme=[$villeBapteme]&source_bapteme=[$g_srcBapteme]&note_bapteme=[$g_noteBapteme]"
      [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
   
   if [[ "${Qui}" == "${QUI_PARENT}" || "${Qui}" == "${QUI_PERE}"  || "${Qui}" == "${QUI_PERE}" ]]; then
      if ! individu:isMaried "$fic_tmp_all"; then
         ged:write "$KeyID" "fams=[$FAMS]"
         [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
      fi
   elif [[ "${Qui}" == "${QUI_CONJOINT}" ]]; then
      # Je suis l'épouse
      ged:write "$KeyID" "fams=[$FAMS]"
      [[ "$?" -ne 0 ]] && log:error "Erreur retour ged:write"
   fi
   # recherche épouse 
   if [[ "$getEpoux" == "1" && "${Qui}" != "${QUI_CONJOINT}" ]]; then
      log:info "($IdFct): Bloc recherche des conjoints"

      sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" | grep -A2 "^$LB_MARIE\|^$LB_RELATION\|^$LB_ENFANT_AVEC_HOMME" | grep -v "^--" | sed -e '/^<ul>$/d' > "$fic_tmp_epoux_tmp"
      nbEpoux=$(grep -i "^$LB_MARIE\|^$LB_MARIE_AVEC\|^$LB_ENFANT_AVEC_HOMME" "$fic_tmp_epoux_tmp" | wc -l)
      nbEpoux=$(( nbEpoux ))
      log:debug "($IdFct): Nb époux:[$nbEpoux]"

      # Si pas d'époux, je supprime le fichier FAMS
      if [[ "$nbEpoux" -eq 0 ]]; then
         # Je regarde si il a des enfants dans ce cas, je supprime pas le fichier seulement si il n'y as pas d'enfant d'un conjoint inconnu
         nbEnfantEpoux=$(sed -e '1,/<!--  Union/d' -e '/^<!--  Freres/,10000d' "$fic_tmp_all" | grep -v "=MOD_FAM" | sed -e 's/<a href=".*m=RL.*<img src="https/<img src="https/g' | grep -v "? ?" | grep -c "<a href=\"")
         if [[ "$nbEnfantEpoux" -eq 0 ]]; then
            sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" | grep -v "=MOD_FAM" | sed -e 's/<a href=".*m=RL.*<img src="https/<img src="https/g' -e '/^<ul>$/d' > "$fic_tmp_enfant_tmp"
            log:debug "($IdFct): Pas d'époux:[$nbEpoux] et pas d'enfants, je supprime le fichier [$(famille:filename "$FAMS")]"
            famille:rm "$FAMS"
         else
            log:debug "($IdFct): Pad d'époux:[$nbEpoux] mais avec des enfants, je ne supprime pas le fichier [$(famille:filename "$FAMS")]"
            :
         fi
      else
         while IFS='' read -r ligne_html; do
            log:debug "($IdFct) Lecture de la ligne [$ligne_html]"
            epoux_trouve=$(echo "$ligne_html" | grep -c "^$LB_MARIE\|^$LB_RELATION\|^$LB_FIANCE\|^$LB_ENFANT_AVEC_HOMME")
            # Si ligne "^Married to" ==> Pas de date de mariage Sinon "^Married date..." et ligne suivante epoux
            SansDate=$(echo "$ligne_html" | grep -c "^${LB_MARIE}${LB_MARIE_AVEC}\|^${LB_ENFANT_AVEC_HOMME}")
            ref_epoux=$(echo "$ligne_html" | grep -ic "^${LB_MARIE}${LB_MARIE_AVEC}<a href=\|^${LB_RELATION}${LB_RELATION_AVEC}<a href=\|^${LB_MARIE_AVEC}<a href=\|^${LB_RELATION_AVEC}<a href=\|^${LB_ENFANT_AVEC_HOMME}<a href=")
#            ref_epoux=$(echo "$ligne_html" | grep -Ei "${LB_MARIE_AVEC}.*<a href=" | wc -l | bc)
            log:debug "($IdFct) epoux_trouve:[$epoux_trouve] SansDate:[$SansDate] ref_epoux:[$ref_epoux]"

            lineMarried=$(echo "$ligne_html" | grep -c "^$LB_MARIE\|^$LB_RELATION")
            [[ "$lineMarried" -eq 1 ]] && numMariage=$(( numMariage + 1 ))

            if [[ "$epoux_trouve" -eq 1 && "$SansDate" -eq 0  ]]; then
               # echo "($IdFct): $ligne_html"
               if [[ "$OPT_DATE" == "1" ]]; then
                  echo "$ligne_html" | sed -e "s/$LG_MARIED_F/$LG_MARIED_M/g" > "$fic_epoux_date_mariage"
                  date:get "$fic_epoux_date_mariage" "$LG_MARIED_M" GEDCOM_mariage villeMariage julienMariage
                  log:info "($IdFct): GEDCOM_mariage:[$GEDCOM_mariage] ville:[$villeMariage] CalJ:[$julienMariage]"
               fi
               ligne_precedente_marie_avec=1
               continue
            fi
            
            if [[ "$epoux_trouve" -eq 1 ]]; then
               # Si il trouve "Married alors typeMariage=1 (Mariage)"
               # Sinon typeMariage=° (relation)
               local typeMariage=$(echo "$ligne_html" | grep -c "^$LB_MARIE")
            fi

            if [[ "$ref_epoux" -eq 1 ]]; then
               if [[ "$numMariage" -gt 1 ]]; then
                  # Plusieur mariage, j'incremente le N° Famille
                  firstFAMS="$FAMS"
                  FAMS=$(incFAM "$fic_fam")
                  famille:write "fams=[$FAMS]&KeyID_Appel=[$KeyID_Appel]&sex=[$sex]&KeyID=[$KeyID]&Married=[$typeMariage]&Qui=[$Qui]"
                  # Initialissation du fichier Famill
               else
                  [[ "$typeMariage" == "0" ]] && famille:write "fams=[$FAMS]&Married=[$typeMariage]"
               fi
               # Verifier si divorcé
               nbDivorce=$(echo "$ligne_html" | grep -ci "${LB_DIVORCE}")
               log:info "========> ligne_html:[$ligne_html] nbDivorce:[$nbDivorce]"
               if [[ "$nbDivorce" -eq 1 ]]; then
                  nomConjoint=$(echo "$ligne_html" | sed -e 's/^.*">//g' -e 's/<.*$//g' | sed -e 's/ /\.\*/g')
                  if [[ "$OPT_DATE" == "1" ]]; then
                     # ==> Enlever Partie Date Julain
                     # sed -e "s/ Julian ([^)]*)//g" -e "s/Julian -/-/g" -e "s/ Julian,/,/g" -e "s/&nbsp;/ /g" -e "s/<em>//g" -e "s/<\/em>//g"
                     echo "$ligne_html" | sed -e "s/ Julian ([^)]*)//g" -e "s/Julian -/-/g" -e "s/ Julian,/,/g" -e "s/&nbsp;/ /g" -e "s/<em>//g" -e "s/<\/em>//g" | sed -e "s/^.*$LB_DIVORCE/$LB_DIVORCE/g" -e "s/ ${LB_AVEC}$//g"> "$fic_tmp_divorce"
                     date:get "$fic_tmp_divorce" "$LB_DIVORCE" GEDCOM_divorce villeDivorce julienDivorce
                     log:info "($IdFct): GEDCOM_divorce:[$GEDCOM_divorce] ville:[$villeDivorce] CalJ:[$julienDivorce]"
                  fi
                  # recherche ville Divorce/note
                  villeDivorce=$(grep -c "Divorce.*${nomConjoint}.* - " "$fic_tmp_all")
                  if [[ "$villeDivorce" -eq 1 ]]; then
                     villeDivorce=$(grep -A2 "Divorce.*${nomConjoint}.* - " "$fic_tmp_all" | sed -e 's/^.* - //g' -e "s/<.*$//g")
                  else
                     villeDivorce=""
                  fi
                  echo "villeDivorce:[$villeDivorce]"
                  if [[ "$OPT_NOTE" == "1" ]]; then
                     g_noteDivorce=$(grep -A2 "Divorce.*${nomConjoint}" "$fic_tmp_all" | grep "nnotes" | sed -e "s/^.*nnotes\">//g" -e "s/<.*$//g")
                  fi
                  log:info "($IdFct): GEDCOM_divorce:[$GEDCOM_divorce] tgDivorce:[$tgDivorce] sj:[$]sj sm:[$sm] sy:[$sy] sj_Fin:[$ƒ] sm_Fin:[$sm_Fin] sy_Fin:[$sy_Fin] villeDivorce:[$villeDivorce] g_noteDivorce:[$g_noteDivorce]"
               fi
               lien_epoux=$(echo "$ligne_html" | sed -e "s/<a href=\"/\n<a href=\"/g" | grep -v "&m=\|&t=|&i1=\|&i2=" | grep "&p=\|&n=\|&i=\|&oc=" | sed -e 's/^.*<a href="//g' | sed -e 's/">.*$//g')
               log:info "lien_epoux:[$lien_epoux]"
               ligne_precedente_marie_avec=0

               # Pour l'épouse je n'increment pas le N°Famills (FAMS)
               log:info "($IdFct): Je recherche l'épouse de [$KeyID]  pour la famille FAMS[$FAMS] lien_epoux:[$lien_epoux]"
               findID=$(Index:Search:URI "URI=[$lien_epoux]")
               if [[ -z "$findID" ]]; then
                  _retIndividu=$(individu:search "KeyID_Appel=[$KeyID]&Qui=[${QUI_CONJOINT}]&uri=[${lien_epoux}]&getParent=[${getParent}]&getEpoux=[${getEpoux}]&getFrere=[${getFrere}]&getEnfant=[0]&numFamille=[${FAMS}]")
                  retCode="$?"
                  Key_epouse=$(getParam "KeyID" "$_retIndividu")
                  [[ "$retCode" -gt 299 ]] && continue
               else
                  log:info "Le conjoint ($findID) de $KeyID est déjà dans la base, pas d'appel à individu:search"
               fi

               # Ecriture dans fichier FAM, qui sera contatené dans le fichier ged à la fin
               [[ -n "$julienDivorce" ]] && g_noteDivorce="[$julienDivorce][$g_noteDivorce]"
               [[ -n "$julienMariage" ]] && g_noteMariage="[$julienNaissance][$g_noteMariage]"
               log:info "($IdFct): Ecriture dans FAMS[$FAMS] KeyID:[$KeyID] info de mariage/divorce Mariage:[$g_noteMariage] Divorce:[$g_noteMariage]"
               famille:write "fams=[$FAMS]&GEDCOM_mariage=[$GEDCOM_mariage]&ville_mariage=[$villeMariage]&note_mariage=[$g_noteMariage]&GEDCOM_divorce=[$GEDCOM_divorce]&ville_divorce=[$villeDivorce]&note_divorce=[$g_noteDivorce]"
               nbEpoux=$((nbEpoux - 1))
               if [[ "$nbEpoux" -eq 0 ]]; then
                  # Plus d'époux, je sors
                  break
               fi
            else
               if [[ "$epoux_trouve" -ne 1 ]] ; then 
                  ligne_precedente_marie_avec=0
               fi
            fi
         done <$fic_tmp_epoux_tmp
      fi
   fi

   log:info "Avant appel à parent:get avec KeyID:[$KeyID]"
   if [[ "$getParent" == "1" ]]; then
      parent:get "KeyID=[$KeyID]&getParent=[$getParent]&getEpoux=[$getEpoux]&getFrere=[$getFrere]&getEnfant=[$getEnfant]"
   fi

   # Je ne recherche pas enfant du début de la branche
   # TO-DO ==> Doit être une option
#   if [[ "$getEnfant" == "1" && "$KeyID" != "1" ]]; then
#   if [[ "$KeyID" == "1" ]]; then
   if [[ "$getEnfant" == "1" ]]; then
      enfant:get "KeyID=[$KeyID]&fams=[$FAMS]&getParent=[0]&getEpoux=[1]&getFrere=[0]&getEnfant=[0]"
   fi

   log:info "FIN individu:search($IdFct): $KeyID"

   clean_fichier_temporaire "$KeyID"
   echo "KeyID=[$KeyID]"
   return 0
}

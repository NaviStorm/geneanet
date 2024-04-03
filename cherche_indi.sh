trace_individu_search="true"

clean_fichier_temporaire() {
   local _keyID="$1"
   local pre="" allFic=""

return 0
   pre="${TMP_DIR}/gen_$(printf "%04d" "$_keyID")"
   allFic="${pre}_*"
   rm $allFic 2>/dev/null 1>&2
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

siMarie() {
   local _nbEpoux=0
   _nbEpoux=$(sed -e "1,/<!--  Union/d"  -e "/^<!--  Freres/,10000d" "$1" | grep -c "^${LB_MARIE}\|^${LB_RELATION}")
   return $((_nbEpoux + 0))
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
      sed -i "/^$KeyID / s/$/ @$dbKeyID@/" "$fic_id_exist"
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
   local KeyID="" _index="" _lastname="" _firstname="" _sex="" _p="" _n=$"" _oc="" _uri=""
   local UniqID=0
   local retCode=0
   local retValue=""
   local _sP="" _sN="" _sI="" 

##   log:info "param:[$param]"
   KeyID=$(getParam "KeyID" "$param")
   _index=$(getParam "index" "$param")
   _lastname=$(getParam "nom" "$param")
   _firstname=$(getParam "prenom" "$param")
   _sex=$(getParam "sex" "$param")
   _p=$(getParam "p" "$param" | sed -e 's/ /+/g')
   _n=$(getParam "n" "$param"| sed -e 's/ /+/g')
   _oc=$(getParam "oc" "$param"| sed -e 's/ /+/g')
   _uri=$(getParam "URI" "$param")

   if [[ -n "$KeyID" && -n "$_index" ]]; then
      grep "\[$_index\]" "$fic_id_exist" 2>/dev/null 1>&2
      UniqID=$(grep "\[$_index\]" "$fic_id_exist" | sed -e 's/ .*$//g')
      if [[ -n "$UniqID" ]]; then
         echo "$UniqID @I$KeyID@" >> "$fic_id_link"
         # Ajoute au vrai ID(KeyID), le nouveau doublon en fin de ligne
         sed -i "/^$UniqID / s/$/ @$KeyID@/" "$fic_id_exist"
         return $INDI_DEJA_TRAITE
      else
         echo "$KeyID [$_index] _lastname:[$_lastname] _firstname:[$_firstname] p:[$_p] n:[$_n]" oc:[$_oc] sex:[$_sex] >> "$fic_id_exist"
         return 0
      fi
   elif [[ -n "$_p" && -n "$_n" ]]; then
      retValue=$(grep "p:\[$_p\].*n:\[$_n\].*oc:\[$_oc\]" "$fic_id_exist" | sed "s/ .*$//g" | wc -l)
      nb=$(echo "$retValue" | wc -l)
      [[ "$nb" -gt 1 ]] && exit 0
      echo "$retValue"
#      grep "p:\[$_p\].*n:\[$_n\].*oc:\[$_oc\]" "$fic_id_exist" | sed "s/ .*$//g"
   elif [[ -n "$_index" ]]; then
      retValue=$(grep " \[$_index\]" "$fic_id_exist" | sed "s/ .*$//g")
      nb=$(echo "$retValue" | wc -l)
      [[ "$nb" -gt 1 ]] && exit 0
      echo "$retValue"
#      grep " \[$_index\]" "$fic_id_exist" | sed "s/ .*$//g"
   elif [[ -n "$_uri" ]]; then
      Index:Search:URI "$_uri"
   fi
}


KeyID:get() {
   local KeyID="$1"

   grep "@I$KeyID@" "$fic_id_link" | sed -e 's/ .*$//g'
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
individu:search( ) {
   local param="$1"
   local KeyID KeyID_Appel Lien_Appel ficGedcom Qui URI getParent getEpoux getFrere getEnfant FAMS KeyID_Appel
   
   pauseRunSH
   ficGedcom=$(getParam "ficGedcom" "$param")
   Qui=$(getParam "Qui" "$param")
   URI=$(getParam "uri" "$param")
   getParent=$(getParam "getParent" "$param")
   getEpoux=$(getParam "getEpoux" "$param")
   getFrere=$(getParam "getFrere" "$param")
   getEnfant=$(getParam "getEnfant" "$param")
   FAMS=$(getParam "numFamille" "$param")
   KeyID_Appel=$(getParam "KeyID_Appel" "$param")
   Lien_Appel=$(getParam "KeyID_Appel" "$param")


   KeyID=$(KeyID:inc)

   local FAMS_SUIVANTE=0

   nbAppel=$((nbAppel + 1))
   local IdFct="$nbAppel/$KeyID/$FAMS"
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
      ) 1>&2
      return "$INDI_DEJA_TRAITE"
   fi

   if [[ "$id_p$id_n" == "" ]]; then
      log:info "($IdFct) Personne Inconnu, mais je traite quand même car peut être le/la père/mère de plusieurs enfants: \$nom\$prenom:[$nom$prenom]"
      (
         ged:write "$KeyID" "KeyID=[$KeyID]&nom=[?]&prenom=[?]&sex=[U]"
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
      # ==> Enlever Partie Date Julain
      # sed -e "s/ Julian ([^)]*)//g" -e "s/Julian -/-/g" -e "s/ Julian,/,/g" -e "s/&nbsp;/ /g" -e "s/<em>//g" -e "s/<\/em>//g"
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
   ged:write "$KeyID" "date_naissance=[$GEDCOM_naissance]&ville_naissance=[$villeNaissance]&source_naissance=[$g_srcNaissance]&note_naissance=[$g_noteNaissance]"
   ged:write "$KeyID" "date_deces=[$GEDCOM_deces]&ville_deces=[$villeDeces]&source_deces=[$g_srcDeces]&note_deces=[$g_noteDeces]"
   ged:write "$KeyID" "date_bapteme=[$GEDCOM_bapteme]&ville_bapteme=[$villeBapteme]&source_bapteme=[$g_srcBapteme]&note_bapteme=[$g_noteBapteme]"
   
   if [[ "${Qui}" == "${QUI_PARENT}" || "${Qui}" == "${QUI_PERE}"  || "${Qui}" == "${QUI_PERE}" ]]; then
      if ! siMarie "$fic_tmp_all"; then
         ged:write "$KeyID" "fams=[$FAMS]"
      fi
   elif [[ "${Qui}" == "${QUI_CONJOINT}" ]]; then
      # Je suis l'épouse
      ged:write "$KeyID" "fams=[$FAMS]"
   fi

   # recherche épouse 
   if [[ "$getEpoux" == "1" && "${Qui}" != "${QUI_CONJOINT}" ]]; then
      log:info "($IdFct): Bloc recherche des conjoints"

      sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" | grep -A2 "^$LB_MARIE\|^$LB_RELATION" | grep -v "^--" | sed -e '/^<ul>$/d' > "$fic_tmp_epoux_tmp"
      nbEpoux=$(grep -i "^$LB_MARIE\|^$LB_MARIE_AVEC" "$fic_tmp_epoux_tmp" | wc -l)
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
            epoux_trouve=$(echo "$ligne_html" | grep -c "^$LB_MARIE\|^$LB_RELATION\|^$LB_FIANCE")
            # Si ligne "^Married to" ==> Pas de date de mariage Sinon "^Married date..." et ligne suivante epoux
            SansDate=$(echo "$ligne_html" | grep -c "^${LB_MARIE}${LB_MARIE_AVEC}")
            ref_epoux=$(echo "$ligne_html" | grep -ic "^${LB_MARIE}${LB_MARIE_AVEC}<a href=\|^${LB_RELATION}${LB_RELATION_AVEC}<a href=\|^${LB_MARIE_AVEC}<a href=\|^${LB_RELATION_AVEC}<a href=")
#            ref_epoux=$(echo "$ligne_html" | grep -Ei "${LB_MARIE_AVEC}.*<a href=" | wc -l | bc)
            log:debug "($IdFct) epoux_trouve:[$epoux_trouve] SansDate:[$SansDate] ref_epoux:[$ref_epoux]"

            lineMarried=$(echo "$ligne_html" | grep -c "^$LB_MARIE\|^$LB_RELATION")
            [[ "$lineMarried" -eq 1 ]] && numMariage=$(( numMariage + 1 ))

            if [[ "$epoux_trouve" -eq 1 && "$SansDate" -eq 0  ]]; then
               # echo "($IdFct): $ligne_html"
               if [[ "$OPT_DATE" == "1" ]]; then
                  echo "$ligne_html" | sed -e "s/$LG_MARIED_F/$LG_MARIED_M/g"> "$fic_epoux_date_mariage"
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
                  _retIndividu=$(individu:search "ficGedcom=[$ficGedcom]&KeyID_Appel=[$KeyID]&Qui=[${QUI_CONJOINT}]&uri=[${lien_epoux}]&getParent=[${getParent}]&getEpoux=[${getEpoux}]&getFrere=[${getFrere}]&getEnfant=[0]&numFamille=[${FAMS}]")
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

   # Recherche Parent
   sed -e "1,/^<!-- Parents /d" -e "/^<!--  Union /,10000d" -e '/<li style=/d' -e "s/<a href=\"/\n<a href=\"/g"  "$fic_tmp_all" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=" | grep "^.*href" | sed -e 's/^.*href="//g' -e 's/">.*$//' >$fic_tmp_parent
   local nb_parent=$(wc -l < "$fic_tmp_parent")
   nb_parent=$((nb_parent+0))
   if [[ "$getParent" == "1" ]]; then
      log:info "($IdFct): Bloc recherche des parents"

      log:info "($IdFct): Parents nb_parent:[$nb_parent]"
      if [[ "$nb_parent" -ne 0 ]]; then
         FAMS_SUIVANTE=$(incFAM "$fic_fam")
         log:info "($IdFct): Nb Parent : [$nb_parent]"
         local lien_pere=$(head -1 "$fic_tmp_parent")
         local lien_mere=$(tail -1 "$fic_tmp_parent")
         log:info "($IdFct): lien_pere:[$lien_pere] lien_mere:[$lien_mere]"

         # Recherche le Père
         log:info "($IdFct) Cherche le pere avec nouveau N° FAMS:[$FAMS_SUIVANTE]"
         _retIndividu=$(individu:search "ficGedcom=[$ficGedcom]&KeyID_Appel=[$KeyID]&Qui=[${QUI_PARENT}]&uri=[${lien_pere}]&getParent=[${getParent}]&getEpoux=[${getEpoux}]&getFrere=[${getFrere}]&getEnfant=[0]&numFamille=[${FAMS_SUIVANTE}]")
         retCode="$?"
         KeyID_Pere=$(getParam "KeyID" "$_retIndividu")
         log:info "($IdFct) KeyID du père retourné : [$KeyID_Pere]"
         if [[ "$retCode" -gt 299 ]]; then
            echo ""
            return "$retCode"
         fi
         # Par sécurité je laisse cette condition
         log:info "($IdFct) I@$KeyID_Pere@ est le père de I@$KeyID@ Pour la famille FAMS:[$FAMS_SUIVANTE]"

         # Recherche la Mère
         log:info "($IdFct) Cherche la mere avec nouveau N° FAMS :[$FAMS_SUIVANTE]"
         _retIndividu=$(individu:search "ficGedcom=[$ficGedcom]&KeyID_Appel=[$KeyID]&Qui=[${QUI_PARENT}]&uri=[${lien_mere}]&getParent=[${getParent}]&getEpoux=[${getEpoux}]&getFrere=[${getFrere}]&getEnfant=[0]&numFamille=[${FAMS_SUIVANTE}]")
         local retCode="$?"
         KeyID_Mere=$(getParam "KeyID" "$_retIndividu")
         log:info "($IdFct) KeyID de la mère retourné : [$KeyID_Mere]"
         if [[ "$retCode" -gt 299 ]]; then
            echo ""
            return "$retCode"
         fi
         log:info "($IdFct) I@$KeyID_Mere@ est le la mère de I@$KeyID@ Pour la famille FAMS:[$FAMS_SUIVANTE]" >&2

         #FAMS_SUIVANTE=$(famille:search "$KeyID_Pere" "$KeyID_Mere")
         FAMS_SUIVANTE=$(famille:search "pere=[$KeyID_Pere]&mere=[$KeyID_Mere]")
          retCode="$?"
         log:info "($IdFct) Retour famille:search I@$KeyID_Mere@ I@$KeyID@ retCode:[$retCode] FAMS_SUIVANTE:[$FAMS_SUIVANTE]"
         if [[ "$retCode" -eq "$FAMILY_EXIST" ]]; then
            famille:write "fams=[$FAMS_SUIVANTE]&child=[$KeyID]"
            ged:write "$KeyID" "famc=[$FAMS_SUIVANTE]"
         else
            FAMS_SUIVANTE=$(incFAM "$fic_fam")
            log:info "($IdFct) Enfant sans fichier famille Enfant:[$KeyID] Père:[$KeyID_Pere] Mère:[$KeyID_Mere]" >&2
            famille:write "fams=[$FAMS_SUIVANTE]&child=[$KeyID]&sex=[M]&pere=[$keyID_Pere]&mere=[keyID_Mere]"

            famille:write "fams=[$FAMS_SUIVANTE]&KeyID_Appel=[$KeyID]&sex=[M]&KeyID=[$keyID_Pere]&Qui=[ENFANT]"
            famille:write "fams=[$FAMS_SUIVANTE]&KeyID_Appel=[$keyID_Pere]&sex=[F]&KeyID=[$keyID_Mere]&Qui=[CONJOINT]"
            famille:write "fams=[$FAMS_SUIVANTE]&child=[$KeyID]&Qui=[$Qui]"
         fi
      fi
      log:info "($IdFct): Fin Recherche Parent"
   fi

   # Je ne recherche pas enfant du début de la branche
   # TO-DO ==> Doit être une option
   if [[ "$getEnfant" == "1" && "$keyID" != "1" ]]; then
      log:info "($IdFct): Recherche des enfants"
      sed   -e '1,/<!--  Union/d' -e '/^<!--  Freres/,10000d' \
            -e "s/<span[^>]*>//g" \
            -e "s/<img[^>]*>//g" \
            -e "s/<a.*ref.*&i1=[^>]*>//g" \
            -e "s/<li.*style.*square[^>]*>//g" \
            -e '/^$/d' \
            -e '/^ to/,+1d' \
            -e "/=MOD_FAM/d" "$fic_tmp_all" > "$fic_tmp_enfant_tmp"
      html_ligne_prec=""
      local NivEnfant=0 
      local BeauParent=0 
      local ConjointEnfant=0
      while IFS='' read -r html_ligne; do
         log:debug "Bloc Enfant html_ligne:[$html_ligne] NivEnfant:[$NivEnfant] BeauParent:[$BeauParent] ConjointEnfant:[$ConjointEnfant]"
         # Laissez ce test en 1er
         if [[ "$html_ligne" == *" href=\""* && "$ConjointEnfant" -eq 1 ]]; then
            ConjointEnfant=0
            continue
         elif [[ "$html_ligne" == " with"* && "$ConjointEnfant" -eq 1 ]]; then
            log:debug "Bloc Ligne $LB_RELATION_AVEC du Conjoint"
            continue
         elif [[ "$ConjointEnfant" -eq 1 ]]; then
            log:debug "Fin Bloc Conjoint"
            ConjointEnfant=0
         fi
         [[ "$html_ligne" == "<div "* ]] && (( NivEnfant++ ))
         [[ "$html_ligne" == "</div>"* ]] && (( NivEnfant-- ))
         if [[ "$html_ligne" == "$LB_MARIE"* ]]; then
            (( BeauParent++ ))
            log:debug "Bloc Beau Pere/Belle Mere"
            continue
         elif [[ "$html_ligne" == *"$LB_MARIE"* || "$html_ligne" == *"$LB_RELATION"* ]];then
            log:debug "Bloc Conjoint"
            ConjointEnfant=1
         fi
         if [[ "$html_ligne" == "$LB_ENFANT_AVEC"* ]]; then
            log:debug "Fin Bloc Beau Pere/Belle Mere"
            (( BeauParent-- ))
         fi
         if [[ "$html_ligne" == *" href=\""* && "$NivEnfant" -eq 0 && "$BeauParent" -eq 0 ]]; then
            ligPrecMarie=$(echo "$html_ligne_prec" | grep -c "^$LB_MARIE\|^$LB_RELATION")
            if [[ "$ligPrecMarie" -ne 0 ]]; then               # log:info "Ligne précédente Married...ligPrecMarie[$ligPrecMarie] html_ligne:[$html_ligne]"
               ligPrecMarie=$html_ligne
               continue
            fi
            lien=$(echo "$html_ligne" | sed -e "s/<a href=\"/\n<a href=\"/g" | grep -v "&m=\|&t=|&i1=\|&i2=" | grep "&p=\|&n=" | sed -e 's/^.*href=\"//g' -e 's/".*$//g')
            findID=$(Index:Search:URI "URI=[$lien]")
            ch_Enfant=0
            if [[ -z "$findID" ]]; then
               log:info "Nv:[$NivEnfant] Je recherche l'enfant ($lien) findID($findID)"
               FAMS_SUIVANTE=$(incFAM "$fic_fam")
               _retIndividu=$(individu:search "ficGedcom=[$fic_gedcom]&KeyID_Appel=[$KeyID]&Qui=[${QUI_PARENT}]&uri=[${lien}]&getParent=[${ch_Parent}]&getEpoux=[${ch_Epoux}]&getFrere=[${ch_Frere}]&getEnfant=[${ch_Enfant}]&numFamille=[${FAMS_SUIVANTE}]")
               local retCode="$?"
               KeyID_Enfant=$(getParam "KeyID" "$_retIndividu")
               log:info "Retourn apple individu:search [$retCode] Moi:[$keyID] Enfant:[$KeyID_Enfant] lien:[$lien]"
               famille:write "fams=[$FAMS]&child=[$KeyID_Enfant]"
               if [[ "$retCode" -gt 299 ]]; then
                  clean_fichier_temporaire "$KeyID"
                  echo ""
                  return "$retCode"
               fi
            else
               log:info "Enfant $findID déjà dans la base, pas d'appel à individu:search"
               KeyID_Enfant="$findID"
               famille:write "fams=[$FAMS]&child=[$KeyID_Enfant]"
            fi
         fi
         [[ "$html_ligne" == *" href=\""* && "$NivEnfant" -eq 1 ]] && log:info "Nv:[$NivEnfant] Je suis le Petit Enfant, rien a faire"
         [[ "$html_ligne" == *" href=\""* && "$NivEnfant" -eq 2 ]] && log:info "Nv:[$NivEnfant] Je suis le Petit Petit Enfant, rien a faire"
         [[ "$html_ligne" == *" href=\""* && "$NivEnfant" -ge 3 ]] && log:info "Nv:[$NivEnfant] Je suis le Petit Petit ... Enfant, rien a faire"
         [[ "$html_ligne" == *" href=\""* && "$BeauParent" -ne 0 ]] && log:info "Nv:[$BeauParent] Je suis le Beau Pere/Belle Mere"
         html_ligne_prec=$html_ligne
      done <"$fic_tmp_enfant_tmp"
   fi

   # recherche frère & soeur
   if [[ "$getFrere" == "9" ]]; then
      #      echo "Recherche frère/soeur"
      sed -e "1,/^<!--  Freres et soeurs /d" -e "/^<!--  Relations/,10000d" "$fic_tmp_all" > "$fic_tmp_frere"
   fi

#   rm "$fic_tmp_all" "$fic_tmp_parent" "$fic_tmp_union" "$fic_tmp_parent_pere" "$fic_tmp_parent_mere" "$fic_tmp_epoux" "$fic_tmp_divorce" "$fic_tmp_epoux_tmp" "$fic_tmp_frere" "$fic_tmp_enfant_tmp" "$fic_tmp_note" 2>/dev/null 1>&2 || true

   log:info "FIN individu:search($IdFct): $KeyID"

   clean_fichier_temporaire "$KeyID"
   echo "KeyID=[$KeyID]"
   return 0
}

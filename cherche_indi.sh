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
   _nbEpoux=$(sed -e "1,/<!--  Union/d"  -e "/^<!--  Freres/,10000d" "$1" | grep -E "^${LB_MARIE}|^${LB_RELATION}" | wc -l | bc)
   return $((_nbEpoux + 0))
}


incFAM() {
   local fic_fam="$1"
   local nFAM=$(($(cat "$fic_fam") + 1))
   echo $nFAM | tee "$fic_fam"
   return 0
}


KeyID:dec() {
   local _fic_id="$1"
   local _KeyID=$(($(cat $_fic_id) - 1))
   echo "$_KeyID" >"$_fic_id"
   eval "${2}=\"$_KeyID\"" 2>/dev/null
}


KeyID:inc() {
   local _fic_id="$1"
   local _KeyID=$(($(cat $_fic_id) + 1))
   echo "$_KeyID" >"$_fic_id"
   eval "${2}=\"$_KeyID\"" 2>/dev/null
}


KeyID:search() {
   trace_individu_deja_traite="true"

   local KeyID="$1"
   local dbKeyID=0
   local _index=""

   _index=$(echo "${2}" | sed -e 's/&type=tree//g' | sed -e "s/lang=../lang=$language/g" -e 's/&type=fiche//g' -e 's/&/_/g' -e 's/=/_/g' -e 's/\?/_/g' -e 's/\+/_/g' -e 's/\].*$//g')

   grep "\[$_index\]" "$fic_id_exist"
   if [[ "$?" -eq 0 ]]; then
      dbKeyID="$KeyID"
      KeyID=$(grep "\[$_index\]" "$fic_id_exist" | sed -e 's/ .*$//g')
      log:info "($dbKeyID) Dejà dans fichier ID_Trouve (déjà traite avec [$KeyID] [$_index])"
      echo "$KeyID @I$dbKeyID@" >> "$fic_id_link"
      # Ajoute au vrai ID(KeyID), le nouveau doublon en fin de ligne
      sed -i "/^$KeyID / s/$/ @$dbKeyID@/" "$fic_id_exist"
      return 1
   else
      echo "$KeyID [$_index]" >> "$fic_id_exist"
      return 0
   fi
exit 0
}

KeyID:get() {
   local KeyID="$1"

   grep "@I$KeyID@" "$fic_id_link" | sed -e 's/ .*$//g'
}

individu:get() {
   local fic="$1"
   local _zone=""
   local _nom=""
   local _prenom=""
   local _sex=""

   _zone=$(sed -e "1,/^(function($, keys){/d" -e "/\<\/head\>/,10000d" -e "/^})(jQuery, GeneanetKeys);$/,10000d" -e 's/^.*$.extend(true, keys.elements, //g' -e 's/);$//g' "$fic" | grep -v "keys.elements =" 2>/dev/null)
   _nom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.lastname' 2>/dev/null)
   _prenom=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.firstname' 2>/dev/null)
   _sex=$(echo "$_zone" | jq --raw-output '.gntGeneweb.person.sex' 2>/dev/null)
   eval "$2=\"$_nom\""
   eval "$3=\"$_prenom\""
   eval "$4=\"$_sex\""
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
individu:getID( ) {
   :
}


individu:search( ) {
   export tab="$tab   "
   local param="$2"
   local KeyID ficGedcom Qui URI getParent getEpoux getFrere getEnfant FAMS
   
   pauseRunSH
   ficGedcom=$(echo "$param" | grep -i "ficGedcom=" | sed -e 's/^.*ficGedcom=\[//i' -e 's/\].*$//g')
   Qui=$(echo "$param" | grep "Qui=" | sed -e 's/^.*Qui=\[//' -e 's/\].*$//g')
   URI=$(echo "$param" | grep "uri=" | sed -e 's/^.*uri=\[//' -e 's/\].*$//g')
   getParent=$(echo "$param" | grep "getParent=" | sed -e 's/^.*getParent=\[//' -e 's/\].*$//g')
   getEpoux=$(echo "$param" | grep "getEpoux=" | sed -e 's/^.*getEpoux=\[//' -e 's/\].*$//g')
   getFrere=$(echo "$param" | grep "getFrere=" | sed -e 's/^.*getFrere=\[//' -e 's/\].*$//g')
   getEnfant=$(echo "$param" | grep "getEnfant=" | sed -e 's/^.*getEnfant=\[//' -e 's/\].*$//g')
   FAMS=$(echo "$param" | grep -i "numFamille=" | sed -e 's/^.*numFamille=\[//' -e 's/\].*$//g')

   KeyID=$(($(cat $fic_id) + 1))
   echo "$KeyID" >"$fic_id"
   eval "${1}=\"$KeyID\"" 2>/dev/null

   local FAMS_SUIVANTE=0

   nbAppel=$((nbAppel + 1))
   local IdFct="$nbAppel/$KeyID/$FAMS"
   pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
   local fic_tmp_all="${pre}_all_page"
   local fic_tmp="${pre}_result"
   local fic_tmp_parent="${pre}_parent"
   local fic_tmp_union="${pre}_union"
   local fic_tmp_parent_pere="${pre}_parent_pere"
   local fic_tmp_parent_mere="${pre}_parent_mere"
   local fic_tmp_epoux="${pre}_parent_epoux"
   local fic_tmp_divorce="${pre}_parent_divorce"
   local fic_tmp_epoux_tmp="${pre}_epoux_tmp"
   local fic_tmp_frere="${pre}_parent_frere"
   local fic_tmp_enfant_tmp="${pre}_enfants"
   local sex
   local labelNaissance
   local labelDeces
   local labelMarie
   local nb_parent

   local nom prenom sex nbEpoux
   local GEDCOM_naissance="" tgNaissance="" villeNaissance="" noteNaissance="" srcNaissance="" julienNaissance=""
   local GEDCOM_deces=""     tgDeces=""     villeDeces=""     noteDeces=""     srcDeces="" julienDeces=""
   local GEDCOM_mariage=""   tgMariage=""   villeMariage=""   noteMariage=""   srcUnion="" julienMariage=""  
   local GEDCOM_divorce=""   tgDivorce=""   villeDivorce=""   noteDivorce="" julienDivorce=""
   local bj="" bm="" by="" bj_Fin="" bm_Fin="" by_Fin=""
   local dj="" dm="" dy="" dj_Fin="" dm_Fin="" dy_Fin=""
   local mj="" mm="" my="" mj_Fin="" mm_Fin="" my_Fin=""
   local sj="" sm="" sy="" sj_Fin="" sm_Fin="" sy_Fin=""
   local srcIndi noteIndi  noteFamille
   local findID retID KeyID_Pere KeyID_Mere KeyID_Epouse nbEnfantEpoux KeyID_Enfant retCode
   local ref_epoux=0 ligne_precedente_marie_avec=0 lineMarried=0 numMariage=0 firstFAMS=0 SansDate=0 epoux_trouve=0 epoux_trouve=0

   log:info "($IdFct) DEB KeyID:[$KeyID] param:[$2]"
   if [[ "$Qui" != "$ENFANT" && "$Qui" != "$CONJOINT" ]]; then
      [[ "$nbAsc" -lt "$optNbAsc" ]] && nbAsc=$(( nbAsc + 1 ))
      [[ "$nbDesc" -lt "$optNbDesc" ]] && nbDesc=$(( nbDesc + 1 ))

      [[ "$optNbAsc" -ne 0  && "$nbAsc" -ge "$optNbAsc" ]] && getParent=0
      [[ "$optNbDesc" -ne 0 && "$nbDesc" -ge "$optNbDesc" ]] && getEnfant=0
   fi

   if [[ -z "$URI" ]]; then
      log:error " URI:[$URI] ne peux être vide"
      [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
      [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
      return 1
   fi
   log:info "($IdFct) URI:[$URI] Qui:[$Qui] KeyID:[$KeyID]"

   html:get "$URI" "$fic_tmp_all" "$fic_tmp" "$fic_tmp_parent"
   retCode="$?"
   if [[ "$retCode" -ne 0 ]]; then
      export tab=$(echo $tab | sed -e 's/   //')
      log:info "($IdFct): Erreur retour html:get:[$retCode]"
      clean_fichier_temporaire "$KeyID"
      [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
      [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
      return 1
   fi

   individu:get "$fic_tmp_all" nom prenom sex

   if [[ "$nom$prenom" == "??" || "$nom$prenom" == "" || "$nom$prenom" == "nullnull" ]]; then
      log:info "($IdFct) Personne Inconnu, mais je traite quand même car peut être le/la père/mère de plusieurs enfants: \$nom\$prenom:[$nom$prenom]"
      [[ "$Qui" == "$QUI_CONJOINT" || "$Qui" == "$QUI_MERE" ]] && sex="F" || sex="M"
      KeyID:search "$KeyID" "$URI"
      if [[ "$?" -eq 1 ]]; then
         findID=$(KeyID:get "$KeyID")
         eval "${1}=\"$findID\"" 2>/dev/null

         log:info "($IdFct): $KeyID Déjà traité ($findID) [$URI]"
         fam:write "fams=[$FAMS]&sex=[$sex]&KeyID=[$findID]"
         retCode="$CODE_DEJA_TRAITE"
      else
         ged:write "$KeyID" "KeyID=[$KeyID]&nom=[INCONNU]&prenom=[INCONNU]&sex=[$sex]"
         fam:write "fams=[$FAMS]&sex=[$sex]&KeyID=[$KeyID]"
         retCode=0
      fi

      export tab="${tab//   /}"
      clean_fichier_temporaire "$KeyID"
      [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
      [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
      log:info "($IdFct) FIN Personne Inconnu"
      return "$retCode"
   fi

   init_label "$sex" sex labelNaissance labelDeces labelMarie labelTypeEpoux
   log:debug "($IdFct) sex:[$sex] labelNaissance:[$labelNaissance] labelDeces:[$labelDeces] labelMarie:[$labelMarie]"

   sed -e "1,/^<!--  Portrait -->/d" -e "/^<!-- Parents /,10000d" -e "s/&nbsp;/ /g" "$fic_tmp_all" > "$fic_tmp"

   trouver_date "$fic_tmp" "$labelNaissance" GEDCOM_naissance tgNaissance bj bm by bj_Fin bm_Fin by_Fin villeNaissance julienNaissance
   log:debug "($IdFct) Naissance trouvé : GEDCOM_naissance:[$GEDCOM_naissance] tgNaissance:[$tgNaissance] bj:[$bj] bm:[$bm] by:[$by] bj_Fin:[$bj_Fin] bm_Fin:[$bm_Fin] by_Fin:[$by_Fin] villeNaissance:[$villeNaissance]"
   trouver_date "$fic_tmp" "$labelDeces" GEDCOM_deces tgDeces dj dm dy dj_Fin dm_Fin dy_Fin villeDeces julienDeces
   log:debug "($IdFct) Décès trouvé : GEDCOM_deces:[$GEDCOM_deces] tgDeces:[$tgDeces] dj:[$dj] dm:[$dm] dy:[$dy] dj_Fin:[$dj_Fin] dm_Fin:[$dm_Fin] dy_Fin:[$dy_Fin] villeDeces:[$villeDeces]"

   log:info "($IdFct): GEDCOM_naissance bj:[$bj] bm:[$bm] by:[$by] julienNaissance:[$julienNaissance] julienDeces:[$julienDeces]"
   local ville=$(grep "$labelNaissance le" "$fic_tmp" | sed -e 's/^.* - //g' -e 's/<\/li>.*$//g')

   # Je regarde si l'individu est déjà traité
   KeyID:search "$KeyID" "$URI"
   if [[ "$?" -eq 1 ]]; then
      findID=$(KeyID:get "$KeyID")
      log:info "($IdFct): $KeyID ($findID) Déjà traité [$URI]"
      eval "${1}=\"$findID\"" 2>/dev/null
      fam:write "fams=[$FAMS]&sex=[$sex]&KeyID=[$findID]"
      export tab=$(echo $tab | sed -e 's/   //')
      clean_fichier_temporaire "$KeyID"
      [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
      [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
      return "$CODE_DEJA_TRAITE"
   fi

   fam:write "fams=[$FAMS]&sex=[$sex]&KeyID=[$KeyID]"

   # Recherche des Sources pour l'individu
   cherche_source "$fic_tmp_all" srcIndi srcNaissance srcUnion srcDeces
   log:debug "($IdFct)Retour cherche_source srcIndi=[$srcIndi] srcNaissance=[$srcNaissance] srcUnion=[$srcUnion] srcDeces=[$srcDeces]"

   # Recherche Note pour l'individu
   cherche_note "$fic_tmp_all" noteIndi noteNaissance noteMariage noteDeces noteFamille
   log:debug "($IdFct) Retour cherche_note noteIndi=[$noteIndi] noteNaissance=[$noteNaissance] noteMariage=[$noteMariage] noteDeces=[$noteDeces] noteFamille:[$noteFamille]"

   [[ -n "$julienNaissance" ]] && note_naissance="[$julienNaissance][$note_naissance]"
   [[ -n "$julienDeces" ]] && noteDeces="[$julienDeces][$noteDeces]"

   ged:write "$KeyID" "KeyID=[$KeyID]&nom=[$nom]&prenom=[$prenom]&sex=[$sex]&source_individu=[$srcIndi]&note_individu=[$noteIndi]"
   ged:write "$KeyID" "date_naissance=[$GEDCOM_naissance]&ville_naissance=[$villeNaissance]&source_naissance=[$srcNaissance]&note_naissance=[$noteNaissance]"
   ged:write "$KeyID" "date_deces=[$GEDCOM_deces]&ville_deces=[$villeDeces]&source_deces=[$srcDeces]&note_deces=[$noteDeces]"

   if [[ "${Qui}" == "${QUI_PARENT}" || "${Qui}" == "${QUI_PERE}"  || "${Qui}" == "${QUI_PERE}" ]]; then      
      if ! siMarie "$fic_tmp_all"; then
         ged:write "$KeyID" "fams=[$FAMS]"
      fi
   elif [[ "${Qui}" == "${QUI_CONJOINT}" ]]; then
      # Je suis l'épouse
      ged:write "$KeyID" "fams=[$FAMS]"
   fi

   # Recherche Parent POur création du Fichier Famille
   FAMS_SUIVANTE=$(incFAM "$fic_fam")

   # recherche épouse 
   if [[ "$getEpoux" == "1" && "${Qui}" != "${QUI_CONJOINT}" ]]; then
      log:info "($IdFct): Bloc recherche des conjoints"
      #      echo "Recherche époux/épouse"
#      sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" > "$fic_tmp_epoux_tmp"
      sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" | grep -A2 "^$LB_MARIE\|^$LB_RELATION" | grep -v "^--"> "$fic_tmp_epoux_tmp"
      nbEpoux=$(grep -i "^$LB_MARIE\|^$LB_MARIE_AVEC" "$fic_tmp_epoux_tmp" | wc -l | bc)
      nbEpoux=$(( nbEpoux + 0))
      log:debug "($IdFct): Nb époux:[$nbEpoux]"

      # Si pas d'époux, je supprime le fichier FAMS
      if [[ "$nbEpoux" -eq 0 ]]; then
         # Je regarde si il a des enfants dans ce cas, je supprime pas le fichier seulement si il n'y as pas d'enfant d'un conjoint inconnu
         nbEnfantEpoux=$(sed -e '1,/<!--  Union/d' -e '/^<!--  Freres/,10000d' "$fic_tmp_all" | grep -v "=MOD_FAM" | sed -e 's/<a href=".*m=RL.*<img src="https/<img src="https/g' | grep -v "? ?" | grep "<a href=\"" | wc -l | bc)
         if [[ "$nbEnfantEpoux" -eq 0 ]]; then
            sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" | grep -v "=MOD_FAM" | sed -e 's/<a href=".*m=RL.*<img src="https/<img src="https/g'> "$fic_tmp_enfant_tmp"
            log:debug "($IdFct): Pas d'époux:[$nbEpoux] et pas d'enfants, je supprime le fichier [$(fam:filename "$FAMS")]"
            fam:rm "$FAMS"
         else
            log:debug "($IdFct): Pad d'époux:[$nbEpoux] mais avec des enfants, je ne supprime pas le fichier [$(fam:filename "$FAMS")]"
         fi
      else
         while IFS='' read -r ligne_html; do
#            log:debug "($IdFct) Lecture de la ligne [$ligne_html]"
            epoux_trouve=$(echo $ligne_html | grep -E "^$LB_MARIE|^$LB_RELATION|^$LB_FIANCE" | wc -l | bc)
#            epoux_trouve=$(echo $ligne_html | grep -E "^$LB_MARIE|^$LB_RELATION|^$LB_FIANCE|^$LB_MARIE_AVEC" | wc -l | bc)
            SansDate=$(echo $ligne_html | grep -E "^${LB_MARIE}${LB_MARIE_AVEC}" | wc -l | bc)
            ref_epoux=$(echo "$ligne_html" | grep -i "^${LB_MARIE}${LB_MARIE_AVEC}<a href=\|^${LB_RELATION}${LB_RELATION_AVEC}<a href=\|^${LB_MARIE_AVEC}<a href=\|^${LB_RELATION_AVEC}<a href=" | wc -l | bc)
#            ref_epoux=$(echo "$ligne_html" | grep -Ei "${LB_MARIE_AVEC}.*<a href=" | wc -l | bc)

            log:debug "($IdFct) epoux_trouve:[$epoux_trouve] SansDate:[$SansDate] ref_epoux:[$ref_epoux]"

            lineMarried=$(echo $ligne_html | grep "^$LB_MARIE\|^$LB_RELATION" | wc -l | bc)
            [[ "$lineMarried" -eq 1 ]] && numMariage=$(( numMariage + 1 ))

            if [[ "$epoux_trouve" -eq 1 && "$SansDate" -eq 0  ]]; then
               # echo "($IdFct): $ligne_html"
               echo "$ligne_html" | sed -e 's/&nbsp;/ /g' | sed -e 's/<em>//g' | sed -e "s/$LG_MARIED_F/$LG_MARIED_M/g"> "$fic_tmp_epoux"
               trouver_date "$fic_tmp_epoux" "$LG_MARIED_M" GEDCOM_mariage tgMariage mj mm my mj_Fin mm_Fin my_Fin villeMariage julienMariage
               log:info "($IdFct): GEDCOM_mariage:[$GEDCOM_mariage] tgMariage:[$tgMariage] mj:$mj] mm:[$mm] my:[$my] mj_Fin:[$mj_Fin] mm_Fin:[$mm_Fin] my_Fin:[$my_Fin] villeMariage:[$villeMariage]"
               ligne_precedente_marie_avec=1
               continue
            fi
            
            if [[ "$epoux_trouve" -eq 1 ]]; then
               # Si il trouve "Married alors typeMariage=1 (Mariage)"
               # Sinon typeMariage=° (relation)
               local typeMariage=$(echo $ligne_html | grep -E "^$LB_MARIE" | wc -l | bc)
            fi

            if [[ "$ref_epoux" -eq 1 ]]; then
               if [[ "$numMariage" -gt 1 ]]; then
                  # Plusieur mariage, j'incremente le N° Famille
                  firstFAMS="$FAMS"
                  FAMS=$(incFAM "$fic_fam")
                  fam:write "fams=[$FAMS]&sex=[$sex]&KeyID=[$KeyID]&Married=[$typeMariage]"
                  # Initialissation du fichier Famill
               else
                  [[ "$typeMariage" == "0" ]] && fam:write "fams=[$FAMS]&Married=[$typeMariage]"
               fi
               # Verifier si divorcé
               nbDivorce=$(echo "$ligne_html" | grep -i "${LB_DIVORCE}" | wc -l | bc)
               log:info "========> ligne_html:[$ligne_html] nbDivorce:[$nbDivorce]"
               if [[ "$nbDivorce" -eq 1 ]]; then
                  echo "$ligne_html" | sed -e 's/&nbsp;/ /g' | sed -e 's/<em>//g' | sed -e "s/^.*$LB_DIVORCE/$LB_DIVORCE/g" -e "s/ ${LB_AVEC}$//g"> "$fic_tmp_divorce"
                  trouver_date "$fic_tmp_divorce" "$LB_DIVORCE" GEDCOM_divorce tgDivorce sj sm sy sj_Fin sm_Fin sy_Fin villeDivorce julienDivorce
                  # recherche ville Divorce/note
                  nomConjoint=$(echo "$ligne_html" | sed -e 's/^.*">//g' -e 's/<.*$//g' | sed -e 's/ /\.\*/g')
                  villeDivorce=$(grep "Divorce.*${nomConjoint}.* - " "$fic_tmp_all" | wc -l | bc)
                  echo "villeDivorce:[$villeDivorce]"
                  if [[ "$villeDivorce" -eq 1 ]]; then
                     villeDivorce=$(grep -A2 "Divorce.*${nomConjoint}.* - " "$fic_tmp_all" | sed -e 's/^.* - //g' -e "s/<.*$//g")
                  else
                     villeDivorce=""  
                  fi
                  noteDivorce=$(grep -A2 "Divorce.*${nomConjoint}" "$fic_tmp_all" | grep "nnotes" | sed -e "s/^.*nnotes\">//g" -e "s/<.*$//g")
                  log:info "($IdFct): GEDCOM_divorce:[$GEDCOM_divorce] tgDivorce:[$tgDivorce] sj:[$]sj sm:[$sm] sy:[$sy] sj_Fin:[$ƒ] sm_Fin:[$sm_Fin] sy_Fin:[$sy_Fin] villeDivorce:[$villeDivorce] noteDivorce:[$noteDivorce]"
               fi
               local lien_epoux=$(echo $ligne_html | sed -e "s/<a href=\"/\n<a href=\"/g" | grep -v "&m=\l&t=|&i1=\|&i2=" | grep "&p=\|&n=\|&i=" | sed -e 's/^.*<a href="//g' | sed -e 's/">.*$//g')
               ligne_precedente_marie_avec=0

               # Pour l'épouse je n'increment pas le N°Famills (FAMS)
               log:info "($IdFct): Je recherche l'épouse de [$KeyID]  pour la famille FAMS[$FAMS] lien_epoux:[$lien_epoux]"               
               individu:search retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_CONJOINT}]?uri=[${lien_epoux}]?getParent=[${getParent}]?getEpoux=[${getEpoux}]?getFrere=[${getFrere}]?getEnfant=[0]?numFamille=[${FAMS}]"
               local retCode="$?"
               if [[ "$retCode" -gt 299 ]]; then
                  continue
               fi
#               CODE_INDIVIDU_INCONNU
               if [[ "$retCode" -eq 0 || "$retCode" -eq "$CODE_DEJA_TRAITE" ]]; then
                  # Ecriture dans fichier FAM, qui sera contatené dans le fichier ged à la fin
                  [[ -n "$julienDivorce" ]] && noteDivorce="[$julienDivorce][$noteDivorce]"
                  [[ -n "$julienMariage" ]] && noteMariage="[$julienNaissance][$noteMariage]"
                  log:info "($IdFct): Ecriture dans FAMS[$FAMS] KeyID:[$KeyID] info de mariage/divorce Mariage:[$noteMariage] Divorce:[$noteMariage]"
                  fam:write "fams=[$FAMS]&GEDCOM_mariage=[$GEDCOM_mariage]&villeMariage=[$villeMariage]&note_mariage=[$noteMariage]&GEDCOM_divorce=[$GEDCOM_divorce]&ville_divorce=[$villeDivorce]&note_divorce=[$noteDivorce]"
               fi
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
   else
      log:info "($IdFct): Je ne recherche pas les conjoints car [$Qui]"
   fi

   # Recherche Parent
   if [[ "$getParent" == "1" ]]; then
      log:info "($IdFct): Bloc recherche des parents"

      # echo "($IdFct): Famille en cours:[$FAMS] Famille du Pere/Mere:[$FAMS_SUIVANTE]"
      # Si les Parents sont mariè, cela fonctionne car
      #      cat $fic_tmp_all |
      sed -e "1,/^<!-- Parents /d" -e "/^<!--  Union /,10000d" -e '/<li style=/d' "$fic_tmp_all" >$fic_tmp_parent
      grep "href=\"" "$fic_tmp_parent" | head -1 >"$fic_tmp_parent_pere"
      grep "href=\"" "$fic_tmp_parent" | tail -1 >"$fic_tmp_parent_mere"
      local nb_parent=$(grep "href" "$fic_tmp_parent" | wc -l | bc)
      nb_parent=$((nb_parent+0))

      log:info "($IdFct): Parents nb_parent:[$nb_parent]"
      if [[ "$nb_parent" -ne 0 ]]; then
         FAMS_SUIVANTE=$(incFAM "$fic_fam")
         # Ecriture dans le fichier ged la famille, je suis l'enfant de la famille FAMS
         # Je nettoie la ligne car elle peut contenir 3 url (tree, lien, titre)
         # <a href ==> tree (&m=...)></a>     <a href==>Lien Parent (&p=...&n=...)> Nom Prenom</a>     <a href==>titre(&t=..)></a>
         # ==> je mets '<a href==' par ligne et ensuite j'exclue "&m=" et "&t=" et j'inclue "&p=" ou "&n="
         log:info "($IdFct): Nb Parent : [$nb_parent]"
         local  nom_pere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_pere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=" | grep "^.*href" | head -1 | sed -e 's/<bdo.*$//g' | sed -e 's/^.*fiche">//' | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//' )
         local lien_pere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_pere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=\|&i=" | grep "^.*href" | head -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
         local  nom_mere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_mere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=" | grep "^.*href" | tail -1 | sed -e 's/<bdo.*$//g' | sed -e 's/^.*fiche">//' | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//' )
         local lien_mere=$(sed -e "s/<a href=\"/\n<a href=\"/g" "$fic_tmp_parent_mere" | grep -v "&m=\|&t=||&i1=\|&i2=" | grep "&p=\|&n=\|&i=" | grep "^.*href" | tail -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
         log:info "($IdFct): nom_pere:[$nom_pere] lien_pere:[$lien_pere] nom_mere:[$nom_mere] lien_mere:[$lien_mere]"
         # Recherche le Père
         log:info "($IdFct) Cherche le pere avec nouveau N° FAMS:[$FAMS_SUIVANTE]"
         local findID
         individu:search retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_PARENT}]?uri=[${lien_pere}]?getParent=[${getParent}]?getEpoux=[${getEpoux}]?getFrere=[${getFrere}]?getEnfant=[0]?numFamille=[${FAMS_SUIVANTE}]"
         local retCode="$?"         
         if [[ "$retCode" -gt 299 ]]; then
            clean_fichier_temporaire "$KeyID"
            [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
            [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
            return "$retCode"
         fi

         [[ "$retCode" -eq "$CODE_DEJA_TRAITE" ]] && KeyID_Pere=$(KeyID:get "$retID") || KeyID_Pere=$retID
         log:info "($IdFct) I@$KeyID_Pere@ est le père de I@$KeyID@ Pour la famille FAMS:[$FAMS_SUIVANTE]"

         # Recherche le Père
         log:info "($IdFct) Cherche la mere avec nouveau N° FAMS :[$FAMS_SUIVANTE]"
         local findID
         individu:search retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_PARENT}]?uri=[${lien_mere}]?getParent=[${getParent}]?getEpoux=[${getEpoux}]?getFrere=[${getFrere}]?getEnfant=[0]?numFamille=[${FAMS_SUIVANTE}]"
         local retCode="$?"
         if [[ "$retCode" -gt 299 ]]; then
            clean_fichier_temporaire "$KeyID"
            [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
            [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
            return "$retCode"
         fi
         [[ "$retCode" -eq "$CODE_DEJA_TRAITE" ]] && KeyID_Mere=$(KeyID:get "$retID") || KeyID_Mere=$retID
         log:info "($IdFct) I@$retID@ (I@$retID@) est le la mère de I@$KeyID@ Pour la famille FAMS:[$FAMS_SUIVANTE]"

         local Old_FAMS_SUIVANTE="$FAMS_SUIVANTE"
         if [[ "$KeyID_Mere" -eq 0 ]]; then
            fam:whithout_spouse "$KeyID_Pere" "WIFE" FAMS_SUIVANTE
            if [[ -z "$FAMS_SUIVANTE" ]]; then
               log:info "Famille avec père celibatire ($KeyID_Pere) de l'enfant ($retID) non trouvé, donc création"
               FAMS_SUIVANTE=$(incFAM "$fic_fam")
               fam:write "fams=[$FAMS_SUIVANTE]&sex=[M]&KeyID=[$KeyID_Pere]"
            fi

            # Je créé une mère fictif
            KeyID:inc "$fic_id" KeyID_Mere
            log:info "Création mère fictif avec N°KeyID:[$KeyID_Mere]"
            ged:write "$KeyID_Mere" "KeyID=[$KeyID_Mere]&nom=[INCONNU]&=prenom=[INCONNU]&sex=[F]"
            fam:write "fams=[$FAMS_SUIVANTE]&sex=[F]&KeyID=[$KeyID_Mere]"
            log:info "La famille trouvé sans mère est Old_FAMS_SUIVANTE:[$Old_FAMS_SUIVANTE] FAMS_SUIVANTE:[$FAMS_SUIVANTE]"
         elif  [[ "$KeyID_Pere" -eq 0 ]]; then
            fam:whithout_spouse "$KeyID_Mere" "HUSB" FAMS_SUIVANTE
            if [[ -z "$FAMS_SUIVANTE" ]]; then
               log:info "Famille avec mère celibatire ($KeyID_Mere) de l'enfant ($retID) non trouvé, donc création"
               FAMS_SUIVANTE=$(incFAM "$fic_fam")
               fam:write "fams=[$FAMS_SUIVANTE]&sex=[F]&KeyID=[$KeyID_Mere]"
            fi
            # Je créé une mère fictif
            KeyID:inc "$fic_id" KeyID_Pere
            log:info "Création père fictif avec N°KeyID:[$KeyID_Pere]"
            ged:write "$KeyID_Pere" "KeyID=[$KeyID_Pere]&nom=[INCONNU]&=prenom=[INCONNU]&sex=[F]"
            fam:write "fams=[$FAMS_SUIVANTE]&sex=[M]&KeyID=[$KeyID_Pere]"
            log:info "La famille trouvé sans père est Old_FAMS_SUIVANTE:[$Old_FAMS_SUIVANTE] FAMS_SUIVANTE:[$FAMS_SUIVANTE]"
         fi

         if [[ ! -f "$(fam:filename "$FAMS")" ]]; then
            log:info "($IdFct) Le fichier Famille $(fam:filename "$FAMS") n'existe pas"
            # Je suis la soeur de quelqu'un qui a déjà été traite, je recherche le fichier famille
            fam:search "$KeyID_Pere" "$KeyID_Mere" FAMS_SUIVANTE
            if [[ -n "$FAMS_SUIVANTE" ]]; then
               log:info "($IdFct) Je($KeyID) suis l'enfant de la famille ($FAMS_SUIVANTE)"
               fam:write "fams=[$FAMS_SUIVANTE]&child=[$KeyID]"
               ged:write "$KeyID" "famc=[$FAMS_SUIVANTE]"
            else
               log:error "($IdFct) Le fichier Famille $(fam:filename "$FAMS") n'existe pas et pas de fichier famille trouver avec les parents [$KeyID_Pere] [$KeyID_Mere]"
               clean_fichier_temporaire "$KeyID"
            [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
            [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
               return 1
            fi
         else
            # Je recherche le fichier Famille de l'enfant
            # Car si je suis l'enfant de la 2ème épouse, le $FAMS_SUIVANTE poine sur la 1ère épouse
            log:info "($IdFct) Ecriture de : je suis l'enfant($KeyID) de la famille Pere($KeyID_Pere) Mere($KeyID_Mere) dans fichier famille FAMS:[$FAMS_SUIVANTE]"
            fam:search "$KeyID_Pere" "$KeyID_Mere" FAMS_SUIVANTE
            if [[ -n "$FAMS_SUIVANTE" ]]; then
               fam:write "fams=[$FAMS_SUIVANTE]&child=[$KeyID]"
               ged:write "$KeyID" "famc=[$FAMS_SUIVANTE]"
            else
               log:info "Enfant sans fichier famille Enfant:[$KeyID] Père:[$KeyID_Pere] Mère:[$KeyID_Mere]"
               fam:write "fams=[$FAMS_SUIVANTE]&sex=[M]&KeyID=[$keyID_Pere]"
               fam:write "fams=[$FAMS_SUIVANTE]&sex=[F]&KeyID=[$keyID_Mere]"
               fam:write "fams=[$FAMS_SUIVANTE]&child=[$KeyID]"
               [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
               [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
            fi
         fi
      else
         log:info "($IdFct): Pas de Parent"
      fi
      log:info "($IdFct): Fin Recherche Parent"
   else
      log:info "Je ne recherche pas les parents"
   fi

   # Je ne recherche pas enfant du début de la branche
   # TO-DO ==> Doit être une option
   if [[ "$getEnfant" == "1" && "$keyID" != "1" ]]; then
      log:info "($IdFct): Recherche des enfants"
      sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" | grep -v "=MOD_FAM" | sed -e 's/<a href=".*m=RL.*<img src="https/<img src="https/g'> "$fic_tmp_enfant_tmp"
      html_ligne_prec=""
      while IFS='' read -r html_ligne; do
         if [[ "$html_ligne" == *" href=\""* ]]; then
            ligPrecMarie=$(echo $html_ligne_prec | grep "^$LB_MARIE\|^$LB_RELATION" | wc -l | bc)
            if [[ "$ligPrecMarie" -ne 0 ]]; then               # log:info "Ligne précédente Married...ligPrecMarie[$ligPrecMarie] html_ligne:[$html_ligne]"
               ligPrecMarie=$html_ligne
               continue
            fi
            lien=$(echo $html_ligne | sed -e "s/<a href=\"/\n<a href=\"/g" | grep -v "&m=\l&t=|&i1=\|&i2=" | grep "&p=\|&n=" | sed -e 's/^.*href=\"//g' -e 's/".*$//g')
            FAMS_SUIVANTE=$(incFAM "$fic_fam")
#            ch_Parent=0; ch_Epoux=0; ch_Enfant=0
            individu:search retID "ficGedcom=[$fic_gedcom]?Qui=[${QUI_PARENT}]?uri=[${lien}]?getParent=[${ch_Parent}]?getEpoux=[${ch_Epoux}]?getFrere=[${ch_Frere}]?getEnfant=[${ch_Enfant}]?numFamille=[${FAMS_SUIVANTE}]"
            local retCode="$?"
            [[ "$retCode" -eq "$CODE_DEJA_TRAITE" ]] && KeyID_Enfant=$(KeyID:get "$retID") || KeyID_Enfant=$retID
            log:info "Retourn apple individu:search [$retCode] Moi:[$keyID] Enfant:[$KeyID_Enfant] lien:[$lien]"
            [[ "$retCode" -eq 0 || "$retCode" -eq "$CODE_DEJA_TRAITE" ]] && fam:write "fams=[$FAMS]&child=[$KeyID_Enfant]"
            if [[ "$retCode" -gt 299 ]]; then
               clean_fichier_temporaire "$KeyID"
               [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
               [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
               return "$retCode"
            fi
         fi
         html_ligne_prec=$html_ligne
      done <"$fic_tmp_enfant_tmp"
   else
      log:info "($IdFct): Je ne recherche pas les enfants"
   fi

   # recherche frère & soeur
   if [[ "$getFrere" == "9" ]]; then
      #      echo "Recherche frère/soeur"
      sed -e "1,/^<!--  Freres et soeurs /d" -e "/^<!--  Relations/,10000d" "$fic_tmp_all" > "$fic_tmp_frere"
   else
      log:info "($IdFct): Je ne recherche pas les frères/soeurs"
   fi

#   rm "$fic_tmp_all" "$fic_tmp_parent" "$fic_tmp_union" "$fic_tmp_parent_pere" "$fic_tmp_parent_mere" "$fic_tmp_epoux" "$fic_tmp_divorce" "$fic_tmp_epoux_tmp" "$fic_tmp_frere" "$fic_tmp_enfant_tmp" "$fic_tmp_note" 2>/dev/null 1>&2 || true

   log:info "FIN individu:search($IdFct): $KeyID"
   export tab=$(echo $tab | sed -e 's/   //')

   clean_fichier_temporaire "$KeyID"
   [[ "$nbAsc" -gt 0 ]] && nbAsc=$(( nbAsc - 1 ))
   [[ "$nbDesc" -gt 0 ]] && nbDesc=$(( nbDesc - 1 ))
   return 0
}

enfant:get() {
   local KeyID=$(getParam "KeyID" "$1")
   local FAMS=$(getParam "fams" "$1")
   local getParent=$(getParam "getParent" "$1")
   local getEpoux=$(getParam "getEpoux" "$1")
   local getFrere=$(getParam "getFrere" "$1")
   local getEnfant=$(getParam "getEnfant" "$1")

   local pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
   local fic_tmp_all=$(file:get $KeyID all_page)
   local fic_tmp_enfant_tmp=$(file:get $KeyID enfant)
   local html_ligne="" html_ligne_prec="" NivEnfant=0 BeauParent=0 ConjointEnfant=0 
   local _retIndividu="" KeyID_Enfant="" lienEnfant="" ligPrecMarie=""


      log:info "($KeyID): Recherche des enfants"
      sed   -e '1,/<!--  Union/d' -e '/^<!--  Freres/,10000d' \
            -e "s/<span[^>]*>//g" \
            -e "s/<img[^>]*>//g" \
            -e "s/<a.*ref.*&i1=[^>]*>//g" \
            -e "s/<li.*style.*square[^>]*>//g" \
            -e '/^$/d' \
            -e '/^ to/,+1d' \
            -e "/=MOD_FAM/d" "$fic_tmp_all" > "$fic_tmp_enfant_tmp"
      html_ligne_prec=""
      NivEnfant=0 
      BeauParent=0 
      ConjointEnfant=0
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
            lienEnfant=$(echo "$html_ligne" | sed -e "s/<a href=\"/\n<a href=\"/g" | grep -v "&m=\|&t=|&i1=\|&i2=" | grep "&p=\|&n=" | sed -e 's/^.*href=\"//g' -e 's/".*$//g')
            findID=$(Index:Search:URI "URI=[$lienEnfant]")
            if [[ -z "$findID" ]]; then
               log:info "Nv:[$NivEnfant] Je recherche l'enfant ($lienEnfant) findID($findID)"
               FAMS_SUIVANTE=$(incFAM "$fic_fam")
#               _retIndividu=$(individu:search "KeyID_Appel=[$KeyID]&Qui=[${QUI_PARENT}]&uri=[${lienEnfant}]&getParent=[${getParent}]&getEpoux=[${getEpoux}]&getFrere=[${getFrere}]&getEnfant=[${getEnfant}]&numFamille=[${FAMS_SUIVANTE}]")
               _retIndividu=$(individu:search "KeyID_Appel=[$KeyID]&Qui=[${QUI_PARENT}]&uri=[${lienEnfant}]&getParent=[0]&getEpoux=[1]&getFrere=[0]&getEnfant=[1]&numFamille=[${FAMS_SUIVANTE}]")
               local retCode="$?"
               KeyID_Enfant=$(getParam "KeyID" "$_retIndividu")
               log:info "Retourn apple individu:search [$retCode] Moi:[$KeyID] Enfant:[$KeyID_Enfant] lienEnfant:[$lienEnfant]"
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
         html_ligne_prec=$html_ligne
      done <"$fic_tmp_enfant_tmp"
}
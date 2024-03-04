cherche_enfant() {
   local param="$1"
   local ficGedcom=$(echo "$param" | grep -i "ficGedcom=" | sed -e 's/^.*ficGedcom=\[//i' -e 's/\].*$//g')
   local fic_in=$(echo "$param" | grep -i "ficEnfant=" | sed -e 's/^.*ficEnfant=\[//i' -e 's/\].*$//g')
   local numFAMS=$(echo "$param" | grep -i "FAMS=" | sed -e 's/^.*FAMS=\[//i' -e 's/\].*$//g')

   local fic_tmp="${fic_in}${RANDOM}${RANDOM}"
   local TYPE_BLOC
   local uri
   local ch_Parent=0
   local ch_Epoux=1
   local ch_Frere=0
   local ch_Enfant=1
   local ch_Frere=1
   local num_ID=0
   local numFAMS=0

   log "================== CHERCHE ENFANT =================="
   log "ficGedcom:[$ficGedcom] fic_in:[$fic_in] numFAMS:[$numFAMS]"
   touch "$fic_tmp"
   if [[ -f "$fic_in" ]]; then
      log "[$fic_in] existe, je le recopie dans [$fic_tmp]"
      cat "$fic_in" > "$fic_tmp"
   else
      while IFS='' read -r data; do
         echo "$data" >>"$fic_tmp"
      done
   fi

   TYPE_BLOC="NULL"
   while IFS='' read -r html_ligne; do
      log "html_ligne:[$html_ligne]"

      if [[ "${html_ligne}" == *"${LB_MARIE}$LB_MARIE_AVEC"* && "$TYPE_BLOC" == "" ]]; then
         TYPE_BLOC="FICHE_UNION"
         #         echo "Début Conjoint"
         continue
      fi
      if [[ "${html_ligne}" == *"$LB_MARIE"* && "$TYPE_BLOC" == "" ]]; then
         TYPE_BLOC="FICHE_UNION_AVEC"
         #         echo "Début Conjoint"
         continue
      fi
      if [[ "${html_ligne}" == *"$LB_MARIE_AVEC"* && "$TYPE_BLOC" == "FICHE_UNION_AVEC" ]]; then
         TYPE_BLOC="FICHE_UNION_AVEC"
         #         echo "Début Conjoint"
         continue
      fi
      if [[ "${html_ligne}" == *"<ul"* && "$TYPE_BLOC" == "NULL" ]]; then
         TYPE_BLOC="FICHE_UNION"
         #         echo "Début Conjoint"
         continue
      fi
      if [[ "${html_ligne}" == *"<ul"* && "$TYPE_BLOC" == "FICHE_UNION" ]]; then
         TYPE_BLOC="ENFANT"
         #         echo "    Début Enfant"
         continue
      fi
      if [[ "${html_ligne}" == *"$LB_MARIE "* && "$TYPE_BLOC" == "FICHE_UNION" ]]; then
         if echo "${html_ligne}" | grep -q 'a href=\"'; then
            echo "   Epouse : $(echo "${html_ligne}" | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//g')"
         else
            TYPE_BLOC="MARIE_AVEC"
         fi
         continue
      fi

      # Bloc Conjoint Petit efant
      if [[ "${html_ligne}" == *"$LB_MARIE_AVEC"* && "$TYPE_BLOC" == "PETIT_ENFANT" ]]; then
         TYPE_BLOC="PETIT_ENFANT_CONJOINT"
         echo "               Début Conjoint Petit enfant (avec)"
         continue
      fi

      if [[ "${html_ligne}" == *"a  href="* && "$TYPE_BLOC" == "PETIT_ENFANT_CONJOINT" ]]; then
         TYPE_BLOC="PETIT_ENFANT"
         echo "               Conjoint Petit enfant $(echo "${html_ligne}" | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//g')"
         if [[ "${html_ligne}" == *"dont"* ]]; then
            TYPE_BLOC="PETIT_PETIT_ENFANT"
            echo "            Début Petit Petit enfant (dont)"
         fi
         continue
      fi
      # Fin Bloc Conjoint Petit efant

      # Bloc Petit Petit Enfant
      if [[ "${html_ligne}" == *"a  href="* && "$TYPE_BLOC" == "PETIT_PETIT_ENFANT" ]]; then
         uri=$(echo "${html_ligne}" | grep "^.*href" | head -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
         # Je dois gerer le N°Individu
         ch_Parent=0
         ch_Epoux=1
         ch_Frere=0
         ch_Enfant=1
         num_ID=0
         num_FAMC=0
         numFAMS=0
         log "uri:[$uri] ch_Parent:[$ch_Parent] ch_Epoux:[$ch_Epoux] ch_Frere:[$ch_Frere] ch_Enfant:[$ch_Enfant ] num_ID:[$num_ID] num_FAMC:[$num_FAMC] numFAMS:[$numFAMS]"
         individu:search retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_ENFANT}]?uri=[${uri}]?getParent=[${getParent}]?getEpoux=[${getEpoux}]?getFrere=[${getFrere}]?getEnfant=[1]?numFamille=[${numFAMS}]"
         local retCode="$?"
         if [[ "$retCode" -ne 0 ]]; then
            log "Erreur retour individu:search:[$retCode]"
            return "$retCode"
         fi
         #         individu:search retID "$QUI_ENFANT" "$uri" "$ch_Parent" "$ch_Epoux" "$ch_Frere" "$ch_Enfant" "$num_ID" "$num_FAMC" "$numFAMS"
         echo "                  Petit Petit enfant $(echo "${html_ligne}" | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//g')"
         echo "                     Lien Petit Petit enfant $uri"
         if [[ "${html_ligne}" == *"dont"* ]]; then
            TYPE_BLOC="PETIT_PETIT_ENFANT"
            echo "            Début Petit Petit enfant (dont)"
         fi
         continue
      fi
      if [[ "${html_ligne}" == *"</ul"* && "$TYPE_BLOC" == "PETIT_PETIT_ENFANT" ]]; then
         TYPE_BLOC="PETIT_ENFANT"
         continue
      fi
      # Fin Bloc Petit Petit Enfant

      # Bloc Petit Petit Enfant
      if [[ "${html_ligne}" == *"<ul"* && "$TYPE_BLOC" == "PETIT_ENFANT" ]]; then
         TYPE_BLOC="PETIT_PETIT_ENFANT"
         echo "+         Début Petit Petit enfant (*<ul*)"
         continue
      fi

      # Bloc Petit Enfant
      if [[ "${html_ligne}" == *"<ul"* && "$TYPE_BLOC" == "ENFANT" ]]; then
         TYPE_BLOC="PETIT_ENFANT"
         #         echo "         Début Petit enfant"
         continue
      fi
      if [[ "${html_ligne}" == *"<a  href="* && "$TYPE_BLOC" == "PETIT_ENFANT" ]]; then
         echo "               Petit enfant $(echo "${html_ligne}" | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//g')"
         continue
      fi
      if [[ "${html_ligne}" == *"</ul"* && "$TYPE_BLOC" == "PETIT_ENFANT" ]]; then
         TYPE_BLOC="ENFANT"
         #         echo "         Fin Petite enfant"
         continue
      fi
      # FinBloc Petit Enfant

      if [[ "${html_ligne}" == *"</ul"* && "$TYPE_BLOC" == "ENFANT_CONJOINT" ]]; then
         TYPE_BLOC="ENFANT"
         #         echo "      Fin Conjoint de l'enfant"
         continue
      fi
      if [[ "${html_ligne}" == *"</ul"* && "$TYPE_BLOC" == "ENFANT" ]]; then
         TYPE_BLOC="FICHE_UNION"
         #         echo "    Fin Enfant"
         continue
      fi
      if [[ "${html_ligne}" == *"</ul"* && "$TYPE_BLOC" == "FICHE_UNION" ]]; then
         TYPE_BLOC="NULL"
         #         echo "Fin Conjoint"
         continue
      fi
      if [[ "${html_ligne}" == *"</ul"* && "$TYPE_BLOC" == "PETIT_ENFANT" ]]; then
         TYPE_BLOC="ENFANT"
         #         echo "         Fin Petite enfant"
         continue
      fi

      # Bloc Parent du conjoitn d'un enfant
      if [[ "${html_ligne}" == *"(Parents :"* && "$TYPE_BLOC" == "FICHE_UNION" ]]; then
         #         echo "      Parent du Conjoint"
         TYPE_BLOC="CONJOINT_PARENT"
         continue
      fi
      if [[ "${html_ligne}" == *"dont"* && "$TYPE_BLOC" == "CONJOINT_PARENT" ]]; then
         TYPE_BLOC="FICHE_UNION"
         #         echo "      Fin Parent du Conjoint"
         continue
      fi
      # Fin Bloc Parent du conjoitn d'un enfant

      # Bloc Conjoint de l'enfant
      if [[ "${html_ligne}" == *"avec</em>"* && "$TYPE_BLOC" == "ENFANT" ]]; then
         #         echo "         Conjoint de l'enfant"
         TYPE_BLOC="ENFANT_CONJOINT"
         continue
      fi
      if [[ "${html_ligne}" == *"<a  href="* && "$TYPE_BLOC" == "ENFANT_CONJOINT" ]]; then
         uri=$(echo "${html_ligne}" | grep "^.*href" | head -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
         # Je dois gerer le N°Individu
         ch_Parent=1
         ch_Epoux=0
         ch_Frere=1
         ch_Enfant=0
         num_ID=0
         num_FAMC=0
         numFAMS=0
         log "uri:[$uri] ch_Parent:[$ch_Parent] ch_Epoux:[$ch_Epoux] ch_Frere:[$ch_Frere] ch_Enfant:[$ch_Enfant ] num_ID:[$num_ID] num_FAMC:[$num_FAMC] numFAMS:[$numFAMS]"
         #         individu:search retID "$QUI_ENFANT" "$uri" "$ch_Parent" "$ch_Epoux" "$ch_Frere" "$ch_Enfant" "$num_ID" "$num_FAMC" "$numFAMS"
         echo "            Conjoint : $(echo "${html_ligne}" | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//g')"
         echo "               Lien Conjoint : $uri"
         TYPE_BLOC="ENFANT"
         continue
      fi
      if [[ "${html_ligne}" == *"dont"* && "$TYPE_BLOC" == "ENFANT_CONJOINT" ]]; then
         TYPE_BLOC="ENFANT"
         #         echo "         Fin Conjoint de l'enfant"
         continue
      fi
      # Fin Bloc Conjoint de l'enfant

      if [[ "${html_ligne}" == *"<a  href="* && "$TYPE_BLOC" == "ENFANT" ]]; then
         echo "       Enfant trouve : $(echo "${html_ligne}" | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//g')"
         continue
      fi
      # Bloc Conjoint
      if [[ "${html_ligne}" == *"avec <a  href="* && "$TYPE_BLOC" == "MARIE_AVEC" ]]; then
         echo "   Conjoint : $(echo "${html_ligne}" | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//g')"
         TYPE_BLOC="FICHE_UNION"
         continue
      fi
      # Fin Bloc Conjoint
   done <"$fic_tmp"

   rm "$fic_tmp"

}

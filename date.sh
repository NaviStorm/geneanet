trace_date="true"

mois_court() {
   local local_mois_court_dm=""
   case "$1" in
      "$LG_MOIS_01") local_mois_court_dm="JAN" ;;
      "$LG_MOIS_02") local_mois_court_dm="FEB" ;;
      "$LG_MOIS_03") local_mois_court_dm="MAR" ;;
      "$LG_MOIS_04") local_mois_court_dm="APR" ;;
      "$LG_MOIS_05") local_mois_court_dm="MAY" ;;
      "$LG_MOIS_06") local_mois_court_dm="JUN" ;;
      "$LG_MOIS_07") local_mois_court_dm="JUL" ;;
      "$LG_MOIS_08") local_mois_court_dm="AUG" ;;
      "$LG_MOIS_09") local_mois_court_dm="SEP" ;;
      "$LG_MOIS_10") local_mois_court_dm="OCT" ;;
      "$LG_MOIS_11") local_mois_court_dm="NOV" ;;
      "$LG_MOIS_12") local_mois_court_dm="DEC" ;;
      *) local_mois_court_dm="" ;;
   esac
   eval "$2=\"$local_mois_court_dm\""
}

recupere_date_from_chaine() {
   local mDate="$1"
   local nbMot="$2"
   local fmtUK="$3"
   local local_jour=""
   local local_jour_tmp=""
   local local_mois=""
   local local_annee=""

   log:info "mDate:[$mDate] nbMot:[$nbMot] fmtUK:[$fmtUK]"
   local_jour=$(echo "$mDate" | sed -e "s/ .*$//g")
   local_annee=$(echo "$mDate" | sed -e "s/^.* //g")
   local_mois=$(echo "$mDate" | sed -e 's/'$local_jour' //g' | sed -e 's/ '$local_annee'//g')

   if [[ "$nbMot" -eq 1 ]]; then
      # log:info "   Date : aaaa"
      local_mois=""
      local_jour=""
   elif [[ "$nbMot" -eq 2 ]]; then
      # log:info "   Date: mm aaaa"
      local_ba="${local_mois/,/}"
      local_mois="${local_jour/,/}"
      local_jour=""
   else
      if [[ "$fmtUK" -eq 1 ]]; then
         local_jour_tmp="${local_jour/,/}"

         local_jour="${local_mois/,/}"
         local_mois="${local_jour_tmp/,/}"
      fi
   fi

   mois_court "$local_mois" local_mois
   if [[ "$local_jour" == "$NUMBER" ]]; then
      if [[ "$local_jour" -gt 31 ]]; then
         local local_jour=""
      fi
   fi

   log:info "local_jour:[$local_jour] local_mois:[$local_mois] local_annee:[$local_annee]"
   eval "$4=\"$local_jour\""
   eval "$5=\"$local_mois\""
   eval "$6=\"$local_annee\""
}


jour_mois_Annee() {
   local date_sans_mois
   local dateEntre
   local local_bj
   local local_ba
   local local_bm
   local local_bj_fin
   local local_ba_fin
   local local_bm_fin
   local nb_Mot_deb
   local entre_fin
   local entre_debut
   local nb_Mot_deb
   local nb_Mot_fin

   # log:info "jour_mois_Annee() PARAM:[$1]"
   # A cause de Juillet et le mot recherche "le", je supprime le mois de juillet pour faire le test
   date_sans_mois=$(echo $1 | sed -e 's/juillet//g' | sed -e 's/aout//g')
   dateEntre=$(echo "$date_sans_mois" | grep "${LG_OU}${LG_LE}\|${LG_OU}${LG_EN}\|${LG_ET}" | wc -l | bc)
   log:info "date_sans_mois:[$date_sans_mois] dateEntre:[$dateEntre]"
   # log:info "   dateEntre:[$dateEntre]"
   if [[ -z "$dateEntre" && "$dateEntre" != "" ]]; then
      echo "Pas un entier dateEntre:[$dateEntre]!"
      return 1
   fi
   fmtUK=$(echo "$1" | grep ',' | wc -l | bc)
   mDate=$(echo "$1" | sed -e "s/${LG_EN}//g" -e "s/,//g")
   nbMot=$(echo "$mDate" | wc -w | bc)

   if [[ "$dateEntre" -eq 0 ]]; then
      # log:info "   date simple"
      log:info "mDate:[$mDate]"
      recupere_date_from_chaine "$mDate" "$nbMot" "$fmtUK" local_bj local_bm local_ba
      log:info "nb_Mot_deb:[$nb_Mot_deb] local_bj:[$local_bj] local_bm:[$local_bm] local_ba:[$local_ba]"
   else
      # log:info "   date entre"
      entre_fin=$(echo $1 | sed -e "s/^.* et le //g" | sed -e "s/^.* et //g" | sed -e 's/^.* ou le //g' | sed -e 's/^.* ou en //g' | sed -e 's/^.* ou //g')
      entre_debut=$(echo $1 | sed -e 's/'"$entre_fin"'//g' | sed -e 's/ et ''//g' | sed -e 's/le //g' | sed -e 's/en //g' | sed -e 's/ ou //g')

      entre_fin=$(echo $1 | sed -e "s/^.*${LG_ET}${LG_LE}//g" -e "s/^.*${LG_ET}//g" -e "s/^.*${LG_OU}${LG_LE}//g" | sed -e "s/^.*${LG_OU}${LG_EN}//g" -e "s/^.*${LG_OU}//g" -e "s/${LG_EN}//g")
      [[ "$LG_LE" == "" ]] && LG_LE="sdkjfglksdjglkdjfglkfdgjlfdkjsglk"
      entre_debut=$(echo $1 | sed -e 's/'"$entre_fin"'//g' | sed -e "s/${LG_ET}//g" -e "s/${LG_EN}//g" -e "s/${LG_OU}//g" -e "s/${LG_LE}//g" | sed -e 's/ $//g')

      nb_Mot_deb=$(echo "$entre_debut" | wc -w | bc)
      nb_Mot_fin=$(echo "$entre_fin" | wc -w | bc)
      log:info "entre_debut:[$entre_debut] nb_Mot_deb:[$nb_Mot_deb] entre_fin:[$entre_fin] nb_Mot_fin:[$nb_Mot_fin] fmtUK:[$fmtUK]"

      recupere_date_from_chaine "$entre_debut" "$nb_Mot_deb" "$fmtUK" local_bj local_bm local_ba
      recupere_date_from_chaine "$entre_fin" "$nb_Mot_fin" "$fmtUK" local_bj_fin local_bm_fin local_ba_fin
   fi

   eval "$2=\"$local_bj\""
   eval "$3=\"$local_bm\""
   eval "$4=\"$local_ba\""

   if [[ "$dateEntre" -ne 0 ]]; then
      eval "$5=\"$local_bj_fin\"" 2>/dev/null
      eval "$6=\"$local_bm_fin\"" 2>/dev/null
      eval "$7=\"$local_ba_fin\"" 2>/dev/null
   fi

   # log:info "Fin jour_mois_Annee()"
}

determine_lable_date() {
   local Quand="$1"
   local Ou="$2"
   local tag="null"

   log:info "Quand:[$Quand] Ou:[$Ou]"
   [[ "$Ou" == "0" ]] && Ou=""

   log:info "QuandOu:[${Quand}${Ou}]"
   case "${Quand}${Ou}" in
      "${dt_label_date} 1" ) :
         # Actuce au cas ou la date est "Born date or date"
         tag="DATE BET"
         ;;
      "${dt_label_date} ${LG_VERS}" ) :
         tag="DATE ABT" 
         ;;
      "${dt_label_date} ${LG_PEUT_ETRE_EN}" | "${dt_label_date} ${LG_PEUT_ETRE_LE}" ) :
         tag="DATE EST"
         ;;
      "${dt_label_date} ${LG_AVANT}") :
         tag="DATE BEF"
         ;;
      "${dt_label_date} ${LG_APRES}") :
         tag="DATE AFT"
         ;;
      "${dt_label_date} ${LG_ENTRE}" | "${dt_label_date} ${LG_ENTRE}${LG_LE}" | "${dt_label_date}${LG_EN}" | "${dt_label_date} ${LG_EN}1" | "${dt_label_date} ${LG_LE}1" ) :
         tag="DATE BET"
         ;;
      "${dt_label_date} ${LG_EN}" | "${dt_label_date} ${LG_LE}" | "${dt_label_date} ") :
         tag="DATE "
         ;;
      *)
         tag="null"
         ;;
   esac
   log:info "Quand:[$Quand] tag:[$tag]"
   eval "$3=\"$tag\""
}


trouver_date() {
   trace_trouver_date="true"
   local fic="$1"
   local dt_label_date="$2"
   local dt_fic_tmp="${TMP_DIR}/gen_date_${RANDOM}${RANDOM}"
   local dt_naissance=""
   local dt_tag=""
   local dt_jour=""
   local dt_mois=""
   local dt_annee=""
   local dt_jour_FIN=""
   local dt_mois_FIN=""
   local dt_annee_FIN=""
   local dt_ville=""
   local NoDate=0
   local dtJulien=0
   local strNull=""


   log:info "fic:[$fic] dt_label_date:[$dt_label_date]"
   sed -e "s/<em>//g" -e "s/<\/em>//g" -e "s/<\/i>//g" -e "s/<i>//g"  -e 's/<\/li>//g' -e 's/<li>//g' -e 's/1er/1/g' -e 's/\&nbsp\;/ /g' "$fic"  | sed -e 's/\//CHARSLASH/g' | { grep "$dt_label_date\( \|,\)" || test $? = 1; } >"$dt_fic_tmp"

   # Si date Julien, je ne fais aucun traitement et je la retourne 
   # dans paramètre $12 pour la mettre dans la note 
   dtJulien=$(cat $dt_fic_tmp | grep " Julian (" | wc -l | bc)

   nbLigne=$(cat $dt_fic_tmp | wc -l | bc)
   log:info "Contenue du fichier $dt_fic_tmp: $(cat $dt_fic_tmp) NbLigne:[$(cat $dt_fic_tmp | wc -l | bc)]"
   if [[ "$nbLigne" -ne 0  && "$dtJulien" -eq 0 ]]; then
         local ville=$(sed "s/^$dt_label_date.* [1-2][0-9][0-9][0-9],//g" "$dt_fic_tmp" | grep -v "$dt_label_date")
      if [[ "$dt_label_date" == "$LG_MARIED_M" ]]; then
         local ville=$(sed "s/^$dt_label_date.* [1-2][0-9][0-9][0-9],//g" "$dt_fic_tmp" | grep -v "$dt_label_date")
         [[ -n "$ville" ]] && echo "$(sed -e "s/$ville.*$//g" "$dt_fic_tmp" | sed -e "s/,$//g" ) - $ville" >  "$dt_fic_tmp"
      fi
      log:info "Contenue du fichier $dt_fic_tmp: $(cat $dt_fic_tmp) NbLigne:[$(cat $dt_fic_tmp | wc -l | bc)]"

      # String contain only the town & not the date of the event
      # Ex: Married, Lyon, France
      NoDate=$(grep "${dt_label_date},\|${dt_label_date} -" "$dt_fic_tmp" | wc -l | bc)
      if [[ "$NoDate" -eq 0 ]]; then
         # Pour version UK ou LG_LE est null et fait planter le sed sous macos
         LG_THE=${LG_LE:- }
         # Et j'enleve tout les mois pour ne pas avoir de caractere parasite quand je recherche le moment de la date (entre, né le, ......)
         mDate=$(grep "${dt_label_date} " "$dt_fic_tmp" | 
            sed -E "s/($LG_MOIS_01|$LG_MOIS_02|$LG_MOIS_03|$LG_MOIS_04|$LG_MOIS_05|$LG_MOIS_06|$LG_MOIS_07|$LG_MOIS_08|$LG_MOIS_09|$LG_MOIS_10|$LG_MOIS_11|$LG_MOIS_12)//g" | \
            sed -E "s/$dt_label_date ($LG_VERS|$LG_PEUT_ETRE_EN|$LG_PEUT_ETRE_LE|$LG_ENTRE$LG_THE|$LG_ENTRE|$LG_AVANT|$LG_APRES|$LG_EN|$LG_THE)//g" "$dt_fic_tmp" | sed -e "s/${dt_label_date} //g" -e "s/ - .*$//g")

         # Traitement MARRIED
         Quand=$(sed -e "s/$mDate.*$//g" "$dt_fic_tmp")
         # Actuce sir Born date1 ou Date2, je compte les ou et ensuite je recherche $born$ou
         Ou=$(echo "$mDate" | grep "$LG_OU" | wc -l | bc) || :
         determine_lable_date "$Quand" "$Ou" "dt_tag"

         log:info "mDate:[$mDate] Quand:[$Quand] Ou:[$Ou] dt_tag:[$dt_tag] "
         jour_mois_Annee "$mDate" dt_jour dt_mois dt_annee dt_jour_FIN dt_mois_FIN dt_annee_FIN

         if [[ "${dt_jour_FIN}${dt_mois_FIN}${dt_annee_FIN}" != "" ]]; then
            log:info "dt_jour_FIN:[$dt_jour_FIN] dt_mois_FIN:[$dt_mois_FIN] dt_annee_FIN:[$dt_annee_FIN]"
            [[ "$Ou" -eq 1 ]] && Ou="OR " || Ou="AND "
            dt_naissance=$(echo "  2  $dt_tag $dt_jour $dt_mois $dt_annee $Ou $dt_jour_FIN $dt_mois_FIN $dt_annee_FIN" | tr -s '[:space:]')
         else
            dt_naissance=$(echo "  2  $dt_tag $dt_jour $dt_mois $dt_annee" | tr -s '[:space:]')
         fi
         if [[ $(grep " - " "$dt_fic_tmp" | wc -l | bc) -eq 1 ]]; then
            dt_ville=$(grep "$dt_label_date " "$dt_fic_tmp" | sed -e 's/^.* - //g' -e 's/<\/li>.*$//g' -e "s/^ *//g" -e "s/CHARSLASH/\//g")
         else
            dt_ville=""
         fi
      else
         dt_ville=$(sed -e "s/^.*${dt_label_date},//g" -e "s/^.*${dt_label_date} - //g" -e "s/^ *//g" "$dt_fic_tmp" -e "s/CHARSLASH/\//g")
      fi
      log:info "trouver_date() dt_naissance:[$dt_naissance] dt_tag[$dt_tag] dt_label_date:[$dt_label_date] dt_ville:[$dt_ville]"
   fi

   eval "$3=\"$dt_naissance\""
   eval "$4=\"$dt_tag\""
   eval "$5=\"$dt_jour\""
   eval "$6=\"$dt_mois\""
   eval "$7=\"$dt_annee\""
   if [[ $# -ne 8 ]]; then
      eval "$8=\"$dt_jour_FIN\""
      eval "$9=\"$dt_mois_FIN\""
      eval "${10}=\"$dt_annee_FIN\""
      eval "${11}=\"$dt_ville\""
   else
      eval "${8}=\"$dt_ville\""
   fi
   if [[ "$dtJulien" -ne 0 ]]; then
      eval "${12}=\"$(cat $dt_fic_tmp)\""
   else
      eval "${12}=\"$strNull\""
   fi
   rm $dt_fic_tmp
}

main() {
   local i=0
}
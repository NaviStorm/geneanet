function clean_fichier_temporaire() {
   return
   log "clean_fichier_temporaire()"
   rm "$fic_tmp_all" "$fic_tmp" "$fic_tmp_parent" "$fic_tmp_union" "$fic_tmp_parent_pere" "$fic_tmp_parent_mere" 2>/dev/null 1>&2
}


function echo_bloc() {
   fic=$1
   if [[ -f "$fic" ]]; then
      cat "$fic"
   else
      while IFS='' read -r data; do
         echo "$data"
      done
   fi

}

function supprime_bloc_div() {
   log "supprime_bloc_div()"
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

function siMarie() {
   nbEpoux=$(sed -e "1,/<!--  Union/d"  -e "/^<!--  Freres/,10000d" "$1" | grep -E "^Marié|^Avec" | wc -l | bc)
   return $((nbEpoux + 0))
}


function incFAM() {
   local fic_fam="$1"
   local nFAM=$(($(cat "$fic_fam") + 1))
   echo $nFAM | tee "$fic_fam"
   return 0
}

function incID() {
   local fic_id="$1"
   local KeyID=$(($(cat "$fic_id") + 1))
   echo "$(($(cat fic_id) + 1))" >"$fic_id"
   echo "$KeyID"
}

function decID() {
   local fic_id="$1"
   local KeyID=$(($(cat "$fic_id") - 1))
   echo "$(($(cat "$fic_id") + 1))" >"$fic_id"
   echo "$KeyID"
}

function individu_deja_traite() {
   trace_individu_deja_traite="false"

   local KeyID="$1"
   local ID_INDI=""
   local deja_trouve="0"

   ID_INDI="${2// /}"
   deja_trouve=$(grep "$ID_INDI" "$fic_trouve" | wc -l | bc)
   log "ID_INDI:[$ID_INDI] deja_trouve:[$deja_trouve]"
   if [[ "$deja_trouve" -ne 0 ]]; then
      log "Dejà dans fichier  ID_Trouve"
      return 1
   else
      log "Pas dans fichier ID_Trouve"
      echo "$KeyID $ID_INDI" >> $fic_trouve
      return 0
   fi
}

function individu:get() {
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


# fontion cherche_indi
# Paramètre :
#   $1 : KeyID pour retour de valeur à l'appelant
#   $2 : Qui, tyep de recherche (PERE, MERE, EPOUSE)
#   $3 : uri
#   $4 : Chercher les parents
#   $5 : Chercher les epoux
#   $6 : Chercher les freres
#   $7 : Chercher les enfants
#   $8 : numero FAMS
function cherche_indi( ) {
   export tab="$tab   "
   local param="$2"
   local KeyID ficGedcom Qui URI URL getParent getEpoux getFrere getEnfant FAMS
   
   log "param:[$2]"
   ficGedcom=$(echo "$param" | grep -i "ficGedcom=" | sed -e 's/^.*ficGedcom=\[//i' -e 's/\].*$//g')
   Qui=$(echo "$param" | grep "Qui=" | sed -e 's/^.*Qui=\[//' -e 's/\].*$//g')
   URI=$(echo "$param" | grep "uri=" | sed -e 's/^.*uri=\[//' -e 's/\].*$//g')
   getParent=$(echo "$param" | grep "getParent=" | sed -e 's/^.*getParent=\[//' -e 's/\].*$//g')
   getEpoux=$(echo "$param" | grep "getEpoux=" | sed -e 's/^.*getEpoux=\[//' -e 's/\].*$//g')
   getFrere=$(echo "$param" | grep "getFrere=" | sed -e 's/^.*getFrere=\[//' -e 's/\].*$//g')
   getEnfant=$(echo "$param" | grep "getEnfant=" | sed -e 's/^.*getEnfant=\[//' -e 's/\].*$//g')
   FAMS=$(echo "$param" | grep -i "numFamille=" | sed -e 's/^.*numFamille=\[//' -e 's/\].*$//g')

##   local Qui="${2}"
##   local URI="${3}"
   URL=$(echo "${URI}" | sed -e "s/^.*$USER_GENEANET?/$USER_GENEANET?/g" -e 's/^.*fiche\///g')
##   local getParent="${4}"
##   local getEpoux="${5}"
##   local getFrere="${6}"
##   local getEnfant="${7}"$

   KeyID=$(($(cat $fic_id) + 1))
   echo "$KeyID" >"$fic_id"
   eval "${1}=\"$KeyID\"" 2>/dev/null

##   local FAMS="${8}"
   local ficFamille="${TMP_DIR}/FAM_$$_${FAMS}"
   local FAMS_SUIVANTE=0

   local nbAppel=$((nbAppel + 1))
   local my_pid="${KeyID}_${RANDOM}_${RANDOM}"
   local fic_trouve="${TMP_DIR}/ID_trouve"
   pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
   local fic_tmp_all="${pre}_all_page_$my_pid"
   local fic_tmp="${pre}_result_$my_pid"
   local fic_tmp_parent="${pre}_parent_$my_pid"
   local fic_tmp_union="${pre}_union_$my_pid"
   local fic_tmp_parent_pere="${pre}_parent_pere_$my_pid"
   local fic_tmp_parent_mere="${pre}_parent_mere_$my_pid"
   local fic_tmp_epoux="${pre}_parent_epoux_$my_pid"
   local fic_tmp_divorce="${pre}_parent_divorce_$my_pid"
   local fic_tmp_epoux_tmp="${pre}_epoux_tmp_$my_pid"
   local fic_tmp_frere="${pre}_parent_frere_$my_pid"
   local fic_tmp_enfant_tmp="${pre}_enfants_$my_pid"
   local bj
   local bm
   local by
   local villeNaissance=""
   local dj
   local dm
   local dy
   local villeDeces=""
   local sex
   local labelNaissance
   local labelDeces
   local labelMarie
   local GEDCOM_naissance="" GEDCOM_deces="" 
   local GEDCOM_divorce="" divJ divM divY divJ_Fin divM_Fin divY_Fin villeDivorce noteDivorce
   local nb_parent

   local nom prenom sex nbEpoux
   local tgNaissance tgDeces srcIndi srcNaissance srcUnion srcDeces noteIndi noteNaissance noteUnion noteDeces noteFamille

   local IdFct="$nbAppel/$KeyID/$FAMS"
   log "DEB ($IdFct) my_pid:[$my_pid] URL:[$URL] Qui:[$Qui] KeyID:[$KeyID]"

   get_page_html "$URI" "$fic_tmp_all" "$fic_tmp" "$fic_tmp_parent"

   individu:get "$fic_tmp_all" nom prenom sex

   if [[ "$nom$prenom" == "??" || "$nom$prenom" == "" || "$nom$prenom" == "nullnull" ]]; then
      echo "FIN ($IdFct): \$nom\$prenom:[$nom$prenom]"
      echo "$(($(cat $fic_id) - 1))" >$fic_id
      export tab="${tab//   /}"
      return 0
   fi

   init_label "$sex" sex labelNaissance labelDeces labelMarie labelTypeEpoux
   log "($IdFct) sex:[$sex] labelNaissance:[$labelNaissance] labelDeces:[$labelDeces] labelMarie:[$labelMarie]"

   sed -e "1,/^<!--  Portrait -->/d" -e "/^<!-- Parents /,10000d" -e "s/&nbsp;/ /g" "$fic_tmp_all" > "$fic_tmp"

   log "($IdFct): Cherche la date de GEDCOM_naissance"
   trouver_date "$fic_tmp" "$labelNaissance" GEDCOM_naissance tgNaissance bj bm by villeNaissance
   log "Naissance trouvé : GEDCOM_naissance:[$GEDCOM_naissance] tgNaissance:[$tgNaissance] bj:[$bj] bm:[$bm] by:[$by] villeNaissance:[$villeNaissance]"
   log "($IdFct): Cherche la date de GEDCOM_deces"
   trouver_date "$fic_tmp" "$labelDeces" GEDCOM_deces tgDeces dj dm dy villeDeces
   log "Décès trouvé : GEDCOM_deces:[$GEDCOM_deces] tgDeces:[$tgDeces] dj:[$dj] dm:[$dm] dy:[$dy] villeDeces:[$villeDeces]"

   log "($IdFct): GEDCOM_naissance bj:[$bj] bm:[$bm] by:[$by]"
   local ville=$(grep "$labelNaissance le" "$fic_tmp" | sed -e 's/^.* - //g' -e 's/<\/li>.*$//g')

   # Je regarde si l'individu est déjà traité
   og_url=$(grep "og:url" $fic_tmp_all | sed -e 's/^.*content="//g' -e 's/\/>//g' -e 's/"//g')
   ID_INDI="$prenom@$nom@$sex@$GEDCOM_naissance@$villeNaissance@$GEDCOM_deces@$villeDeces@$og_url"
   individu_deja_traite "$KeyID" "$ID_INDI"
   if [[ "$?" -eq 1 ]]; then
      export tab=$(echo $tab | sed -e 's/   //')
      log "($IdFct): $KeyID Déjà traité [${ID_INDI}]"
      return 1
   fi

   fam:write "$ficFamille" "sex=[$sex]?KeyID=[$KeyID]?fams=[$FAMS]"

   cherche_source "$fic_tmp_all" srcIndi srcNaissance srcUnion srcDeces
   cherche_note "$fic_tmp_all" noteIndi noteNaissance noteUnion noteDeces noteFamille
   log "noteIndi=[$noteIndi] noteNaissance=[$noteNaissance] noteUnion=[$noteUnion] noteDeces=[$noteDeces] noteFamille:[$noteFamille]"

   ged:write "$ficGedcom" "KeyID=[$KeyID]?nom=[$nom]?=prenom=[$prenom]?sex=[$sex]?source_individu=[$srcIndi]?note_individu=[$noteIndi]"
   ged:write "$ficGedcom" "date_naissance=[$GEDCOM_naissance]?ville_naissance=[$villeNaissance]?source_naissance=[$srcNaissance]?note_naissance=[$noteNaissance]"
   ged:write "$ficGedcom" "date_deces=[$GEDCOM_deces]?ville_deces=[$villeDeces]?source_deces=[$srcDeces]?note_deces=[$noteDeces]"

   if [[ "${Qui}" == "${QUI_PERE}" ]]; then      
      if ! siMarie "$fic_tmp_all"; then
         ged:write "$ficGedcom" "fams=[$FAMS]"
      fi
   elif [[ "${Qui}" == "${QUI_EPOUSE}" ]]; then
      # Je suis l'épouse
      ged:write "$ficGedcom" "fams=[$FAMS]"
   fi

   # recherche épouse 
   if [[ "$getEpoux" == "1" ]]; then
      log "($IdFct): Bloc recherche des époux"
      #      echo "Recherche époux/épouse"
      sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" "$fic_tmp_all" > "$fic_tmp_epoux_tmp"
      nbEpoux=$(grep -i "^$LB_MARIE\|^$LB_MARIE_AVEC" "$fic_tmp_epoux_tmp" | wc -l | bc)
      nbEpoux=$(( nbEpoux + 0))
      log "($IdFct): Nb époux:[$nbEpoux]"
      #      echo "Marie($prenom $nom) $nbEpoux fois"

      local epoux_x=0 ref_epoux=0 ligne_precedente_marie_avec=0 numMariage=0 firstFAMS=0
      local SansDate=0
      while IFS='' read -r ligne_html; do
         log "($IdFct) Lecture de la ligne [$ligne_html]"
         local epoux_trouve=$(echo $ligne_html | grep -E "^$LB_MARIE|^$LB_RELATION|^$LB_FIANCE|^$LB_MARIE_AVEC" | wc -l | bc)
         SansDate=$(echo $ligne_html | grep -E "^${LB_MARIE}${LB_MARIE_AVEC}" | wc -l | bc)
         local ref_epoux=$(echo "$ligne_html" | grep -Ei "${LB_MARIE_AVEC}.*<a href=" | wc -l | bc)

         log "($IdFct) epoux_trouve:[$epoux_trouve] SansDate:[$SansDate] ref_epoux:[$ref_epoux]"

         if [[ "$epoux_trouve" -eq 1 && "$SansDate" -eq 0  ]]; then
            # echo "($IdFct): $ligne_html"
            echo "$ligne_html" | sed -e 's/&nbsp;/ /g' | sed -e 's/<em>//g' | sed -e "s/$LG_MARIED_F/$LG_MARIED_M/g"> "$fic_tmp_epoux"
            trouver_date "$fic_tmp_epoux" "$LG_MARIED_M" date_mariage tgNaissance bj bm by bj_Fin bm_Fin by_Fin ville_mariage
            log "($IdFct): date_mariage:[$date_mariage] tgNaissance:[$tgNaissance] bj:$bj] bm:[$bm] by:[$by] bj_Fin:[$bj_Fin] bm_Fin:[$bm_Fin] by_Fin:[$by_Fin] ville_mariage:[$ville_mariage]"
            local epoux_x=1
            ligne_precedente_marie_avec=1
            numMariage=$(( numMariage + 1 ))
            continue
         fi
         if [[ "$ref_epoux" -eq 1 ]]; then
            if [[ "$numMariage" -gt 1 ]]; then
               # Plusieur mariage, j'incremente le N° Famille
               firstFAMS="$FAMS"
               FAMS=$(incFAM "$fic_fam")
               fam:write "$ficFamille" "fams=[$FAMS]?sex=[$sex]?KeyID=[$KeyID]?"
               # Initialissation du fichier Famill
            fi
            # Verifier si divorcé
            nbDivorce=$(echo "$ligne_html" | grep -i "${LB_DIVORCE}" | wc -l | bc)
            echo "========> ligne_html:[$ligne_html] nbDivorce:[$nbDivorce]"
            if [[ "$nbDivorce" -eq 1 ]]; then
               echo "$ligne_html" | sed -e 's/&nbsp;/ /g' | sed -e 's/<em>//g' | sed -e "s/^.*$LB_DIVORCE/$LB_DIVORCE/g" -e "s/ ${LB_AVEC}$//g"> "$fic_tmp_divorce"
               trouver_date "$fic_tmp_divorce" "$LB_DIVORCE" GEDCOM_divorce tgDivorce divJ divM divY divJ_Fin divM_Fin divY_Fin villeDivorce
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
               log "($IdFct): GEDCOM_divorce:[$GEDCOM_divorce] tgDivorce:[$tgDivorce] divJ:[$divJ] divM:[$divM] divY:[$divY] divJ_Fin:[$divJ_Fin] divM_Fin:[$divM_Fin] divY_Fin:[$divY_Fin] villeDivorce:[$villeDivorce] noteDivorce:[$noteDivorce]"
            fi
            local lien_epoux=$(echo $ligne_html | sed -e 's/^.*<a href="//g' | sed -e 's/">.*$//g')
            #            echo "URL Conjoint de ($prenom $nom) : [$lien_epoux]"
            ligne_precedente_marie_avec=0

            # Pour l'épouse je n'increment pas le N°Famills (FAMS)
            log "($IdFct): Je recherche l'épouse de [$KeyID]  pour la famille FAMS[$FAMS]"
            cherche_indi retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_EPOUSE}]?uri=[${lien_epoux}]?getParent=[${getParent}]?getEpoux=[${getEpoux}]?getFrere=[${getFrere}]?getEnfant=[0]?numFamille=[${FAMS}]"
            retChercheIndi="$?"
            if [[ "$retChercheIndi" -eq 0 ]]; then
               # Ecriture dans fichier FAM, qui sera contatené dans le fichier ged à la fin
               log "($IdFct): J'écris dans fichier FAMS[$FAMS] KeyID:[$KeyID]"
               fam:write "$ficFamille" "fams=[$FAMS]?GEDCOM_mariage=[$date_mariage]?ville_mariage=[$ville_mariage]?GEDCOM_divorce=[$GEDCOM_divorce]?ville_divorce=[$villeDivorce]?note_divorce=[$noteDivorce]"
            fi
            local epoux_x=0
            local nbEpoux=$(($nbEpoux - 1))
            #            echo "Epoux restant:[$nbEpoux]"
            if [[ "$nbEpoux" -eq 0 ]]; then
               break
            fi
         else
            if [[ "$epoux_trouve" -ne 1 ]] ; then 
               ligne_precedente_marie_avec=0
            fi
         fi
      done <$fic_tmp_epoux_tmp
   else
      log "($IdFct): Je ne recherche pas les époux/épouses"
   fi

   # Recherche Parent
   if [[ "$getParent" == "1" ]]; then
      log "($IdFct): Bloc recherche des parents"

      # echo "($IdFct): Famille en cours:[$FAMS] Famille du Pere/Mere:[$FAMS_SUIVANTE]"
      # Si les Parents sont mariè, cela fonctionne car
      #      cat $fic_tmp_all |
      sed -e "1,/^<!-- Parents /d" -e "/^<!--  Union /,10000d" -e '/<li style=/d' "$fic_tmp_all" >$fic_tmp_parent
      grep "href=\"" "$fic_tmp_parent" | head -1 >"$fic_tmp_parent_pere"
      grep "href=\"" "$fic_tmp_parent" | tail -1 >"$fic_tmp_parent_mere"
      local nb_parent=$(grep "href" "$fic_tmp_parent" | wc -l | bc)
      nb_parent=$((nb_parent+0))

      log "($IdFct): Parents nb_parent:[$nb_parent]"
      if [[ "$nb_parent" -ne 0 ]]; then
         FAMS_SUIVANTE=$(incFAM "$fic_fam")
         # Ecriture dans le fichier ged la famille, je suis l'enfant de la famille FAMS
         log "($IdFct): Nb Parent : [$nb_parent]"
         local nom_pere=$(grep "^.*href" "$fic_tmp_parent_pere" | head -1 | sed -e 's/<bdo.*$//g' | sed -e 's/^.*fiche">//' | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//' )
         local lien_pere=$(grep "^.*href" "$fic_tmp_parent_pere" | head -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
         local nom_mere=$(grep "^.*href" "$fic_tmp_parent_mere" | tail -1 | sed -e 's/<bdo.*$//g' | sed -e 's/^.*fiche">//' | sed -e 's/<\/a>.*$//g' | sed -e 's/^.*">//')
         local lien_mere=$(grep "^.*href" "$fic_tmp_parent_mere" | tail -1 | sed -e 's/^.*href="//g' | sed -e 's/">.*$//')
         log "($IdFct): nom_pere:[$nom_pere] lien_pere:[$lien_pere] nom_mere:[$nom_mere] lien_mere:[$lien_mere]"         echo ""

         if [[ "$nom_pere" == *"? ?"* || "$nom_pere" == "" || "$nom_pere" == *"null null"* ]]; then
            log "($IdFct): Pas de père [$nom_pere] [$lien_pere] $nom $prenom" "$getParent" "0" "$getFrere"
            nb_parent=$((nb_parent-1))
         else
            log "($IdFct) Cherche le pere avec nouveau N° FAMS:[$FAMS_SUIVANTE]"
            cherche_indi retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_PERE}]?uri=[${lien_pere}]?getParent=[${getParent}]?getEpoux=[${getEpoux}]?getFrere=[${getFrere}]?getEnfant=[0]?numFamille=[${FAMS_SUIVANTE}]"
            ## cherche__indi retID "$QUI_PERE" "$lien_pere" "$getParent" "$getEpoux" "$getFrere" "0" "${FAMS_SUIVANTE}"
            retID_Pere=$retID
            log "($IdFct) I@$retID@ est le père de I@$KeyID@ Pour la famille FAMS:[$FAMS_SUIVANTE]"
         fi

         if [[ "$nom_mere" == *"? ?"* || "$nom_mere" == "" || "$nom_mere" == *"null null"*  ]]; then
            log "($IdFct): Pas de mère pour $nom $prenom" "$getParent" "0" "$getFrere"
            nb_parent=$((nb_parent-1))
         else
            log "($IdFct) Cherche la mere avec nouveau N° FAMS :[$FAMS_SUIVANTE]"
            cherche_indi retID "ficGedcom=[$ficGedcom]?Qui=[${QUI_MERE}]?uri=[${lien_mere}]?getParent=[${getParent}]?getEpoux=[${getEpoux}]?getFrere=[${getFrere}]?getEnfant=[0]?numFamille=[${FAMS_SUIVANTE}]"
            # cherche__indi retID "$QUI_MERE" "$lien_mere" "$getParent" "$getEpoux" "$getFrere" "0" "${FAMS_SUIVANTE}"
            retID_Mere=$retID
            log "($IdFct) I@$retID@ est le la mère de I@$KeyID@ Pour la famille FAMS:[$FAMS_SUIVANTE]"
         fi

         if [[ "$nb_parent" -ne 0 ]]; then
            echo "  1 FAMC @${FAMS_SUIVANTE}@"
            if [[ ! -f "${TMP_DIR}/FAM_$$_${FAMS_SUIVANTE}" ]]; then
               error "($IdFct) Le fichier Famille ${TMP_DIR}/FAM_$$_${FAMS_SUIVANTE} n'existe pas"
               quitter 1
            else
               log "($IdFct) Ecriture de : je suis l'enfant($KeyID) de la famille Pere($retID_Pere) Mere($retID_Mere) dans fichier famille FAMS:[$FAMS_SUIVANTE]"
               echo "  1 CHIL @I$KeyID@" >> "${TMP_DIR}/FAM_$$_${FAMS_SUIVANTE}"
            fi
         fi
      else
         log "($IdFct): Pas de Parent"
      fi
      log "($IdFct): Fin Recherche Parent"
   else
      echo "Je ne recherche pas les parents"
   fi

   if [[ "$getEnfant" == "9" ]]; then
      sed -e "1,/<!--  Union/d" -e "/^<!--  Freres/,10000d" -e 's/^<img style=.* alt="H">//g' "$fic_tmp_all" > "$fic_tmp_enfant_tmp"
      cherche_enfant "$fic_tmp_enfant_tmp" "$FAMS"
   else
      log "($IdFct): Je ne recherche pas les enfants"
   fi

   # recherche frère & soeur
   if [[ "$getFrere" == "9" ]]; then
      #      echo "Recherche frère/soeur"
      sed -e "1,/^<!--  Freres et soeurs /d" -e "/^<!--  Relations/,10000d" "$fic_tmp_all" > "$fic_tmp_frere"
   else
      log "($IdFct): Je ne recherche pas les frères/soeurs"
   fi

   clean_fichier_temporaire
   log "FIN ($IdFct): $my_pid"
   export tab=$(echo $tab | sed -e 's/   //')
}
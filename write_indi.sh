ged:init() {
   local ficGCOM="$1"
   local filename="${ficGCOM##*/}"
   local user=$(grep user "${fic_config}" | sed -e 's/user.*=//g' -e 's/ //g' -e "s/'//g")

   file:write "$ficGCOM" "$(
      echo "0 HEAD"
      echo "1 SOUR geneanet.sh"
      echo "2 VERS 0.5.6"
      echo "2 NAME gwb2ged"
      echo "3 ADDR Lyon, France"
      echo "2 DATA ${user}.gwb"
      echo "1 FILE ${filename}"
      echo "1 CHAR UTF-8"
      )"
}


ged:finalize() {
   local rep="$1"
   local ficGCOM="$2"

   cat "$rep/ID_"* "$rep/FAM_"* > "$ficGCOM"
   file:write "$ficGCOM" "0 TRLR"
}


ged:filename() {
   echo "${TMP_DIR}/ID_$(printf "%.5d" "$1")"
}


ged:write() {
   local numID="$1"
   local param="$2"
   local _nb=0
   local KeyID nom prenom sex noteIndividu dateNaissance VilleNaissance sourceNnaissance noteNaissance dateDeces villeDeces srcDeces noteDeces fams

   ficCOM=$(ged:filename "$numID")

   log:info "DEB numID:[$numID] Param:[$param]"
   KeyID=$(getParam "KeyID" "$param")
   nom=$(getParam "nom" "$param")
   prenom=$(getParam "prenom" "$param")
   sex=$(getParam "sex" "$param")
   srcIndividu=$(getParam "source_individu" "$param")
   noteIndividu=$(getParam "note_individu" "$param")
   dateNaissance=$(getParam "date_naissance" "$param")
   VilleNaissance=$(getParam "ville_naissance" "$param")
   sourceNnaissance=$(getParam "source_naissance" "$param")
   noteNaissance=$(getParam "note_naissance" "$param")
   dateDeces=$(getParam "date_deces" "$param")
   villeDeces=$(getParam "ville_deces" "$param")
   srcDeces=$(getParam "source_deces" "$param")
   noteDeces=$(getParam "note_deces" "$param")
   fams=$(getParam "fams" "$param")
   famc=$(getParam "famc" "$param")
   {
      [[ "$KeyID" != "" ]] && echo "0 @I$KeyID@ INDI"
      [[ "$prenom" != "" || "$nom" != "" ]] && echo "  1 NAME $prenom /$nom/" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
      [[ "$sex" != "" ]] && echo "  1 SEX $sex"
      [[ "$noteIndividu" != "" ]] && echo "  1 NOTE $noteIndividu" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
      [[ "$srcIndividu" != "" ]] && echo "  1 SOUR $srcIndividu" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
      [[ "$fams" != "" ]] && echo "  1 FAMS @F$fams@"
      if [[ "$famc" != "" ]]; then
         _nb=$(grep -c "  1 FAMC @" $ficCOM )
          [[ "$_nb" -eq 0 ]] && echo "  1 FAMC @F$famc@"
      fi
      [[ -n "$dateNaissance" || -n "$sourceNnaissance" || -n "$noteNaissance" || -n "$VilleNaissance" ]] && echo "  1 BIRT"
      [[ -n "$dateNaissance"  ]] && echo " $dateNaissance"
      [[ -n "$VilleNaissance"  ]] && echo "  2 PLAC $VilleNaissance" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
      [[ -n "$noteNaissance"  ]] && echo "  2 NOTE $noteNaissance" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
      [[ -n "$sourceNnaissance"  ]] && echo "  2 SOUR $sourceNnaissance" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 

      [[ -n "$dateDeces" || -n "$villeDeces" || -n "$noteDeces" || -n "$srcDeces" ]] && echo "  1 DEAT"
      [[ -n "$dateDeces" ]] && echo " $dateDeces"
      [[ "$villeDeces" != "" ]] && echo "  2 PLAC $villeDeces" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
      [[ "$noteDeces" != "" ]] && echo "  2 NOTE $noteDeces" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
      [[ "$srcDeces" != "" ]] && echo "  2 SOUR $srcDeces" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" 
   } >> "$ficCOM"
}


ged:finalize() {
   local rep="$1"
   local ficGCOM="$2"

   log:info "rep:[$rep] ficGCOM:[$ficGCOM]"
   for fic in "$rep"/ID_*; do
      cat "$fic" >> "$ficGCOM"
   done

   for fic in $rep/FAM_*; do
      cat "$fic" >> "$ficGCOM"
   done
}


famille:rm() {
   local _fic=""

   _fic=$(famille:filename "$1")
   rm "$_fic" 2>/dev/null
   return "$?"
}

famille:filename() {
   echo "${TMP_DIR}/FAM_$(printf "%.5d" "$1")"
}


getParam() {
   local key="$1"
   local value="$2"
   local _value=""

   # format possible &key=[] &key:[] ?key=[] ?key=[]
   echo "$value" | grep "&$key\(:\|=\)\|^$key\(:\|=\)" | sed -e "s/^$key=\[//g" |  sed -e "s/^.*\][&?]$key=\[//g" | sed -e "s/\][&?].*$//g" | sed -e "s/\]$//g"
}

famille:write() {
   local param="$1"
   local KeyID=0 Married="1" sex="N" nFAMS=0 labelTypeEpoux="" GEDCOM_mariage="" villeMariage="" noteMariage=""  GEDCOM_divorce="" villeDivorce="" noteDivorce="" nChild="" ficCOM="" nbEpoux=0 KeyID_Conjoint=""

   KeyID=$(getParam "KeyID" "$param")
   sex=$(getParam "sex" "$param")
   nFAMS=$(getParam "fams" "$param")
   GEDCOM_mariage=$(getParam "GEDCOM_mariage" "$param")
   villeMariage=$(getParam "ville_mariage" "$param")
   GEDCOM_divorce=$(getParam "GEDCOM_divorce" "$param")
   villeDivorce=$(getParam "ville_divorce" "$param")
   noteMariage=$(getParam "note_mariage" "$param")
   noteDivorce=$(getParam "note_divorce" "$param")
   nChild=$(getParam "child" "$param")
   Married=$(getParam "Married" "$param")
   KeyID_Conjoint=$(echo "$param" | grep -i "KeyIDApple=" | sed -e 's/^.*KeyIDApple=\[//' -e 's/\].*$//g')


   if [[ -z "$nFAMS" ]]; then
      log:error " Le numero de famille est obligatoire Param:[$param]"
      quitter 1
      return 1
   fi
   ficCOM=$(famille:filename "$nFAMS")

   log:info "DEB ficCOM:[$ficCOM] Param:[$param]"

   [[ "$nFAMS" -eq 0 ]] && exit 0
   # Initialisation du fichier Famille
   if [[ ! -f "$ficCOM" ]]; then
      log:info "Initialisation fichier [$ficCOM]"
      echo "0 @F${nFAMS}@ FAM" >> "$ficCOM"
   fi
   
   if [[ "$Married" == "0" ]]; then
      echo "  1 EVEN" >> "$ficCOM"
      echo "  2 TYPE unmarried" >> "$ficCOM"
   else
      local _nb=$(grep "  1 MAR\|unmarried" "$ficCOM" 2>/dev/null | wc -l | bc)
      [[ $_nb -eq 0 ]] && file:write "$ficCOM" "  1 MAR"  
      #echo "  1 MAR" >> "$ficCOM"
   fi

   if [[ -n "$sex" ]]; then      
      if [[ "$sex" == "M" || "$sex" == "0" ]]; then
         labelTypeEpoux="HUSB @I$KeyID@"
      elif [[ "$sex" == "F" || "$sex" == "1" ]]; then
         labelTypeEpoux="WIFE @I$KeyID@"
      else
         labelTypeEpoux="INCO @I$KeyID@"
      fi

      # Si sex est renseigné, le KeyID doit m'être aussi
      [[ -n "$sex" && -z "$KeyID" ]] && return 1

      # Si sex est renseigné, le KeyID doit m'être aussi
      [[ -n "$sex" && -n "$KeyID" && -z "$KeyID_Conjoint" ]] && return 1

      # Je verifie que le fichier FAM n'existe pas déjà
      # KeyID_Conjoint peut aussi être l'enfant mais pas de problème dans ce cas
      if [[ -n "$sex" && -n "$KeyID" && -n "$KeyID_Conjoint" ]]; then
         # famille:search "$KeyID" "$KeyID_Conjoint" 2>/dev/null 1>&2
         famille:search "pere=[$KeyID]&mere=[$KeyID_Conjoint]" 2>/dev/null 1>&2
         retCode="$?"
         log:info "retour famille:search $KeyID $KeyID_Conjoint retCode:[$retCode]"
         [[ "$retCode" == "$FAMILY_EXIST" ]] && return 1
      fi
      # Je recherche la personne si elle est déjà dans le fihcier FAMS
      # Recherche "WIFE I@KeyID@" ou "HUSB I@KeyID@"
      grep "\(WIFE \|HUSB \|INCO \)@I$KeyID@" "$ficCOM" 2>/dev/null 1>&2

      [[ "$?" -eq 0 ]] && return 0

      nbEpoux=$(grep "HUSB\|WIFE\|INCO" "$ficCOM" | wc -l | bc)
      if [[ "$nbEpoux" -ge 2 ]]; then
         log:error "Déjà 2 conjoints dans FAMS [$nFAMS] Param:[$param]"
         return 1
      fi

      log:info "Ecriture dans fichier nFAMS ${nFAMS} $labelTypeEpoux"
      file:write "$ficCOM" "  1 $labelTypeEpoux"
      # echo "  1 $labelTypeEpoux" >> "$ficCOM"
      return 0
   fi
   [[ -n "$GEDCOM_mariage" ]] && file:write "$ficCOM" " $GEDCOM_mariage"
   [[ -n "$villeMariage" ]] && file:write "$ficCOM" "  2 PLAC $villeMariage"
   [[ -n "$noteMariage" ]] && file:write "$ficCOM" "  2 NOTE $noteMariage"

   [[ -n "$GEDCOM_divorce" || -n "$villeDivorce" || -n "$noteDivorce" ]] && file:write "$ficCOM" "  1 DIV"
   [[ -n "$GEDCOM_divorce" ]] && file:write "$ficCOM" " $GEDCOM_divorce"
   [[ -n "$villeDivorce" ]] && file:write "$ficCOM" "$(echo "  2 PLAC $villeDivorce" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g")"
   [[ -n "$noteDivorce" ]] && file:write "$ficCOM" "$(echo "  2 NOTE $noteDivorce" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g")"

   if [[ -n "$nChild" ]]; then
      existeDeja=$(grep "  1 CHIL @I$nChild@"  "$ficCOM" | wc -l | bc)
      log:info "Recherche [  1 CHIL @I$nChild@] dans fichier famille existeDeja:[$existeDeja]"
      if [[ "$existeDeja" -eq 1 ]]; then
            log:info "Cette enfant (@I$nChild@) est déjà dans le fichier Famille [$nFAMS]"
            return 1
      fi
      file:write "$ficCOM" "  1 CHIL @I$nChild@"
      # J'écris dans le fichier individu le numero de famille
      ged:write "$nChild" "famc=[$nFAMS]"
      return 0
   fi
}

famille:search() {
   local _enfant="" _pere="" _mere="" _numFamille=""

   _enfant=$(getParam "enfant" "$1")
   _pere=$(getParam "pere" "$1")
   _mere=$(getParam "mere" "$1")

   log:info "_enfant:[$_enfant] _pere:[$_pere] _mere:[$_mere]"
   [[ $_enfant -eq 3 ]] && cat $TMP_DIR/FAM_* 1>&2
   if [[ -n "$_enfant" ]]; then
      _numFamille=$(grep -l "1 CHIL.*${_enfant}" $TMP_DIR/FAM_* | sed -e 's/^.*_//g' -e 's/^0*//')
   else
      _numFamille=$(grep -l "1 \(HUSB \|WIFE \|INCO \)@I$_pere@" "$TMP_DIR/FAM_"* | xargs grep -l "1 \(HUSB \|WIFE \|INCO \)@I$_mere@" | sed -e 's/^.*_//g' -e 's/^0*//')
   fi

   log:info "Famille trouvé : [$_numFamille]"
   if [[ -z "$_numFamille" ]]; then
      echo ""
      return $FAMILY_NO_EXIST
   fi
   echo "$_numFamille"
   return $FAMILY_EXIST
}


famille:whithout_spouse() {
      local KeyID="$1"
      local Conjoint="$2"
      local ficFAM=""
      local nFAMS=0
      # Je recherche fichier famille pour un époux
      # grep -L "CHIL.*17" ==> Dont l'époux n'est pas le fils d'une famille
      # Qui ne contient pas de WIFE (Si contient Wife, je n'appelle pas cette fonction)
      ficFAM=$(grep -l "@I${KeyID}@" "$TMP_DIR/FAM_"* | xargs grep -L "CHIL @I${KeyID}@" | xargs grep -L "$Conjoint")
      nFAMS=${ficFAM//*_/}
      log:info "Trouvé Famille pour KeyID:[$KeyID] le [$nFAMS] sans Conjoint [$Conjoint]"
      eval "$3=\"$nFAMS\""
}




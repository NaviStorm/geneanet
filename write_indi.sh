ged:init() {
   local ficGCOM="$1"
   local filename="${ficGCOM##*/}"
   local user=$(grep user "${fic_config}" | sed -e 's/user.*=//g' -e 's/ //g' -e "s/'//g")

   {
      echo "0 HEAD"
      echo "1 SOUR geneanet.sh"
      echo "2 VERS 0.5.6"
      echo "2 NAME gwb2ged"
      echo "3 ADDR Lyon, France"
      echo "2 DATA ${user}.gwb"
      echo "1 FILE ${filename}"
      echo "1 CHAR UTF-8"
      } > "$ficGCOM"
}

ged:filename() {
   local KeyID="$1"
   echo "${TMP_DIR}/ID_$(printf "%.5d" $KeyID)"
}


ged:write() {
   local numID="$1"
   local param="$2"
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
      [[ "$fams" != "" ]] && echo "  1 FAMS @$fams@"
      [[ "$famc" != "" ]] && echo "  1 FAMC @${famc}@"

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


ged:initialize() {
   local ficGCOM="$1"
   {
      echo "0 HEAD"
      echo "1 SOUR geneanet.sh"
      echo "2 VERS 0.5.6"
      echo "2 NAME gwb2ged"
      echo "3 ADDR Lyon, France"
      echo "2 DATA fichier.gwb"
      echo "1 FILE fichier.ged"
   } > "$ficGCOM"
}

ged:finalize() {
   local rep="$1"
   local ficGCOM="$2"

   log:info "rep:[$rep] ficGCOM:[$ficGCOM]"
   for fic in $rep/ID_*; do
      cat "$fic" >> "$ficGCOM"
   done

   for fic in $rep/FAM_*; do
      cat "$fic" >> "$ficGCOM"
   done
}


fam:rm() {
   local nFAMS="$1" 
   local ficCOM=""

   ficCOM=$(fam:filename "$nFAMS")
   rm "$ficCOM"
   return "$?"
}

fam:filename() {
   local nFAMS=$(( $1 ))

   echo "${TMP_DIR}/FAM_$(printf "%.5d" $nFAMS)"
}


getParam() {
   local key="$1"
   local value="$2"

   # ged:write "$KeyID" "KeyID=[$KeyID]&nom=[$nom]&prenom=[$prenom]&sex=[$sex]&source_individu=[$srcIndi]&note_individu=[$noteIndi]"
   # ]&note_deces=[
   echo "$value" | grep "$key=\[" | sed -e "s/^$key=\[//g" |  sed -e "s/^.*\]&$key=\[//g" | sed -e "s/\]&.*$//g" | sed -e "s/\]$//g"
}

fam:write() {
   local param="$1"
   local KeyID=0 Married="1" sex="N" nFAMS=0 labelTypeEpoux="" GEDCOM_mariage="" villeMariage="" noteMariage=""  GEDCOM_divorce="" villeDivorce="" noteDivorce="" nChild="" ficCOM="" nbEpoux=0

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

   if [[ -z "$nFAMS" ]]; then
      log:error " Le numero de famille est obligatoire Param:[$param]"
      quitter 1
      return 1
   fi
   ficCOM=$(fam:filename "$nFAMS")

   log:info "DEB ficCOM:[$ficCOM] Param:[$param]"
   # Initialisation du fichier Famille
   if [[ ! -f "$ficCOM" ]]; then
      log:info "Initialisation fichier [$ficCOM]"
      echo "0 @F${nFAMS}@ FAM" >> "$ficCOM"
   fi

   if [[ "$Married" == "0" ]]; then
      echo "  1 EVEN" >> "$ficCOM"
      echo "  2 TYPE unmarried" >> "$ficCOM"
   fi
   
   if [[ -n "$sex" ]]; then
      if [[ "$sex" == "M" ]]; then
         labelTypeEpoux="HUSB @I$KeyID@"
      elif [[ "$sex" == "F" ]]; then
         labelTypeEpoux="WIFE @I$KeyID@"
      else
         labelTypeEpoux="INCO @I$KeyID@"
      fi

      # Si sex est renseigné, le KeyID doit m'être aussi
      [[ -n "$sex" && -z "$KeyID" ]] && return 1

      # Je recherche la personne si elle est déjà dans le fihcier FAMS
      # Recherche "WIFE I@KeyID@" ou "HUSB I@KeyID@"
      grep "\(WIFE \|HUSB \)@I$_KeyID@" "$_ficCOM" 2>/dev/null 1>&2
      [[ "$?" -eq 0 ]] && return 0

      nbEpoux=$(grep "HUSB\|WIFE\|INCO" "$ficCOM" | wc -l | bc)
      if [[ "$nbEpoux" -ge 2 ]]; then
         log:error "Déjà 2 conjoints dans FAMS [$nFAMS] Param:[$param]"
         return 1
      fi

      log:info "Ecriture dans fichier nFAMS ${nFAMS} $labelTypeEpoux"
      echo "  1 $labelTypeEpoux" >> "$ficCOM"
      return 0
   fi
   [[ -n "$GEDCOM_mariage" ]] && echo " $GEDCOM_mariage" >> "$ficCOM"
   [[ -n "$villeMariage" ]] && echo "  2 PLAC $villeMariage" >> "$ficCOM"
   [[ -n "$noteMariage" ]] && echo "  2 NOTE $noteMariage" >> "$ficCOM"

   [[ -n "$GEDCOM_divorce" || -n "$villeDivorce" || -n "$noteDivorce" ]] && echo "  1 DIV" >> "$ficCOM"
   [[ -n "$GEDCOM_divorce" ]] && echo " $GEDCOM_divorce" >> "$ficCOM"
   [[ -n "$villeDivorce" ]] && echo "  2 PLAC $villeDivorce" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" >> "$ficCOM"
   [[ -n "$noteDivorce" ]] && echo "  2 NOTE $noteDivorce" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" >> "$ficCOM"

   if [[ -n "$nChild" ]]; then
      labelTypeEpoux="  1 CHIL @I$nChild@"
      existeDeja=$(grep "$labelTypeEpoux"  "$ficCOM" | wc -l | bc)
      log:info "Recherche $labelTypeEpoux dans fichier famille existeDeja:[$existeDeja]"
      if [[ "$existeDeja" -eq 1 ]]; then
            log:info "Cette enfant (@I$nChild@) est déjà dans le fichier Famille [$nFAMS]"
            return 1
      fi
      echo "  1 CHIL @I$nChild@" >> "$ficCOM"
   fi
}

fam:search() {
   local I1="$1" I2="$2"
   local ficFAM
   local nFAMS=0

   ficFAM=$(grep -l "1 HUSB @I$I1@\|1 WIFE @I$I1@\|1 INCO @I$I1@" "$TMP_DIR/FAM_"* | xargs grep -l "1 HUSB @I$I2@\|1 WIFE @I$I2@\|1 INCO @I$I2@" | sed -e 's/^.*_//g' -e 's/^0*//')
   if [[ -z "$ficFAM" || "$ficFAM" == "" ]]; then
      log:error "pas de famille trouvé pour ID_1[$I1] et ID_2:[$I2]"
      echo ""
      return 1
   fi
   echo "$nFAMS"
   return 0
}


fam:whithout_spouse() {
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




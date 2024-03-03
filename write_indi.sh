#!/bin/bash

ged:init() {
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

ged:filename() {
   local KeyID="$1"
   echo "${TMP_DIR}/ID_${KeyID}"
}


ged:write() {
   local numID="$1"
   local param="$2"
   local KeyID nom prenom sex noteIndividu dateNaissance VilleNaissance sourceNnaissance noteNaissance dateDeces villeDeces srcDeces noteDeces fams

   ficCOM=$(ged:filename "$numID")

   log "ficCOM:[$ficCOM] Param: [$param]"
   KeyID=$(echo "$param" | grep "KeyID=" | sed -e 's/^.*KeyID=\[//' -e 's/\].*$//g')
   nom=$(echo "$param" | grep "^nom=\|?nom=" | sed -e 's/prenom=[^|]//' -e 's/^.*nom=\[//' -e 's/\].*$//g')
   prenom=$(echo "$param" | grep "prenom=" | sed -e 's/^.*prenom=\[//' -e 's/\].*$//g')
   sex=$(echo "$param" | grep "sex=" | sed -e 's/^.*sex=\[//' -e 's/\].*$//g')
   srcIndividu=$(echo "$param" | grep "source_individu=" | sed -e 's/^.*source_individu=\[//' -e 's/\].*$//g')
   noteIndividu=$(echo "$param" | grep "note_individu=" | sed -e 's/^.*note_individu=\[//' -e 's/\].*$//g')
   dateNaissance=$(echo "$param" | grep "date_naissance=" | sed -e 's/^.*date_naissance=\[//' -e 's/\].*$//g')
   VilleNaissance=$(echo "$param" | grep "ville_naissance=" | sed -e 's/^.*ville_naissance=\[//' -e 's/\].*$//g')
   sourceNnaissance=$(echo "$param" | grep "source_naissance=" | sed -e 's/^.*source_naissance=\[//' -e 's/\].*$//g')
   noteNaissance=$(echo "$param" | grep "note_naissance=" | sed -e 's/^.*note_naissance=\[//' -e 's/\].*$//g')
   dateDeces=$(echo "$param" | grep "date_deces=" | sed -e 's/^.*date_deces=\[//' -e 's/\].*$//g')
   villeDeces=$(echo "$param" | grep "ville_deces=" | sed -e 's/^.*ville_deces=\[//' -e 's/\].*$//g')
   srcDeces=$(echo "$param" | grep "source_deces=" | sed -e 's/^.*source_deces=\[//' -e 's/\].*$//g')
   noteDeces=$(echo "$param" | grep "note_deces=" | sed -e 's/^.*note_deces=\[//' -e 's/\].*$//g')
   fams=$(echo "$param" | grep "fams=" | sed -e 's/^.*fams=\[//' -e 's/\].*$//g')
   famc=$(echo "$param" | grep "famc=" | sed -e 's/^.*famc=\[//' -e 's/\].*$//g')
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


fam:rm() {
   local nFAMS="$1" 
   local ficCOM=""

   ficCOM=$(fam:filename "$nFAMS")
   rm "$ficCOM"
   return "$?"
}

fam:filename() {
   local nFAMS="$1"

   echo "${TMP_DIR}/FAM_${nFAMS}"
}


fam:write() {
   local param="$1"
   local KeyID=0 Married="1" sex="N" nFAMS=0 labelTypeEpoux="" GEDCOM_mariage="" villeMariage="" GEDCOM_divorce="" villeDivorce="" noteDivorce="" nChild="" ficCOM="" nbEpoux=0
   
   KeyID=$(echo "$param" | grep "KeyID=" | sed -e 's/^.*KeyID=\[//' -e 's/\].*$//g' )
   sex=$(echo "$param" | grep "sex=" | sed -e 's/^.*sex=\[//' -e 's/\].*$//g' )
   nFAMS=$(echo "$param" | grep "fams=" | sed -e 's/^.*fams=\[//' -e 's/\].*$//g' )
   GEDCOM_mariage=$(echo "$param" | grep "GEDCOM_mariage=" | sed -e 's/^.*GEDCOM_mariage=\[//' -e 's/\].*$//g' )
   villeMariage=$(echo "$param" | grep "ville_mariage=" | sed -e 's/^.*ville_mariage=\[//' -e 's/\].*$//g' )
   GEDCOM_divorce=$(echo "$param" | grep "GEDCOM_divorce=" | sed -e 's/^.*GEDCOM_divorce=\[//' -e 's/\].*$//g' )
   villeDivorce=$(echo "$param" | grep "ville_divorce=" | sed -e 's/^.*ville_divorce=\[//' -e 's/\].*$//g' )
   noteDivorce=$(echo "$param" | grep "note_divorce=" | sed -e 's/^.*note_divorce=\[//' -e 's/\].*$//g' )
   nChild=$(echo "$param" | grep "child=" | sed -e 's/^.*child=\[//' -e 's/\].*$//g' )
   Married=$(echo "$param" | grep "Married=" | sed -e 's/^.*Married=\[//' -e 's/\].*$//g' )

   if [[ -z "$nFAMS" ]]; then
      error " Le numero de famille est obligatoire"
      return 1
   fi
   ficCOM=$(fam:filename "$nFAMS")

   log "DEB ficCOM:[$ficCOM] Param:[$param]"
   # Initialisation du fichier Famille
   if [[ ! -f "$ficCOM" ]]; then
      log "Initialisation fichier nFAMS${nFAMS}"
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

      nbEpoux=$(grep "HUSB\|WIFE\|INCO" "$ficCOM" | wc -l | bc | wc -l)
      if [[ "$nbEpoux" -eq 2 ]]; then
         error "Il y a deja 2 conjoints dans le fichier FAMS [$nFAMS] Param:[$param]"
         return 1
      fi

      existeDeja=$(grep "$labelTypeEpoux" "$ficCOM" | wc -l | bc)
      log "Recherche $labelTypeEpoux dans fichier famille existeDeja:[$existeDeja]"
      if [[ "$existeDeja" -eq 2 ]]; then
         error "Il y a deja $labelTypeEpoux $nom $prenom (@I$KeyID@) dans le fichier Famille [$nFAMS]"
         return 1
      else
         log "Ecriture dans fichier nFAMS ${nFAMS} $labelTypeEpoux Qui:[$Qui]"
         echo "  1 $labelTypeEpoux" >> "$ficCOM"
      fi
   fi
   [[ -n "$GEDCOM_mariage" ]] && echo " $GEDCOM_mariage" >> "$ficCOM"
   [[ -n "$villeMariage" ]] && echo "  2 PLAC $villeMariage" >> "$ficCOM"
   [[ -n "$GEDCOM_divorce" || -n "$villeDivorce" || -n "$noteDivorce" ]] && echo "  1 DIV" >> "$ficCOM"

   [[ -n "$GEDCOM_divorce" ]] && echo " $GEDCOM_divorce" >> "$ficCOM"
   [[ -n "$villeDivorce" ]] && echo "  2 PLAC $villeDivorce" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" >> "$ficCOM"
   [[ -n "$noteDivorce" ]] && echo "  2 NOTE $noteDivorce" | sed -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" >> "$ficCOM"

   [[ -n "$nChild" ]] && echo "  1 CHIL @I$nChild@" >> "$ficCOM"
}

fam:search() {
   local I1="$1" I2="$2"
   local ficFAM
   local nFAMS=0

   ficFAM=$(grep -l "@I$I1@" "$TMP_DIR/FAM_"* | xargs grep -l "@I$I2@")
   nFAMS=${ficFAM//*_/}
   eval "$3=\"$nFAMS\""
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
      log "Trouvé Famille pour KeyID:[$KeyID] le [$nFAMS] sans Conjoint [$Conjoint]"
      eval "$3=\"$nFAMS\""
}




cache:uri_to_link() {
   local _uri="$1"

   echo "${_uri}" | sed -e 's/&/_/g' -e 's/=/_/g' -e 's/\?/_/g' -e 's/\+/_/g' -e 's/\].*$//g'
}


cache:filename(){
   local _uri="$1"
   local _fic="$2"
   local _link="" NbFicCache=0
   local _ficCache=""

   _link=$(cache:uri_to_link "$_uri")
   NbFicCache=$(grep "\[${_link}\]" "${FIC_CACHE}" | wc -l | bc)
   [[ "$NbFicCache" -ne 1 ]] && return 1
   _ficCache=$(grep "\[${_link}\]" "${FIC_CACHE}" | sed -e 's/^.*f:\[//g' -e 's/\].*$//g' -e "s/\$HOME/$(echo $HOME|sed -e 's/\//\\\//g')/g")
   echo "$_ficCache"
   return 0
}


cache:exist() {
   local _uri="$1"
   local _fic=""
   local _link="" NbFicCache=0
   local _ficCache=""

   _link=$(cache:uri_to_link "$_uri")
   NbFicCache=$(grep "\[${_link}\]" "${FIC_CACHE}" | wc -l | bc)

   if [[ "$NbFicCache" -eq 1 ]]; then
      _ficCache=$(grep "\[${_link}\]" "${FIC_CACHE}" | sed -e 's/^.*f:\[//g' -e 's/\].*$//g' -e "s/\$HOME/$(echo "$HOME"|sed -e 's/\//\\\//g')/g")
      sha256sum "$_ficCache" | sed -e 's/ .*$//g'
      return 1
   else
      echo ""
      return 0
   fi
}


cache:get(){
   local _uri="$1"
   local _fic="$2"
   local _ficCache="" sha256sum=""

   sha256sum=$(cache:exist "$_uri")
   retCode="$?"
#   [[ "$retCode" -eq 0 ]] && log:info "$_uri n'est pas en cache" || log:info "$_uri est en cache"
   [[ "$retCode" -eq 0 ]] && return 1
   _ficCache=$(cache:filename "$_uri")
#   log:info "nom fichier en cache [$_ficCache]"

   gunzip -c "$_ficCache" > "$_fic"
#   cp "$_ficCache" "$_fic"
   retCode="$?"
   return "$retCode"
}


cache:rm() {
   local _uri="$1"
   local _filename=""

   sha256sum=$(cache:exist "$_uri")
   retCode="$?"
   echo "sha256sum:[$sha256sum] retCode[$retCode]"
   [[ "$retCode" -eq 0 ]] && return 1
   _filename=$(cache:filename "$_uri")
   [[ "$?" -ne 0 ]] && return 1 
   ls -latr "$_filename"
   return 0
}


cache:put(){
   tab:inc
   local _uri="$1"
   local _fic="$2"
   local force="$3"
   local _link=""
   local _ficCache=$(uuidgen)
   local retCode=0

   local sha256_cache="" sha256_fic="" 
   
   nameFic="${DIR_CACHE}/$(uuidgen | tr '[:upper:]' '[:lower:]').gz"
   sha256_cache=$(cache:exist "${_uri}")
   retCode="$?"
   [[ "$retCode" -eq 1 ]] && log:info "Cette page [${_uri}] est déjà dans le cache" || log:info "Cette page [${_uri}] n'est pas dans le cache"
   [[ "$retCode" -eq 1 && "$force" == "false" ]] && return 0

   if [[ -n "$sha256_cache" ]]; then
      log:info "Page dans le cache, je vérifie le sha256sum"
      sha256_fic=$(sha256sum "$_fic" | sed -e 's/ .*$//g')
      if [[ "$sha256_cache" == "$sha256_fic" ]]; then
         log:info "[$_fic] et identique au cache, je ne fais rien"
         return 0
      fi
      log:info "sha256_cache:[$sha256_cache] sha256_fic:[$sha256_fic]"
      gzip -c "$_fic"  > "$nameFic"
#      cp "${_fic}" "$nameFic" 2>/dev/null 1>&2
      retCode="$?"
      [[ "$retCode" -ne 0 ]] && log:info "Mise a jour du cache" || log:info "Erreur de copie, pas de mise a jour du cache"
   else
      log:info "Pas dans le cache, je copie [$_fic] dans [$nameFic]"
      gzip -c "$_fic"  > "$nameFic"
#      cp "${_fic}" "${nameFic}" 2>/dev/null 1>&2
#      cp "${_fic}" "${nameFic}" 2>/dev/null 1>&2
      retCode="$?"
      [[ "$retCode" -eq 0 ]] && log:info "Pas d'erreur de copie" || log:info "Erreur lors de la copie de $_fic"
      if [[ "$retCode" -eq 0 ]]; then
         _link=$(cache:uri_to_link "$_uri")
         echo "l:[$_link] f:[$nameFic]" >> "${FIC_CACHE}"
         return 0
      else
         return 1
      fi
   fi
   tab:dec
quitter 0
   return 0
}


cache:test() {
   local _uri=$(echo "$1" | sed -e 's/^.*net.org\///g' -e "s/type=fiche//g" -e "s/&$//g")

   echo "$_uri"   
   cache:rm "$_uri"
   retCode="$?"
   [[ "$retCode" -ne 0 ]] && echo "Cette pas [$_uri] n'existe pas" || echo "Cette page [$_uri] existe"
}

lst() {
   echo "lst"
}
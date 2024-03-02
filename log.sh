tab:inc() {
   return 0
   local tab=$(cat "/tmp/tab")   
   echo -n "$tab   " > "/tmp/tab"
}

tab:dec() {
   return 0
   local tab=$(cat "/tmp/tab") 
   local _tab=""

   len=$((${#tab}))
   [[ "$len" -ne 0 ]] && len=$(( len - 3 ))
   _tab=$(printf "%${len}s" "")
   echo -n "$_tab" > "/tmp/tab"
}

tab:get() {
   echo ""
   return 0
   cat "/tmp/tab"
}

log () {
   local tab=$(tab:get)
   local idFct=""
   local chrono
   if [[ "$TRACE" == "true" ]]; then
      [[ "$CHRONO" == "true" ]] && chrono=$(date "+%d/%m/%Y %T ")
      local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]} lineAppelant=${BASH_LINENO[1]}
      TRACE_SCRIPT=$(echo "TRACE_${file}" | tr A-Z a-z | sed -e "s/.sh$//g")
      TRACE_FUNCTION=$(echo "TRACE_${func}" | tr A-Z a-z  | sed -e 's/:/_/g')
      [[ "${!TRACE_FUNCTION}" == "false" ]] && return 0
      [[ "${!TRACE_SCRIPT}" == "false" ]] && return 0
      idFct=$(printf "%50s" "${chrono}${file##*/}:$lineAppelant:$func:$line")
      idFct=$(printf "%50s" "${chrono}[${FUNCNAME[2]}:$lineAppelant][$func:$line]")
      echo "$idFct: $tab$*"
#      echo "${chrono}${file##*/}:$lineAppelant:$func:$line: $tab$*"
   fi
}

error() {
   log "$@" >&2
   quitter 1
}




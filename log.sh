log () {
   local chrono
   if [[ "$TRACE" == "true" ]]; then
      [[ "$CHRONO" == "true" ]] && chrono=$(date "+%d/%m/%Y %T ")
      local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]} lineAppelant=${BASH_LINENO[1]}
      TRACE_SCRIPT=$(echo "TRACE_${file}" | tr A-Z a-z | sed -e "s/.sh$//g")
      TRACE_FUNCTION=$(echo "TRACE_${func}" | tr A-Z a-z  | sed -e 's/:/_/g')
      [[ "${!TRACE_FUNCTION}" == "false" ]] && return 0
      [[ "${!TRACE_SCRIPT}" == "false" ]] && return 0
      echo "${chrono}${file##*/}:$lineAppelant:$func:$line: $tab$*"
   fi
}

erreur() {
   {
      echo "usage: $(basename "$0") : "
      echo "$*"
   } >&2
}




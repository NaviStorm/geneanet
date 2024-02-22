function log () {
   if [[ "$TRACE" == "true" || "$LOG" == "true" ]]; then
      [[ "$CHRONO" == "true" ]] && chrono=$(date "+%d/%m/%Y %T ")
      local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]} lineAppelant=${BASH_LINENO[1]}
      TRACE_SCRIPT=$(echo "TRACE_${file}" | tr A-Z a-z | sed -e "s/.sh$//g")
      TRACE_FUNCTION=$(echo "TRACE_${func}" | tr A-Z a-z)
      [[ "${!TRACE_FUNCTION}" == "false" ]] && return 0
      [[ "${!TRACE_SCRIPT}" == "false" ]] && return 0
      echo "${chrono}${file##*/}:$lineAppelant:$func:$line: $tab$*"
   fi
}

function logOLD () {
#   echo "log.1:${BASH_SOURCE[2]}"
#   echo "log.2:${FUNCNAME[2]}"
#   echo "log.3[${BASH_LINENO[0]}]"
#   echo "LOG ${BASH_SOURCE[1]##*/}:${FUNCNAME[1]}[${BASH_LINENO[0]}] $@"
#   return
   local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]}
   echo "${file##*/}:$func:$line $*"; return
   line() {
      echo "${funcfiletrace[2]}" | sed -e 's/^.*://g'
   }
   if [[ "$TRACE" == "true" || "$LOG" == "true" ]]; then
      if [[ -n $BASH_VERSION ]]; then
         #printf "$tab%s\n" "$(date "+%d/%m/%Y %T") ${FUNCNAME[1]}[${BASH_LINENO[$((${#BASH_LINENO[1]} - 2))]}] $@"
         printf "$tab%s\n" "$(date "+%d/%m/%Y %T") ${FUNCNAME[1]}[${BASH_LINENO[0]}] $@"
      else  # zsh
         printf "$tab%s\n" "$(date "+%d/%m/%Y %T") ${funcstack[@]:1:1}[$(line)] : $@"
      fi
   fi
}

function erreur() {
   {
      echo "usage: $(basename "$0") : "
      echo "$*"
   } >&2
}




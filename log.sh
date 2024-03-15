tab:init() {
   echo "" > "/tmp/tab"
}

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


log:put() {
   local _level="$1"

   shift
   echo "$@"
}

log:info() {
   local tab=$(tab:get)
   local idFct=""
   local chrono=""

   if [[ "$TRACE" == "true" ]]; then
      [[ "$CHRONO" == "true" ]] && chrono=$(date "+%d/%m/%Y %T ")
      local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]} lineAppelant=${BASH_LINENO[1]}
      TRACE_SCRIPT=$(echo "TRACE_${file}" | tr A-Z a-z | sed -e "s/.sh$//g")
      TRACE_FUNCTION=$(echo "TRACE_${func}" | tr A-Z a-z  | sed -e 's/:/_/g')
      [[ "${!TRACE_FUNCTION}" == "false" ]] && return 0
      [[ "${!TRACE_SCRIPT}" == "false" ]] && return 0
      idFct=$(printf "%s" "${chrono}[${FUNCNAME[2]}:$lineAppelant][$func:$line]")
      log:put "INFO" "$idFct: $tab$*"
#      echo "${chrono}${file##*/}:$lineAppelant:$func:$line: $tab$*"
   fi
}

log:debug() {
   local tab=$(tab:get)
   local idFct=""
   local chrono=""
   
   if [[ "$DEBUG" == "true" ]]; then
      [[ "$CHRONO" == "true" ]] && chrono=$(date "+%d/%m/%Y %T ")
      local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]} lineAppelant=${BASH_LINENO[1]}
      TRACE_SCRIPT=$(echo "TRACE_${file}" | tr A-Z a-z | sed -e "s/.sh$//g")
      TRACE_FUNCTION=$(echo "TRACE_${func}" | tr A-Z a-z  | sed -e 's/:/_/g')
      [[ "${!TRACE_FUNCTION}" == "false" ]] && return 0
      [[ "${!TRACE_SCRIPT}" == "false" ]] && return 0
      idFct=$(printf "%s" "${chrono}[${FUNCNAME[2]}:$lineAppelant][$func:$line]")
      log:put "DEBUG" "$idFct: $tab$*"
   fi
}


log:error() {
   local tab=$(tab:get)
   local idFct=""

   local file=${BASH_SOURCE[1]##*/} func=${FUNCNAME[1]} line=${BASH_LINENO[0]} lineAppelant=${BASH_LINENO[1]}
   idFct=$(printf "%s" "[${FUNCNAME[2]}:$lineAppelant][$func:$line]")
   log:put "ERROR" "$idFct: FATAL ERROR $tab$*" >&2
   return 1
}



spin() {
   printf "\b${sp:sc++:1}"
   ((sc==${#sp})) && sc=0
}

pauseRunSH() {
	local filename="" pause="" runsh="" i=0

	filename=$(basename -- "$0")
	filename="${filename%.*}"

	pause="/tmp/$filename.pause.$$"
	runsh="/tmp/$filename.runsh.$$"
	if [[ -f "$runsh" ]]; then
      rm $runsh 2>/dev/null 1>&2
		bash
	fi
	if [[ -f "$pause" ]]; then
		echo -n "Pause ."
		i=0
		while [ -f "$pause" ]; do
			spin
		done
	fi
}

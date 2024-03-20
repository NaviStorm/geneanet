SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/var.sh"

readini(){
   local _fic="$1"
   local _key="$2"
   local _value=""


   # !!6M@84!j$uej9454GQ4
   _value=$(cat "$_fic" | grep "^$_key" | sed -e "s/^$_key=//g" 2>/dev/null)
   if [[ ${_value:0:1} == "'"* || ${_value:0:1} == "\""* ]]; then
      len=$(( ${#_value} - 2 ))
      _value=${_value:1:len}
   fi
   echo "$_value"
}


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
   echo "$@" >&2
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

	local pause="/tmp/$filename.pause.$$"
	local runsh="/tmp/$filename.runsh.$$"
	local fic_opt="/tmp/$filename.opt.$$"
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
	if [[ -f "$fic_opt" ]]; then
      local _OPT_CACHE=$(readini "$fic_opt" "opt-cache")
      local _OPT_SOURCE=$(readini "$fic_opt" "opt-source")
      local _OPT_NOTE=$(readini "$fic_opt" "opt-note")
      local _OPT_TRACE=$(readini "$fic_opt" "opt-trace")
      local _OPT_DEBUG=$(readini "$fic_opt" "opt-debug")
      local _OPT_CHRONO=$(readini "$fic_opt" "opt-chrono")
      [[ "$_OPT_CACHE" == "1" || "$_OPT_CACHE" == "0" ]] && OPT_CACHE=$_OPT_CACHE
      [[ "$_OPT_SOURCE" == "1" || "$_OPT_SOURCE" == "0" ]] && OPT_SOURCE=$_OPT_SOURCE
      [[ "$_OPT_NOTE" == "1" || "$_OPT_C_OPT_NOTEACHE" == "0" ]] && OPT_NOTE=$_OPT_NOTE
      
      [[ "$_OPT_TRACE" == "true" || "$_OPT_TRACE" == "false" ]] && TRACE=$_OPT_TRACE
      [[ "$_OPT_DEBUG" == "true" || "$_OPT_DEBUG" == "false" ]] && DEBUG=$_OPT_CACHE
      [[ "$_OPT_CHRONO" == "true" || "$_OPT_CHRONO" == "false" ]] && CHRONO=$_OPT_CHRONO
      mv "$fic_opt" "${fic_opt}.bck"2>/dev/null 1>&2
	fi
}

typeset -i _logging=0
typeset -i _logging_debug=0
typeset _logging_fmt="json"
typeset _logging_chrono=""

readini(){
   local _fic="$1"
   local _key="$2"
   local _value=""
   local -i len=0

   _value=$(cat "$_fic" | grep "^$_key" | sed -e "s/^$_key=//g" 2>/dev/null)
   if [[ ${_value:0:1} == "'"* || ${_value:0:1} == "\""* ]]; then
      len=$(( ${#_value} - 2 ))
      _value=${_value:1:len}
   fi
   echo "$_value"
}


log:put() {
   local _level="$1"
   shift

   builtin echo "$_level $@" >&2
}

log:date() {
   date "+%Y-%m-%dT%T.%03N"  
}


log:active() {
   typeset -i _ActiveLog="$1"
   if (( _ActiveLog )) ; then
      _logging=1
   else
      _logging=0
   fi
}


log:debug:active() {
   typeset -i _ActiveDebug="$1"
   if (( _ActiveDebug )) ; then
      _logging_debug=1
   else
      _logging_debug=0
   fi
}


log:info() {
   local _logging_chrono=""; _logging_chrono=$(date "+%Y-%m-%dT%T.%03N")
   local _file=${BASH_SOURCE[1]##*/} _func=${FUNCNAME[1]} _line=${BASH_LINENO[0]} _lineAppelant=${BASH_LINENO[1]}
   local _idFct=""; idFct=$(printf "%s" "${_logging_chrono} [${FUNCNAME[2]}:$_lineAppelant][$_func:$_line]")


   local src="" i=0
   # à partir de 1 car je ne veux pas l'info log:info:ligne
   # Jusqu'a ${#FUNCNAME[@]}-2, car je ne veux mpas le main:0 et le main:365
#   for (( i=1; i<((${#FUNCNAME[@]}-2)); i++ )); do
#      [[ -n "$src" ]] && src="${FUNCNAME[$i]}:${BASH_LINENO[((i-1))]} $src" || src="${FUNCNAME[$i]}:${BASH_LINENO[((i-1))]}"
#   done
#   src="[$src]"

   if (( _logging )); then
      if [[ "$_logging_fmt" == "json" ]]; then
         builtin echo "{\"timestamp\": \"$_logging_chrono\",\"level\": \"INFO\", \"fct0\":\"${FUNCNAME[2]}:${BASH_LINENO[1]}\", \"fct\": \"${FUNCNAME[1]}:${BASH_LINENO[0]}\",\"message\": \"$*\"}"  >&2
#         builtin echo "{\"timestamp\": \"$_logging_chrono\",\"level\": \"INFO\", \"src0\": \"${BASH_SOURCE[2]##*/}\",\"fct0\":\"${FUNCNAME[2]}\",\"line0\": \"${BASH_LINENO[1]}\", \"src\": \"${BASH_SOURCE[1]##*/}\",\"fct\": \"${FUNCNAME[1]}\",\"line\": \"${BASH_LINENO[0]}\",\"message\": \"$*\"}"  >&2
      else
         builtin echo "[INFO]  ${FUNCNAME[1]}:${BASH_LINENO[0]} : $*"  >&2
#         log:put "[INFO] " "$_idFct: $*"
      fi
   fi
}

log:debug() {
   local _logging_chrono=""; _logging_chrono=$(date "+%Y-%m-%dT%T.%03N")
   local _file=${BASH_SOURCE[1]##*/} _func=${FUNCNAME[1]} _line=${BASH_LINENO[0]} _lineAppelant=${BASH_LINENO[1]}
   local _idFct=""; idFct=$(printf "%s" "${_logging_chrono} [${FUNCNAME[2]}:$_lineAppelant][$_func:$_line]")

   if (( _logging_debug )); then
      if [[ "$_logging_fmt" == "json" ]]; then
#         builtin echo "{\"timestamp\": \"$_logging_chrono\",\"level\": \"DEBUG\", \"src0\": \"${BASH_SOURCE[2]##*/}\",\"fct0\":\"${FUNCNAME[2]}\",\"line0\": \"${BASH_LINENO[1]}\", \"src\": \"${BASH_SOURCE[1]##*/}\",\"fct\": \"${FUNCNAME[1]}\",\"line\": \"${BASH_LINENO[0]}\",\"message\": \"$*\"}"  >&2
         builtin echo "{\"timestamp\": \"$_logging_chrono\",\"level\": \"INFO\", \"fct0\":\"${FUNCNAME[2]}:${BASH_LINENO[1]}\", \"fct\": \"${FUNCNAME[1]}:${BASH_LINENO[0]}\",\"message\": \"$*\"}"  >&2
      else
         builtin echo "[DEBUG] ${FUNCNAME[1]}:${BASH_LINENO[0]} : $*"  >&2
#         log:put "[DEBUG] " "$_idFct: $*"
      fi
   fi
}


log:error() {
   local _logging_chrono=""; _logging_chrono=$(date "+%Y-%m-%dT%T.%03N")
   local _file=${BASH_SOURCE[1]##*/} _func=${FUNCNAME[1]} _line=${BASH_LINENO[0]} _lineAppelant=${BASH_LINENO[1]}
   local _idFct=""; idFct=$(printf "%s" "${_logging_chrono} [${FUNCNAME[2]}:$_lineAppelant][$_func:$_line]")

   if (( _logging_debug )); then
      if [[ "$_logging_fmt" == "json" ]]; then
#         builtin echo "{\"timestamp\": \"$_logging_chrono\",\"level\": \"ERROR\", \"src0\": \"${BASH_SOURCE[2]##*/}\",\"fct0\":\"${FUNCNAME[2]}\",\"line0\": \"${BASH_LINENO[1]}\", \"src\": \"${BASH_SOURCE[1]##*/}\",\"fct\": \"${FUNCNAME[1]}\",\"line\": \"${BASH_LINENO[0]}\",\"message\": \"$*\"}"  >&2
         builtin echo "{\"timestamp\": \"$_logging_chrono\",\"level\": \"INFO\", \"fct0\":\"${FUNCNAME[2]}:${BASH_LINENO[1]}\", \"fct\": \"${FUNCNAME[1]}:${BASH_LINENO[0]}\",\"message\": \"$*\"}"  >&2
      else
         builtin echo "[ERROR] ${FUNCNAME[1]}:${BASH_LINENO[0]} : $*"  >&2
#         log:put "[ERROR] " "$_idFct: $*"
      fi
   fi
}

log:errorOLD() {
   local _logging_chrono=""; _logging_chrono=$(date "+%Y-%m-%dT%T.%03N")
   local _file=${BASH_SOURCE[1]##*/} _func=${FUNCNAME[1]} _line=${BASH_LINENO[0]} _lineAppelant=${BASH_LINENO[1]}
   local _idFct=""; idFct=$(printf "%s" "${_logging_chrono} [${FUNCNAME[2]}:$_lineAppelant][$_func:$_line]")

   log:put "[ERROR]" "$_idFct: FATAL ERROR $*" >&2
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

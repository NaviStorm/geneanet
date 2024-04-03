file:get() {
   local _p=""

   eval _p="$pattern"
   printf "$_p" "$@"
}

vartype() {
    local var=$( declare -p "$1" 2>/dev/null )
    local reg='^declare -n [^=]+=\"([^\"]+)\"$'
    while [[ $var =~ $reg ]]; do
            var=$( declare -p ${BASH_REMATCH[1]} )
    done

    case "${var#declare -}" in
    a*)
            echo "ARRAY"
            ;;
    A*)
            echo "HASH"
            ;;
    i*)
            echo "INT"
            ;;
    x*)
            echo "EXPORT"
            ;;
    *)
            echo "OTHER"
            ;;
    esac
}

file:write() {
   local _fic="$1"
   local _value="$2"

   log:info "write [$_value] NbElem:[${#_value[@]}] dans fic:[$_fic]"
   echo "$_value" >> "$_fic"
   return "$?"
}

tst() {
   local KeyID="$1"
   file:get "all_page"
}

#TMP_DIR="/tmp"
#pattern="$TMP_DIR/gen_%04d_%s"
#KeyID=8
#tst 1
#echo
#tst 56
#file:get 1 "all_page"

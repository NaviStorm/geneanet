file:get() {
   local _p=""

   eval _p="$pattern"
   builtin printf "$_p" "$@"
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
   builtin echo "$2" >> "$1"
   return "$?"
}

tst() {
   local KeyID="$1"
   file:get "all_page"
}

trace_cherche_source="false"

edit_source() {
    local _ref=$1
    local section=$2
    local __srcIndi="" __srcNaissance="" __srcUnion="" __srcDeces=""
    local _ref=""

    log:info "DEB edit_source ref:[$ref] section:[$section]"
    
    if [[ "${_ref}" != "" ]]; then
        if [[ "$section" == "$LB_SRC_PERSONNE" ]]; then
        __srcIndi="${_ref}"
        elif [[ "$section" == "$LB_SRC_NAISSANCE" ]]; then
        __srcNaissance="${_ref}"
        elif [[ "$section" == "$LB_SRC_UNION" ]]; then
        __srcUnion="${_ref}"
        elif [[ "$section" == "$LB_SRC_DECES" ]]; then
        __srcDeces=$(echo "${_ref}")
        fi
    fi
    [[ "$__srcIndi" != "" ]] && eval "$3=\"$__srcIndi\""
    [[ "$__srcNaissance" != "" ]] && eval "$4=\"$__srcNaissance\""
    [[ "$__srcUnion" != "" ]] && eval "$5=\"$__srcUnion\""
    [[ "$__srcDeces" != "" ]] && eval "$6=\"$__srcDeces\""
    log:info "FIN edit_source __srcIndi:[${__srcIndi}] __srcNaissance:[$__srcNaissance] __srcUnion:[$__srcUnion] __srcDeces:[$__srcDeces]"
}


cherche_source() {
    local _fic="$1"
    local ficSource="${TMP_DIR}_source_$$"

    local _srcIndi="" _srcNaissance="" _srcUnion="" _srcDeces="" x_ligne="false" deb_ligne=0 fin_ligne=0

    sed -e '1,/^<!-- sources -->/d' -e '/^<div id="block\-media"/,10000d' "$_fic" |\
        sed -e '1,/^<ul>/d' -e '/^<\/ul>/,10000d' -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" -e 's/<a>//g' -e 's/<\/a>//g' -e 's/<br>//g' -e 's/<\/br>//g' > "${ficSource}"

    log:info "DEB cherche_source ficSource:[$ficSource]"
    while read -r ligne_html; do
        deb_ligne=$(echo $ligne_html | grep -E "^<li>" | wc -l | bc)
        if [[ "$deb_ligne" -eq 1 ]]; then
            section=$(echo $ligne_html | sed -e 's/<li>//g' -e 's/:.*$//g')
            local fin_ligne=$(echo $ligne_html | grep -E "<\/li>" | wc -l | bc)
            if [[ "$fin_ligne" -eq 1 ]]; then
                log:info "ligne_html:[$ligne_html] section:[$section]"
                ref=$(echo $ligne_html | sed -e "s/^.*$section: //g" -e 's/<\/li>.*$//g')
                [[ "$?" -ne 0 ]] && return 1
                edit_source "$ref" "$section" _srcIndi _srcNaissance _srcUnion _srcDeces
                x_ligne="false"
            else
                ref=""
                x_ligne="true"
            fi
            continue
        else
            if [[ "$x_ligne" == "true" ]]; then
            local deb_ref=$(echo $ligne_html | grep -E "^<dt>" | wc -l | bc)
            if [[ "$deb_ref" -eq 1 ]]; then
                ref=$(echo $ligne_html | sed -e 's/^<dt>//g' -e 's/<\/dt>.*//g')   
                x_ligne="false"
                edit_source "$ref" "$section" _srcIndi _srcNaissance _srcUnion _srcDeces
            else
                ref=""
            fi
            else
            ref=""
            fi
        fi
    done < "$ficSource"
    rm "${ficSource}"
    log:info "FIN cherche_source _srcIndi:[$_srcIndi]_srcNaissance:[$_srcNaissance] _srcUnion:[$_srcUnion]_srcDeces:[$_srcDeces]"
    eval "$2=\"$_srcIndi\""
    eval "$3=\"$_srcNaissance\""
    eval "$4=\"$_srcUnion\""
    eval "$5=\"$_srcDeces\""
}


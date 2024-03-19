trace_cherche_source="true"

source:edit() {
    local _ref=$1
    local section=$2

    log:info "DEB ref:[$ref] section:[$section]"
    
    if [[ "${_ref}" != "" ]]; then
        case "$section" in
            "$LB_SRC_PERSONNE"*) g_srcIndi="${_ref}";;
            "$LB_SRC_NAISSANCE"*) g_srcNaissance="${_ref}";;
            "$LB_SRC_UNION"*) g_srcUnion="${_ref}";;
            "$LB_SRC_DECES"*) g_srcDeces="${_ref}";;
            *) 
            log:error " Type de source inconnue [$section]";;
        esac
    fi
    log:debug "FIN g_srcIndi:[${g_srcIndi}] g_srcNaissance:[$g_srcNaissance] g_srcUnion:[$g_srcUnion] g_srcDeces:[$g_srcDeces]"
}


source:get() {
    local _fic="$1"
    local ficSource="${TMP_DIR}_source_$$"

    local _srcIndi="" _srcNaissance="" _srcUnion="" _srcDeces="" x_ligne="false" deb_ligne=0 fin_ligne=0

    sed -e '1,/^<!-- sources -->/d' -e '/^<div id="block\-media"/,10000d' "$_fic" |\
        grep "^<li>" | sed -e 's/^<li>//g' -e "s/<\/li>//g" -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" > "${ficSource}"

    log:info "DEB ficSource:[$ficSource]"
    while read -r ligne_html; do
        deb_ligne=$(echo $ligne_html | grep -E "^<li>" | wc -l | bc)
        if [[ "$deb_ligne" -eq 1 ]]; then
            section=$(echo $ligne_html | sed -e 's/<li>//g' -e 's/:.*$//g')
            local fin_ligne=$(echo $ligne_html | grep -E "<\/li>" | wc -l | bc)
            if [[ "$fin_ligne" -eq 1 ]]; then
                log:info "ligne_html:[$ligne_html] section:[$section]"
                ref=$(echo $ligne_html | sed -e "s/^.*$section: //g" -e 's/<\/li>.*$//g')
                [[ "$?" -ne 0 ]] && return 1
                source:edit "$ref" "$section"
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
                    source:edit "$ref" "$section"
                else
                    ref=""
                fi
            else
                ref=""
            fi
        fi
    done < "$ficSource"
    rm "${ficSource}"
    log:debug "FIN g_srcIndi:[${g_srcIndi}] g_srcNaissance:[$g_srcNaissance] g_srcUnion:[$g_srcUnion] g_srcDeces:[$g_srcDeces]"
}


source:getOLD() {
    local _fic="$1"
    local ficSource="${TMP_DIR}_source_$$"

    local _srcIndi="" _srcNaissance="" _srcUnion="" _srcDeces="" x_ligne="false" deb_ligne=0 fin_ligne=0

    sed -e '1,/^<!-- sources -->/d' -e '/^<div id="block\-media"/,10000d' "$_fic" |\
        grep "^<li>" | sed -e '1,/^<ul>/d' -e '/^<\/ul>/,10000d' -e "s/&#34;/\"/g" -e "s/&#39;/\'/g" -e 's/<a>//g' -e 's/<\/a>//g' -e 's/<br>//g' -e 's/<\/br>//g' > "${ficSource}"

    log:info "DEB ficSource:[$ficSource]"
    while read -r ligne_html; do
        deb_ligne=$(echo $ligne_html | grep -E "^<li>" | wc -l | bc)
        if [[ "$deb_ligne" -eq 1 ]]; then
            section=$(echo $ligne_html | sed -e 's/<li>//g' -e 's/:.*$//g')
            local fin_ligne=$(echo $ligne_html | grep -E "<\/li>" | wc -l | bc)
            if [[ "$fin_ligne" -eq 1 ]]; then
                log:info "ligne_html:[$ligne_html] section:[$section]"
                ref=$(echo $ligne_html | sed -e "s/^.*$section: //g" -e 's/<\/li>.*$//g')
                [[ "$?" -ne 0 ]] && return 1
                source:edit "$ref" "$section"
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
                source:edit "$ref" "$section"
            else
                ref=""
            fi
            else
            ref=""
            fi
        fi
    done < "$ficSource"
    rm "${ficSource}"
    log:debug "FIN g_srcIndi:[${g_srcIndi}] g_srcNaissance:[$g_srcNaissance] g_srcUnion:[$g_srcUnion] g_srcDeces:[$g_srcDeces]"
}


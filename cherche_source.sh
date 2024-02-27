#!/bin/bash

trace_cherche_source="true"

edit_source() {
    local ref=$1
    local section=$2
    local __srcIndi="" __srcNaissance="" __srcUnion="" __srcDeces=""

    log "DEB edit_source ref:[$ref] section:[$section]"
    if [[ "$ref" != "" ]]; then
        if [[ "$section" == "$LB_SRC_PERSONNE" ]]; then
        __srcIndi="$ref"
        elif [[ "$section" == "$LB_SRC_NAISSANCE" ]]; then
        __srcNaissance="$ref"
        elif [[ "$section" == "$LB_SRC_UNION" ]]; then
        __srcUnion="$ref"
        elif [[ "$section" == "$LB_SRC_DECES" ]]; then
        __srcDeces="$ref"
        fi
    fi
    [[ "$__srcIndi" != "" ]] && eval "$3=\"$__srcIndi\""
    [[ "$__srcNaissance" != "" ]] && eval "$4=\"$__srcNaissance\""
    [[ "$__srcUnion" != "" ]] && eval "$5=\"$__srcUnion\""
    [[ "$__srcDeces" != "" ]] && eval "$6=\"$__srcDeces\""
    log "FIN edit_source __srcIndi:[${__srcIndi}] __srcNaissance:[$__srcNaissance] __srcUnion:[$__srcUnion] __srcDeces:[$__srcDeces]"
}


cherche_source() {
    local ficSource="$1"
    local _srcIndi="" _srcNaissance="" _srcUnion="" _srcDeces="" x_ligne="false" deb_ligne=0 fin_ligne=0

    log "DEB cherche_source ficSource:[$ficSource]"
    while read -r ligne_html; do
        deb_ligne=$(echo $ligne_html | grep -E "^<li>" | wc -l | bc)
        if [[ "$deb_ligne" -eq 1 ]]; then
            section=$(echo $ligne_html | sed -e 's/<li>//g' -e 's/:.*$//g')
            local fin_ligne=$(echo $ligne_html | grep -E "<\/li>" | wc -l | bc)
            if [[ "$fin_ligne" -eq 1 ]]; then
                log "ligne_html:[$ligne_html] section:[$section]"
                ref=$(echo $ligne_html | sed -e "s/^.*$section: //g" -e 's/<\/li>.*$//g')
                [[ "$?" -ne 0 ]] && quitter 1
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
   log "FIN cherche_source _srcIndi:[$_srcIndi]_srcNaissance:[$_srcNaissance] _srcUnion:[$_srcUnion]_srcDeces:[$_srcDeces]"
   eval "$2=\"$_srcIndi\""
   eval "$3=\"$_srcNaissance\""
   eval "$4=\"$_srcUnion\""
   eval "$5=\"$_srcDeces\""
}


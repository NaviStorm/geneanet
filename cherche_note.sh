trace_cherche_note="true"

note:edit() {
    local type_note=$1
    local note=$(echo "$2" | sed -e 's/&#62/>/g' -e 's/&#60;/</g' -e 's/&#47;/\//g' -e 's/&#41;/)/g' -e 's/&#40;/(/g' -e 's/&#38;/\&/g' -e 's/&#37;/%/g' -e 's/&#36;/$/g' -e 's/&#35;/#/g' -e 's/&#34;/"/g' -e 's/&#33;/!/g' -e 's/&#42;/*/g' -e 's/&#43;/+/g')

    log:info "DEB: type_note:[$type_note] note:[$note]"
    case "$type_note" in
        "indi") g_noteIndi="$note";;
        "naissance") g_noteNaissance="$note";;
        "union") g_noteFamille="$note";;
        "union_avec") g_noteMariage="$note";;
        "deces") g_noteDeces="$note";;
        "famille") g_noteFamille="$note";;
        *)
            log:error "Type note inconnue [$type_note]"
    esac

    log:info "Fin: g_noteIndi:[$g_noteIndi] g_noteNaissance:[$g_noteNaissance] g_noteFamille:[$g_noteFamille] g_noteUnion:[$g_noteDeces] g_noteDeces:[$g_noteDeces]"
    return 0
}

note:get() {
    local _fic="$1"
    local ficNote="${1}_note"
#    local ficNote="${TMP_DIR}_note_$$"
    local line=""
    local deb_section=0 note="" type=""

    sed -e '1,/^<!-- notes -->/d' -e '/^<!-- /,10000d' -e 's/<a href="//g' -e 's/<\/a>//g' -e 's/<\/p>//g' -e 's/<br>//g' -e 's/ <p>//g' "$_fic" |\
        grep -v 'div.*class' | grep -v '^<p>$' | grep -v '^</p>$' | grep -v '^</div>$' | grep -v '<p style=' | sed -e 's/<\/div>//g' > "$ficNote"

    log:info "DEB note:get ficNote:[$ficNote]"
    while read -r line; do
        deb_section=$(echo "$line" | grep -E "<h3>|<h3 |note-wed-" | wc -l | bc)
        # log:info "deb_section:[$deb_section] $line"
        if [[ "$deb_section" -eq 1 && "$note" != "" ]]; then
            # log:info "deb_section:[$deb_section] note:[$note] Appel note:edit ($type)"
            note:edit "$type" "$note" _noteIndi _noteNaissance _noteUnion _noteDeces _noteFamille
            note=""
        fi
        if [[ "$deb_section" -eq 1 ]]; then
            case "$line" in
                *">$LB_NOTE_PERSONNE<"*) type="indi";;
                *">$LB_NOTE_NAISSANCE<"*) type="naissance";;
                *">$LB_NOTE_UNION<"* ) type="union";;
                *">$LB_NOTE_UNION_AVEC<"*) type="union_avec";;
                *">$LB_NOTE_DECES<"*) type="deces";;
                *"note-wed"*) type="famille";;
                *)
                    log:error "Type note inconnue [$line]"
            esac
            note_inclus=$(echo "$line" | sed -e 's/^.*<\/h3>$//g' -e 's/^.*note-wed-1"><p>//g')
            # log:info "note_inclus:[$note_inclus]"
            if [[ "$note_inclus" != "" ]]; then
                note_tmp=$(echo "$line" | sed -e 's/^.*<\/h3>//g' | sed -e 's/<p.*$//g')
                # log:info "note_tmp:[$note_tmp]"
                note="$note $note_tmp"
                # log:info "note:[$note]"
            fi
            continue
        else
            if [[ "$type" != "" && "$line" != "" ]]; then
                # log:info "$type != \"\""
                note_tmp=${line//ototototototo/}
                # log:info "$type != \"\" note_tmp:[$note_tmp]"
                if [[ "$note" == "" ]]; then
                    note="$note_tmp"
                else
                    note="$note@n@$note_tmp"
                fi
                # log:info "$type != \"\" note:[$note]"
                deb_section=0
            fi
        fi
    done < $ficNote
    if [[ "$type" != "" && "$note" != "" ]]; then
        note:edit "$type" "$note" _noteIndi _noteNaissance _noteUnion _noteDeces _noteFamille
        note=""
    fi
#    rm "$ficNote"

    log:info "Fin: g_noteIndi:[$g_noteIndi] g_noteNaissance:[$g_noteNaissance] g_noteFamille:[$g_noteFamille] g_noteUnion:[$g_noteDeces] g_noteDeces:[$g_noteDeces]"
    return 0
}

note:get:autre() {
    local _KeyID="$1"
    local lig="" plig="" type="" _note="" _noBirth="" _noBaptism="" _noMarriage="" _noDivorce="" _noDeath=""
    local -i span=0

    pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
    local _fic=$(file:get $KeyID all_page)
    local _fic_note=$(file:get $KeyID autre_note)
    sed -e '1,/^<!-- Timeline/d' -e '/<!-- notes/,10000d' -e '/<tr>/d' -e '/$<\/tr>$/d' -e '/^<td>$/d' -e '/^<\/td>$/d'  -e '/class="ddate/d' -e '/<br>/d' -e '/valign/d' -e '/show-for-/d' -e '/<\/p><\/div>/d' -e 's/<p>//g' -e 's/<\/tr>//g' "$_fic" > "$_fic_note"
    ifs=''
    span=0
    while read lig; do
        [[ "$lig" == "" ]] && continue
        if [[ ( "$lig" == "<span class=\"nnom\">" || "$lig" == "</table>" ) && $span -ne 0 ]]; then
            log:info "type:[$type] _note:[$_note] _source:[$_source]"
            case "$type" in
                "Birth")
                    _noBirth="$_note"
                    _sBirth="$_source"
                    ;;
                "Baptism")
                    _noBaptism="$_note"
                    _sBaptism="$_source"
                    ;;
                "Marriage")
                    _noMarriage="$_note"
                    _sMarriage="$_source"
                    ;;
                "Divorce")
                    _noDivorce="$_note"
                    _sDivorce="$_source"
                    ;;
                "Death")
                    _noDeath="$_note"
                    _sDeath="$_source"
                    ;;
            esac
        fi
        if [[ "$lig" == "<span class=\"nnom\">" ]]; then
#            log:info "span trouvé=[$lig]"
            _note=""
            _source=""
            span=1
            continue
        fi
        if [[ $span -eq 1 ]]; then
            type=$(echo $lig | sed -e 's/ .*$//g')
#            log:info "type:[$type]"
            span=2
            continue
        fi
        if [[ $span -eq 2 && "$lig" == *"nnotes"* &&  "$lig" == *"/div"* ]]; then
            _note=$(echo "$lig" | sed -e 's/<\/div>.*$//g' -e "s/^.*\">//g")
#            log:info "lig:[$lig] type:[$type] _note:[$_note]"
            continue
        fi
        if [[ $span -eq 2 && "$lig" == "<div class=\"nnotes\">" ]]; then
            continue
        fi
        if [[ "$span -eq 2 && $lig" == *"class=\"ssource\">"* ]]; then
            _source=$(echo $lig | sed -e 's/^.*">//g' -e 's/<\/.*$//g' -e 's/^Sources: //')
#            log:info "source:[$_source]"
            continue
        fi
        if [[ $span -eq 2 ]]; then
            [[ "$_note" == "" ]] && _note="$lig" || _note="$_note@n@$lig"
#            log:info "lig:[$lig] _note:[$_note]"
            continue
        fi
#        log:info "non trité:[$lig]"
    done < "$_fic_note"
    echo "birth=[$_noBirth]&baptism=[$_noBaptism]&marriage=[$_noMarriage]&divorce=[$_noDivorce]&death=[$_noDeath]&sbirth=[$_sBirth]&sbaptism=[$_sBaptism]&smarriage=[$_sMarriage]&sdivorce=[$_sDivorce]&sdeath=[$_sDeath]"
}


main_cherche_note() {
    local TRACE="true"
    log:active "1"
    local chrono="false"
    local KeyID="0001"
    local my_pid="${KeyID}_${RANDOM}_${RANDOM}"
    local pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
    local noteIndi="" noteNaissance="" noteUnion="" noteDeces="" noteFamille=""


    cherche_note "/tmp/geneanet_test/gen_0001_all_page_1_13078_26650" noteIndi noteNaissance noteUnion noteDeces noteFamille
}

#main_cherche_note
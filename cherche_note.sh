trace_cherche_note="false"

edit_note() {
    local type_note=$1
    local note=$2
    local __noteIndi="" __noteNaissance="" __noteUnion="" __noteDeces="" __noteFamille=""

    log:info "DEB: cherche_note(): type_note:[$type_note] note:[$note]"
    if [[ "$type_note" == "indi" ]]; then
        __noteIndi="$note"
    elif [[ "$type_note" == "naissance" ]]; then
        __noteNaissance="$note"
    elif [[ "$type_note" == "union" ]]; then
        __noteFamille="$note"
    elif [[ "$type_note" == "union_avec" ]]; then
        __noteUnion="$note"
    elif [[ "$type_note" == "deces" ]]; then
        __noteDeces="$note"
    elif [[ "$type_note" == "famille" ]]; then
        __noteFamille="$note"
    fi
    [[ "$__noteIndi" != "" ]] && eval "$3=\"$__noteIndi\""
    [[ "$__noteNaissance" != "" ]] && eval "$4=\"$__noteNaissance\""
    [[ "$__noteUnion" != "" ]] && eval "$5=\"$__noteUnion\""
    [[ "$__noteDeces" != "" ]] && eval "$6=\"$__noteDeces\""
    [[ "$__noteFamille" != "" ]] && eval "$7=\"$__noteFamille\""
    log:info "Fin: cherche_note(): __noteIndi:[$__noteIndi] __noteNaissance:[$__noteNaissance] __noteFamille:[$__noteFamille] __noteUnion:[$__noteDeces] NOTE_DECES:[$__noteDeces]"
    return 0
}

cherche_note() {
    local _fic="$1"
    local ficNote="${TMP_DIR}_note_$$"
    local _noteIndi="" _noteNaissance="" _noteUnion="" _noteDeces="" _noteFamille="" line=""
    local deb_section=0 note="" type=""

    sed -e '1,/^<!-- notes -->/d' -e '/^<!-- /,10000d' -e 's/<a href="//g' -e 's/<\/a>//g' -e 's/<\/p>//g' -e 's/<br>//g' -e 's/ <p>//g' "$_fic" |\
        grep -v 'div.*class' | grep -v '^<p>$' | grep -v '^</p>$' | grep -v '^</div>$' | grep -v '<p style=' | sed -e 's/<\/div>//g' > "$ficNote"

    log:info "DEB cherche_note ficNote:[$ficNote]"
    while read -r line; do
        deb_section=$(echo "$line" | grep -E "<h3>|<h3 |note-wed-" | wc -l | bc)
        # log:info "deb_section:[$deb_section] $line"
        if [[ "$deb_section" -eq 1 && "$note" != "" ]]; then
            # log:info "deb_section:[$deb_section] note:[$note] Appel edit_note ($type)"
            edit_note "$type" "$note" _noteIndi _noteNaissance _noteUnion _noteDeces _noteFamille
            note=""
        fi
        if [[ "$deb_section" -eq 1 ]]; then
            if [[ "$line" == *">$LB_NOTE_PERSONNE<"* ]]; then
                # log:info "==> note individuelle"
                type="indi"
            elif [[ "$line" == *">$LB_NOTE_NAISSANCE<"* ]]; then
                # log:info "==> note Naissance"
                type="naissance"
            elif [[ "$line" == *">$LB_NOTE_UNION<"* ]]; then
                # log:info "==> Notes concernant l'union"
                type="union"
            elif [[ "$line" == *">$LB_NOTE_UNION_AVEC<"* ]]; then
                # log:info "==> note Union avec"
                type="union_avec"
            elif [[ "$line" == *">$LB_NOTE_DECES<"* ]]; then
                # log:info "==> note Deces"
                type="deces"
            elif [[ "$line" == *"note-wed"* ]]; then
                # log:info "==> note note.wed"
                type="famille"
            fi
            note_inclus=$(echo $line | sed -e 's/^.*<\/h3>$//g' -e 's/^.*note-wed-1"><p>//g')
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
                    note="$note\n$note_tmp"
                fi
                # log:info "$type != \"\" note:[$note]"
                deb_section=0
            fi
        fi
    done < $ficNote
    if [[ "$type" != "" && "$note" != "" ]]; then
        edit_note "$type" "$note" _noteIndi _noteNaissance _noteUnion _noteDeces _noteFamille
        note=""
    fi
    rm "$ficNote"
    eval "$2=\"$_noteIndi\""
    eval "$3=\"$_noteNaissance\""
    eval "$4=\"$_noteUnion\""
    eval "$5=\"$_noteDeces\""
    eval "$6=\"$_noteFamille\""

    log:info "FIN: cherche_note() type:[$type] note:[$note] _noteIndi:[$_noteIndi] _noteNaissance:[$_noteNaissance] _noteFamille:[$_noteFamille] _noteUnion:[$_noteUnion] _noteDeces:[$_noteDeces]"
    return 0
}

main_cherche_note() {
    local TRACE="true"
    local chrono="false"
    local KeyID="0001"
    local my_pid="${KeyID}_${RANDOM}_${RANDOM}"
    local pre="${TMP_DIR}/gen_$(printf "%04d" "$KeyID")"
    local noteIndi="" noteNaissance="" noteUnion="" noteDeces="" noteFamille=""


    cherche_note "/tmp/geneanet_test/gen_0001_all_page_1_13078_26650" noteIndi noteNaissance noteUnion noteDeces noteFamille
}

#main_cherche_note
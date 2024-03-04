trace_cherche_note="false"

edit_note() {
    local type_note=$1
    local note=$2
    local __noteIndi="" __noteNaissance="" __noteUnion="" __noteDeces="" __noteFamille=""

    log "DEB: cherche_note(): type_note:[$type_note] note:[$note]"
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
    log "Fin: cherche_note(): __noteIndi:[$__noteIndi] __noteNaissance:[$__noteNaissance] __noteFamille:[$__noteFamille] __noteUnion:[$__noteDeces] NOTE_DECES:[$__noteDeces]"
}

cherche_note() {
    local ficNote="$1"
    local _noteIndi="" _noteNaissance="" _noteUnion="" _noteDeces="" _noteFamille="" line=""
    local deb_section=0 note="" type=""

    log "DEB cherche_note ficNote:[$ficNote]"
    while read -r line; do
        deb_section=$(echo "$line" | grep -E "<h3>|<h3 |note-wed-" | wc -l | bc)
        # log "deb_section:[$deb_section] $line"
        if [[ "$deb_section" -eq 1 && "$note" != "" ]]; then
            # log "deb_section:[$deb_section] note:[$note] Appel edit_note ($type)"
            edit_note "$type" "$note" _noteIndi _noteNaissance _noteUnion _noteDeces _noteFamille
            note=""
        fi
        if [[ "$deb_section" -eq 1 ]]; then
            if [[ "$line" == *">$LB_NOTE_PERSONNE<"* ]]; then
                # log "==> note individuelle"
                type="indi"
            elif [[ "$line" == *">$LB_NOTE_NAISSANCE<"* ]]; then
                # log "==> note Naissance"
                type="naissance"
            elif [[ "$line" == *">$LB_NOTE_UNION<"* ]]; then
                # log "==> Notes concernant l'union"
                type="union"
            elif [[ "$line" == *">$LB_NOTE_UNION_AVEC<"* ]]; then
                # log "==> note Union avec"
                type="union_avec"
            elif [[ "$line" == *">$LB_NOTE_DECES<"* ]]; then
                # log "==> note Deces"
                type="deces"
            elif [[ "$line" == *"note-wed"* ]]; then
                # log "==> note note.wed"
                type="famille"
            fi
            note_inclus=$(echo $line | sed -e 's/^.*<\/h3>$//g' -e 's/^.*note-wed-1"><p>//g')
            # log "note_inclus:[$note_inclus]"
            if [[ "$note_inclus" != "" ]]; then
                note_tmp=$(echo "$line" | sed -e 's/^.*<\/h3>//g' | sed -e 's/<p.*$//g')
                # log "note_tmp:[$note_tmp]"
                note="$note $note_tmp"
                # log "note:[$note]"
            fi
            continue
        else
            if [[ "$type" != "" && "$line" != "" ]]; then
                # log "$type != \"\""
                note_tmp=${line//ototototototo/}
                # log "$type != \"\" note_tmp:[$note_tmp]"
                if [[ "$note" == "" ]]; then
                    note="$note_tmp"
                else
                    note="$note\n$note_tmp"
                fi
                # log "$type != \"\" note:[$note]"
                deb_section=0
            fi
        fi
    done < $ficNote
    if [[ "$type" != "" && "$note" != "" ]]; then
        edit_note "$type" "$note" _noteIndi _noteNaissance _noteUnion _noteDeces _noteFamille
        note=""
    fi

    eval "$2=\"$_noteIndi\""
    eval "$3=\"$_noteNaissance\""
    eval "$4=\"$_noteUnion\""
    eval "$5=\"$_noteDeces\""
    eval "$6=\"$_noteFamille\""

    log "FIN: cherche_note() type:[$type] note:[$note] _noteIndi:[$_noteIndi] _noteNaissance:[$_noteNaissance] _noteFamille:[$_noteFamille] _noteUnion:[$_noteUnion] _noteDeces:[$_noteDeces]"
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
trace_cherche_note="false"

edit_note() {
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

cherche_note() {
    local _fic="$1"
    local ficNote="${TMP_DIR}_note_$$"
    local line=""
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

    log:info "Fin: g_noteIndi:[$g_noteIndi] g_noteNaissance:[$g_noteNaissance] g_noteFamille:[$g_noteFamille] g_noteUnion:[$g_noteDeces] g_noteDeces:[$g_noteDeces]"
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
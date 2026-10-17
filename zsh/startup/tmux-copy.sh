# copylast: copy the previous command and its output to the clipboard (tmux + zsh).
#
# tmux can only tell where a command starts and ends if the shell says so, via
# OSC 133 escape sequences: "A" marks the line holding the command, "C" marks
# where its output begins. tmux then flags those lines in `capture-pane -F`
# ('P' = prompt, 'O' = output start), which is what copylast slices on.
#
#   copylast        previous command line + its output
#   copylast -o     previous output only
#   copylast 3      the last 3 commands and their output
#   copylast ~2     just the 2nd-to-last command (like HEAD~2; ~1 is the last)
#
# -o combines with either form, e.g. `copylast -o ~2`.
#
# Goes to the tmux paste buffer and, via OSC 52 (`load-buffer -w`), to the
# system clipboard of the outer terminal.
[[ -n $ZSH_VERSION ]] || return 0

# Both markers go out from preexec. A zle hook would mark the line while the
# prompt is drawn, but powerlevel10k's transient prompt later erases and
# redraws that line, dropping the flag. In preexec the command is already on
# screen in its final form and the cursor sits on the line below it, so step
# up, mark it as the prompt line, and step back down before marking output.
_osc133_preexec() { printf '\e[A\e]133;A\e\\\e[B\r\e]133;C\e\\' }
preexec_functions+=(_osc133_preexec)

copylast() {
    local skip=0 oldest=1 newest=1
    while (( $# )); do
        case $1 in
            -o) skip=1 ;;
            '~'<1->) oldest=${1#\~}; newest=$oldest ;;
            <1->) oldest=$1; newest=1 ;;
            *) echo "usage: copylast [-o] [N | ~K]" >&2; return 2 ;;
        esac
        shift
    done
    [[ -n $TMUX ]] || { echo "copylast: not inside tmux" >&2; return 1; }

    # A multi-line prompt leaves header lines between the output and the next
    # command line, so trim them. p10k's transient prompt collapses those
    # headers once a command runs, so there is nothing to trim in that case.
    local header=0
    if [[ -z $POWERLEVEL9K_TRANSIENT_PROMPT || $POWERLEVEL9K_TRANSIENT_PROMPT == off ]]; then
        local rendered=${(%)PROMPT}
        header=${#${rendered//[^$'\n']/}}
    fi

    local text
    text=$(tmux capture-pane -p -J -S - -L -F | awk -v hdr="$header" -v skip="$skip" -v oldest="$oldest" -v newest="$newest" '
        { n++; flags[n] = $2; sub(/^[0-9]+ [^ ]+ ?/, ""); txt[n] = $0 }
        END {
            # Only real commands carry a P flag (it is emitted from preexec), so
            # the last P line is copylast itself and the ones before it are the
            # commands to pick from; k=1 is the command just before copylast.
            m = 0
            for (i = 1; i <= n; i++) if (flags[i] ~ /P/) p[++m] = i
            if (m - oldest < 1) exit 1
            for (k = oldest; k >= newest; k--) {
                start = p[m - k]; end = p[m - k + 1]
                for (i = start + skip; i < end - hdr; i++) print txt[i]
            }
        }') || { echo "copylast: no previous command found (are OSC 133 markers on? try a new shell)" >&2; return 1; }

    # The command line still carries the prompt before it (e.g. " $<powerline
    # glyph> "; those glyphs live in the Unicode private-use area), so drop up
    # to the glyph, then any leading whitespace and invisible characters. With -o the first line
    # is real output, so only blank lines are dropped there to keep indentation.
    text=$(printf '%s\n' "$text" | SKIP=$skip perl -CSD -0777 -pe '
        s/[ \t\p{Co}\p{Cf}]+$//mg;
        if ($ENV{SKIP}) { s/\A(?:[ \t]*\n)+// } else { s/\A\s*[^\n\p{Co}\s]{0,8}\p{Co}+\s*// or s/\A\s*[\x{276F}\x{279C}\x{3BB}\$#%>]\s+//; s/\A[\s\p{Cf}]+// }
        s/\s+\z/\n/;')

    printf '%s\n' "$text" | tmux load-buffer -w -
    echo "copylast: copied $(printf '%s\n' "$text" | wc -l | tr -d ' ') lines"
}

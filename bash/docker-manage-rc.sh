dm ()
{
    if [ -r docker/docker-manage.sh -a -x docker/docker-manage.sh ]; then
        ( cd docker && ./docker-manage.sh "$@" );
    else
        echo "No docker-manage.sh present.";
    fi
}

_dm_actions()
{
    local file="docker/docker-manage.sh"
    if [ ! -r "$file" ]; then
        return
    fi

    awk '
        $0 ~ /^case[[:space:]]+"\$action"[[:space:]]+in/ { in_case=1; next }
        in_case {
            if ($0 ~ /^[[:space:]]*esac/) { exit }
            if ($0 ~ /^[[:space:]]*\*/) { next }
            if ($0 ~ /^[[:space:]]*[A-Za-z0-9_|.-]+\)/) {
                line=$0
                sub(/^[[:space:]]*/, "", line)
                sub(/\).*/, "", line)
                gsub(/\|/, " ", line)
                print line
            }
        }
    ' "$file"
}

_dm()
{
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "-b" -- "$cur") )
        return
    fi

    local i=1
    while [[ $i -lt $COMP_CWORD ]]; do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            break
        fi
        ((i++))
    done

    if [[ $i -eq $COMP_CWORD ]]; then
        local actions
        actions="$(_dm_actions)"
        COMPREPLY=( $(compgen -W "$actions" -- "$cur") )
    fi
}

complete -F _dm dm

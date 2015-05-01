_fendeb_general()
{
    COMPREPLY=()
    local home=$HOME/.fendeb
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts

    # No command typed in yet
    if [ "$COMP_CWORD" == "1" ]; then
        opts="build env create update"
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    case "${COMP_WORDS[1]}" in
        build)
            local dsc_files=`find *.dsc -maxdepth 1 -type f -printf '%f\n' 2>/dev/null`
            COMPREPLY=( $(compgen -W "$dsc_files" -- ${cur}) )
            return 0
        ;;
        env)
            if [ "$COMP_CWORD" == "2" ]; then
                if [ ! -f "$home/storage-path" ]; then
                    return 0
                fi
                local storage_path=`cat $home/storage-path`

                if [ ! -f "$home/available-envs" ]; then
                    return 0
                fi
                local file="$home/available-envs"

                opts="list"
                local rawbuilds="$opts "
                for build in `cat $file`; do
                    if [ -f "$storage_path/$build/base.tar.gz" ]; then
                        rawbuilds+="$build "
                    fi
                done

                COMPREPLY=( $(compgen -W "$rawbuilds" -- ${cur}) )
                return 0
            fi
        ;;
    esac
}
complete -F _fendeb_general fendeb

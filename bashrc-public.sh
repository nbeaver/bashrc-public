#! /usr/bin/env bash

# Like `free`, but with percentages instead of absolute amounts.
# http://stackoverflow.com/questions/10585978/linux-command-for-percentage-of-memory-that-is-free
# http://stackoverflow.com/questions/10585978/linux-command-for-percentage-of-memory-that-is-free#comment34895569_10586020
function free-mem-percent {
    free | awk '/Mem/{printf("used: %.2f%"), $3/$2*100} /buffers\/cache/{printf(", buffers: %.2f%"), $4/($3+$4)*100} /Swap/{printf(", swap: %.2f%\n"), $3/$2*100}'
}

# Show if you're losing packets.
# http://askubuntu.com/a/278469
# http://askubuntu.com/questions/278441/how-to-show-failed-ping
alias ping-packet-loss='ping -i 1 -f 8.8.8.8'

# Open Debian package page tracking page.
function qa {
    for var in "$@"; do
        #xdg-open "https://packages.qa.debian.org/$var"
        xdg-open "https://tracker.debian.org/pkg/$var"
    done
}

# Find the difference between two dates in days.
# http://stackoverflow.com/questions/4679046/bash-relative-date-x-days-ago
# http://stackoverflow.com/a/4679150
function date-subtract {
    echo $(( ( $(date -d "$1" +%s) - $(date -d "$2" +%s) ) /(24 * 60 * 60 ) )) ;
}

# Find out the time and date without changing the locale.
function date-india() {
    local temp="$TZ"
    export TZ="Asia/Kolkata"
    printf "%s : " "$TZ"
    date
        # e.g. Asia/Kolkata : Thursday, January 1, 1970 at 00:00:00 AM
    export TZ="$temp"
}
function date-chicago() {
    local temp="$TZ"
    export TZ="America/Chicago"
    printf "%s : " "$TZ"
    date
    export TZ="$temp"
}

# Not a real function, but similar to one I use.
# This will copy any given files to a folder on a remote machine.
# http://www.omnis-dev.com/cgi-bin/nextkey.omns?Key=20080118142922
function to-remote-machine {
    local resolved
    resolved="$(readlink --canonicalize-existing "$@")"
    rsync --verbose --progress --archive --compress --update "$resolved" user@remote-machine:~/remote-folder/
}

# Make gdb run with date-stamped logfiles,
# and pass arguments properly.
# https://forum.transmissionbt.com/viewtopic.php?f=1&t=14103#p62594
function gdb-log() {
    gdb -ex "set logging file $(date +%T)-gdb.txt" -ex 'handle SIGPIPE nostop noprint nopass' -ex 'set logging on' -ex 'run' --args "$@" ;
}

# Follow a command to the directory it comes from,
# or follows a symbolic link to the location of the file.
# Like `which (1)`, but dereferences symlinks and moves to the executable's directory.
# Also works for non-executable symlinks, but for convoluted symlinks /usr/bin/namei is better.
# Has to be a shell function, otherwise it could not use pushd and popd.
function followpath() {
    unset CDPATH
    local command_type
    command_type="$(type -t "$*")"
    # one of 'alias', 'keyword', 'function', 'builtin', 'file', or ''
    if [ "$command_type" == 'file' ]
    then
        local maybe_symlink
        maybe_symlink="$(type -p "$*")"
        local target
        target="$(readlink --canonicalize-existing "$maybe_symlink")"
        printf -- "%s\n" "$target"
        local target_directory
        target_directory="$(dirname "$target")"
        pushd -- "$target_directory"
    elif [ "$command_type" == '' ]
    then
        printf "Error: command not found: '%s'\n" "$*"
        return 1
    elif test "$command_type" = 'builtin' || test "$command_type" = 'keyword'
    then
        printf "Error: cannot follow '%s' since it is a %s\n" "$*" "$command_type"
        printf "Try running this:\n"
        printf "$ help '%s'\n" "$*"
        return 2
    elif test "$command_type" = 'alias' || test "$command_type" = 'function'
    then
        printf "Error: cannot follow '%s' since it is a %s\n" "$*" "${command_type}"
        printf "Try running this:\n"
        printf "$ type %s\n" "$*"
        return 2
    else
        # Should not run, unless I've forgotten a command type.
        printf "Error: '%s' has unknown command type '%s'\n" "$*" "${command_type}"
        return 3
    fi
}
# Use the same autocomplete settings as `which (1)`.
complete -c followpath

# Move the the parent directory of a symlink.
# Has to be a shell function, otherwise it could not use cd / pushd.
function follow() {
    unset CDPATH
    if test -L "$*"
    then
        # Check if the input is a symbolic link.
        local symlink_target
        symlink_target="$(readlink --canonicalize-existing "$*")"
        printf -- "%s\n" "$symlink_target"
        local target_directory
        target_directory="$(dirname "$symlink_target")"
        pushd -- "$target_directory"
    else
        printf -- "Error: '%s'is not a symbolic link.\n" "%*"
        return 1
    fi
}

edit_function() {
    local line_number
    local function_file
    if declare -F "$*"
    then
        shopt -s extdebug
        # The output of
        # declare -F _filedir_xspec
        # looks like this:
        # _filedir_xspec 1819 /usr/share/bash-completion/bash_completion
        # so we want the 2nd and 3rd fields.
        line_number="$(declare -F "$*" | cut -d ' ' -f 2)"
        function_file="$(declare -F "$*" | cut -d ' ' -f 3-)"
        shopt -u extdebug
        unset CDPATH
        pushd -- "$(dirname "$function_file")"
        editor +"$line_number" "$function_file"
        # The command `editor +100 /path/to/file`
        # positions the cursor on line 100 of the file.
        # This works for emacs, vim, nano, joe, jed, and probably others too.
    else
        printf "Error: \`%s\` is not a function.\n" "$*"
        return 1
    fi
}

get_completion_function_name() {
    # The output of
    #     complete -p vim
    # looks like this:
    #     complete -F _filedir_xspec vim
    # or this:
    #     complete -o default -F _dict dict
    # so we want the argument after -F.
    # First, we shift to get rid of the leading 'complete' argument.
    shift
    # Next, we parse all the possible arguments to 'complete'.
    # Usually, it's only -o or -F, but it doesn't hurt to be cautious.
    while getopts 'aA:bcC:dDeEfF:G:gjko:pP:rsS:uvW:X:' flag
    do
        if test "$flag" = 'F'
        then
            printf -- "%s\n" "$OPTARG"
        fi
    done
}

edit_completion_function() {

    local function_name
    if complete -p "$*"
    then
        function_name="$(get_completion_function_name "$(complete -p "$*")")"
        edit_function "$function_name"
    fi
    # TODO: edit the dynamically loaded completions
    # in /usr/share/bash-completion/completions/
}
complete -c edit_completion_function

# Add $SHLVL to the prompt if it's greater than 1.
# This way, exiting a shell is less surprising.
if [ $SHLVL -gt 1 ]; then
    PS1="$PS1""SHLVL=$SHLVL \$ "
fi

# http://redclay.altervista.org/wiki/doku.php?id=projects:old-projects
function apt-history(){
    case "$1" in
        install)
            tac /var/log/dpkg.log | grep 'install ' | less
            ;;
        upgrade|remove)
            tac /var/log/dpkg.log | grep "$1" | less
            ;;
        rollback)
            tac /var/log/dpkg.log | grep upgrade |
            grep "$2" -A10000000 |
            grep "$3" -B10000000 |
            awk '{print $4"="$5}' | less
            ;;
        *)
            tac /var/log/dpkg.log | less
            ;;
    esac
}

# Takes you to the first matching path using the locate(1) command.
# Most useful if you know a globally unique filename or directory name.
# Has to be a shell function, otherwise it could not use pushd and popd.

lucky() {
    local matches
    matches=0
    local duplicates
    declare -a duplicates

    err() {
        echo "Error: $*" >&2
    }
    warn() {
        echo "Warning: $*" >&2
    }

    in_array() {
        local item="$1"
        local array="$2[@]"
        for i in "${!array}"
        do
            if [ "$item" == "$i" ]
            then
                return 0
            fi
        done
        return 1
    }

    in_dirstack() {
        local path="$*"
        if test -z "$path"; then
            err 'empty string.'
            return 1
        elif ! test -e "$path";  then
            err "path does not exist: $path"
            return 1
        elif ! test -d "$path"; then
            err "path is not a directory: $path"
            return 1
        fi
        local resolved
        resolved="$(realpath -e -- "$path")"
        # We have to use dirs -l
        # instead of DIRSTACK
        # due to lack of tilde expansion.
        local realdirs
        declare -a realdirs=()
        local dir
        local realdir
        while read dir
        do
            realdir="$(realpath -e -- "$dir")"
            realdirs+=("$realdir")
        done < <(dirs -l -p)
        if in_array "$resolved" realdirs
        then
            if ! in_array "$resolved" duplicates
            then
                duplicates+=("$resolved")
            fi
            return 0
        else
            return 1
        fi
    }

    try_pushd() {
        local dir="$*"
        if ! test -d "$dir"
        then
            # It's not a directory,
            # so we can't do it.
            err "not a directory: ‘$dir‘"
            return 1
        elif in_dirstack "$dir"
        then
            # If we're already in this directory,
            # or it's already in the DIRSTACK,
            # try a different option.
            return 1
        else
            pushd "$dir" > /dev/null
            return 0
        fi
    }

    locate_iter() {
        # This is somewhat inefficient,
        # since it has to run a full 'locate' search,
        # and usually does not need all the results,
        # but there does not seem to be an easy way around this.
        local parent
        while read path
        do
            matches=$((matches+1))
            if [ -d "$path" ]; then
                if try_pushd "$path"
                then
                    printf "match: \`%s\`\n" "$(basename "$path")"
                    return 0
                else
                    continue
                fi

            elif [ -f "$path" ]; then
                parent="$(dirname "$path")"
                if try_pushd "$parent"
                then
                    printf "match: \`%s\`\n" "$(basename "$path")"
                    return 0
                else
                    continue
                fi
            else
                warn "database may be stale; this is not a file or directory: ‘$path’"
            fi
        done < <(locate --basename "$*")
        return 1
    }

    # Try for exact match first.
    if locate_iter "\\$*"
    then
        return 0
    # Next try for matches to *NAME*, not just NAME (see mlocate manpage).
    elif locate_iter "$*"
    then
        return 0
    fi
    if [ $matches -eq 0 ]; then
        err "No matches for ‘$*’"
    else
        err "No further matches for ‘$*’"
        echo "Number of duplicates already in DIRSTACK: ${#duplicates[@]}"
        echo "Date of last locate(1) database modification: $(stat -c %y /var/lib/mlocate/mlocate.db)" 1>&2
    fi
    return 1
}

# cd to parent directory of argument.
cdd()
{
    cd "$(dirname "$*")"
}


# Handy function for combining tree(1) and less(1)
# so that colors are preserved.
tree-less() {
    if test $# -lt 1
    then
        tree -C | less -R
    else
        # We have to quote "$*" to handle paths with spaces,
        # but if we don't check number of arguments,
        # the command will be: tree ""
        # and give this error: [error opening dir]
        tree -C "$*" | less -R
    fi
}

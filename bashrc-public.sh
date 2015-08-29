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

# Load the bug page for a given package.
function bugpage {
    # TODO: Make this a separate executable shell script.
    # TODO: Handle multiple arguments.
    # TODO: Make this portable to BSDs.
    local DISTRO="$(lsb_release --short --id)"
    if [ $# -gt 1 ]; then
        echo "Error: received $# arguments instead of 1: $*"
        return 1
    elif [ $# -eq 0 ]; then
        echo "Usage: enter package name:"
        echo "    bugpage package-name"
        echo "or bug number:"
        echo "    bugpage 1234567"
        echo "Your Linux distribution is $DISTRO"
        return 1
    fi
    local DISTRO="$(lsb_release --short --id)"
    if (( $1 > 0 )); then
        # The argument is a positive integer, so it must be a bug number.
        # TODO: use associative arrays instead of conditionals.
        if [ "$DISTRO" = 'Debian' ]; then
            xdg-open "https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=$1"
        elif [ "$DISTRO" = 'Ubuntu' ]; then
            xdg-open "https://bugs.launchpad.net/bugs/$1"
        elif [ "$DISTRO" = 'Fedora' ]; then
            xdg-open "https://bugzilla.redhat.com/show_bug.cgi?id=$1"
        elif [ "$DISTRO" = 'Arch' ]; then
            xdg-open "https://bugs.archlinux.org/task/$1"
        else
            echo "Unrecognized distro: $DISTRO"
        fi
    else
        # If it's not a positive integer, maybe it's a package name.
        if [ "$DISTRO" = 'Debian' ]; then
            xdg-open "https://bugs.debian.org/cgi-bin/pkgreport.cgi?archive=both;pkg=$1"
        elif [ "$DISTRO" = 'Ubuntu' ]; then
            xdg-open "https://bugs.launchpad.net/ubuntu/+source/$1/+bugs"
        elif [ "$DISTRO" = 'Fedora' ]; then
            xdg-open "https://bugzilla.redhat.com/buglist.cgi?component=$1"
        elif [ "$DISTRO" = 'Arch' ]; then
            xdg-open "https://bugs.archlinux.org/index.php?string=$1&project=0"
        else
            echo "Unrecognized distro: $DISTRO"
        fi
    fi
}
# Autocomplete Debian package names.
# Requires debian-goodies package.
complete -F _pkg_names bugpage

# Open Debian package page tracking page.
function qa {
    for var in "$@"; do
        #xdg-open "https://packages.qa.debian.org/$var"
        xdg-open "https://tracker.debian.org/pkg/$var"
    done
}
complete -F _pkg_names qa

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
    echo -n "$TZ : "
    date +'%A, %B %e, %Y at %r'
        # e.g. Asia/Kolkata : Thursday, January 1, 1970 at 00:00:00 AM
    export TZ="$temp"
}

# Not a real function, but similar to one I use.
# This will copy any given files to a folder on a remote machine.
# http://www.omnis-dev.com/cgi-bin/nextkey.omns?Key=20080118142922
function to-remote-machine {
    local resolved="$(readlink --canonicalize-existing "$@")"
    rsync --verbose --progress --archive --compress --update "$resolved" user@remote-machine:~/remote-folder/
}

# Edit your bash configuration and then reload it right afterward.
# http://www.reddit.com/r/linux/comments/1xcdtk/the_generally_helpful_bashrc_alias_thread/cfa4p21
function config() {
    $EDITOR ~/.bashrc && source ~/.bashrc
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
function followpath() {
    unset CDPATH
    local command_type="$(type -t "$*")"
    # one of 'alias', 'keyword', 'function', 'builtin', 'file', or ''
    if [ "$command_type" == 'file' ]
    then
        local maybe_symlink="$(type -p "$*")"
        local target="$(readlink --canonicalize-existing "$maybe_symlink")"
        printf -- "$target\n"
        local target_directory="$(dirname "$target")"
        pushd -- "$target_directory"
    elif [ "$command_type" == '' ]
    then
        echo "Error: command not found: $*"
        return 1
    elif [ "$command_type" == 'builtin' -o "$command_type" == 'keyword' ]
    then
        echo "Error: cannot follow '$*' since it is a $command_type"
        echo "Try running this:"
        echo "$ help $*"
        return 2
    elif [ "$command_type" == 'alias' -o "$command_type" == 'function' ]
    then
        echo "Error: cannot follow '$*' since it is a $command_type"
        echo "Try running this:"
        echo "$ type $*"
        return 2
    else
        # Should not run, unless I've forgotten a command type.
        echo "Error: '$*' has unknown command type $command_type"
        return 3
    fi
}
# Use the same autocomplete settings as `which (1)`.
complete -c followpath

# Move the the parent directory of a symlink.
function follow() {
    unset CDPATH
    if [ -L "$*" ]
    then
        # Check if the input is a symbolic link.
        local symlink_target="$(readlink --canonicalize-existing "$*")"
        printf -- "$symlink_target\n"
        local target_directory="$(dirname "$symlink_target")"
        cd -- "$target_directory"
    else
        printf -- "Error: '$*'is not a symbolic link.\n"
        return 1
    fi
}

# Only autocomplete symlinks or paths to symlinks.
# TODO: escape spaces and other characters in the filename.
_follow() {
    if test "$1" != "$3"
    then
        # This means the previous word is not the same as the command being executed,
        # i.e. trying to pass multiple arguments to this command, which takes only one.
        return 1
    fi
    _init_completion || return
    local candidate candidates
    #TODO: autocomplete ~, $HOME, etc.
    candidates="$(compgen -f $2)"

    # TODO: test paths with spaces in them.
    # TODO: complete partial matches.
    for candidate in "$candidates"
    do
        if test -L "$candidate"
        then
            COMPREPLY+=("$candidate")
        elif test -d "$candidate"
        then
            # TODO: autocomplete only the children that are symlinks.
            _filedir
        else
            # This is not a symlink or directory,
            # so we do nothing.
            :
        fi
    done
}
complete -F _follow follow

edit_function() {
    local line_number function_file
    if declare -F "$*"
    then
        shopt -s extdebug
        # The output of
        # declare -F _filedir_xspec
        # looks like this:
        # _filedir_xspec 1819 /usr/share/bash-completion/bash_completion
        # so we want the 2nd and 3rd fields.
        line_number="$(declare -F $* | cut -d ' ' -f 2)"
        function_file="$(declare -F $* | cut -d ' ' -f 3-)"
        shopt -u extdebug
        unset CDPATH
        cd -- "$(dirname "$function_file")"
        editor +$line_number "$function_file"
        # The command `editor +100 /path/to/file`
        # positions the cursor on line 100 of the file.
        # This works for emacs, vim, nano, joe, jed, and probably others too.
    else
        printf "Error: \`$*\` is not a function.\n"
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
            printf -- "$OPTARG\n"
        fi
    done
}

edit_completion_function() {

    local function_name
    if complete -p "$*"
    then
        function_name="$(get_completion_function_name $(complete -p $*))"
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

lucky() {
    IFS=$'\n'
    local counter=0

    in_dirstack() {
        local path="$1"
        for i in "${DIRSTACK[@]}"
        do
            if [ "$path" == "$(realpath $i)" ]
            then
                return 0
            fi
        done
        return 1
    }

    lucky_helper() {
        local path
        for path in $(locate --basename "$*")
        do
            ((counter++))
            if [ -d "$path" ]; then
                if in_dirstack "$path"
                then
                    # If we're already in this directory,
                    # try a different option.
                    continue
                fi
                pushd "$path"
                return 0
            elif [ -f "$path" ]; then
                local parent="$(dirname "$path")"
                if in_dirstack "$parent"
                then
                    # If we're already in this file's parent,
                    # try a different option.
                    continue
                fi
                pushd "$parent"
                return 0
            else
                echo "Warning: database may be stale, this is not a file or directory: \`$path\`" 1>&2
            fi
        done
        return 1
    }

    # Try for exact match first.
    if lucky_helper "\\$*"
    then
        return 0
    # Next try for matches to *NAME*, not just NAME (see mlocate manpage).
    elif lucky_helper "$*"
    then
        return 0
    fi
    if [ $counter -eq 0 ]; then
        echo "No matches for \`$*\`" 1>&2
    else
        echo "All matches failed for \`$*\`" 1>&2
        echo "Date of last locate(1) database update: $(stat -c %y /var/lib/mlocate/mlocate.db)" 1>&2
    fi
    return 1
}

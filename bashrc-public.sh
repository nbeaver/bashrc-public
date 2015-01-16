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
	local DISTRO=$(lsb_release --short --id)
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
	local DISTRO=$(lsb_release --short --id)
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
			xdg-open "https://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg=$1"
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

# Open Debian package page tracking page.
function qa {
	for var in $@; do
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
	export TZ=Asia/Kolkata
	echo -n "$TZ : "
	date +'%A, %B %e, %Y at %r'
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

# Follow a command to the directory it comes from.
# Like `which (1)`, but dereferences all the symlinks and also moves you to the directory the executable is in.
function follow() {
	set -e
	local command_type="$(type -t "$*")"
	# one of 'alias', 'keyword', 'function', 'builtin', 'file', or ''
	if [ "$command_type" == 'file' ]
	then
		local target="$(type -p "$*")"
		local resolved="$(readlink --canonicalize-existing "$target")"
		printf -- "$resolved\n"
		cd -- "$(dirname "$resolved")"
	elif [ "$command_type" == '' ]
	then
		echo "Error: command not found: $*"
	else
		echo "Error: cannot follow '$*' since it is a $command_type"
	fi
	set +e
}

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
              tac /var/log/dpkg.log | grep $1 | less
              ;;
        rollback)
              tac /var/log/dpkg.log | grep upgrade | \
                  grep "$2" -A10000000 | \
                  grep "$3" -B10000000 | \
                  awk '{print $4"="$5}' | less
              ;;
        *)
              tac /var/log/dpkg.log | less
              ;;
      esac
}

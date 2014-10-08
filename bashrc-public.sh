# Like `free`, but with percentages instead of absolute amounts.
# http://stackoverflow.com/questions/10585978/linux-command-for-percentage-of-memory-that-is-free
# http://stackoverflow.com/questions/10585978/linux-command-for-percentage-of-memory-that-is-free#comment34895569_10586020
function free-mem-percent {
    free | awk '/Mem/{printf("used: %.2f%"), $3/$2*100} /buffers\/cache/{printf(", buffers: %.2f%"), $4/($3+$4)*100} /Swap/{printf(", swap: %.2f\n%"), $3/$2*100}'
}

# Show if you're losing packets.
# http://askubuntu.com/a/278469
# http://askubuntu.com/questions/278441/how-to-show-failed-ping
alias ping-packet-loss='ping -i 1 -f 8.8.8.8'

# Load the bug page for a given package.
function bugpage {
    # TODO: grep uname for:
    #       -- Ubuntu https://bugs.launchpad.net/ubuntu/+source/$@/+bugs
    #       -- Arch https://bugs.archlinux.org/?project=1&cat%5B%5D=31&string=gcc
    # TODO: if it starts with #, open https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=$@ instead.
    xdg-open "https://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg=$@;dist=unstable" 2> /dev/null
}

# Find the difference between two dates in days.
# http://stackoverflow.com/questions/4679046/bash-relative-date-x-days-ago
# http://stackoverflow.com/a/4679150
function date-subtract { 
    echo $(( ( $(date -d "$1" +%s) - $(date -d "$2" +%s) ) /(24 * 60 * 60 ) )) ; 
}

# Find out the time and date without changing the locale.
function date-india() {
  local temp=$TZ
  export TZ=Asia/Kolkata
  echo -n "$TZ : "
  date +'%A, %B%e, %Y at %r'
  export TZ=$temp
}

# Not a real function, but similar to one I use.
# This will copy any given files to a folder on a remote machine.
# http://www.omnis-dev.com/cgi-bin/nextkey.omns?Key=20080118142922
function to-remote-machine { 
    rsync --verbose --progress --archive --compress --update "$@" user@remote-machine:~/remote-folder/
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

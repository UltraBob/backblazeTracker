#!/bin/sh
##TODO add a check before the $SPACEREMAINING checks that if the current file is different from the previous file, unset the SPACEREMAINING related variables, remove unset statements from the no transfer happening block

FREQUENCY=1
COLORTIME="\033[31m"
COLORTEXT="\033[32m"
COLORSPACE="\033[33m"
COLORFILE="\033[36m"

#unset SPACEDIFFERENCE
#unset $SPACEREMAININGRAW

if [ "$1" ]
then
    FREQUENCY=$1
fi

DEBUGGER=0

debug() {
    if [ $DEBUGGER = 1 ]
    then
        echo "$1"
    fi
}

space_remaining_recordkeeping() {
    debug "space_remaining_recordkeeping"
    if [ -n "$SPACEREMAININGRAW" ]
    then
        SPACEREMAININGOLD="$SPACEREMAININGRAW"
    fi
    SPACEREMAININGRAW=$(du "$SPACECHECK" | awk '{print $1}')
    if [ -n "$SPACEREMAININGOLD" ]
    then
        #do time remaining math
        SPACEDIFFERENCE=$(( SPACEREMAININGOLD-SPACEREMAININGRAW ))
        debug "SPACEDIFFERENCE is $SPACEDIFFERENCE"
        if [ $SPACEDIFFERENCE != 0 ]
        then
            MINUTESREMAINING=$(( SPACEREMAININGRAW * FREQUENCY / SPACEDIFFERENCE ))
            debug "SPACEDIFFERENCE was not zero so MINUTESREMAINING is $MINUTESREMAINING"
            MINUTESMESSAGE=$(human_time $MINUTESREMAINING)
        else
            MINUTESMESSAGE=" ETA Unavailable due to low transfer speed."
        fi
    else
        # Make the time remaining message blank
        MINUTESMESSAGE=""
    fi
}

human_filesize() {
    read filesize
    awk -v sum="$filesize" ' BEGIN {hum[1024^3]="G"; hum[1024^2]="M"; hum[1024]="K"; for (x=1024^3; x>=1024; x/=1024) { if (sum>=x) { printf "%.2f%s\n",sum/x,hum[x]; break; } } if (sum<1024) print "1K"; } '
}

human_time() {
    local totalminutes="$1"
    min=0
    hour=0
    day=0
    if [ "$totalminutes" -lt 0 ]
    then
        debug "minutes remaining was less than 0, return an empty string"
        echo ""
    else
    if [ "$totalminutes" -gt 59 ]
        then
            min=$((totalminutes%60))
            totalminutes=$((totalminutes/60))
            if [ "$totalminutes" -gt 23 ]
            then
                hour=$((totalminutes%24))
                day=$((totalminutes/24))
            else
                hour="$totalminutes"
            fi
        else
            min="$totalminutes"
        fi
        echo " Roughly $COLORTIME${day}d,${hour}h,${min}m$COLORTEXT remaining."
    fi
}

## Possible states:
# Ext scratch set, using external
# Ext scratch set, using local
# Ext scratch set, using neither (not backing up or between files)
# local scratch set, using local
# local scratch set, using none (not backing up or between files)

SLTIME=$((FREQUENCY * 60))
echo "This script will run until you interrupt it (CTRL-C)"
debug "You will receive an update every $COLORTIME$FREQUENCY minutes$COLORTEXT."
while true
do
    CHKTIME=$(date +'%R')
    if [ -f /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml ]
    then
        VOLUME=$(sed -n 's/^.*external_scratch_folder="\(.*\)\.bzvol.*".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml)
        if [[ -z "$VOLUME" ]] # Local Scratch
        then
            VOLUMEFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml)
            SCRATCH="System Disk"
            CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml)
            SPACECHECK=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile
            FILEFORSIZE=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml
        else
            VOLUMEFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' "$VOLUME".bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml)
            SCRATCH="$VOLUME"
            CHKFILE="$VOLUMEFILE"
            SPACECHECK="$VOLUME".bzvol/bzscratch/bzcurrentlargefile
            FILEFORSIZE="$VOLUME".bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml
        fi
        TRANSFERRING=$(sed -n 's/^.*current_file_fullpath="\([^\"]*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/overviewstatus.xml)
        if [ "$VOLUMEFILE" = "$TRANSFERRING" ] # check that external scratch transfer data matches current transfer (TODO: interrupted transfer could lead to false reporting when local is transferring file formerly being transferred on scratch, try to find a definitive answer from backblaze about what scratch is being used currently)
        then
            transferring=true
        else
            transferring=false
        fi
    else
        transferring=false
    fi
    if [ "$transferring" = true ]
    then
        SPACEREMAINING=$(du "$SPACECHECK" | awk '{print $1}')
        SPACEREMAINING=$((SPACEREMAINING * 1024 / 2))
        SPACEREMAINING=$(echo $SPACEREMAINING | human_filesize)
        if [ -n "$OLDFILE" ] # If there was a file being considered last loop through
        then
            debug "old file exists"
            if [ "$SPACECHECK" = "$OLDFILE" ] # if we are working with the same file
            then
                debug "same file as last loop through"
                space_remaining_recordkeeping
            else
                debug "file changed, reset things"
                unset OLDFILE
                unset SPACEREMAININGRAW
                space_remaining_recordkeeping
            fi
        else
            debug "old file doesn't exist first run through or file changed last time"
            OLDFILE=$SPACECHECK
            space_remaining_recordkeeping
        fi
        FILESIZE=$(sed -n 's/^.*numbytesinfile="\([^\"]*\)".*$/\1/p' "$FILEFORSIZE" | human_filesize)
        echo "$COLORTIME$CHKTIME $COLORSPACE$SPACEREMAINING$COLORTEXT / $COLORSPACE$FILESIZE$COLORTEXT remaining of $COLORFILE$CHKFILE$COLORTEXT (scratch on $COLORFILE$SCRATCH$COLORTEXT)$MINUTESMESSAGE"

    else # no transfer
        echo "$COLORTIME$CHKTIME$COLORTEXT" There seems to be no large transfer underway currently.
        unset OLDFILE
        unset SPACEREMAININGRAW
    fi

    sleep "$SLTIME"
done

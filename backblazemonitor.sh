#!/bin/sh

FREQUENCY=1
COLORTIME="\033[31m"
COLORTEXT="\033[32m"
COLORSPACE="\033[34m"
COLORFILE="\033[36m"

if [ $1 ]
then
    FREQUENCY=$1
fi

## Possible states:
# Ext scratch set, using external
# Ext scratch set, using local
# Ext scratch set, using neither (not backing up or between files)
# local scratch set, using local
# local scratch set, using none (not backing up or between files)

SLTIME=$(expr "$FREQUENCY" \* 60)
echo "You will receive an update every $FREQUENCY minutes"
while [ 1 ]
do 
    VOLUME=$(sed -n 's/^.*scratch_mountpoint="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzinfo.xml)
    if [ -f "$VOLUME".bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml ] # Check that external scratch transfer info exists
    then
        VOLUMEFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' "$VOLUME".bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml)
        TRANSFERRING=$(sed -n 's/^.*current_file_fullpath="\([^\"]*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/overviewstatus.xml)
        if [ "$VOLUMEFILE" == "$TRANSFERRING" ] # check that external scratch transfer data matches current transfer (TODO: interrupted transfer could lead to false reporting when local is transferring file formerly being transferred on scratch, try to find a definitive answer from backblaze about what scratch is being used currently)
        then
            SCRATCH="$VOLUME"
            CHKFILE="$VOLUMEFILE"
            SPACECHECK="$VOLUME".bzvol/bzscratch/bzcurrentlargefile
            FILEFORSIZE="$VOLUME".bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml
            EXT=true
        else
            EXT=false
        fi
    else
        EXT=false
        if [ -f /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml ] # ensure that there is data transfer info for local scratch
        then
            LOCAL=true
            SCRATCH="System Disk"
            CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml)
            SPACECHECK=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile
            FILEFORSIZE=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml
        else
            LOCAL=false
        fi
    fi
    if [ $EXT == true ] || [ $LOCAL == true ] #transfer active
    then
        CHKTIME=$(date +'%R')
        SPACEREMAINING=$(du -h -d 0 "$SPACECHECK" | awk '{print $1}')
        FILESIZE=$((`sed -n 's/^.*numbytesinfile="\([^\"]*\)".*$/\1/p' "$FILEFORSIZE"`/1024**2))"M"
        echo "$COLORTIME$CHKTIME $COLORSPACE$SPACEREMAINING$COLORTEXT / $COLORSPACE$FILESIZE$COLORTEXT remaining of $COLORFILE$CHKFILE$COLORTEXT (scratch on "$SCRATCH")"
        
    else # no transfer
        echo There seems to be no large transfer underway currently.
    fi
    
    sleep "$SLTIME"
done

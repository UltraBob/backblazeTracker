#!/bin/sh

FREQUENCY=1
COLORTIME="\033[31m"
COLORTEXT="\033[32m"
COLORSPACE="\033[33m"
COLORFILE="\033[36m"

if [ $1 ]
then
    FREQUENCY=$1
fi

localcheck() {
    if [ -f /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml ] # ensure that there is data transfer info for local scratch
    then
        SCRATCH="System Disk"
        CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml)
        SPACECHECK=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile
        FILEFORSIZE=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml
        LOCAL=true
    else
        LOCAL=false
    fi
}

human_filesize() { 
    read foo
    awk -v sum="$foo" ' BEGIN {hum[1024^3]="Gb"; hum[1024^2]="Mb"; hum[1024]="Kb"; for (x=1024^3; x>=1024; x/=1024) { if (sum>=x) { printf "%.2f %s\n",sum/x,hum[x]; break; } } if (sum<1024) print "1kb"; } '
}

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
    CHKTIME=$(date +'%R')
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
            localcheck
        fi
    else
        EXT=false
        localcheck
    fi
    if [[ $EXT == true ]] || [[ $LOCAL == true ]] #transfer active
    then
        SPACEREMAINING=$(du -d 0 "$SPACECHECK" | awk '{print $1}' | human_filesize)
        FILESIZE=`sed -n 's/^.*numbytesinfile="\([^\"]*\)".*$/\1/p' "$FILEFORSIZE" | human_filesize`
        echo "$COLORTIME$CHKTIME $COLORSPACE$SPACEREMAINING$COLORTEXT / $COLORSPACE$FILESIZE$COLORTEXT remaining of $COLORFILE$CHKFILE$COLORTEXT (scratch on "$SCRATCH")"
        
    else # no transfer
        echo "$COLORTIME$CHKTIME$COLORTEXT" There seems to be no large transfer underway currently.
    fi
    
    sleep "$SLTIME"
done

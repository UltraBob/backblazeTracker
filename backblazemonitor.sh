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

SLTIME=$(expr "$FREQUENCY" \* 60)
VOLUME=$(sed -n 's/^.*scratch_mountpoint="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzinfo.xml)
CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' "$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml)
echo "You will receive an update every $FREQUENCY minutes"
while [ 1 ]
do 
    CHKTIME=$(date +'%R')
    SPACEREMAINING=$(du -h -d 0 "$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile | awk '{print $1}')
    FILESIZE=$((`sed -n 's/^.*numbytesinfile="\([^\"]*\)".*$/\1/p' "$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml`/1024**2))"M"
    echo "$COLORTIME$CHKTIME $COLORSPACE$SPACEREMAINING$COLORTEXT / $COLORSPACE$FILESIZE$COLORTEXT remaining of $COLORFILE$CHKFILE"
    sleep "$SLTIME"
done

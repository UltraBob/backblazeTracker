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
if [ -f /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml ]
then
    echo "local scratch"
    CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml)
    SPACECHECK=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile
    FILEFORSIZE=/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter/bzcurrentlargefile/currentlargefile.xml
else
    echo "external scratch"
    CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' "$VOLUME".bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml)
    SPACECHECK="$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile
    FILEFORSIZE="$VOLUME".bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml
fi
echo "You will receive an update every $FREQUENCY minutes"
while [ 1 ]
do 
    CHKTIME=$(date +'%R')
    SPACEREMAINING=$(du -h -d 0 "$SPACECHECK" | awk '{print $1}')
    FILESIZE=$((`sed -n 's/^.*numbytesinfile="\([^\"]*\)".*$/\1/p' "$FILEFORSIZE"`/1024**2))"M"
    echo "$COLORTIME$CHKTIME $COLORSPACE$SPACEREMAINING$COLORTEXT / $COLORSPACE$FILESIZE$COLORTEXT remaining of $COLORFILE$CHKFILE"
    sleep "$SLTIME"
done

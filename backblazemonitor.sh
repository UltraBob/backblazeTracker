#!/bin/sh

FREQUENCY=1
if [ $1 ]
then
    FREQUENCY=$1
fi
SLTIME=$(expr "$FREQUENCY" \* 60)
echo $SLTIME
VOLUME=$(sed -n 's/^.*scratch_mountpoint="\(.*\)".*$/\1/p' /Library/Backblaze.bzpkg/bzdata/bzinfo.xml)

CHKTIME=$(date +'%R')
SPACEREMAINING=$(du -h -d 0 "$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile | awk '{print $1}')
REPORTINGTIME=$(date)
CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' "$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml)
FILESIZE=$(du -h "$CHKFILE"| awk '{print $1}')
echo $CHKTIME $SPACEREMAINING / $FILESIZE remaining of $CHKFILE
echo "You will receive an update every $FREQUENCY minutes"
while sleep "$SLTIME"
do 
    CHKTIME=$(date +'%R')
    SPACEREMAINING=$(du -h -d 0 "$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile | awk '{print $1}')
    REPORTINGTIME=$(date)
    CHKFILE=$(sed -n 's/^.*bzfname="\(.*\)".*$/\1/p' "$VOLUME"/.bzvol/bzscratch/bzcurrentlargefile/currentlargefile.xml)
    FILESIZE=$(du -h "$CHKFILE"| awk '{print $1}')
    echo $CHKTIME $SPACEREMAINING / $FILESIZE remaining of $CHKFILE
done
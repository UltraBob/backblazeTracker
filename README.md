backblazeTracker
================

A shell script to track large uploads to [backblaze](http://www.backblaze.com/partner/af7798)

Files larger than 10.5 Mb are broken into pieces before being uploaded to Backblaze.  If you have a lot of larger files to transfer it can be very useful to see how far along an upload is.  backblazeTracker was created to meet that need.  When transferring files smaller than 10.5 Mb, backblazeTracker will show no information, but when backblaze is working on a large transfer, this tool allows you to see the details of the transfer and track its progress,

The script is run with an optional argument to specify how many minutes to wait between updates.  The script can be halted by pressing ctrl-c.  Pressing b at any time while the script is running and the terminal is in focus will launch the backblaze preference panel.

I checked with [backblaze](http://www.backblaze.com/partner/af7798) before publishing this script, and they tell me that while this script does not violate the terms of service, it is also unsupported.  If it breaks something, and they find it running, they will not troubleshoot the matter.

It shouldn't break anything, as it only reads information and doesn't write anything to the filesystem, but needless to say this is provided without any type of warranty or support.  Use in good health, but at your own risk.

**Usage examples:**

```bash
backblazemonitor.sh
```
*See updates on the progress of large file transfers every minute*
```bash
backblazemonitor.sh 10
```
*See progress updates every 10 minutes*

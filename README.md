backblazeTracker
================

A shell script to track large uploads to [backblaze](http://www.backblaze.com/partner/af7798)

This script is run with an optional argument to specify how many minutes to wait between updates.  The script can be halted by pressing ctrl-c

I checked with backblaze before publishing this script, and they tell me that while this script does not violate the terms of service, it is also unsupported.  If it breaks something, and they find it running, they will not troubleshoot the matter

It shouldn't break anything, as it only reads information and doesn't write anything to the filesystem, but needless to say this is provided without any type of warranty or support.  Use in good health, but at your own risk.

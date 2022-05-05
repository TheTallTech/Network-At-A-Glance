# Network-At-A-Glance

This script reads a csv file of names and ip addresses, runs pings in parallel, then outputs whether or not the devices are online/pingable.

Notes:
1. This script was written and tested in Powershell Version 5.1.19041.1645 When tested in Powershell Version 7 there are issues with false negative results so Version 7 is not recommended.
2. This script must be run in a Powershell terminal, NOT ISE. The variables that get the window size do not work in the ISE.
3. The CSV file must have headers with the following names: Displayed Name,IP Address
4. The Powershell terminal must have Virtual Terminal enabled in order for the text coloring to work. I'm not sure how to disable/enable this feature myself I just know that if it's not enabled you will get an interesting output.

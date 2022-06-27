# Network-At-A-Glance

These scripts come without warranty of any kind. Use them at your own risk. I assume no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this site nor for any sort of damages using these scripts may cause.

This script reads a csv file of names and ip addresses, runs pings in parallel, then outputs whether or not the devices are online/pingable.

Notes:
1. This script was written and tested in Powershell Version 5.1.19041.1645 When tested in Powershell Version 7 there are issues with false negative results so Version 7 is not recommended.
2. This script must be run in a Powershell terminal, NOT ISE. The variables that get the window size do not work in the ISE.
3. The CSV file must be titled NetworkDevices.csv and have headers with the following names: Displayed Name,IP Address
4. The Powershell terminal must have Virtual Terminal enabled in order for the text coloring to work. I'm not sure how to disable/enable this feature myself I just know that if it's not enabled you will get an interesting output.
5. This script is a memory hog since all background processes run at the same time. The more devices you want to monitor the more memory it uses. I tested it with monitoring 95 devices and it was using around 1.5 GB of memory.

# makesite
![makesite](https://user-images.githubusercontent.com/86271004/180330635-4c7f7994-ca33-413e-a33a-ea09ab2753d7.png)

makesite is a Bash script that automatically installs WordPress. It uses the cPanel API and wp-cli to automate every step of the process, from database creation to the actual install.

For this script to work, it must be run on a cPanel server with wp-cli installed. This script does not work with cPanel on CentOS 6 due to slight API differences.

## minisite
minisite is makesite without the need to download an execute a script. It's the same code stripped of all comments and excess spacing for compactness, and wrapped between `makesite()` and brackets. It's meant to be run directly from the shell.

There can sometimes be problems copying and pasting lengthy code like this into a terminal - Windows Terminal seems to be especially problematic. If you run into any issues, I recommend copying and pasting half the code at a time.

I offer no warranty for this code and what it might do etc. etc.

# makesite
![makesite](https://user-images.githubusercontent.com/86271004/180330635-4c7f7994-ca33-413e-a33a-ea09ab2753d7.png)

makesite is a Bash script that automatically installs WordPress. It uses the cPanel API and wp-cli to automate every step of the process, from database creation to the actual install.

For this script to work, it must be run on a cPanel server with wp-cli installed. This script does not work with cPanel on CentOS 6 due to slight API differences.

Since v0.2 makesite offers a detailed verbose mode that outputs every command run and the response. You can access it with `-V` or `--verbose`. v0.3 adds a rollback feature than can be useful to clean up if the install fails for some reason - if the install fails at a wp-cli step, the created database and its user can be automatically deleted to avoid switching back and forth between the shell and cPanel. This is available with the `-r` or `--rollback` option.

The current version is **v0.3** and was updated on **7/23/2022**. You can check the version in the script with `-v` or `--version`. The latest code between releases will usually include fixes and small improvements, and is safe to use - breaking changes are held back until the next version release.

**Sometimes the `wp config` setup fails and can't connect to the database. What gives?**

There seems to be an issue with the cPanel API where creating a database user with a password doesn't always _set_ that password. It doesn't seem to be a formatting issue, and the API returns no errors when it happens. I've tried to work around this by setting the password twice, but no dice. The best I can recommend is to run the install again, and it should work. This is mainly the reason why I added the rollback feature.

I'm thinking of some possible solutions. One is, if the config process fails, reset the password and try again. If it still fails, give up.

## minisite
minisite is makesite without the need to download and execute a script. It's the same code stripped of all comments and excess spacing for compactness, and wrapped between `makesite()` and brackets. It's meant to be run directly from the shell.

There can sometimes be problems copying and pasting lengthy code like this into a terminal - Windows Terminal seems to be especially problematic. If you run into any issues, I recommend copying and pasting half the code at a time.

I offer no warranty for this code and what it might do etc. etc.

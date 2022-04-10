# squid-update-blocklist-tools
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://github.com/yvoinov/squid-update-blocklist-tools/blob/master/LICENSE)

## Squid update blocklist tools

These tools are developer to support squid's setup with ufdbguard filtering service. Can be executed by cron or interactively.

They downloads appropriate lists, process it, install to target directory and compile to ufdbguard database.

All utilities are run as root (since sudo may not necessarily be installed). Read them carefully before run to understand what you are doing exactly.

`update_blocklist.sh` is intended to run as main script which can execute all others when found.

`update_phishtank.sh` updates Phishtank database. Edit with your Phishtank API key.

`update_miners.sh` optional add-on to block known miners.

Note: Due to Shalla list is dead, main script was reworked to use pfsense list.

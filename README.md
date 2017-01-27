# rdiff-backup-utils
`rdiff-backup-utils` is a set of tools to ease rdiff-backup deployment

# Installation

1. `git clone https://github.com/nixhr/rdiff-backup-utils`
2. Copy `backup.sh`, `check_rdiff-backup` and `config.ini` to your preferred locations

# Usage 

1. Install [crudini](https://github.com/pixelb/crudini)
2. Configure settings in `config.ini`
3. Set the path to `config.ini` in `backup.sh` and `check_rdiff-backup` 
4. Copy your public key to the backed up machine, put it in `/root/.ssh/authorized_keys`
  * Preferably, limit access rights, something like:
   `command="rdiff-backup --server --restrict-read-only /" ssh-rsa AAAA......`
5. Run `backup.sh <profile_name>`
6. Configure your cron daemon to run `backup.sh <profile_name>` periodically.

Nagios plugin check if the last successful backup is not older than `critical_age` configured
in `config.ini` for the corresponding profile. Plugin should be invoked with only one parameter:
`check_rdiff-backup <profile_name>`

# Dependancies

`rdiff-backup-utils` utilizes [crudini](https://github.com/pixelb/crudini) for `.ini` file access.

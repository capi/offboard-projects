## What it is about
I have a PC I use as "terminalserver" for development.
It has a small SSD, but a large HDD attached.

This helper scripts help move projects I currently don't work on from SSD to HDD, and adding a symlink to the "offboarded" location.
When I want to work on the project again (and need the I/O speed), the project is moved back to the SSD ("onboarding").

To make re-offboarding fast, the onboarded state is kept on the HDD and re-used when offboarding the project again.

## Example
```
cd my-projects && ls -al
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-a
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-b
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-c
```
Now let's offboard `project-b`:
```
offboard.sh project-b
# <output skipped>
ls -al
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-a
lrwxrwxrwx 1 developer developer   58 May 22 23:16 project-b -> /mnt/disk/my-projects/project-b.offboarded
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-c
```
Due to the symlink, it is still possible to work with the projects. It's just slow(er) due to being on the HDD instead of the SSD.

Let's re-onboard the project:
```
onboard.sh project-b
# <output skipped>
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-a
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-b
drwxr-xr-x 1 developer developer    0 May 22 23:15 project-c
```
While the project has now been copied back to the project disk, the old state remains as offboarding basis in the offboarding location:
```
ls -al /mnt/disk/my-projects/
drwxr-xr-x 1 developer developer  0 May 22 23:15 project-b.onboarded
```

## Installation
Copy or symlink the two helper scripts to a location in your path, e.g. `/usr/local/bin` or `$HOME/bin/`.

## Configuration
Configuration is done via environment variables.
Those can either be set via `export` in the shell, or via a config file in one of the following two locations:
* `$HOME/.offboard.env`
* `/etc/offboard.env`

The following variables need to be defined:
* `ONBOARD_BASE_DIR`: the base-directory of the SSD, typically your `$HOME`
* `OFFBOARD_BASE_DIR`: the base-directory where to offboard projects to. The directory structure from the onboarded base-directory is re-created there as needed during offboarding.

If one of the config files exists, it is `source`d into the script, so can use the following template to have existing environment variables take precedence:
```
[ -z "$ONBOARD_BASE_DIR" ]  && export ONBOARD_BASE_DIR=/home/developer
[ -z "$OFFBOARD_BASE_DIR" ] && export OFFBOARD_BASE_DIR=/mnt/disk
```
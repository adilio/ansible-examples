# DRS_Changelog Role

The DRS Changelog Role creates the set of DRS folders required for logs, scripts, and software (for both Windows and Linux). It also creates the `changelog.txt` file, which is used to capture any changes we make on servers. This role can be included in other roles to check for existence of drs folders or changelog, and creation if needed.

## Variables

The only explicitly-defined variable is `cl_message`, which is the changelog message put into the changelog.txt file at the end of the playbook run. This variable is found in the `drs_changelog.yml` playbook in the root of our repo.

All other `host_vars` are inherited via the Ansible directory structure. In order to ensure your hosts and host_vars are present, you will have to make sure your host inventory is up-to-date. Assuming you've cloned the `ansible` repo into your home directory, you can run the following:

```bash
<create folders if don't exist already>
~$ mkdir -p $HOME/ansible/hosts/host_vars
~$ cd ~/ansible/scripts/inventory
~$ read pass1
<input bis-svc-sharepoint cred>
~$ python ans-inventory.py -siy --hostdir=$HOME/ansible/hosts --pass=$pass1
```

## Usage

You can make a copy of the `ansible/drs_changelog.yml` playbook and add the host or host group to the `hosts` field.

Once you've set your hosts, you may wish to use the `--check` flag once to check your steps without actually making changes:

```bash
~$ ansible-playbook drs_changelog.yml -i hosts/inventory.ini --ask-vault-pass --check
```

If the plays in the task return expected output, go ahead and remove the `--check` flag and actually run the playbook.

If you want to confirm that you're targeting the correct hosts, you can use the `--list-hosts` flag. If you're testing and would like more output, you can always add the `-vvv` verbose flag.

## A Note about Changelog in Windows

In the existing Windows Preflight method (one monolithic PowerShell script), the method used to have the changelog open on any user's logon was `mklink`, which creates a symbolic link of the changelog in 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup'. Symlinks in Windows can be problematic, as they are difficult to copy or create in an idempotent manner. Thus, we are opting to remove the existing symlink, and create the Windows-native shortcut, which is functionally identical. We utilize the `win_shortcut` module for this task. The code to remove the symlink and add the shortcut is contained in: `ansible/roles/drs_changelog/tasks/drs_changelog_Win32NT.yml`.

## Compatibility

This role has been tested and confirmed to work on the following Operating Systems.

**OS Family**|**OS Name**|**Version**|**Role Tested**|**Role Working**
-----|-----|-----|-----|-----
Linux|RHEL Server|6|Yes|Yes
Linux|RHEL Server|7|Yes|Yes
Linux|Ubuntu Server|14.04 LTS|Yes|Yes
Linux|Ubuntu Server|16.04 LTS|Yes|Yes
Windows|Windows Server|2008 R2|Yes|Yes
Windows|Windows Server|2012 R2|Yes|Yes
Windows|Windows Server|2016|Yes|Yes

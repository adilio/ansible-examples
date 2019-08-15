# Win_Firewall_Rules Role

The win_firewall_rules role can be utilized to apply the initial set of Windows Firewall rules for any Windows Server managed by BIS. These include, but are not limited to:

- WinRM HTTPS (tcp/5986; restricted to BIS subnet and Ansible servers)
- Sophos (tcp/8192,8194; restricted to BIS-SOPHOS)
- WMI (restricted to BIS subnet)
- Various File and Print Sharing / SMB rules (restricted to BIS subnet)

## Variables

The only explicitly-defined variable is `cl_message`, which is the changelog message put into the changelog.txt file at the end of the playbook run. This variable is found in the `ansible/win_firewall_rules.yml` playbook in the root of our repo.

All other `host_vars` are inherited via the Ansible directory structure (required for WinRM conection info). In order to ensure your hosts and host_vars are present, you will have to make sure your host inventory is up-to-date.

## Usage

You can make a copy of the `ansible/win_firewall_rules.yml` playbook and add the host or host group to the `hosts` field.

Once you've set your hosts, you may wish to use the `--check` flag once to check your steps without actually making changes:

```bash
~$ ansible-playbook win_firewall_rules.yml -i hosts/inventory.ini --ask-vault-pass --check
```

If the plays in the task return expected output, go ahead and remove the `--check` flag and actually run the playbook.

If you want to confirm that you're targeting the correct hosts, you can use the `--list-hosts` flag. If you're testing and would like more output, you can always add the `-vvv` verbose flag.

## Maintaining Idempotence

The first time the playbook runs, it will copy over the `Set-FirewallRules.ps1` file, and then run this file to apply the firewall rules. This file generates the local logfile `C:\DRS\Logs\Set-FirewallRules.txt`. This is important, as subsequent runs of the playbook will check for the existence of this logfile. If the logfile is present, the task step running this script will be skipped.

If you'd like to re-apply the rules for any reason, go ahead and delete `C:\DRS\Logs\Set-FirewallRules.txt`, and re-run your playbook.

## Why Not `win_firewall_rule` Module

Ansible has a nicely-packaged module called `win_firewall_rule`, that is meant to accomplish the same task as `Set-FirewallRules.ps1`. It would be great to use this, as it would be easier to maintain idempotence. Unfortunately, we've run into a problem where built-in Windows Firewall rules are unable to be modified (e.g.: 'Windows Remote Management (HTTP-In)'). As of today (2018-12-04; Ansible v.2.7.1), this feature is still not funcitonal, and thus does not meet our needs.

## Compatibility

This role has been tested and confirmed to work on the following Operating Systems.

**OS Family**|**OS Name**|**Version**|**Role Tested**|**Role Working**
-----|-----|-----|-----|-----
Windows|Windows Server|2008 R2|Yes|Yes
Windows|Windows Server|2012 R2|Yes|Yes
Windows|Windows Server|2016|Yes|Yes
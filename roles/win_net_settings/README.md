# Win_Net_Settings Role

The win_net_settings role can be utilized to apply the initial set of DNS and network settings for any Windows Server managed by BIS. These include:

- Registry key to disable IPv6 (2 methods; one for 2008 R2)
- Set DNS IP's, and order
- Set default DNS suffix
- Set DNS suffix search order

## Variables

The only explicitly-defined variable is `cl_message`, which is the changelog message put into the changelog.txt file at the end of the playbook run. This variable is found in the `ansible/win_net_settings.yml` playbook in the root of our repo.

All other `host_vars` are inherited via the Ansible directory structure (required for WinRM conection info). In order to ensure your hosts and host_vars are present, you will have to make sure your host inventory is up-to-date.

## Usage

You can make a copy of the `ansible/win_net_settings.yml` playbook and add the host or host group to the `hosts` field.

Once you've set your hosts, you may wish to use the `--check` flag once to check your steps without actually making changes:

```bash
~$ ansible-playbook win_net_settings.yml -i hosts/inventory.ini --ask-vault-pass --check
```

If the plays in the task return expected output, go ahead and remove the `--check` flag and actually run the playbook.

If you want to confirm that you're targeting the correct hosts, you can use the `--list-hosts` flag. If you're testing and would like more output, you can always add the `-vvv` verbose flag.

## Maintaining Idempotence

Specific tasks in this role generate local logfiles on the client server, in `C:\DRS\Logs`. In the main role task file (`ansible/roles/win_net_settings/tasks/main.yml`), any task step that has the parameter `creates:` spceified at the end of the task uses this method. This is important, as subsequent runs of the playbook will check for the existence of these logfiles. If the logfiles are present, the task step will be skipped.

If you'd like to re-apply the rules for any reason, go ahead and delete the respective logfile in `C:\DRS\Logs`, and re-run your playbook.

## Compatibility

This role has been tested and confirmed to work on the following Operating Systems.

**OS Family**|**OS Name**|**Version**|**Role Tested**|**Role Working**
-----|-----|-----|-----|-----
Windows|Windows Server|2008 R2|Yes|Yes
Windows|Windows Server|2012 R2|Yes|Yes
Windows|Windows Server|2016|Yes|Yes

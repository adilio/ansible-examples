## maint_window role on the Linux side

Installs the cron task for executing the Linux update on a scheduled basis. The
[Server Maintenance Windows](https://shareit.it.ubc.ca/teams/Teams/BIS/AdminOps/Lists/Server%20Maintenance%20Windows/AllItems.aspx)
ShareIT sharepoint list is used to define the schedule. The original scripts used in the role were obtained from the ones
authored by Jeff Burton and Eric Lai.

This role assumes the Linux preflight has been applied to the server already. Eventually, the preflight will be converted to a Ansible role.

Jeff's Ansible inventory script pulls the defined schedules for each host from the Server Maintenance Windows ShareIT sharepoint list and
generates a host_vars file for each host with the applicable scheduled defined as `mw_` vars as described below. If no valid schedule exists
for the host, then `mw_enable` is set to `'False'`.

When `mw_enable` is set to `'False'` for a host, this executes tasks that remove all maint_window components from the host.
To quickly override the `mw_enable` setting, to delete the files and task from a set of servers, you can set it as an extra var:
`ansible-playbook maint_window.yml -i hosts/inventory.ini --ask-vault-pass --extra-vars "mw_enable=False"`

### host_vars

The maint_window role specific host_vars are prefixed with `mw_`. These particular host_vars are used in the
Linux version of the maint_window role:

* `mw_enable: 'True'`  - Enables the maint_window role to be applied to the host. Removed otherwise.

* `mw_week: L`  - Which week of the month to execute, `L` for last week of the month, `1` for first week...

* `mw_month_freq: /3`  - Cron format for specifying monthly schedule. `/3` means every 3 months = 4 times a year = quarterly. `'*'` would mean every month.
  Oops! Need to implement this into the maint_window role

* `mw_day: 4` - Cron format to specify day, `0` for Sunday

* `mw_hour: '10'`

* `mw_min: '00'`


### Usage

Make a copy of the `ansible/maint_window.yml` playbook and add the host group to the `hosts` field.
If you want to test/debug the scripts, you may want to override the notification email address field `bis_systems_email`
as shown below with your own. If needed, set the `cl_message` variable used to set the changelog message on each host in play.
```bash
---
- name: create maintenance windows for Linux
  hosts: ANS
  gather_facts: yes

  vars:
    cl_message: "{{ 'Enabled' if mw_enable == 'True' else 'Disabled' }} Ansible role maint_window"
    # override during testing
    #bis_systems_email: dewey.liew@ubc.ca

  roles:
  - role: maint_window
```

Test the playbook. If all is good, remove the `--check` switch and run it.
```bash
~$ cd ~/ansible
~$ ansible-playbook maint_window.yml -i ./hosts/inventory.ini --ask-vault-pass --check
```

### Issues

## maint_window role on the Windows side

Installs the windowsupdate_ps scheduled task for executing the Windows update on a scheduled basis.
The schedule defined in the [Server Maintenance Windows](https://shareit.it.ubc.ca/teams/Teams/BIS/AdminOps/Lists/Server%20Maintenance%20Windows/AllItems.aspx)
ShareIT sharepoint list is used to define the schedule. The original scripts used in the role were obtained from the git package for
[task-windowsupdate](https://bis-src-prd.ead.ubc.ca/bis-aop/windowsupdate_ps).

This role assumes the Windows preflight has been applied to the server already. Eventually, the preflight will be converted to a Ansible role.

Jeff's Ansible inventory script pulls the defined schedules for each host from the Server Maintenance Windows ShareIT sharepoint list and
generates a host_vars file for each host with the applicable scheduled defined as `mw_` vars as described below. If no valid schedule exists
for the host, then `mw_enable` is set to `'False'`.

When `mw_enable` is set to `'False'` for a host, this executes tasks that remove all maint_window components from the host.

### host_vars

The maint_window role specific host_vars are prefixed with `mw_`. These particular host_vars are used in the
Windows version of the maint_window role:

* `mw_enable: 'True'`  - Enables the maint_window role to be applied to the host. Skipped otherwise.

* `mw_dayname: Tuesday`

* `mw_month_freq: /3`  - Cron format for specifying monthly schedule. `/3` means every 3 months = 4 times a year = quarterly. `'*'` would mean every month.

* `mw_time: '12:00'`

* `mw_week: L`  - Which week of the month to execute, `L` for last week of the month, `1` for first week...

### Usage

Make a copy of the `ansible/maint_window.yml` playbook and add the host group to the `hosts` field.
If you want to test/debug the scripts, you may want to override the notification email address field `bis_systems_email`
as shown below with your own. If needed, set the `cl_message` variable used to set the changelog message on each host in play.
```bash
---
- name: create maintenance windows for Windows
  hosts: ANS
  gather_facts: yes

  vars:
    # for changelog message
    cl_message: "{{ 'Enabled' if mw_enable == 'True' else 'Disabled' }} Ansible role maint_window"
    # override during testing
    #bis_systems_email: dewey.liew@ubc.ca

  roles:
    - role: maint_window
```

Test the playbook. If all is good, remove the `--check` switch and run it.
```bash
~$ cd ~/ansible
~$ ansible-playbook maint_window.yml -i ./hosts/inventory.ini --ask-vault-pass --check
```

### Issues

1. Scheduled task xml config file causes error during parsing in Ansible templating
   * maint_window/templates/windowsupdate_ps/maintenance_windows_update.xml
   * Workaround: this file must be converted to ANSI before use as an Ansible template.
     `# iconv -c -f utf-16le -t ms-ansi`
   * 2018-08-29 This is no longer an issue since the use of the Ansible v2.5 version of the win_scheduled_task module instead of the win_command implementation.
     Previous to Ansible v2.5, the win_scheduled_task was not supported for Windows Server 2016 and was missing required trigger arguments.
2. win_scheduled_task issue with omitting weeks_of_month argument for the case of last week of the month
   * see BISAI-43 for details

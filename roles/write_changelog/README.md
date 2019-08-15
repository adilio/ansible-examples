# Write_Changelog role (Linux side)

This role assumes the drs_changelog role has been applied already as it requires the `/opt/drs/log/changelog.txt` file to exist.

This role takes the `cl_message` variable and appends it to the `/opt/drs/log/changelog.txt` as a host changelog entry, similar to this:

```bash
Mon Aug 20 15:49:43 PDT 2018 - root@bis-appans-p01
* added this log via role

Tue Aug 21 11:46:24 PDT 2018 - root@bis-appans-p01
* Enabled Ansible role maint_window from bis-appans-p01
```

The datetime line is added automatically. `cl_message` should only be the text of the message ie. "Enabled Ansible role maint_window from bis-appans-p01".
The default value of `cl_message` is defined in `write_changelog/defaults/main.yml` and should be overridden in the playbook. The role is only executed as
a handler in `write_changelog/handlers/main.yml`, it does not have any tasks.

## Usage

Include the role in the playbook and set `cl_message`. For example, with the maint_window role, include it like this:

```bash
---
- name: create maintenance windows for Linux
  hosts: ANS
  gather_facts: yes

  vars:
    cl_message: "{{ 'Enabled' if mw_enable == 'True' else 'Disabled' }} Ansible role maint_window"

  roles:
  - role: maint_window
  - role: write_changelog
```

Then include the `notify` statement for the handler in the role tasks. For example, with the maint_window role, include it like this in `maint_window/tasks/main.yml`:

```bash
- name: Cleanup file content artifacts
  lineinfile:
    path: '/var/spool/cron/root'
    state: absent
    regexp: '^.*yumupdate.sh$'
  notify: add changelog entry
```

The `notify` statement only runs the handler if the task results in a host change state. Note that `notify` can be included multiple times in the role
but the handler will only be executed once after all the roles in the play have been executed.

# Write_Changelog role (Windows side)

This role assumes the drs_changelog role has been applied already as it requires the `C:\DRS\logs\changelog.txt` file to exist.

This role takes the `cl_message` variable and appends it to the `C:\DRS\logs\changelog.txt` as a host changelog entry, similar to this:

```bash
23-Aug-2018 11:48
Enabled Ansible role maint_window

23-Aug-2018 12:06
Disabled Ansible role maint_window
```

The datetime line is added automatically. `cl_message` should only be the text of the message ie. "Enabled Ansible role maint_window".
The default value of `cl_message` is defined in `write_changelog/defaults/main.yml` and should be overridden in the playbook. The role is only
executed as a handler in `write_changelog/handlers/main.yml`, it does not have any tasks.

## Usage

Using the write_changelog role is identical to the Linux side as explained above.

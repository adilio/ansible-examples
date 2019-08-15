# Install Windows Packages

Installs packages not installed by other roles, including 7zip, Notepad++, BgInfo.

## Install Files

Files are stores at /var/local/ansible-role-files and softlinked into the ansible role 'files' directory.

## Usage

Include the role in a playbook:

```bash
---
- name: Install Windows Packages
  hosts: ANS
  gather_facts: yes

  vars:
    cl_message: "Install Windows Packgages - JB"

  roles:
  - role: win_intstall_pkgs
```

## Compatibility

Tested on Ansible version 2.7.2

**OS Family**|**OS Name**|**Version**|**Role Tested**|**Role Working**
-----|-----|-----|-----|-----
Linux|RHEL Server|6|No|No
Linux|RHEL Server|7|No|No
Linux|Ubuntu Server|14.04 LTS|No|No
Linux|Ubuntu Server|16.04 LTS|No|No
Windows|Windows Server|2008 R2|No|No
Windows|Windows Server|2012 R2|No|No
Windows|Windows Server|2016|Yes|Yes


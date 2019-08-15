## Linux SSH Restart

The lin_ssh_restart role is a handler to manage SSH restarts for RHEL 6/7, CentOS 6/7, and Ubuntu 14/16 OSes. The role does not have any tasks, only one handler.

In RHEL/CentOS SSH is controlled via the **sshd** service and in Ubuntu it is controlled via the **ssh** service.

The handler utilizes the "listen" argument that allows triggering mulitple handlers at once (in this case, *restart SSH service RHEL* and *restart SSH service Ubuntu*).

### Usage

Include the role in a playbook:

```bash
---
# Create an SSH restart handler 

- name: SSH restart handler
  hosts: Linux
  gather_facts: yes
  remote_user: sysadmin
  become: yes

  roles:
    - lin_ssh_restart
  
```
Then, call the handler, by its listener, in a task:

```bash
---
# Echo something and then restart SSH

- name: message for red hat
  shell: echo "This is a Red Hat system, using the sshd service"
  when: ansible_distribution == "RedHat"

  notify: "restart ssh"

- name: message for ubuntu
  shell: echo "This is an Ubuntu system, using the ssh service"
  when: ansible_distribution == "Ubuntu"

  notify: "restart ssh"
```


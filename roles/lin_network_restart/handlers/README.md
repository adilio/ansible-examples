## Linux Network Restart

The lin_network_restart role is a handler to manage network restarts for RHEL 6/7, CentOS 6/7, and Ubuntu 14/16 OSes. The role does not have any tasks, only one handler.

Because of the way networking was implemented in Ubuntu 14.04, using the *network* service as a method to restart networking will not work.  As a result, `ifdown` and `ifup` commands are utilized for all Ubuntu flavors as they will reliably 
bring the interfaces up and down, effectively restarting the network.

The handler utilizes the "listen" argument that allows triggering mulitple handlers at once (in this case, *restart rhel network* and *restart ubuntu network*).

### Usage

Include the role in a playbook:

```bash
---
# Create a Linux network restart handler 

- name: network restart handler
  hosts: Linux
  gather_facts: yes
  remote_user: sysadmin
  become: yes

  roles:
    - lin_network_restart
  
```
Then, call the handler, by its listener, in a task:

```bash
---
# Echo something and then restart networking

- name: message for red hat
  shell: echo "This is a Red Hat system, use network service"
  when: ansible_distribution == "RedHat"

  notify: "restart network"

- name: message for ubuntu
  shell: echo "This is an Ubuntu system, use ifconfig"
  when: ansible_distribution == "Ubuntu"

  notify: "restart network"
```


Reboot
======

* this is a reboot handler
* to use it, include the role and use notify: 'reboot server'.
* realise that as a handler, the reboot will occur at the end of a play.
* the 'reboot' module for linux is new in Ansible 2.7
* To use it in a playbook, remember the task has to report a change:
```bash
roles:
  - role: reboot
post_tasks:
- name: 'reboot test linux'
  shell: echo 'reboot this machine'
  when: ansible_system == 'Linux'
  notify: 'reboot server'
- name: 'reboot test win32'
  win_shell: echo 'reboot this win machine'
  when: ansible_system == 'Win32NT'
  notify: 'reboot server'
```

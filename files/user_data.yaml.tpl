#cloud-config
%{ if admin_user_password != "" ~}
chpasswd:
  list: |
     ${ssh_admin_user}:${admin_user_password}
  expire: False
%{ endif ~}
preserve_hostname: false
hostname: ${hostname}
%{ if is_fqdn != "" ~}
fqdn: ${hostname}
prefer_fqdn_over_hostname: true
%{ endif ~}
users:
  - default
  - name: ${ssh_admin_user}
    ssh_authorized_keys:
      - "${ssh_admin_public_key}"
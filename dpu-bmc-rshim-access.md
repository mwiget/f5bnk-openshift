ssh to DPU BMC IP, default root password is 0penBmc and needs to be changed
at first login. 


```
[mwiget@arm1 rhcos-bfb-builder]$ ssh root@192.168.68.88
The authenticity of host '192.168.68.88 (192.168.68.88)' can't be established.
RSA key fingerprint is SHA256:EN7k4TWhC7zL+pyC/eYSPafgrTNUxksaEMEmDNL/yIc.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.68.88' (RSA) to the list of known hosts.
root@192.168.68.88's password:

You are required to change your password immediately (administrator enforced)
Password has expired. Please change it now.
Enter root@192.168.68.88's old password:
Enter root@192.168.68.88's new password:
Retype root@192.168.68.88's new password:

BAD PASSWORD: is too simple
Permission denied, please try again.
root@192.168.68.88's password:

You are required to change your password immediately (administrator enforced)
Password has expired. Please change it now.
Enter root@192.168.68.88's old password:
Enter root@192.168.68.88's new password:
Retype root@192.168.68.88's new password:
root@dpu-bmc:~# ls
root@dpu-bmc:~# df
Filesystem           1K-blocks      Used Available Use% Mounted on
dev                     495072         0    495072   0% /dev
tmpfs                   504296     50068    454228  10% /run
/dev/loop0               30592     30592         0 100% /run/initramfs/ro
/dev/mtdblock6           16384      2676     13708  16% /run/initramfs/rw
cow                      16384      2676     13708  16% /
tmpfs                   504296        12    504284   0% /dev/shm
tmpfs                     4096         0      4096   0% /sys/fs/cgroup
tmpfs                   504296        20    504276   0% /tmp
tmpfs                   504296        24    504272   0% /var/volatile
root@dpu-bmc:~# pwd
/home/root
root@dpu-bmc:~# df -h .
Filesystem                Size      Used Available Use% Mounted on
cow                      16.0M      2.6M     13.4M  16% /
root@dpu-bmc:~# systemctl enable rshim
Created symlink /etc/systemd/system/multi-user.target.wants/rshim.service -> /lib/systemd/system/rshim.service.
root@dpu-bmc:~# systemctl start rshim
root@dpu-bmc:~# systemctl status rshim
* rshim.service - rshim driver for BlueField SoC
     Loaded: loaded (/lib/systemd/system/rshim.service; enabled; vendor preset: disabled)
     Active: active (running) since Tue 2025-08-05 08:22:21 UTC; 4s ago
       Docs: man:rshim(8)
    Process: 4649 ExecStart=/usr/sbin/rshim $OPTIONS (code=exited, status=0/SUCCESS)
   Main PID: 4650 (rshim)
     CGroup: /system.slice/rshim.service
             `-4650 /usr/sbin/rshim

Aug 05 08:22:21 dpu-bmc rshim[4650]: USB device detected
Aug 05 08:22:25 dpu-bmc rshim[4650]: Probing usb-2.1
Aug 05 08:22:25 dpu-bmc rshim[4650]: create rshim usb-2.1
Aug 05 08:22:25 dpu-bmc rshim[4650]: another backend already attached
Aug 05 08:22:25 dpu-bmc rshim[4650]: rshim usb-2.1 deleted
root@dpu-bmc:~# bfb-install
Error: Need to provide both bfb file and rshim device name.
Usage: /usr/sbin/bfb-install [options]
Options:
  -b, --bfb <bfb_file>           BFB image file to use.
  -c, --config <config_file>     Optional configuration file.
  -f, --rootfs <rootfs_file>     Optional rootfs file.
  -h, --help                     Show help message.
  -m, --remote-mode <mode>       Remote mode to use (scp, nc, ncpipe).
  -r, --rshim <device>           Rshim device, format [<ip>:<port>:]rshim<N>.
  -R, --reverse-nc               Reverse netcat mode.
  -v, --verbose                  Enable verbose output.
root@dpu-bmc:~#
```

Then one can query the firmware with

```
$ curl -k -u root:<pwd> https://192.168.68.88/redfish/v1/UpdateService/FirmwareInventory/BMC_Firmware
{
  "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/BMC_Firmware",
  "@odata.type": "#SoftwareInventory.v1_4_0.SoftwareInventory",
  "Description": "BMC image",
  "Id": "BMC_Firmware",
  "Manufacturer": "",
  "Name": "Software Inventory",
  "RelatedItem": [],
  "RelatedItem@odata.count": 0,
  "SoftwareId": "0x0018",
  "Status": {
    "Conditions": [],
    "Health": "OK",
    "HealthRollup": "OK",
    "State": "Enabled"
  },
  "Updateable": true,
  "Version": "BF-24.04-5",
  "WriteProtected": false
```


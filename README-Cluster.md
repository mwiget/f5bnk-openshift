## Create Redhat AIO OpenShift Cluster

1) I created the AIO cluster using Assisted Installer, created a bootstrap ISO via UI, then booted a KVM VM with it (14 cores, 42G RAM, br0 as bridge, host-passthru). 

2) Then I created DNS entries pointing to the VM's IP address

```
$ host api.mw-bnk.mwlabs.net
api.mw-bnk.mwlabs.net has address 192.168.68.95
$ host api-int.mw-bnk.mwlabs.net
api-int.mw-bnk.mwlabs.net has address 192.168.68.95
$ host *.apps.mw-bnk.mwlabs.net
*.apps.mw-bnk.mwlabs.net has address 192.168.68.95
```

3) Once cluster is up, downloaded kubeadm from the UI and upgraded with 

```
oc adm upgrade --to-multi-arch
```

This took roughly 30 minutes.

4) Create worker.ign with 

```
oc extract -n openshift-machine-api secret/worker-user-data-managed --keys=userData --to=- > worker.ign
```

5) Imaged the DPU with 

```
sudo bfb-install --rshim rshim0 --config worker.ign --bfb rhcos_4.19.0-ec.4_installer_2025-04-23_07-48-42.bfb
```

now this works for me, because the host the DPU is sitting in still runs Ubuntu. We have to find a simple way (take a peak at DPF) on howto do this on a RHCOS node.

7) change hostname of the DPU to rome1-dpu 

edit /etc/hosts and add rome1-dpu to 127.0.0.1

```
sudo hostnamectl set-hostname rome1-dpu
echo rome1-dpu > /etc/hostname
sudo systemctl restart systemd-hostnamed
sudo systemctl restart kubelet
```

6) Wait for another 20 to 30 minutes until the DPU knocks with a csr request, which shows up on the redhat console UI and can be approved there. Approve it (twice), via UI or CLI (oc get csr; oc adm certificate approve csr-xxxxx)

 Image 

7) wait for the node to show up

```
$ oc get node
NAME STATUS ROLES AGE VERSION
master-0 Ready control-plane,master,worker 112m v1.32.5
rome1-dpu Ready worker 17m v1.32.5
```

8) Adding worker node hosting the DPU

The order of adding DPU and host worker node doesn't matter. I just used this method as I had Ubuntu and DOCA drivers on the host, making
it straightforward to image the DPU.

Via Redhat Console UI, Click on Hosts, then 'Add Hosts', which guides you thru creating an installer ISO. The original ISO
used to bootstrap the AIO cluster can't be used. 

Boot the worker node with the ISO, then wait for it to show up in the UI, adjust the hostname, edit details (like not to format the existing
ubuntu disk), then click install.

After a while, the node will show up on the local cluster UI under compute, waiting to get approved. 

All set.

```
$ oc get node
NAME        STATUS   ROLES                         AGE   VERSION
master-0    Ready    control-plane,master,worker   44h   v1.32.5
rome1       Ready    worker                        29h   v1.32.5
rome1-dpu   Ready    dpu,worker                    42h   v1.32.5
```


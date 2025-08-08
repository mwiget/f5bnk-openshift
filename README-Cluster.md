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

4) Create worker.ign

Check all secrets

```
$ oc get secret -n openshift-machine-api
NAME                                                 TYPE                      DATA   AGE
cluster-autoscaler-operator-cert                     kubernetes.io/tls         2      8h
cluster-autoscaler-operator-dockercfg-psf2b          kubernetes.io/dockercfg   1      8h
cluster-baremetal-operator-tls                       kubernetes.io/tls         2      8h
cluster-baremetal-webhook-server-cert                kubernetes.io/tls         2      8h
control-plane-machine-set-operator-dockercfg-kchs2   kubernetes.io/dockercfg   1      8h
control-plane-machine-set-operator-tls               kubernetes.io/tls         2      8h
machine-api-controllers-tls                          kubernetes.io/tls         2      8h
machine-api-operator-dockercfg-zm6sl                 kubernetes.io/dockercfg   1      8h
machine-api-operator-machine-webhook-cert            kubernetes.io/tls         2      8h
machine-api-operator-tls                             kubernetes.io/tls         2      8h
machine-api-operator-webhook-cert                    kubernetes.io/tls         2      8h
master-user-data                                     Opaque                    2      8h
master-user-data-managed                             Opaque                    2      8h
worker-user-data                                     Opaque                    2      8h
worker-user-data-managed                             Opaque                    2      8h
```

list machine config pools

```
$ oc get machineconfigpools
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-cfa8a1f464e15fad7d436c7741a5ac45   True      False      False      1              1                   1                     0                      8h
worker   rendered-worker-c10b59efee5a90e5882b168ab0b9524e   True      False      False      0              0                   0                     0                      8h
```

Create worker.ign

```
oc extract -n openshift-machine-api secret/worker-user-data-managed --keys=userData --to=- > worker.ign
```

We wan't to create a separate pool for dpu role so we can define a specific DPU OS version.

```
$ ./create-dpu-mcp.sh

machineconfig.machineconfiguration.openshift.io/00-role-dpu unchanged
machineconfigpool.machineconfiguration.openshift.io/dpu unchanged
waiting for dpu machineconfig status True ...
machineconfigpool.machineconfiguration.openshift.io/dpu condition met
NAME   CONFIG                                          UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
dpu    rendered-dpu-c10b59efee5a90e5882b168ab0b9524e   True      False      False      0              0                   0                     0                      5m56s

# userData

-rw-r--r-- 1 mwiget mwiget 1867 Aug  8 04:05 dpu.ign
```

```
$ oc get mcp
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
dpu      rendered-dpu-c10b59efee5a90e5882b168ab0b9524e      True      False      False      0              0                   0                     0                      17s
master   rendered-master-cfa8a1f464e15fad7d436c7741a5ac45   True      False      False      1              1                   1                     0                      8h
worker   rendered-worker-c10b59efee5a90e5882b168ab0b9524e   True      False      False      0              0                   0                     0                      8h
```

list secrets, look for the newly created dpu-user-data-managed Opaque 

```
$ oc get secret -n openshift-machine-api
NAME                                                 TYPE                      DATA   AGE
cluster-autoscaler-operator-cert                     kubernetes.io/tls         2      8h
cluster-autoscaler-operator-dockercfg-psf2b          kubernetes.io/dockercfg   1      8h
cluster-baremetal-operator-tls                       kubernetes.io/tls         2      8h
cluster-baremetal-webhook-server-cert                kubernetes.io/tls         2      8h
control-plane-machine-set-operator-dockercfg-kchs2   kubernetes.io/dockercfg   1      8h
control-plane-machine-set-operator-tls               kubernetes.io/tls         2      8h
dpu-user-data-managed                                Opaque                    2      2m
machine-api-controllers-tls                          kubernetes.io/tls         2      8h
machine-api-operator-dockercfg-zm6sl                 kubernetes.io/dockercfg   1      8h
machine-api-operator-machine-webhook-cert            kubernetes.io/tls         2      8h
machine-api-operator-tls                             kubernetes.io/tls         2      8h
machine-api-operator-webhook-cert                    kubernetes.io/tls         2      8h
master-user-data                                     Opaque                    2      8h
master-user-data-managed                             Opaque                    2      8h
worker-user-data                                     Opaque                    2      8h
worker-user-data-managed                             Opaque                    2      8h
```


5) Imaged the DPU with 

use dpu.ign instead of worker.ign if using machineconfig 

```
sudo bfb-install --rshim rshim0 --config worker.ign --bfb rhcos_4.19.0-ec.4_installer_2025-04-23_07-48-42.bfb
```

now this works for me, because the host the DPU is sitting in still runs Ubuntu. We have to find a simple way (take a peak at DPF) on howto do this on a RHCOS node.

7) change hostname of the DPU to rome1-dpu 

edit /etc/hosts and add rome1-dpu to 127.0.0.1

```
sudo hostnamectl set-hostname rome1-dpu
echo rome1-dpu > /etc/hostname
sudo vi /etc/hosts  # add hostname to 127.0.0.1
reboot
```


6) Wait for another 20 to 30 minutes until the DPU knocks with a csr request, which shows up on the redhat console UI and can be approved there. Approve it (twice), via UI or CLI (oc get csr; oc adm certificate approve csr-xxxxx)

```
$ oc get csr                                                                                                                      
NAME        AGE   SIGNERNAME                                    REQUESTOR                                                                   REQUESTEDDURATION   CONDITION
csr-szlwn   30s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper   <none>              Pending

$ oc adm certificate approve csr-szlwn 
certificatesigningrequest.certificates.k8s.io/csr-szlwn approved

$ oc get csr
NAME        AGE     SIGNERNAME                                    REQUESTOR                                                                   REQUESTEDDURATION   CONDITION
csr-g5rtk   12s     kubernetes.io/kubelet-serving                 system:node:rome1-dpu                                                       <none>              Pending
csr-szlwn   2m42s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper   <none>              Approved,Issued

$ oc adm certificate approve csr-g5rtk
certificatesigningrequest.certificates.k8s.io/csr-g5rtk approved


(base) mwiget@lake1:~/f5/f5bnk-openshift$ oc get csr
NAME        AGE     SIGNERNAME                                    REQUESTOR                                                                   REQUESTEDDURATION   CONDITION
csr-g5rtk   57s     kubernetes.io/kubelet-serving                 system:node:rome1-dpu                                                       <none>              Approved,Issued
csr-szlwn   3m27s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper   <none>              Approved,Issued
```


 Image 

7) wait for the node to show up

```
$ oc get node -o wide
NAME                STATUS     ROLES                         AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                                                KERNEL-VERSION                  CONTAINER-RUNTIME
52-54-00-ab-cd-e1   Ready      control-plane,master,worker   10h   v1.32.6   192.168.68.98   <none>        Red Hat Enterprise Linux CoreOS 9.6.20250715-0 (Plow)   5.14.0-570.27.1.el9_6.x86_64    cri-o://1.32.6-3.rhaos4.19.gitd9321ae.el9
rome1-dpu           NotReady   worker                        91s   v1.32.6   192.168.68.79   <none>        Red Hat Enterprise Linux CoreOS 9.6.20250715-0 (Plow)   5.14.0-570.27.1.el9_6.aarch64   cri-o://1.32.6-3.rhaos4.19.gitd9321ae.el9
```

This shows that the dpu node upgraded its OS version to match the cluster, which overwrote the bfb image that contained DOCA.

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


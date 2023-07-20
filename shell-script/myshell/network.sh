virsh net-destroy default
virsh net-undefine default
systemctl restart libvirtd.service
yum remove libvirt


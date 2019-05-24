# Cluster test Provisioning

cluster_name = "k8s"
az_list=["jakarta-1a", "jakarta-1b", "jakarta-1c"]
dns_nameservers=["8.8.8.8" , "8.8.4.4"]

# SSH key to use for access to nodes
#public_key_path = "/root/.ssh/id_rsa.pub"

# image to use for bastion, masters, standalone etcd instances, and nodes
image = "Ubuntu 18.04 LTS"

# user on the node (ex. core on Container Linux, ubuntu on Ubuntu, etc.)
ssh_user = "ubuntu"

# 0|1 bastion nodes
number_of_bastions = 0
flavor_bastion = "c1b7530d-be10-4097-a90f-d75423d97210"

# standalone etcds
number_of_etcd = 0
flavor_etcd = "c1b7530d-be10-4097-a90f-d75423d97210"

# masters
number_of_k8s_masters = 1
number_of_k8s_masters_no_etcd = 0
number_of_k8s_masters_no_floating_ip = 0
number_of_k8s_masters_no_floating_ip_no_etcd = 0
flavor_k8s_master = "c1b7530d-be10-4097-a90f-d75423d97210"

# nodes
number_of_k8s_nodes = 2
number_of_k8s_nodes_no_floating_ip = 0
flavor_k8s_node = "c1b7530d-be10-4097-a90f-d75423d97210"

# GlusterFS
# either 0 or more than one
#number_of_gfs_nodes_no_floating_ip = 1
#gfs_volume_size_in_gb = 150
# Container Linux does not support GlusterFS
image_gfs = "buntu 18.04 LTS"
# May be different from other nodes
#ssh_user_gfs = "ubuntu"
#flavor_gfs_node = "a627cac9-8ef6-40f6-b030-573231751309"

# networking
network_name = "k8s-network"
external_net = "fa2c3b23-5f25-4ab1-b06b-6edc405ec323"
subnet_cidr = "10.20.20.0/24"
floatingip_pool = "Public_Network"
master_allowed_remote_ips = ["0.0.0.0/0"]

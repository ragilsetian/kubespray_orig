resource "openstack_compute_keypair_v2" "k8s" {
  name       = "new-keypair"
  public_key = "${chomp(file(var.public_key_path))}"

}

resource "openstack_networking_secgroup_v2" "k8s_master" {
  name                 = "${var.cluster_name}-k8s-master"
  description          = "${var.cluster_name} - Master"
  delete_default_rules = false
}

resource "openstack_networking_secgroup_rule_v2" "master-ssh" {
  count             = "${length(var.master_allowed_remote_ips)}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "22"
  port_range_max    = "22"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "open-ports" {
  count             = "${length(var.master_allowed_remote_ips)}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  port_range_min    = "0"
  port_range_max    = "0"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "master-icmp" {
  count             = "${length(var.master_allowed_remote_ips)}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "30000"
  port_range_max    = "32767"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_master.id}"
}

resource "openstack_compute_instance_v2" "k8s_master" {
  name              = "${var.cluster_name}-master-${count.index+1}"
  count             = "${var.number_of_k8s_masters}"
  availability_zone = "${element(var.az_list, count.index)}"
  image_name        = "${var.image}"
  flavor_id         = "${var.flavor_k8s_master}"
  key_pair          = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = ["${openstack_networking_secgroup_v2.k8s_master.name}"  ]

  metadata = {
    ssh_user         = "${var.ssh_user}"
    kubespray_groups = "etcd,kube-master,${var.supplementary_master_groups},k8s-cluster,vault"
    depends_on       = "${var.network_id}"
  }

  provisioner "local-exec" {
    command = "sed s/USER/${var.ssh_user}/ contrib/terraform/openstack/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element( concat(var.bastion_fips, var.k8s_master_fips), 0)}/ > contrib/terraform/group_vars/no-floating.yml"
  }
}

resource "openstack_compute_instance_v2" "k8s_master_no_etcd" {
  name              = "${var.cluster_name}-master-ne-${count.index+1}"
  count             = "${var.number_of_k8s_masters_no_etcd}"
  availability_zone = "${element(var.az_list, count.index)}"
  image_name        = "${var.image}"
  flavor_id         = "${var.flavor_k8s_master}"
  key_pair          = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = ["${openstack_networking_secgroup_v2.k8s_master.name}" ] 

  metadata = {
    ssh_user         = "${var.ssh_user}"
    kubespray_groups = "kube-master,${var.supplementary_master_groups},k8s-cluster,vault"
    depends_on       = "${var.network_id}"
  }

  provisioner "local-exec" {
    command = "sed s/USER/${var.ssh_user}/ contrib/terraform/openstack/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element( concat(var.bastion_fips, var.k8s_master_fips), 0)}/ > contrib/terraform/group_vars/no-floating.yml"
  }
}

resource "openstack_compute_instance_v2" "etcd" {
  name              = "${var.cluster_name}-etcd-${count.index+1}"
  count             = "${var.number_of_etcd}"
  availability_zone = "${element(var.az_list, count.index)}"
  image_name        = "${var.image}"
  flavor_id         = "${var.flavor_etcd}"
  key_pair          = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = ["${openstack_networking_secgroup_v2.k8s_master.name}"]

  metadata = {
    ssh_user         = "${var.ssh_user}"
    kubespray_groups = "etcd,vault,no-floating"
    depends_on       = "${var.network_id}"
  }
}

resource "openstack_compute_instance_v2" "k8s_master_no_floating_ip" {
  name              = "${var.cluster_name}-master-nf-${count.index+1}"
  count             = "${var.number_of_k8s_masters_no_floating_ip}"
  availability_zone = "${element(var.az_list, count.index)}"
  image_name        = "${var.image}"
  flavor_id         = "${var.flavor_k8s_master}"
  key_pair          = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = ["${openstack_networking_secgroup_v2.k8s_master.name}"]
  

  metadata = {
    ssh_user         = "${var.ssh_user}"
    kubespray_groups = "etcd,kube-master,${var.supplementary_master_groups},k8s-cluster,vault,no-floating"
    depends_on       = "${var.network_id}"
  }
}

resource "openstack_compute_instance_v2" "k8s_master_no_floating_ip_no_etcd" {
  name              = "${var.cluster_name}-master-ne-nf-${count.index+1}"
  count             = "${var.number_of_k8s_masters_no_floating_ip_no_etcd}"
  availability_zone = "${element(var.az_list, count.index)}"
  image_name        = "${var.image}"
  flavor_id         = "${var.flavor_k8s_master}"
  key_pair          = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = "${openstack_networking_secgroup_v2.k8s_master.name}"

  metadata = {
    ssh_user         = "${var.ssh_user}"
    kubespray_groups = "kube-master,${var.supplementary_master_groups},k8s-cluster,vault,no-floating"
    depends_on       = "${var.network_id}"
  }
}

resource "openstack_compute_instance_v2" "k8s_node" {
  name              = "${var.cluster_name}-node-${count.index+1}"
  count             = "${var.number_of_k8s_nodes}"
  availability_zone = "${element(var.az_list, count.index)}"
  image_name        = "${var.image}"
  flavor_id         = "${var.flavor_k8s_node}"
  key_pair          = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.network_name}"
  }

   security_groups = ["${openstack_networking_secgroup_v2.k8s_master.name}"]

  metadata = {
    ssh_user         = "${var.ssh_user}"
    kubespray_groups = "kube-node,k8s-cluster,${var.supplementary_node_groups}"
    depends_on       = "${var.network_id}"
  }

  provisioner "local-exec" {
    command = "sed s/USER/${var.ssh_user}/ contrib/terraform/openstack/ansible_bastion_template.txt | sed s/BASTION_ADDRESS/${element( concat(var.bastion_fips, var.k8s_node_fips), 0)}/ > contrib/terraform/group_vars/no-floating.yml"
  }
}

resource "openstack_compute_instance_v2" "k8s_node_no_floating_ip" {
  name              = "${var.cluster_name}-node-nf-${count.index+1}"
  count             = "${var.number_of_k8s_nodes_no_floating_ip}"
  availability_zone = "${element(var.az_list, count.index)}"
  image_name        = "${var.image}"
  flavor_id         = "${var.flavor_k8s_node}"
  key_pair          = "${openstack_compute_keypair_v2.k8s.name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = [ "${openstack_networking_secgroup_v2.k8s_master.name}"]
  
metadata = {
    ssh_user         = "${var.ssh_user}"
    kubespray_groups = "kube-node,k8s-cluster,no-floating,${var.supplementary_node_groups}"
    depends_on       = "${var.network_id}"
  }
}


resource "openstack_compute_floatingip_associate_v2" "k8s_master" {
  count       = "${var.number_of_k8s_masters}"
  instance_id = "${element(openstack_compute_instance_v2.k8s_master.*.id, count.index)}"
  floating_ip = "${var.k8s_master_fips[count.index]}"
}

resource "openstack_compute_floatingip_associate_v2" "k8s_master_no_etcd" {
  count       = "${var.number_of_k8s_masters_no_etcd}"
  instance_id = "${element(openstack_compute_instance_v2.k8s_master_no_etcd.*.id, count.index)}"
  floating_ip = "${var.k8s_master_no_etcd_fips[count.index]}"
}

resource "openstack_compute_floatingip_associate_v2" "k8s_node" {
  count       = "${var.number_of_k8s_nodes}"
  floating_ip = "${var.k8s_node_fips[count.index]}"
  instance_id = "${element(openstack_compute_instance_v2.k8s_node.*.id, count.index)}"
}


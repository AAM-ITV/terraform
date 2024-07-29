terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.88"
    }
  }
}
provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}
resource "yandex_compute_instance" "builder_instance" {
  name        = "terraform-instance"
  platform_id = "standard-v1"
  resources {
    cores  = 4
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd88m3uah9t47loeseir"
      size     = 30
      type     = "network-ssd"
    }
  }
  network_interface {
    subnet_id = "e9bbqtbbo4evg3kk5esc"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-11-jdk maven git",
      "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",
      "cd boxfuse-sample-java-war-hello",
      "mvn package",
       "scp -i ~/.ssh/id_rsa target/hello-1.0.war ubuntu@${yandex_compute_instance.production_instance.network_interface.0.nat_ip_address}:/home/ubuntu/hello-1.0.war"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface.0.nat_ip_address
    }
  }
}

resource "yandex_compute_instance" "production_instance" {
  name        = "production-instance"
  platform_id = "standard-v1"
  resources {
    cores  = 4
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd88m3uah9t47loeseir"
      size     = 30
      type     = "network-ssd"
    }
  }
  network_interface {
    subnet_id = "e9bbqtbbo4evg3kk5esc"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "file" {
    source      = "/path/to/hello-1.0.war"  # Локальный путь
    destination = "/home/ubuntu/hello-1.0.war"
}
  provisioner "remote-exec" {
   inline = [
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-11-jdk tomcat9",
      "sudo systemctl start tomcat9",
      "sudo systemctl enable tomcat9",
      "sudo mv /home/ubuntu/hello-1.0.war /var/lib/tomcat9/webapps/hello.war"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface.0.nat_ip_address
   }
 } 
}
  

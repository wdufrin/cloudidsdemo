terraform{
}

provider "google" {
    project = var.project_id
    region = var.region
    zone = var.zone
}

module "services" {
    #Enables 3 required APIs. Compute, Service Networking and IDS
    source  = "terraform-google-modules/project-factory/google//modules/project_services"
    version = "~> 6.0.0"

    project_id                  = var.project_id
    enable_apis                 = var.enable_apis
    disable_services_on_destroy = var.disable_services_on_destroy
    disable_dependent_services  = var.disable_dependent_services

    activate_apis = [
        "compute.googleapis.com",
        "servicenetworking.googleapis.com",
        "ids.googleapis.com"
    ]
}

module "networking" {
    #Creates VPC network and 2 subnets
    depends_on = [module.services.activate_apis]
    source  = "terraform-google-modules/network/google"
    version = "~> 3.0"

    project_id   = var.project_id
    network_name = var.network
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = var.subnet
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = var.region
            subnet_private_access = true
            subnet_flow_logs      = true
        },{
            subnet_name           = "red-subnet"
            subnet_ip             = "10.20.10.0/24"
            subnet_region         = "europe-west1"
            subnet_private_access = true
            subnet_flow_logs      = true
        }
    ]
}

resource "time_sleep" "wait_30_seconds" {
    #Adds a delay to ensure VPC creation completes before Compute is started
    depends_on = [module.networking.subnets]
    create_duration = "30s"
}

resource "google_compute_instance" "blue-server" {
    #Builds a simple apache webserver with a hello world page
    depends_on = [module.firewall_rules]
    project = var.project_id
    zone = var.zone
    name = "blue-server"
    machine_type = "n1-standard-2"
    tags = ["http-server", "https-server", "ssh"]
    
    boot_disk {
        initialize_params {
            image = "debian-10-buster-v20210817"
        }
    }
    
    shielded_instance_config {
        enable_secure_boot = true      
    }
     
    network_interface {
        network = var.network
        subnetwork = var.subnet
        access_config {} # use for external IP
    } 
    allow_stopping_for_update = true

    metadata_startup_script = <<SCRIPT
        sudo apt update && sudo apt -y install apache2
        echo '<!doctype html><html><body><h1>Hello World!</h1></body></html>' | sudo tee /var/www/html/index.html
        SCRIPT
}

resource "google_compute_instance" "red-server" {
    #Builds a basic linux server for simulating attacks from the red-subnet
    depends_on = [module.firewall_rules]
    project = var.project_id
    zone = "europe-west1-b"
    name = "red-server"
    machine_type = "n1-standard-2"
    tags = ["red-server", "ssh"]
    
    boot_disk {
        initialize_params {
            image = "debian-10-buster-v20210817"
        }
    }
    
    shielded_instance_config {
        enable_secure_boot = true      
    }
     
    network_interface {
        network = var.network
        subnetwork = "red-subnet"
        access_config {} # use for external IP
    } 
    allow_stopping_for_update = true
}

#Start firewall rule creation
resource "google_compute_firewall" "http" {
    depends_on = [time_sleep.wait_30_seconds]
    project     = var.project_id # Replace this with your project ID in quotes
    name        = "allow-http-traffic"
    network     = var.network
    description = "Creates firewall rule targeting tagged instances"

    allow {
        protocol = "tcp"
        ports    = ["80", "8080", "1000-2000"]
  }
    target_tags = ["http-server"]
}

module "firewall_rules" {
  depends_on = [time_sleep.wait_30_seconds]
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = var.network

  rules = [{
    name                    = "allow-ssh-ingress"
    description             = "Allow ssh ingress access to the servers"
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = ["ssh"]
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },{
    name                    = "allow-http-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = ["http-server"]
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },{
    name                    = "allow-https-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = ["https-server"]
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["443"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },{
    name                    = "allow-rpc-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = ["rpc"]
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["135"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },{
    name                    = "allow-smb-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = ["smb"]
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["445"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },{
    name                    = "allow-rdp-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = ["rdp"]
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["3389"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}
#End Firewall Creation
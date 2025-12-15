Production level CI/CD Pipeline Project
-----------------------------------------------------------------------------------------------------------------------------
User -> Github -> Jenkins -> Maven Test -> Unit Test -> Trivy File scanning -> SonaQube quality check -> Maven Package
								
								Terraform script to create cluseter
									|
	LB URL <- Deploy to EKS <- Push image to Registry	<=Trivy Image scan <- Build Docker Image/PR <- Nexus Artifactory
	  |
Godaddy domain mapping -> Url (Shubh.com) -> BlackBoxExporter tool(Metrix collection -> forward to) -> Prometheus & Grafana
	  
*********************************************************************************************************************************
Lab:
---
	1. Setup Repo
	2. Setup Required servers [Jenkins, Sonar, Nexus, Monitoring tool]
	3. Configure tools
	4. Create the pipeline and Create EKS cluster
	5. Trigger the pipeline to deploy an application
	6. Assign custom domain to the deployed application
	7. Monitoring the application
*********************************************************************************************************************************

1. Create 2 machine for sonarqube and nexus
	- t2.micro
2. Create 1 machine for jenkins
	- t2.large
	- 25 GB

*********************************************************************************************************************************
Connect to those machines

1. Setup nexus
	- sudo apt update
	- Install docker
		. sudo apt install docker.io
	- sudo docker run -d -p 8081:8081 sonatype/nexus3
	- Setup password
	
	
2. Setup sonarqube
	- sudo apt update
	- Install docker
		. sudo apt install docker.io
	- sudo docker run -d -p 9000:9000 sonarqube:lts-community
	- setup password
	- Generate Token
		Administration
			. security -> Generate
			squ_77f9956791e66a62df27e46c31af1005b315f41d
	
	- sonarqube server = the location where reports stored
	- sonarqube scanner = Installed within jenkins, perform analysis and publish the reports
	So Configure sonarqube-server
	- System -> Sonarqube servers -> add -> name: sonar-server -> Server URL -> ec2>ip:port
	- add credential token inside creds for sonarqube
	- Configure sonar scanner
	
	
3. setup Jenkins
	- sudo apt update -y
	- sudo apt install openjdk
	- install jenkins LTS version 
		* sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
		  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
		  echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
		  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
		  /etc/apt/sources.list.d/jenkins.list > /dev/null
		  sudo apt update
		* sudo apt install jenkins
		* sudo systemctl enable jenkins
		* sudo systemctl start jenkins
	- Install docker on this machine
		$ # Add Docker's official GPG key:
			sudo apt update
			sudo apt install ca-certificates curl
			sudo install -m 0755 -d /etc/apt/keyrings
			sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
			sudo chmod a+r /etc/apt/keyrings/docker.asc

			# Add the repository to Apt sources:
			sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
			Types: deb
			URIs: https://download.docker.com/linux/ubuntu
			Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
			Components: stable
			Signed-By: /etc/apt/keyrings/docker.asc
			EOF

			sudo apt update
		$	Install the Docker packages.
			sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
				By Default when we install docker only root user has the access to docker
				we need to create Group and add user to that group
		* sudo usermod -aG docker jenkins 
				You can restart the vm or logout and login or  simply
			OR 
		  sudo chmod 666 /var/run/docker.sock
	- Configure jenkins
		- <ip>:8080
	- Install necessary plugins
		1. sonar scanner					6. docker pipeline	
		2. config file provider				7. kubernetes
		3. maven							8. kubernetes Client API
		4. pipeline maven integration		9. kubernetes Credentials
		5. pipeline stage view				10. kubernetes CLI
											11. Eclipse temurine installer
	- Restart jenkins
	- Install Trivy on jenkins as by default no plugin in jenkins
		$ Add repository setting to /etc/apt/sources.list.d.
		* sudo apt-get install wget gnupg
		  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
		  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
		  sudo apt-get update
		  sudo apt-get install trivy
	Configure Tools:
	- Goto settings -> tools -> docker -> install auto
								sonar-scanner -> name(sonar-scanner)
								maven -> maven3 
								jdk -> jdk 21 -> add installer
							
	
-----------
1. Create 1 server 
	- Install terraform, kubectl, aws-cli
	- create tf files to provision cluster (main.tf, variables.tf, output.tf)
	- update kubeconfig (aws eks --region ap-south-1 update-kubeconfig --name logging_cluster)
	- add RBAC for cluster (serviceAccount.yml, role.yml,rolebinding.yml,clusterrole.yml,clusterrolebinding.yml,secret.yml)
	- connect to docker registry
		. kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=shubh1818 --docker-password=<Password> -n webapps
	- Get secrets
		kubectl get secret -n webapps
	- Describe secrets and copy token
		kubectl describe secret mysecretname -n webapps
	- Add token in jenkins credentials as secret text
----------------------
1. Create 1 vm for monitoring t2.large
	- wget https://github.com/prometheus/prometheus/releases/download/v3.8.0/prometheus-3.8.0.linux-amd64.tar.gz
	- tar -xvf prometheus-3.8.0.linux-amd64.tar.gz
	- mv prometheus-3.8.0.linux-amd64 prometheus
	- wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.28.0/blackbox_exporter-0.28.0.linux-amd64.tar.gz
	- tar -xvf blackbox_exporter-0.28.0.linux-amd64.tar.gz
	- mv blackbox_exporter-0.28.0.linux-amd64 blackbox_exporter
	- sudo apt-get install -y adduser libfontconfig1 musl
	- wget https://dl.grafana.com/grafana-enterprise/release/12.3.0/grafana-enterprise_12.3.0_19497075765_linux_amd64.deb
	- sudo dpkg -i grafana-enterprise_12.3.0_19497075765_linux_amd64.deb
	- sudo /bin/systemctl start grafana-server
	
		Login to grafana -> IP:3000
	
	- cd prometheus > ./prometheus &
		login to prometheus -> IP:9090
	
	- cd blackbox > ./blackbox_exporter &
		login to blackbox -> ip:9115
		
	- Goto https://github.com/prometheus/blackbox_exporter
		copy
		scrape_configs:
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]  # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - http://prometheus.io    # Target to probe with http.
        - https://prometheus.io   # Target to probe with https.
        - http://example.com:8080 # Target to probe with http on port 8080. (Replace with eks endpoint)
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115  # The blackbox exporter's real hostname:port.
  - job_name: 'blackbox_exporter'  # collect blackbox exporter's operational metrics.
    static_configs:
      - targets: ['127.0.0.1:9115']
	  
	  
	- configure data source in grafana
	- add prometheus url
	- add new dashboard
	- copy id 


# CONTAINER MONITORING [@RSYSLOG SERVER]

> **⚠️THE FOLLOWING DOCKER COMPOSE AND ALL IS NEEDED FOR THE RSYSLOG SERVER ONLY-NOWHERE ELSE!**

Well, I have made some changes in the file structure and the whole flow of how the things will work-so yes, these are the changes of the refactor
```txt
container-monitoring
	├── deviceDetails.toml
	├── docker-compose.yml
	├── makePrometheus.sh
	├── prometheus.yml
	├── prometheus_template.yml
	└── README.md
```
Follow the **FLOW** mentioned below to setup things properly:-
1. We first clone the repo on each and every **REMOTE DEVICE** and there, we run the `remote container setup/remoteConfig.sh` file, and once that setup is done, we note these three things per device *(be it LXC or a real Computer - and without running script, we need the same things for Network Nodes)* - 
`Device Name : Static IP : Password`

> **NOTE**: On successful running of the script, this part ends. We head out from the remote-device, and then, we configure the server with the steps given below. **THE BELOW STEPS ARE FOR SERVER SIDE ONLY, NOT FOR THE REMOTE-HOST SIDE**

2. Once we have done `1` for all the devices, we then head to this directory, and add the data in the `deviceDetails.toml`. The reason I am going with `.toml` is that its better than `.json` and can be easily understood.
3. After adding the things to toml, we run the script that will automatically make the `prometheus.yml`, that is, we run `./makePrometheus.sh`
4. Running the script, `prometheus.yml` will be created, and it will have all the device's services under jobs *(like, for every device, there will be two jobs- nodeExporter and cAdvisor)*.
5. With `.yml` made, we run the command `sudo docker compose up -d`. This will run the compose command, and set up the things for us.
6. With Prometheus and even the local cAdvisor running, we can check the same by hitting the `localhost:9090` for prometheus check. And within that, under the status, we can see, the connection status of all the devices with us.


> **Individual Device Metrics Check** - check whether you can hit their mentioned routes from your server *(by typing on the internet the PC's <IP:Port> which should show their NodeExporter page, and even a route `/metrics` or so will show the same)*. Also, check if your prometheus has added the jobs for scraping the things. If the page shows all the PCs u have in the yml, then, you are good to go, and add the things in the Grafana dashboards

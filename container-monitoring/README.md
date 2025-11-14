# CONTAINER MONITORING

> **THE FOLLOWING DOCKER COMPOSE AND ALL IS NEEDED FOR THE RSYSLOG SERVER ONLY-NOWHERE ELSE!**

This should be used once the `./automateSetup.sh` is done, then you come on to **run this on** the **RSYSLOG SERVER**.

While running this, the thing is, you have to **add the IP address along with Port** *(and before doing this, ensure, you have gone thru the container metrics, where the command for setting the `node-exporter` is done on the Device-aka computer or your LXC)* of all the devices you wish to monitor-that is, make a **SEPARATE Job Name** for that.

Like, when you open the `prometheus.yml`, there are `job_name`s present. It is these parameters which we will be using on the Grafana dashboard to show the things. So keep sure, this is working well for you!

**Once made the changes in the `.yml` you must `restart` prometheus** => `sudo docker restart prometheus`

After restarting, wait for 5mins or so, and then, check whether you can hit their mentioned routes from your server *(by typing on the internet the PC's <IP:Port> which should show their NodeExporter page, and even a route `/metrics` or so will show the same)*. Also, check if your prometheus has added the jobs for scraping the things. If the page shows all the PCs u have in the yml, then, you are good to go, and add the things in the Grafana dashboards
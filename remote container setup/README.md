# CONTAINER-METRICS

The following directory should be used on the PCs (aka, LXCs) whose metrics I want to import on my rsyslog server.

Running the `remoteConfig.sh` will do the following things:
- Download and Setup the rsyslog to send the logs *(by making and editing the rsyslog server's IP over there)*
- Run the container of `nodeexporter` which enables the FETCH of system metrics by some other device *(here, our prometheus on syslog server)*

**Alright, to RUN THE SCRIPT, do this:-**
```bash
cd "remote container setup"         # this directory
chmod +x remoteConfig.sh

# replace the IP below with the actual IP of the Rsyslog Server
./remoteConfig.sh --<IP_OF_SYSLOG_SERVER> 
```
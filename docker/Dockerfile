FROM ubuntu:16.04

LABEL Author="Jason Hindulak"

# Server Name
ENV SESSIONNAME "Ark Docker"
# Map name
ENV SERVERMAP "Extinction"
# Server password
ENV SERVERPASSWORD ""
# Admin password
ENV ADMINPASSWORD "adminpassword"
# Number of Players
ENV NBPLAYERS 70
# If the server is updating when start with docker start
ENV UPDATEONSTART 1
# if the server is backup when start with docker start
ENV BACKUPONSTART 1
#  Tag on github for ark server tools
ENV GIT_TAG v1.6.42
# Server PORT (you can't remap with docker, it doesn't work)
ENV SERVERPORT 27015
# Steam port (you can't remap with docker, it doesn't work)
ENV STEAMPORT 7778
# if the server should backup after stopping
ENV BACKUPONSTOP 0
# If the server warn the players before stopping
ENV WARNONSTOP 0
# UID of the user steam
ENV UID 1000
# GID of the user steam
ENV GID 1000

# Install dependencies 
RUN apt-get update &&\ 
    apt-get install -y perl-modules curl lsof libc6-i386 lib32gcc1 bzip2 git

# Enable passwordless sudo for users under the "sudo" group
RUN touch /etc/sudoers && \
	sed -i.bkp -e \
	's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
	/etc/sudoers

# Run commands as the steam user
RUN adduser \ 
	--disabled-login \ 
	--shell /bin/bash \ 
	--gecos "" \ 
	steam
# Add to sudo group
RUN usermod -a -G sudo steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN touch /root/.bash_profile && \
	chmod 777 /home/steam/run.sh && \
	chmod 777 /home/steam/user.sh && \
	mkdir  /ark

# We use the git method, because api github has a limit ;)
RUN  git clone https://github.com/FezVrasta/ark-server-tools.git /home/steam/ark-server-tools
WORKDIR /home/steam/ark-server-tools/
RUN  git checkout $GIT_TAG 
# Install 
WORKDIR /home/steam/ark-server-tools/tools
RUN chmod +x install.sh && \
	./install.sh steam 

# Allow crontab to call arkmanager
RUN ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

# Define default config file in /etc/arkmanager
COPY arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg

# Define default config file in /etc/arkmanager
COPY instance.cfg /etc/arkmanager/instances/main.cfg

RUN chown steam -R /ark && chmod 755 -R /ark

# download steamcmd
RUN mkdir /home/steam/steamcmd && \
	cd /home/steam/steamcmd && \
	curl http://media.steampowered.com/installer/steamcmd_linux.tar.gz | tar -vxz

EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}
EXPOSE ${STEAMPORT}/udp ${SERVERPORT}/udp

VOLUME  /ark 

# Change the working directory to /arkd
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/home/steam/user.sh"]
# Dockerfile to run a linux quake live server
FROM ubuntu:20.04
MAINTAINER Daniel Deflax <daniel@deflax.net>

RUN dpkg --add-architecture i386
RUN apt-get update
#RUN apt-get -y upgrade
RUN apt-get install -y --force-yes libc6:i386 libstdc++6:i386 wget software-properties-common
RUN apt-get install -y --force-yes python3.6 python3.6-dev redis-server
RUN apt-get install -y --force-yes build-essential libzmq3-dev

RUN useradd -ms /bin/bash quake

# copy the nice dotfiles that dockerfile/ubuntu gives us:
RUN cd && cp -R .bashrc .profile /home/quake

WORKDIR /home/quake

RUN chown -R quake:quake /home/quake

USER quake
ENV HOME /home/quake
ENV USER quake

# download and extract steamcmd
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
RUN tar -xvzf steamcmd_linux.tar.gz

# install the quake live server program
RUN ./steamcmd.sh +login anonymous +app_update 349090 +quit
RUN ln -s "Steam/steamapps/common/Quake Live Dedicated Server/" ql

# copy over the custom game files
USER root
COPY server.sh ql/
RUN chown quake:quake ql/server.sh
COPY download-workshop.sh ./
RUN chown quake:quake download-workshop.sh

COPY config/server.cfg ql/baseq3/
RUN chown quake:quake ql/baseq3/server.cfg

COPY config/mappools/mappool_pqlctf.txt ql/baseq3/mappool.txt
RUN chown quake:quake ql/baseq3/mappool.txt

COPY pqlctf.factories ql/baseq3/scripts/
RUN chown -R quake:quake ql/baseq3/scripts

COPY config/workshop.txt ql/baseq3/
RUN chown quake:quake ql/baseq3/workshop.txt

COPY config/acl/access_qlx.txt .quakelive/27960/baseq3/access.txt
RUN chown -R quake:quake .quakelive

USER quake
# download the workshop items
#RUN ./download-workshop.sh

# download and install latest minqlx
# http://stackoverflow.com/a/26738019
RUN wget -O - https://api.github.com/repos/MinoMino/minqlx/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4 | xargs wget
RUN git clone https://github.com/MinoMino/minqlx-plugins.git minqlx-plugins-mainline
RUN git clone https://github.com/tjone270/Quake-Live minqlx-plugins-tjone270
RUN git clone https://github.com/cstewart90/minqlx-plugins minqlx-plugins-cstewart90
RUN git clone https://github.com/dsverdlo/minqlx-plugins minqlx-plugins-dsverdlo
RUN git clone https://github.com/x0rnn/minqlx-plugins minqlx-plugins-x0rnn
RUN git clone https://github.com/x0rnn/minqlx-plugins-1 minqlx-plugins-x0rnn-1
COPY minqlx-plugins-mainline ql/minqlx-plugins
COPY minqlx-plugins-tjone270 ql/minqlx-plugins
COPY minqlx-plugins-tjone270/gamemodes ql/minqlx-plugins 
COPY minqlx-plugins-cstewart90 ql/minqlx-plugins
COPY minqlx-plugins-dsverdlo ql/minqlx-plugins
COPY minqlx-plugins-x0rnn ql/minqlx-plugins
COPY minqlx-plugins-x0rnn-1 ql/minqlx-plugins
COPY plugins ql/minqlx-plugins
RUN cd ql && tar xzf ~/minqlx_v*.tar.gz

USER root
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3.6 get-pip.py
RUN rm get-pip.py
RUN python3.6 -m easy_install pyzmq hiredis
RUN python3.6 -m pip install -r minqlx-plugins/requirements.txt
RUN chown -R quake:quake ql/

USER quake
# ports to connect to: 27960 is udp and tcp, 28960 is tcp
EXPOSE 27960 28960
CMD ql/server.sh 0

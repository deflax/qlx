# Dockerfile to run a linux quake live server
FROM debian:11
MAINTAINER Daniel Deflax <daniel@deflax.net>

RUN dpkg --add-architecture i386
RUN apt-get update
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get -y upgrade
RUN apt-get install -y -q libc6:i386 libstdc++6:i386 wget git apt-utils software-properties-common python3 python3-dev build-essential libzmq3-dev

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
COPY workshop-download.sh ./
RUN chown quake:quake workshop-download.sh

COPY config/server.cfg ql/baseq3/
RUN chown quake:quake ql/baseq3/server.cfg

COPY config/mappools/mappool_pqlctf.txt ql/baseq3/mappool.txt
RUN chown quake:quake ql/baseq3/mappool.txt

COPY config/factories/pqlctf.factories ql/baseq3/scripts/
RUN chown -R quake:quake ql/baseq3/scripts

COPY config/workshop.txt ql/baseq3/
RUN chown quake:quake ql/baseq3/workshop.txt

COPY config/acl/access_qlx.txt .quakelive/27960/baseq3/access.txt
RUN chown -R quake:quake .quakelive

USER quake
# download the workshop items
#RUN ./workshop-download.sh

# download and install latest minqlx
# http://stackoverflow.com/a/26738019
RUN wget -O - https://api.github.com/repos/MinoMino/minqlx/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4 | xargs wget
RUN git clone https://github.com/MinoMino/minqlx-plugins.git minqlx-plugins-mainline && mv -v minqlx-plugins-mainline ql/minqlx-plugins
RUN git clone https://github.com/tjone270/Quake-Live minqlx-plugins-tjone270 && cp -v minqlx-plugins-tjone270/minqlx-plugins/*.py ql/minqlx-plugins && cp -v minqlx-plugins-tjone270/minqlx-plugins/gamemodes/*.py ql/minqlx-plugins
RUN git clone https://github.com/cstewart90/minqlx-plugins minqlx-plugins-cstewart90 && cp -v minqlx-plugins-cstewart90/*.py ql/minqlx-plugins
RUN git clone https://github.com/dsverdlo/minqlx-plugins minqlx-plugins-dsverdlo && cp -v minqlx-plugins-dsverdlo/*.py ql/minqlx-plugins
RUN git clone https://github.com/x0rnn/minqlx-plugins minqlx-plugins-x0rnn && cp -v minqlx-plugins-x0rnn/*.py ql/minqlx-plugins
COPY plugins ql/minqlx-plugins
RUN cd ql && tar xzf ~/minqlx_v*.tar.gz

USER root
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py
RUN rm get-pip.py
RUN python3 -m easy_install pyzmq hiredis
RUN python3 -m pip install -r minqlx-plugins/requirements.txt
RUN chown -R quake:quake ql/

USER quake
# ports to connect to: 27960 is udp and tcp, 28960 is tcp
EXPOSE 27960 28960
CMD ql/server.sh 0

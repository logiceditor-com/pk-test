FROM ubuntu
EXPOSE 5000:5000/tcp
STOPSIGNAL SIGINT
ADD . /code
WORKDIR /code
RUN apt-get -y update
RUN apt-get -y install lua5.1
RUN apt-get -y install lua-socket
CMD ["lua", "standalone_echoserv.lua"]


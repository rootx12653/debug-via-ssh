FROM kalilinux/kali-rolling:latest

LABEL org.opencontainers.image.author="benjitrapp.github.io"

ENV DEBIAN_FRONTEND noninteractive
ARG NGROK_TOKEN
ARG PASSWORD=rootuser
ENV GOROOT=/usr/lib/go
ENV GO111MODULE=on
ENV GOPATH=$HOME/go
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip git vim curl python3

ARG NGROK_API=$1
ARG SSH_USERNAME=$2
ARG SSH_PASSWORD=$3

RUN sudo apt-get update 
RUN sudo apt-get install -y curl jq openssh-server

RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc > /dev/null
RUN echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
RUN sudo apt-get install -y ngrok
RUN sudo service ssh start

RUN sudo adduser --disabled-password --gecos "" $SSH_USERNAME --force-badname
echo "$SSH_USERNAME:$SSH_PASSWORD" | sudo chpasswd
RUN sudo usermod -aG sudo $SSH_USERNAME

RUN ngrok authtoken $NGROK_API
RUN nohup bash -c 'while true; do ngrok tcp 22; sleep 3600; done' &

RUN sleep 10
RUN curl --silent --show-error http://127.0.0.1:4040/api/tunnels > tunnels.json
RUN NGROK_URL=$(jq -r '.tunnels[] | select(.proto=="tcp") | .public_url' tunnels.json)
RUN NGROK_HOST=$(echo $NGROK_URL | cut -d':' -f2 | cut -c 3-)
RUN NGROK_PORT=$(echo $NGROK_URL | cut -d':' -f3)
RUN echo "SSH login information:"
RUN echo "Username: $SSH_USERNAME"
RUN echo "Password: $SSH_PASSWORD"
RUN echo "Hostname: $NGROK_HOST"
RUN echo "Port: $NGROK_PORT"
RUN echo "Use the above information to connect using PuTTY or any SSH client."RUN rm -rf nohup* tunnels*
RUN sleep "3000" 

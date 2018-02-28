FROM ubuntu

RUN apt-get update && apt-get install -y software-properties-common curl git ctags ack-grep
RUN add-apt-repository ppa:neovim-ppa/unstable
RUN apt-get update && apt-get install neovim

RUN echo ". ~/.config/bash/rc" >> /root/bashrc

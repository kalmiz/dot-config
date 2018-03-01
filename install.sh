#!/bin/bash
#
# It installs the dotfiles into the current user's $HOME directory.  If it's
# invoked with the "clean" parameter then this script removes every link which
# definition ends with "#clean".  For example:
#
# ```bash
#  clink ack/rc .ackrc #clean
# ```
# 
# will create a symlink of ack/rc as $HOME/.arkrc and if it's invoked with
# "clean" then removes that symlink.
#

PWD=$(dirname $0)
DIR=$HOME

clink () {
	if [ ! -e $DIR/$2 ]; then
		ln -s $PWD/$1 $DIR/$2
	fi
}

cd $PWD

if [ "$1" == "clean" ]; then
	for i in `grep clink $0 | grep '#clean$' | cut -d ' ' -f 3`; do
		if [ -h $DIR/$i ]; then
			unlink $DIR/$i
		else
			echo "'$DIR/$i' is not a symlink, not safe to delete it." >> /dev/stderr
		fi
	done
else
	[ ! -d $HOME/bin ] && mkdir $HOME/bin
	[ ! -d $HOME/.vim/pack/bundle/start ] && mkdir -p $HOME/.vim/pack/{undodir,pack}/{bundle,themes}/{start,opt}
	[ ! -d $HOME/.local/share/nvim/site ] && mkdir -p $HOME/.local/share/nvim/site
	[ ! -h $HOME/.local/share/nvim/site/pack ] && ln -s $HOME/.vim/pack $HOME/.local/share/nvim/site/
	clink bash/rc .bash_profile
	clink ack/rc .ackrc #clean
	clink ctags/ctags .ctags #clean
	clink ssh .ssh #clean
	clink inputrc .inputrc #clean
	clink nvim/init.vim .vim/vimrc #clean
	if [ $(uname) == "Darwin" ]; then
		source ./osx/defaults
		# http://zanshin.net/2013/08/27/setup-openconnect-for-mac-os-x-lion/
		#curl -s http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script > /usr/local/bin/vpnc-script
		#chmod +x /usr/local/bin/vpnc-script
		#cd /Library/Extensions
		#echo "Loading tun.kext..."
		#sudo kextload -v tun.kext
		clink vpn bin/vpn #clean
		clink vpnc-script bin/vpnc-script #clean
		/usr/local/opt/fzf/install
	else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
		~/.fzf/install
	fi
fi

#!/bin/bash
#
# Ruby Ready
#
# Author: fir.im<dev@fir.im> 

# Base on Josh Frye <joshfng@gmail.com>
# Licence: MIT
#
# Contributions from: Wayne E. Seguin <wayneeseguin@gmail.com>
# Contributions from: Ryan McGeary <ryan@mcgeary.org>
#
# http://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p0.tar.gz
shopt -s nocaseglob
set -e

ruby_version="2.2.3"
ruby_version_string="2.2.3"
ruby_source_url="https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz"
ruby_source_tar_name="ruby-2.2.3.tar.gz"
ruby_source_dir_name="ruby-2.2.3"
script_runner=$(whoami)
rubyready_path=$(cd && pwd)/rubyready
log_file="$rubyready_path/install.log"
system_os=`uname | env LANG=C LC_ALL=C LC_CTYPE=C tr '[:upper:]' '[:lower:]'`

control_c()
{
  echo -en "\n\n*** Exiting ***\n\n"
  exit 1
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

clear

echo "#################################"
echo "########## Ruby Ready ###########"
echo "#################################"

#determine the distro
if [[ $system_os = *linux* ]] ; then
  distro_sig=$(cat /etc/issue)
  redhat_release='/etc/redhat-release'
  if [[ $distro_sig =~ ubuntu ]] ; then
    distro="ubuntu"
  else
      if [ -e $redhat_release ] ; then
          distro="centos"
      fi
  fi
elif [[ $system_os = *darwin* ]] ; then
  distro="osx"
    if [[ ! -f $(which gcc) ]]; then
      echo -e "\nXCode/GCC must be installed in order to build required software. Note that XCode does not automatically do this, but you may have to go to the Preferences menu and install command line tools manually.\n"
      exit 1
    fi
else
  echo -e "\nRuby Ready currently only supports Ubuntu, CentOS and OSX\n"
  exit 1
fi

echo -e "\n\n"
echo "run tail -f $log_file in a new terminal to watch the install"

echo -e "\n"
echo "What this script gets you:"
echo " * Ruby $ruby_version_string"
echo " * Git"
echo " * fir cli Gem"


# Check if the user has sudo privileges.
sudo -v >/dev/null 2>&1 || { echo $script_runner has no sudo privileges ; exit 1; }

# Ask if you want to build Ruby or install RVM
echo -e "\n"
echo "Build Ruby or install RVM?"
echo "=> 1. Build from source"
echo "=> 2. Install RVM"
echo "=> 3. Install rbenv"
echo -n "Select your Ruby type [1, 2, 3]? "
read whichRuby

echo -e "\n"
echo "Using Taobao Gem source for avoiding GFW block?"
echo "=> '1' to use Gem source Mirror from Taobao"
echo "=> '0' or other to download gem directly"
echo -n "Select [1, 0]? "
read useMirror



if [ $useMirror -eq 1 ] ; then
  echo -e "\n\n!!! use taobao gem source \n"
else
  echo -e "\n\n!!! okay, download gem from official source !"
  exit 1
fi

echo -e "\n=> Creating install dir..."
cd && mkdir -p rubyready/src && cd rubyready && touch install.log
echo "==> done..."

echo -e "\n=> Downloading and running recipe for $distro...\n"
#Download the distro specific recipe and run it, passing along all the variables as args
if [[ $system_os = *linux* ]] ; then
  wget --no-check-certificate -O $rubyready_path/src/$distro.sh https://raw.githubusercontent.com/jicheng1014/rubyready/master/recipes/$distro.sh && cd $rubyready_path/src && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $rubyready_path $log_file
else
  cd $rubyready_path/src && curl -O https://raw.githubusercontent.com/jicheng1014/rubyready/master/recipes/$distro.sh && bash $distro.sh $ruby_version $ruby_version_string $ruby_source_url $ruby_source_tar_name $ruby_source_dir_name $whichRuby $rubyready_path $log_file
fi
echo -e "\n==> done running $distro specific commands..."

#now that all the distro specific packages are installed lets get Ruby
if [ $whichRuby -eq 1 ] ; then
  # Install Ruby
  echo -e "\n=> Downloading Ruby $ruby_version_string \n"
  cd $rubyready_path/src && wget $ruby_source_url
  echo -e "\n==> done..."
  echo -e "\n=> Extracting Ruby $ruby_version_string"
  tar -xzf $ruby_source_tar_name >> $log_file 2>&1
  echo "==> done..."
  echo -e "\n=> Building Ruby $ruby_version_string (this will take a while)..."
  cd  $ruby_source_dir_name && ./configure --prefix=/usr/local >> $log_file 2>&1 \
   && make >> $log_file 2>&1 \
    && sudo make install >> $log_file 2>&1
  echo "==> done..."
elif [ $whichRuby -eq 2 ] ; then
  #thanks wayneeseguin :)
  echo -e "\n=> Installing RVM the Ruby enVironment Manager http://rvm.beginrescueend.com/rvm/install/ \n"
  \curl -L https://get.rvm.io | bash >> $log_file 2>&1
  echo -e "\n=> Setting up RVM to load with new shells..."
  #if RVM is installed as user root it goes to /usr/local/rvm/ not ~/.rvm
  if [ -f ~/.bash_profile ] ; then
    if [ -f ~/.profile ] ; then
      echo 'source ~/.profile' >> "$HOME/.bash_profile"
    fi
  fi
  echo "==> done..."
  echo "=> Loading RVM..."
 




  
  if [ -f ~/.profile ] ; then
    source ~/.profile
  fi
  if [ -f ~/.bashrc ] ; then
    source ~/.bashrc
  fi
  if [ -f ~/.bash_profile ] ; then
    source ~/.bash_profile
  fi
  if [ -f /etc/profile.d/rvm.sh ] ; then
    source /etc/profile.d/rvm.sh
  fi
  if [ $useMirror -eq 1 ] ; then
    if [[ $system_os = *linux* ]] ; then
      sed -i 's!cache.ruby-lang.org/pub/ruby!ruby.taobao.org/mirrors/ruby!' $rvm_path/config/db
    else
      sed -i .bak 's!cache.ruby-lang.org/pub/ruby!ruby.taobao.org/mirrors/ruby!' $rvm_path/config/db
    fi
  fi


  echo "==> done..."
  echo -e "\n=> Installing Ruby $ruby_version_string (this will take a while)..."
  echo -e "=> More information about installing rubies can be found at http://rvm.beginrescueend.com/rubies/installing/ \n"
  rvm install $ruby_version >> $log_file 2>&1
  echo -e "\n==> done..."
  echo -e "\n=> Using $ruby_version and setting it as default for new shells..."
  echo "=> More information about Rubies can be found at http://rvm.beginrescueend.com/rubies/default/"
  rvm --default use $ruby_version >> $log_file 2>&1
  echo "==> done..."
elif [ $whichRuby -eq 3 ] ; then
  echo -e "\n=> Installing rbenv https://github.com/sstephenson/rbenv \n"
  git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  if [ -f ~/.profile ] ; then
    source ~/.profile
  fi
  if [ -f ~/.bashrc ] ; then
    source ~/.bashrc
  fi
  if [ -f ~/.bash_profile ] ; then
    source ~/.bash_profile
  fi
  echo -e "\n=> Installing ruby-build  \n"
  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
  echo -e "\n=> Installing ruby \n"
  rbenv install $ruby_version_string >> $log_file 2>&1
  rbenv rehash
  rbenv global $ruby_version_string
  echo "===> done..."
else
  echo "How did you even get here?"
  exit 1
fi

# Reload bash
echo -e "\n=> Reloading shell so ruby and rubygems are available..."
if [ -f ~/.bashrc ] ; then
  source ~/.bashrc
fi
echo "==> done..."

if [ $useMirror -eq 1 ] ; then
  sudo gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
  sudo gem update --system --no-ri --no-rdoc >> $log_file 2>&1
fi



echo -e "\n=> Updating Rubygems..."
if [ $whichRuby -eq 1 ] ; then
  sudo gem update --system --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 2 ] ; then
  gem update --system --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 3 ] ; then
  gem update --system --no-ri --no-rdoc >> $log_file 2>&1
fi
echo "==> done..."

echo -e "\n=> install Gem fir-cli ..."
if [ $whichRuby -eq 1 ] ; then
  sudo gem install fir-cli --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 2 ] ; then
  gem install fir-cli --no-ri --no-rdoc >> $log_file 2>&1
elif [ $whichRuby -eq 3 ] ; then
  gem install fir-cli --no-ri --no-rdoc >> $log_file 2>&1
fi
echo "==> done..."


echo -e "\n#################################"
echo    "### Installation is complete! ###"
echo -e "#################################\n"

echo -e "\n !!! logout and back in to access Ruby !!!\n"


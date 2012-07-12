#!/bin/bash
# Install Dev System

INSTALL_HOME="${HOME}/develop"
LOG_FILE="${INSTALL_HOME}/install.log"
ENABLE_COLOR=true

# Package manager, with default flags
PM="aptitude -y"
RUBY_GEM_SRC="rubygems-1.8.11"
RUBY_GEM_SITE="http://production.cf.rubygems.org/rubygems/"

#########################################################
#
#    Utility Functions
#
#########################################################

puts()
{
  local date_string=`date +'%Y-%m-%d %H:%M:%S'`
  echo -e "[${date_string}] $1" |tee -a $LOG_FILE 2>&1
}

warn()
{
  local message="[NOTE] $1"
  if [ $ENABLE_COLOR ] ; then
    message="\033[32m${message}\033[37m"
  fi
  local date_string=`date +'%Y-%m-%d %H:%M:%S'`
  echo -e "[${date_string}] ${message}" |tee -a $LOG_FILE 2>&1
}

error()
{
  local message="[ERROR] $1"
  if [ $ENABLE_COLOR ] ; then
    message="\033[31m${message}\033[37m"
  fi
  local date_string=`date +'%Y-%m-%d %H:%M:%S'`
  echo -e "[${date_string}] ${message}" |tee -a $LOG_FILE 2>&1
  exit 1
}

exit_if_failed()
{
  if [ $? -eq 0 ] ; then
    puts "success..."
  else
    error "failed..."
  fi
}

control_c()
{
  error "Existing!!\n\n"
}


update_packages_list()
{
  warn "=> updating $PM ..."
  $PM update -q | tee -a $LOG_FILE 2>&1
}


install_pkg() {
  local PKG=$1
  puts "=> checking $PKG ..."
  if dpkg -s $PKG > /dev/null 2>&1 ; then
    warn "package $PKG found"
  else
    puts "installing $PKG"
    $PM install $PKG -q | tee -a $LOG_FILE 2>&1
    if dpkg -s $PKG > /dev/null ; then
      warn "$PKG installed"
    else
      error "$PKG install failed!\nSee $LOG_FILE for details.."
    fi
  fi
}

upgrade_pkg() {
  local PKG=$1
  if dpkg -s $PKG > /dev/null 2>&1 ; then
    puts "=> upgrading $PKG ..."
    $PM reinstall $PKG -q | tee -a $LOG_FILE 2>&1
  else
    puts "=> installing $PKG"
    $PM install $PKG -q | tee -a $LOG_FILE 2>&1
  fi
  
  if dpkg -s $PKG > /dev/null ; then
    warn "$PKG installed"
  else
    error "$PKG install failed!\nSee $LOG_FILE for details.."
  fi
}

install_gem() {
  local GEM=$1
  local SOURCE=$2
  warn "=> checking $GEM ..."
  if gem list $GEM |grep -v grep |grep $GEM > /dev/null ; then
    warn "gem $GEM found"
  else
    puts "installing $GEM"
    gem install $GEM --no-ri --no-rdoc $SOURCE | tee -a $LOG_FILE 2>&1
    if gem list $GEM |grep -v grep |grep $GEM > /dev/null ; then
      puts "$GEM installed"
    else
      error "$GEM install failed!\nSee $LOG_FILE for details\nExiting"
    fi
  fi
}

install_gem_v() {
  local GEM=$1
  local VERSION=$2
  warn "=> checking $GEM ..."
  if gem list $GEM |grep -v grep |grep $GEM > /dev/null ; then
    warn "gem $GEM found"
  else
    puts "installing $GEM" 
    gem install $GEM --version $VERSION --no-ri --no-rdoc | tee -a $LOG_FILE 2>&1
    if gem list $GEM |grep -v grep |grep $GEM > /dev/null ; then
      puts "$GEM installed"
    else
      error "$GEM install failed!\nSee $LOG_FILE for details\nExiting"
    fi
  fi
}

########################################################
#
#    Update Packages and Gems
#
#########################################################

install_default_libraries()
{
  warn "=> Installing Base Libraries "
  local libraries=( curl build-essential zlib1g zlib1g-dev \
    vim openssl bison libcurl4-openssl-dev \
    libreadline6-dev libffi-dev libyaml-dev \
    libssl-dev libc6-dev libxml2-dev libxslt1-dev git autoconf \
    gcc bison flex libglib2.0-dev libpcap-dev unzip \
    python-software-properties libpcre3-dev \
    apt-show-versions sysstat reprepro \
    openjdk-6-jre-headless
  )

  for p in "${libraries[@]}"; do  
    install_pkg $p
  done
}

install_ruby()
{
  local PKG="ruby1.9.1-full"
  warn "=> Install Ruby "
  puts "=> checking $PKG ..."
  if which ruby && ruby --version |grep "1.9.2" > /dev/null ; then
    warn "ruby 1.9.2 installed"
  else
    install_pkg $PKG
    update-alternatives --install /usr/local/bin/ruby ruby /usr/bin/ruby1.9.1 100
    update-alternatives --install /usr/local/bin/irb irb /usr/bin/irb1.9.1 100
    update-alternatives --install /usr/local/bin/gem gem /usr/bin/gem1.9.1 100
  fi
  puts `ruby -v`
  puts `gem -v`
  puts `irb -v`

  local BASH_EXTENTION="${HOME}/gem_bin_path.sh"
  local GEM_BIN_PATH=`gem env gemdir`"/bin"
  echo "export PATH=${GEM_BIN_PATH}:\$PATH" > ${BASH_EXTENTION}
  mv ${BASH_EXTENTION} /etc/profile.d/
  . /etc/profile
}

upgrade_gem()
{
  cd ${INSTALL_HOME}
  warn "=> Upgrade RubyGem to ${RUBY_GEM_SRC}"
  puts "=> checking ${RUBY_GEM_SRC} ..."
  if gem -v | grep 1.8 ; then
    puts "package ${RUBY_GEM_SRC} found"
  else
    puts "Upgrading.. ${RUBY_GEM_SRC}"
    wget ${RUBY_GEM_SITE}${RUBY_GEM_SRC}.tgz | tee -a $LOG_FILE 2>&1
    tar xzf ${RUBY_GEM_SRC}.tgz | tee -a $LOG_FILE 2>&1
    cd ${RUBY_GEM_SRC}
    ruby setup.rb | tee -a $LOG_FILE 2>&1
  fi
  cd ${TESTLOUNGE_HOME}
}


#########################################################
#
#    Main
#
#########################################################

install_dev_software() {
	install_default_libraries
	install_gem bundler
	install_gem rails
}

puts "Install Dev Packages"
install_dev_software
puts "Finished Installation"






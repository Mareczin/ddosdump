#!/bin/bash
#===============================================================================================
#   System Required:  CentOS 6,7, Debian, Ubuntu
#   Version: 1.0.1
#   Version type: Public
#	  Extra's:
#   Author: Mareczin <pm@me> <gg:45602375> <TS3:OnlineSpeak.eu Nick: Mareczin>
#   Intro:  github.com/ddosdump
#===============================================================================================

#====CONFIG START==========
#Date
date=$(date +"%d-%B_%H-%M")
#Your MEGA.nz logins,remotepath and checktime (edit in config.cfg)
source config.cfg
email=$mega_username
passwd=$mega_password
remotepath=$remotepath
checktime=$checktime
directory=$directory
#====CONFIG STOP===========
#==========================
#====DO NOT EDIT BELOW=====
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root :("
    echo "Please try running this command again as root user"
    exit 1
fi

#set variables
SYNCREC=`netstat -n -p | grep SYN_REC | sort -u`
NUMBERCONN=`netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n|wc -l`
ESTASH=`netstat -plan|grep :80|awk {'print $5'}|cut -d: -f 1|sort|uniq -c|sort -nk 1`

function printMessage() {
    echo -e "\e[1;37m# $1\033[0m"
}

function ddosdir() {
    mkdir $directory
}

function tcpdump() {
  # just a simple one
  # let's check for udp flooding
  timeout $checktime tcpdump -n udp > $directory/udpflood.$date.log
  # SYN
  timeout $checktime tcpdump -n tcp |grep S > $directory/synflood.$date.log
  # ICMP
  timeout $checktime tcpdump -n icmp > $directory/icmpflood.$date.log
}

function netstats() {
  # TOP IP addresses
  netstat -n|grep :80|cut -c 45-|cut -f 1 -d ':'|sort|uniq -c|sort -nr|more > $directory/topIP.$date.log
  # This will display all active connections to the server
  netstat -an | grep :80 | sort > $directory/activeConn.$date.log
}

function putinmega() {
  # TOP IP addresses
  /usr/bin/megaput $directory/udpflood.$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #udp send
  /usr/bin/megaput $directory/synflood.$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #tcp send
  /usr/bin/megaput $directory/icmpflood.$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #icmp send
  /usr/bin/megaput $directory/activeConn.$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #netstat send
  /usr/bin/megaput $directory/topIP.$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #topip send
}

clear

echo ""
echo "---------------------------------------------------------------"
echo "Ktoś cię ddosuje? Znajdźmy go!"
echo "  Wersja: 1.0.1"
echo "  Wymagania: Brak"
echo "  "
echo "  Niektóre aktualne statystyki:"
echo "  SYN_REC Connections: $SYNREC"
echo "  Total connections: $NUMBERCONN"
echo "  Established Connections: $ESTASH"
echo "---------------------------------------------------------------"
echo ""
echo "Reading config...." >&2
echo "Config for the username: $mega_username" >&2
echo "Config for the password: $mega_password" >&2
printMessage "Zaczynam analizować..."
printMessage "Sprawdzam czy istnieje wymagany folder jeżeli nie utworzę go..."
ddosdir
printMessage "Wykonywanie polecenia: tcpdump (potrwa:ok.30s)..."
tcpdump
printMessage "Wykonywanie polecenia: netstats..."
netstats

#send to mega.nz
putinmega

#ending
printMessage "Wysłano dziennik analiz UDP"
printMessage "Wysłano dziennik analiz TCP"
printMessage "Wysłano dziennik analiz ICMP"
printMessage "Wysłano dziennik analiz NETSTAT"
printMessage "Wysłano dziennik analiz TopIP"
printMessage "Stworzyłem dzienniki analizy w następującym katalogu: $directory"
printMessage "Dodatkowo wysłałem je na twoje konto Mega.nz do katalogu: $remotepath"

echo ""
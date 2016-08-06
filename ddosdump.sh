#!/bin/bash
#===============================================================================================
#   System Required:  CentOS 6,7, Debian, Ubuntu
#   Version type: Public
#	  Extra's:
#   Author: Mareczin <pm@me> <gg:45602375> <TS3:OnlineSpeak.eu Nick: Mareczin>
#   Intro:  github.com/ddosdump
#===============================================================================================

#====CONFIG START==========
#Date
date=$(date +"%d-%B_%H-%M")
#Your MEGA.nz logins
email=email@email.com
passwd=password

#folder on mega, where you want to store you data (vždy musí začínát částí /Root/)
remotepath=/Root/ddosdumpy
#check time
checktime=10s
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
    mkdir /tmp/ddos
}

function tcpdump() {
  # just a simple one
  # let's check for udp flooding
  timeout $checktime tcpdump -n udp > /tmp/ddos/udpflood$date.log
  # SYN
  timeout $checktime tcpdump -n tcp |grep S > /tmp/ddos/synflood$date.log
  # ICMP
  timeout $checktime tcpdump -n icmp > /tmp/ddos/icmpflood$date.log
}

function netstats() {
  # TOP IP addresses
  netstat -n|grep :80|cut -c 45-|cut -f 1 -d ':'|sort|uniq -c|sort -nr|more > /tmp/ddos/topIP$date.log
  # This will display all active connections to the server
  netstat -an | grep :80 | sort > /tmp/ddos/activeConn$date.log
}

function putinmega() {
  # TOP IP addresses
  /usr/bin/megaput /tmp/ddos/udpflood$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #udp send
  /usr/bin/megaput /tmp/ddos/synflood$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #tcp send
  /usr/bin/megaput /tmp/ddos/icmpflood$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #icmp send
  /usr/bin/megaput /tmp/ddos/activeConn$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #netstat send
  /usr/bin/megaput /tmp/ddos/topIP$date.log --reload --username=$email --password=$passwd  --path=$remotepath --disable-previews #topip send
}

clear

echo ""
echo "---------------------------------------------------------------"
echo "Ktoś cię ddosuje? Znajdźmy go!"
echo "  Wersja: 0.1"
echo "  Wymagania: Brak"
echo "  "
echo "  Niektóre aktualne statystyki:"
echo "  SYN_REC Connections: $SYNREC"
echo "  Total connections: $NUMBERCONN"
echo "  Established Connections: $ESTASH"
echo "---------------------------------------------------------------"
echo ""
printMessage "Zaczynam analizować..."
ddosdir
printMessage "Wykonanie polecenia tcpdump ..."
tcpdump
printMessage "Wykonywanie poleceń netstat ..."
netstats
#send to mega.nz
putinmega

printMessage "Wysłano dziennik analiz UDP"
printMessage "Wysłano dziennik analiz TCP"
printMessage "Wysłano dziennik analiz ICMP"
printMessage "Wysłano dziennik analiz NETSTAT"
printMessage "Wysłano dziennik analiz TopIP"
printMessage "Stworzyłem dzienniki analizy w następującym katalogu /tmp/DDoS/"
printMessage "Dodatkowo wysłałem je na twoje konto Mega.nz do katalogu: $remotepath"

echo ""
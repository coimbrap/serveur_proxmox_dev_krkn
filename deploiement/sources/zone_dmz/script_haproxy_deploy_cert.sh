#!/bin/bash
if [ "$(ip a | grep -c "10.0.0.8")" -ge 1 ]; then
  ct_ip=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1 | tail -c2)
  if [ $ct_ip = 6 ]
  	then
  		other_ip=10.0.0.7
  fi
  if [ $ct_ip = 7 ]
  	then
  		other_ip=10.0.0.6
  fi
  rm -f /etc/letsencrypt/live/README
  rm -rf /etc/ssl/letsencrypt/*
  for domain in $(ls /etc/letsencrypt/live); do
      cat /etc/letsencrypt/live/$domain/privkey.pem /etc/letsencrypt/live/$domain/fullchain.pem > /etc/ssl/letsencrypt/$domain.pem
  done
  scp -r /etc/ssl/letsencrypt/* root@$ct_ip:/etc/ssl/letsencrypt
  ssh root@$ct_ip 'service haproxy reload'
  service haproxy reload
fi

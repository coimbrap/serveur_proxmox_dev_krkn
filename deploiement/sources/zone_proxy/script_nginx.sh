#!/bin/bash
if [ "$#" -eq  "0" ]
	then
		echo "Bad Usage !"
else
		ct_ip=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1 | tail -c2)
		if [ $ct_ip = 3 ]
			then
				other_ip=10.0.1.4
		fi
		if [ $ct_ip = 4 ]
			then
				other_ip=10.0.1.3
		fi
    if [ -f "/etc/nginx/sites-available/$1" ]
        then
            ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled
            systemctl restart nginx.service
            scp /etc/nginx/sites-available/$1 root@$other_ip:/etc/nginx/sites-available/
            ssh root@$other_ip "ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled"
            ssh root@$other_ip 'systemctl restart nginx.service'
        else
            echo "Not exist !"
    fi
fi

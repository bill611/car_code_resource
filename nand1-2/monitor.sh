#!/bin/sh

#./network.sh > debug.txt &

./v
reboot
exit
while [ 1 ];do
	./v
	
	ret=$?
	
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ret = $ret"
	
	if [ "$ret" -eq "2" ] ;then
		echo "return code is $ret and ..........start to SoftAP mode!"	
		
		killall wpa_supplicant
		
		./RTL8189/fini.sh

		usleep 100000

		./RTL8189/init.sh
	
		usleep 200000

		./network.sh SoftAP > debug.txt

	elif [ "$ret" -eq "3" ] ;then
		echo "return code is $ret and ..........start to Station mode!"	
		
		if [ -e "network_config.bak" ];then
			cp network_config.bak network_config
			rm -f network_config.bak
			sync
			#reboot
		fi	
		
		killall wpa_supplicant
			
		./RTL8189/fini.sh

		usleep 100000

		./RTL8189/init.sh		

		usleep 200000

		./network.sh Infra > debug.txt			
		
	elif [ "$ret" -eq "4" ] ;then
		echo "return code is $ret and ..........network is not ok!"	
			
			./RTL8189/fini.sh

			usleep 100000

			./RTL8189/init.sh		

			usleep 200000

			./network.sh Infra > debug.txt					
			
	else
		echo "return code is $ret and ............."			
		#./RTL8189/fini.sh
		#usleep 100000
		#./RTL8189/init.sh		
		#usleep 200000			
		#./network.sh Infra > debug.txt	
		
		if [ -e "Update.cab" ] ;then
			echo "updating !!!"
			
			if [ -d update ] ;then
				rm -rf update
			fi
			
			echo "mv Update.cab update.tar.gz"
			mv Update.cab update.tar.gz
			
			echo "tar -xzvf update.tar.gz"
			tar -xzvf update.tar.gz
			
			if [ -d update ] ;then
				rm -f update.tar.gz
				cd update
				
				cp -pR nand1-2/* /mnt/nand1-2
				cp -pR nand1-1/* /mnt/nand1-1
				sync

			else
				echo "update.tar.gz fail"
			fi	
		fi
		
		sleep 20		
	fi
done


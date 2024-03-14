#!/usr/local/bin/bash

logRotate() {
	# Log directory
	LOGDIR="$1"
	#Log files to be handled in that log directory 
	files=("$2")

	# Maximum number of archive logs to keep
	MAXNUM=30


	for LOGFILE in "${files[@]}"
	do 
		## Check if the last log archive exists and delete it.
		if [ -f $LOGDIR/$LOGFILE.$MAXNUM.gz ]; then
		rm $LOGDIR/$LOGFILE.$MAXNUM.gz
		fi
		NUM=$(($MAXNUM - 1))

		## Check the previous log file.
		while [ $NUM -ge 0 ]
		do
			NUM1=$(($NUM + 1))
			if [ -f $LOGDIR/$LOGFILE.$NUM.gz ]; then
			mv $LOGDIR/$LOGFILE.$NUM.gz $LOGDIR/$LOGFILE.$NUM1.gz
			fi

			NUM=$(($NUM - 1))
		done

		# Compress and clear the log file
		if [ -f $LOGDIR/$LOGFILE ]; then
		cat $LOGDIR/$LOGFILE | gzip > $LOGDIR/$LOGFILE.0.gz
		cat /dev/null > $LOGDIR/$LOGFILE
		fi
	done
}



#LOG="/tmp/geneanet"$(date "+%Y%m%d_%H%M%S")".log"
LOG_DIR="/Volumes/DisqueRAM/tmp"
LOG_DIR_GEN="/Volumes/DisqueRAM/geneanet"

LOG_DIR="/tmp/"
LOG_DIR_GEN="//tmp/geneanet"
DIR_CACHE="${HOME}/geneanet_cache"

mkdir -p "${LOG_DIR}" 2>/dev/null 1>&2
logRotate "{$LOG_DIR>}" "geneanet.log"
LOG="${LOG_DIR}/geneanet.log"

test() {
	#./geneanet.sh -v -i -c "/etc/secret/config" -o "/tmp/geneanet/geneanet.ged" -s -u "https://gw.geneanet.org/jpgain_w?lang=fr&pz=homme01&nz=nom01&p=enfant+conjoint+02&n=nom01&type=fiche" | tee $HOME/Downloads/geneanet.log
	$HOME/script/geneanet/geneanet.sh -v -i -c "/etc/secret/config" -o "/tmp/geneanet/geneanet.ged" -s -u "https://gw.geneanet.org/jpgain_w?lang=fr&oc=0&pz=homme01&nz=nom01&p=homme01&n=nom01&type=fiche" | tee /tmp/geneanet.log
	exit 0
}

enfant() {
	url="https://gw.geneanet.org/hirtrey_w?lang=fr&n=canicio&oc=0&p=maria+margarita+luisa&type=tree"
	url="https://gw.geneanet.org/jpgain_w?lang=fr&oc=0&pz=homme01&nz=nom01&p=homme01&n=nom01&type=fiche"
	$HOME/script/geneanet/geneanet.sh -v -i --no-frere -c "/etc/secret/config" -o "/tmp/geneanet/geneanet.ged" -s -u "$url" | tee $LOG
	#./geneanet.sh -v -i --no-parent --no-epoux --no-frere -c "/etc/secret/config" -o "/tmp/geneanet/geneanet.ged" -s -u "https://gw.geneanet.org/jpgain_w?lang=fr&oc=0&pz=homme01&nz=nom01&p=homme01&n=nom01&type=fiche" | tee /tmp/geneanet/geneanet.log
	exit 0
}


go() {
	#./geneanet.sh -i -c -s -u "https://gw.geneanet.org/hirtrey_w?lang=fr&p=maria+margarita+luisa&n=canicio&oc=0&pz=shaz&nz=andreu+genin&type=tree" | tee geneanet.log
	#./geneanet.sh -v -i -c "/etc/secret/config" -s -u "https://gw.geneanet.org/hirtrey_w?lang=fr&p=sylvie&n=andreu&oc=0&pz=shaz&nz=andreu+genin&type=tree" | tee /tmp/geneanet/geneanet.log
	url="https://gw.geneanet.org/hirtrey_w?lang=fr&n=canicio&oc=0&p=maria+margarita+luisa&type=tree"
	# url="https://gw.geneanet.org/anilu1?lang=en&iz=0&p=antonio&n=mira&oc=2"
	#url="https://gw.geneanet.org/hirtrey_w?lang=en&pz=shaz&nz=andreu+genin&p=marie&n=michaud&type=fiche"
   # Pour test date Julien
   # url="https://gw.geneanet.org/hirtrey_w?n=x&oc=0&p=louise&type=fiche"
	if [[ "$1" == "hirtrey" || -z "$1" ]]; then
		url="https://gw.geneanet.org/hirtrey_w?lang=fr&n=canicio&oc=0&p=maria+margarita+luisa&type=tree"
		bash $HOME/script/geneanet/geneanet.sh -v -i --tmp="$HOME/genealogie/geneanet.hirtrey" --cache="$DIR_CACHE" -c "/etc/secret/config" -o "$HOME/genealogie/geneanet_hirtrey.ged" -s -u "$url" "$@" |& tee /tmp/gen-hirtrey.log
	elif [[ "$1" == "charle" ]]; then
		url="https://gw.geneanet.org/drobaldo?lang=fr&n=de+francie&oc=0&p=charles+i&type=tree"
		bash $HOME/script/geneanet/geneanet.sh -v -i --tmp="$HOME/genealogie/geneanet.charles" --cache="$DIR_CACHE" -c "/etc/secret/config" -o "$HOME/genealogie/geneanet_charles.ged" -s -u "$url" "$@" |& tee /tmp/gen-charles.log
	elif [[ "$1" == "sel" ]]; then
		url="https://gw.geneanet.org/drobaldo?lang=en&iz=1&p=antiochos+iii+megas+antiochus+iii&n=ton+selefkidon"
		bash $HOME/script/geneanet/geneanet.sh -v -i --tmp="$HOME/genealogie/geneanet.sel" --cache="$DIR_CACHE" -c "/etc/secret/config" -o "$HOME/genealogie/geneanet_sel.ged" -s -u "$url" "$@" |& tee /tmp/gen-sel.log
	elif [[ "$1" == "pas" ]]; then
		# Lien vers mon arbre https://gw.geneanet.org/hirtrey_w?lang=en&p=jose+pedro+pasqual&n=lopez&oc=0&pz=shaz&nz=andreu+genin&type=tree
		url="https://gw.geneanet.org/lserranomiralle?lang=en&iz=0&p=joseph+pedro+pasqual&n=lopez+canicio"
		bash $HOME/script/geneanet/geneanet.sh -v -i --tmp="$HOME/genealogie/geneanet.lopez" --cache="$DIR_CACHE" -c "/etc/secret/config" -o "$HOME/genealogie/geneanet_lopez.ged" -s -u "$url" "$@" |& tee /tmp/gen-lopez.log
	else
		bash $HOME/script/geneanet/geneanet.sh -v -i --asc=5 --desc=5 --tmp="$HOME/genealogie/geneanet.sel" --cache="$DIR_CACHE" -c "/etc/secret/config" -o "$HOME/genealogie/geneanet_sel.ged" -s "$@" |& tee /tmp/geneanet.log
	fi
	#rm -rf /tmp/geneanet;./geneanet.sh --no-parent --no-frere -i -c -s -u "https://gw.geneanet.org/hirtrey_w?lang=fr&p=maria+margarita+luisa&n=canicio&oc=0&pz=shaz&nz=andreu+genin&type=tree"
}

#enCours=$(ps -ef | grep "geneanet.sh" | grep -v grep | wc -l | bc)
#if [[ "$enCours" -ne 0 ]]; then
#	echo "Un process geneanet.sh est déjà en cours"
#	exit 1
#fi


#enfant
#test
go "$@"

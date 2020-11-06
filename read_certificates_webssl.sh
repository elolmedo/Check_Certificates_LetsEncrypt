#!/bin/bash  

######
##
## check_file_registre_ssl
## Autor: rolmedo
## Fecha: 21-01-19
## Función: Script encargado de leer el fichero de configuración, si encuentra algun domino con Error nos devolverá un Critical
##
######



#Recuperación del IFS Original con tal de no tener problemas con él.
IFS=$'\n'

filename='/tmp/dominios_ssl';

control=""

ESTADO_FINAL="OK";
TEXTO="";

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

if [ -z $filename ];
	then
		echo "Error!! El ficher no existe"
		exit $STATE_UNKNOWN
	else
	
		for nextline in `cat $filename`
		do
			control=`echo $nextline | awk -F" " '{ print $4 }'`
			
			if [ "$control" = "Error" ];
			then
				#echo "$nextline";
				ESTADO_FINAL="KO";
			fi
			
		done
fi


###### RESULTADO FINAL 
if [ "$ESTADO_FINAL" == "KO" ];
then
	echo "Algun dominio no esta sincronizado con el SSL"
	for nextline in `cat $filename`
		do
						
			echo "$nextline";
			
	done
	
	exit $STATE_WARNING;
else
	echo "Todos los dominios sincronizados con el SSL"
	for nextline in `cat $filename`
		do
		
			echo "$nextline";
			
	done
	exit $STATE_OK;
fi
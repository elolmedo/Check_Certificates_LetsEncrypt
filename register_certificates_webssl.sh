#!/bin/bash

######
##
## register_certificates_webssl
## Autor: rolmedo
## Fecha: 21-01-19
## Función: Script de generar un registro de la comprobación del certificado mediante la fecha del certificado y la fecha del certificado en el servidor web.
##
######


		
LISTA=("");


STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=
		
ESTADO_FINAL="OK"
TEXTO=""

fichero_registro='/tmp/dominios_ssl'

#Control Ejecucción
# MODOS: SSLPROPIO, LETSENCRYPT, DEBUG
execute_mode="DEBUG"
control=""

path_ssl_propio="/www/conf/certificados/"

IFS_OLD=$IFS
IFS=$'\n'

### Limpiamos el fichero de comprobación de dominio
echo " " > $fichero_registro

for LINEA in ${LISTA[@]}
	do
		nombrecert=`echo $LINEA| awk -F" " '{ print $1}'`
		subdomain=`echo $LINEA| awk -F" " '{ print $2}'`
		
		if [ "$execute_mode" = "SSLPROPIO" ];
		then
		
			control=`/root/scripts/check_ssl_openssl.sh $nombrecert $subdomain $path_ssl_propio`
		
		elif [ "$execute_mode" = "LETSENCRYPT" ];
		then
			control=`/root/scripts/check_ssl_openssl.sh $nombrecert $subdomain`
			
		elif [ "$execute_mode" = "DEBUG" ];
		then
			control=`/home/raul/workspace/BashSpace/Check_Nagios/check_ssl_openssl.sh $nombrecert $subdomain $path_ssl_propio`	
		else
			echo "[Error] No se ha obtenido nada de la variable execute_mode"
		
		fi

		if [ "$control" = "OK" ];	then
			TEXTO="Dominio: $subdomain - $control"
			echo $TEXTO >> $fichero_registro
			
		else
			TEXTO="Dominio: $subdomain - $control"
			echo $TEXTO >> $fichero_registro
			ESTADO_FINAL="KO";
		fi

	done


#!/bin/bash  -xp

##
#check_ssl_letsencrypt
#Función: 	Comparar las fechas obtenidas mediante curl y openssl para comprobar que son las mismas y el webserver fue reiniciado
#			después de la renovación de certificado.
#Autor: Raúl Olmedo
#Fecha: 14/01/2019
#Versión: 1.0
##




###VARIABLES

######## EXIT CODES NAGIOS
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

#Guardamos el primer nombre del certificado.
#Ha esta variable la atacará un cron diario desde el script /root/script/register_certificates_webssl.sh, el cuál contendrá una lista de 
nombre_certif="$1";

#Guardamos el directorio de los vhost
curl_vhost=$2

#Path de los certificados
#path_certificados=`ls /etc/letsencrypt/live`
path_certificados="";

#Variable para guardar el dominio y utilizarlo para la consulta curl
control_dominio="";

#Variables que utlizamos en la función parse_date
fecha_curl="";
fecha_curl_oph="";

#Variables que utilizamos en la función search_cert_in_directory
fecha_cert="";
fecha_cert_oph="";

#Variables que utilizamos para las fechas obtenidas con openssl
fecha_openssl="";
formato_fecha="";
fecha_openssl_oph="";

#Variable control modo ejecucción
control_modo=""; 

if [ $# -eq 3 ]
then
	control_modo="propio";
	path_certificados=`ls $3`;
	
else
	control_modo="letsencrypt";
	path_certificados=`ls /etc/letsencrypt/live/`
fi

###FIN VARIABLES

##DECLARACION ARRYS
declare -a arrayMeses
declare -a arrayMonth


#Función Control Fechas Curl. Nos ayuda cuando una fecha es respuesta en castellano.
function parse_curl {
	
	mes=$1

	arrayMeses=(ene feb mar abr may jun jul ago sep oct nov dic)
	arrayMonth=(Jan Feb Mar Apr May Jun Jul Ago Sep Oct Nov Dec)

	max_array=${#arrayMeses[@]}

	mesparseado="";

	for index in `seq 0 1 $max_array`
	do
		if [ "${arrayMeses[$index]}" = "$mes" ];
		then
			mesparseado=${arrayMonth[$index]};
			break;			
		else
			mesparseado=$mes
		fi
	done

 	echo $mesparseado

}

#Función que nos ayuda a preparar la fecha que nos llega del curl para que sea del mismo tipo que la fecha
#que obtenemos del comando letsencrypt certificates, además la pasamos a formato epoch para su posterior comparación.
function parse_date {

	curl_vhost=$1
		
	mes_get_data=`curl -vk --silent https://$curl_vhost 2>&1 | grep "expire date" | awk -F" " '{print $4}'`

	mes_parseado=`parse_curl $mes_get_data`

	dia_get_data=`curl -vk --silent https://$curl_vhost 2>&1 | grep "expire date" | awk -F" " '{print $5}'`
	year_get_data=`curl -vk --silent https://$curl_vhost 2>&1 | grep "expire date" | awk -F" " '{print $7}'`
		
	fecha="$dia_get_data $mes_parseado $year_get_data"
	fecha_curl=`date -d"$fecha" +%Y-%m-%d`
	fecha_curl_epoch=`date -d"$fecha_curl" +%s`
			
}

function parse_date_openssl {

	dominio=$1

	if [ $control_modo == "letsencrypt" ];
	then
		mes_fecha_openssl=`openssl x509 -in /etc/letsencrypt/live/$dominio/cert.pem -noout -dates 2>&1 | grep notAfter | awk -F"=" '{ print $2}' | awk -F" " '{ print $1}'`
		dia_fecha_openssl=`openssl x509 -in /etc/letsencrypt/live/$dominio/cert.pem -noout -dates 2>&1 | grep notAfter | awk -F" " '{ print $2}'`
		year_fecha_openssl=`openssl x509 -in /etc/letsencrypt/live/$dominio/cert.pem -noout -dates 2>&1 | grep notAfter | awk -F" " '{ print $4}'`
		
		fecha_openssl="$dia_fecha_openssl $mes_fecha_openssl $year_fecha_openssl";
		formato_fecha=`date -d"$fecha_openssl" +%Y-%m-%d`;
		fecha_openssl_oph=`date -d"$formato_fecha" +%s`;
	elif [ $control_modo == "propio" ];
	then		
		mes_fecha_openssl=`openssl x509 -in /www/conf/certificados/$nombre_certif/$nombre_certif.crt -noout -dates 2>&1 | grep notAfter | awk -F"=" '{ print $2}' | awk -F" " '{ print $1}'`
		dia_fecha_openssl=`openssl x509 -in /www/conf/certificados/$nombre_certif/$nombre_certif.crt -noout -dates 2>&1 | grep notAfter | awk -F" " '{ print $2}'`
		year_fecha_openssl=`openssl x509 -in /www/conf/certificados/$nombre_certif/$nombre_certif.crt -noout -dates 2>&1 | grep notAfter | awk -F" " '{ print $4}'`
		
		fecha_openssl="$dia_fecha_openssl $mes_fecha_openssl $year_fecha_openssl";
		formato_fecha=`date -d"$fecha_openssl" +%Y-%m-%d`;
		fecha_openssl_oph=`date -d"$formato_fecha" +%s`;
	else
		echo "[Error] No se ha obtenido el valor de la variable control_modo"
	fi
				
}

function control_nagios_openssl {
	
	if [ ! -z $fecha_openssl_oph ];
	then
		if [ $fecha_openssl_oph = $fecha_curl_epoch ];
		then
			echo "OK"
		else
			echo "Error";
		fi
	else
		echo "Error";
	fi
}

function search_cert_in_live {
	
	certificados=$1
	#certificados=`ls /www/conf/certificados/`

	
	for cert in $certificados;
	do
	
		if [ "$nombre_certif" = "$cert" ];
		then
			parse_date_openssl $cert
			parse_date $curl_vhost
			control_nagios_openssl 
			
		fi
		
	done
}

search_cert_in_live "$path_certificados"

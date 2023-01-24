#!/bin/bash
#!/usr/bin/env bash

########################################################################
#                                                                      #
#            Instalador, actualizador, eliminador y más de Pterodactyl #
#            Copyright 2023, Eymer A, <eymersamp16@gmail.com>          #
#            Copyright 2022, Malthe K, <me@malthe.cc>                  #        
# https://github.com/eymersamp16/Pterodactyl-Installer-Spanish/blob/main/LICENSE  #
#                                                                      #
#  Este script no está asociado con el panel oficial de Pterodactyl.   #
#  No puedes eliminar esta línea.                                      #
#                                                                      #
########################################################################

### VARIABLES ###

SSL_CONFIRM=""
AGREEWINGS=""
SSLCONFIRM=""
SSLSTATUS=""
SSLSWITCH=""
EMAILSWITCHDOMAINS=""
FQDN=""
UFW=""
AGREE=""
PANELUPDATE=""
LASTNAME=""
FIRSTNAME=""
USERNAME=""
PASSWORD=""
WEBSERVER=""
SSLSTATUSPHPMYADMIN=""
FQDNPHPMYADMIN=""
SSL_CONFIRM_PHPMYADMIN=""
AGREEPHPMYADMIN=""
PHPMYADMINEMAIL=""
DOMAINSWITCH=""
SSLSWTICH=""
IP=""
DOMAIN=""
dist="$(. /etc/os-release && echo "$ID")"

WINGSFQDN=""
WINGSEMAIL=""

### SALIDAS ###

output(){
    echo -e '\e[36m'"$1"'\e[0m';
}

function trap_ctrlc ()
{
    output "Chao!"
    exit 2
}
trap "trap_ctrlc" 2

warning(){
    echo -e '\e[31m'"$1"'\e[0m';
}

### CHEQUES ###

if [[ $EUID -ne 0 ]]; then
    output ""
    output "* ERROR *"
    output ""
    output "* Lo sentimos, pero debe ser root para ejecutar este script."
    output "* La mayoría de las veces esto se puede hacer escribiendo sudo su en su terminal"
    exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
    output ""
    output "* ERROR *"
    output ""
    output "Se requiere cURL para ejecutar este script."
    output "Para continuar, instale cURL en su máquina."
    output ""
    output "Sistemas basados en Debian: apt install curl"
    output "CentOS: yum instalar curl"
    exit 1
fi

### Instalación completa de PHPMyAdmin ###

phpmyadminweb(){
    if  [ "$SSLSTATUSPHPMYADMIN" =  "true" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/phpmyadmin-ssl.conf
        sed -i -e "s@<domain>@${FQDNPHPMYADMIN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf
        systemctl stop nginx || exit || output "Ocurrió un error. NGINX no está instalado." || exit
        certbot certonly --standalone -d $FQDNPHPMYADMIN --staple-ocsp --no-eff-email -m $PHPMYADMINEMAIL --agree-tos || exit || output "Ocurrió un error. Certbot no instalado." || exit
        systemctl start nginx || exit || output "Ocurrió un error. NGINX no está instalado." || exit

        apt install mariadb-server
        PHPMYADMIN_USER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
        mysql -u root -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_USER';" && mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"

        clear
        output ""
        output "* PHPMYADMIN INSTALADO CON ÉXITO *"
        output ""
        output "Gracias por usar el script. Recuerda darle una estrella."
        output "URL: https://$FQDNPHPMYADMIN"
        output ""
        output "Detalles de la cuenta de administrador:"
        output "Nombre de usuario: admin"
        output "Contraseña: $PHPMYADMIN_USER"
        fi
    if  [ "$SSLSTATUSPHPMYADMIN" =  "false" ]; then
        rm -rf /etc/nginx/sites-enabled/default || exit || output "Ocurrió un error. NGINX no está instalado." || exit
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/phpmyadmin.conf || exit || output "Ocurrió un error. cURL no está instalado." || exit
        sed -i -e "s@<domain>@${FQDNPHPMYADMIN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf || exit || output "Ocurrió un error. NGINX no está instalado." || exit
        systemctl restart nginx || exit || output "Ocurrió un error. NGINX no está instalado." || exit

        apt install mariadb-server
        PHPMYADMIN_USER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
        mysql -u root -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_USER';" && mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"

        clear
        output ""
        output "* PHPMYADMIN INSTALADO CON ÉXITO *"
        output ""
        output "Gracias por usar el script. Recuerda darle una estrella."
        output "URL: http://$FQDNPHPMYADMIN"
        output ""
        output "Detalles de la cuenta de administrador:"
        output "Nombre de usuario: admin"
        output "Contraseña: $PHPMYADMIN_USER"
        fi
}

### Instalación de PHPMyAdmin ###

phpmyadmininstall(){
    output ""
    output "Comenzando la instalación de PHPMyAdmin"
    output "Mientras el script está haciendo su trabajo, no cancele la instalación. Esto puede conducir a problemas en su máquina."
    output "En su lugar, deje que el script instale PHPMyAdmin. Luego desinstálelo después si ha cambiado de opinión."
    sleep 1s
    if  [ "$dist" =  "ubuntu" ] || [ "$dist" =  "debian" ]; then
        mkdir /var/www/phpmyadmin && cd /var/www/phpmyadmin || exit || output "Ocurrió un error. No se pudo crear el directorio." || exit
        apt install nginx -y
        apt install certbot -y
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        apt -y install php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip}
        wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.tar.gz
        tar xzf phpMyAdmin-5.2.0-all-languages.tar.gz
        mv /var/www/phpmyadmin/phpMyAdmin-5.2.0-all-languages/* /var/www/phpmyadmin
        chown -R www-data:www-data *
        mkdir config
        chmod o+rw config
        cp config.sample.inc.php config/config.inc.php
        chmod o+w config/config.inc.php
        rm -rf /var/www/phpmyadmin/config
        phpmyadminweb
    fi
}

continueanywayphpmyadmin(){
    output ""
    output "¿Quieres continuar de todos modos?"
    output "(Y/N):"
    read -r CONTINUE_ANYWAY_PHPMYADMIN

    if [[ "$CONTINUE_ANYWAY_PHPMYADMIN" =~ [Yy] ]]; then
        phpmyadmininstall
    fi
    if [[ "$CONTINUE_ANYWAY_PHPMYADMIN" =~ [Nn] ]]; then
        exit 1
    fi
}

fqdnphpmyadmin(){
    output ""
    output "* URL PHPMYADMIN * "
    output ""
    output "Ingrese su FQDN o IP"
    output "Asegúrese de que su FQDN apunte a su IP con un registro A. De lo contrario, el script no podrá proporcionar la página web."
    read -r FQDNPHPMYADMIN
    [ -z "$FQDNPHPMYADMIN" ] && output "FQDN no puede estar vacío."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${FQDNPHPMYADMIN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        output ""
        output "Su FQDN no se resuelve en la IP del servidor actual."
        output "Apunte la IP de su servidor a su FQDN."
        continueanywayphpmyadmin
    else
        output "Su FQDN está apuntado correctamente. Continuo."
        phpmyadmininstall
    fi
}

phpmyadminemailsslyes(){
    output ""
    output "* CORREO *"
    output ""
    warning "Leer:"
    output "El script ahora le pide su correo electrónico. Se compartirá con Lets Encrypt para completar el SSL."
    output "Si no está de acuerdo, detenga el guión."
    warning ""
    output "Por favor introduzca su correo electrónico"
    read -r PHPMYADMINEMAIL
    fqdnphpmyadmin
}

phpmyadminssl(){
    output ""
    output "* SSL * "
    output ""
    output "¿Quieres usar SSL para PHPMyAdmin? Esto requiere un dominio."
    output "(Y/N):"
    read -r SSL_CONFIRM_PHPMYADMIN

    if [[ "$SSL_CONFIRM_PHPMYADMIN" =~ [Yy] ]]; then
        SSLSTATUSPHPMYADMIN=true
        phpmyadminemailsslyes
        fi
    if [[ "$SSL_CONFIRM_PHPMYADMIN" =~ [Nn] ]]; then
        fqdnphpmyadmin
        SSLSTATUSPHPMYADMIN=false
        fi
}


startphpmyadmin(){
    output ""
    output "* CONVENIO *"
    output ""
    output "El script instalará PHPMYAdmin con el servidor web NGINX."
    output "¿Quieres continuar?"
    output "(Y/N):"
    read -r AGREEPHPMYADMIN

    if [[ "$AGREEPHPMYADMIN" =~ [Yy] ]]; then
        phpmyadminssl
    fi
}

### Terminar la instalación del panel ###

finish(){
    clear
    warning ""
    warning "* PANEL INSTALADO CON ÉXITO *"
    warning ""
    warning "Gracias por usar el script. Recuerda darle una estrella."
    warning "El guión ha terminado."
    warning "https://$FQDN o http://$FQDN para ir a su Panel."
    warning ""
    warning "¡Espero que disfrutes de tu nuevo panel!"
    warning "Su información de inicio de sesión para su nuevo Panel:"
    warning ""
    warning "Correo electrónico: $EMAIL"
    warning "Nombre de usuario: $USERNAME"
    warning "Primer nombre: $FIRSTNAME"
    warning "Apellido: $LASTNAME"
    warning "Contraseña: $USERPASSWORD"
    warning ""
    warning "No es necesario que copie la contraseña aquí."
    warning "Esta contraseña también se puede ver en /var/www/pterodactyl/.env"
    warning "No utilizará esta contraseña en su uso diario,"
    warning "este script ya lo configuró para usted."
    warning ""
    warning "Contraseña de la base de datos: $DBPASSWORD"
    warning ""
    warning "Host de base de datos para nodos. Si un servidor en su panel necesita una base de datos,"
    warning "se puede crear fácilmente a través de un host de base de datos"
    warning ""
    warning "Host: 127.0.0.1"
    warning "User: pterodactyluser"
    warning "Password: $DBPASSWORDHOST"
    warning ""
    warning "Si desea crear bases de datos en su Panel,"
    warning "tendrá que insertar esta información en"
    warning "Su panel de administración luego bases de datos -> Crear nuevo"
    warning ""
    warning "cortafuegos:"
    warning "Es posible que el Panel no se cargue si los puertos 80 y 433 no están abiertos."
    warning "Verifique su firewall o vuelva a ejecutar este script"
    warning "y seleccione Configuración de cortafuegos."
}

start(){
    output ""
    output "* CONVENIO *"
    output ""
    output "El script instalará Pterodactyl Panel, se le pedirán varias cosas antes de la instalación."
    output "¿Estás de acuerdo con esto?"
    output "(Y/N):"
    read -r AGREE

    if [[ "$AGREE" =~ [Yy] ]]; then
        AGREE=yes
        web
    fi
}

### ALAS ###

startwings(){
    output ""
    output "* CONVENIO *"
    output ""
    output "El script instalará Pterodactyl Wings."
    output "¿Quieres continuar?"
    output "(Y/N):"
    read -r AGREEWINGS

    if [[ "$AGREEWINGS" =~ [Yy] ]]; then
        AGREEWINGS=yes
        wingsfqdn
    fi
}

wingsfqdn(){
    output ""
    output "* FQDN *"
    output ""
    output "¿Le gustaría instalar un certificado SSL para un FQDN?"
    output "(Y/N):"
    read -r WINGSFQDN

    if [[ "$WINGSFQDN" =~ [Yy] ]]; then
        WINGSFQDN=yes
        wingsemail
    fi
    if [[ "$WINGSFQDN" =~ [Nn] ]]; then
        WINGSFQDN=no
        wingsinstall
    fi
}

wingsemail(){
    output ""
    output "* CORREO *"
    output ""
    warning "Leer:"
    output "Para generar su nuevo certificado FQDN para Wings, su dirección de correo electrónico debe compartirse con Let's Encrypt."
    output "Le enviarán un correo electrónico cuando su certificado esté a punto de caducar. Un certificado dura 90 días a la vez y puede renovar sus certificados de forma gratuita y sencilla, incluso con este script."
    output ""
    output "Por lo tanto, ingrese su correo electrónico. Si no tiene ganas de dar su correo electrónico, entonces el script no puede continuar. Presione CTRL + C para salir."
    read -r WINGSEMAIL
    wingsfqdn-ask
}

wingsfqdn-ask(){
    output ""
    output "* Alas FQDN * "
    output ""
    output "Ingrese FQDN para Wings."
    output "Asegúrese de que su FQDN apunte a su IP con un registro A. De lo contrario, el script no podrá proporcionar el servicio."
    read -r FQDNwingsurl
    [ -z "$FQDNwingsurl" ] && output "FQDN no puede estar vacío."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${FQDNwingsurl})
    if [ "${IP}" != "${DOMAIN}" ]; then
        output ""
        output "Su FQDN no se resuelve en la IP del servidor actual."
        output "Apunte la IP de su servidor a su FQDN."
        output ""
        output "Este error puede ser falso positivo. El guión continúa en 10 segundos.."
        sleep 10s
        apt install certbot
        systemctl stop nginx
        certbot certonly --standalone -d $FQDNwingsurl --staple-ocsp --no-eff-email -m $WINGSEMAIL --agree-tos
        systemctl start nginx
        wingsinstall
    else
        output "Su FQDN está apuntado correctamente. Continuo."
        apt install certbot
        systemctl stop nginx
        certbot certonly --standalone -d $FQDNwingsurl --staple-ocsp --no-eff-email -m $WINGSEMAIL --agree-tos
        systemctl start nginx
        wingsinstall
    fi
}

wingsinstall(){
    output "Instalando..."
    if  [ "$dist" =  "ubuntu" ] || [ "$dist" =  "debian" ]; then
        curl -sSL https://get.docker.com/ | CHANNEL=stable bash
        systemctl enable --now docker

        mkdir -p /etc/pterodactyl || exit || output "Ocurrió un error. No se pudo crear el directorio." || exit
        apt-get -y install curl tar unzip
        curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
        curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/wings.service
        chmod u+x /usr/local/bin/wings
        clear
        output ""
        output "* ALAS INSTALADAS CON ÉXITO *"
        output ""
        output "Gracias por usar el script. Recuerda darle una estrella."
        output "Todo lo que necesitas es configurar Wings."
        output "Para hacer esto, cree el nodo en su Panel, luego presione en Configuración,"
        output "presione Generar token, péguelo en su servidor y luego escriba systemctl enable wings --now"
        output ""
    fi
}

### Servidor web ###

webserver(){
    if  [ "$SSLSTATUS" =  "true" ]; then
        command 1> /dev/null
        rm -rf /etc/nginx/sites-enabled/default
        output "Configuring webserver..."
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/pterodactyl-nginx-ssl.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl stop nginx
        certbot certonly --standalone -d $FQDN --staple-ocsp --no-eff-email -m $EMAIL --agree-tos
        systemctl start nginx
        finish
        fi
    if  [ "$SSLSTATUS" =  "false" ]; then
        command 1> /dev/null
        rm -rf /etc/nginx/sites-enabled/default
        output "Configuring webserver..."
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/pterodactyl-nginx.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        finish
        fi
}

### permisos ###

extra(){
    output "Cambio de permisos..."
    if  [ "$dist" =  "ubuntu" ] || [ "$dist" =  "debian" ]; then
        chown -R www-data:www-data /var/www/pterodactyl/*
        curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/pteroq.service
        (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
        sudo systemctl enable --now redis-server
        sudo systemctl enable --now pteroq.service
        webserver
    elif  [ "$dist" =  "fedora" ] ||  [ "$dist" =  "centos" ] || [ "$dist" =  "rhel" ] || [ "$dist" =  "rocky" ] || [ "$dist" = "almalinux" ]; then
        chown -R nginx:nginx /var/www/pterodactyl/*
        curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/pteroq-centos.service
        (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
        sudo systemctl enable --now redis-server
        sudo systemctl enable --now pteroq.service
        webserver
    fi
}

### Confirmación del Panel ###

configuration(){
    output "Configurar el Panel... Puede ser un proceso largo."
    sleep 1s
    [ "$SSLSTATUS" == true ] && appurl="https://$FQDN"
    [ "$SSLSTATUS" == false ] && appurl="http://$FQDN"
    DBPASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    USERPASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    DBPASSWORDHOST=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    mysql -u root -e "CREATE USER 'pterodactyluser'@'127.0.0.1' IDENTIFIED BY '$DBPASSWORDHOST';" && mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'pterodactyluser'@'127.0.0.1' WITH GRANT OPTION;"
    mysql -u root -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DBPASSWORD';" && mysql -u root -e "CREATE DATABASE panel;" &&mysql -u root -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;" && mysql -u root -e "FLUSH PRIVILEGES;"
    php artisan p:environment:setup --author="$EMAIL" --url="$appurl" --timezone="America/New_York" --cache="redis" --session="redis" --queue="redis" --redis-host="localhost" --redis-pass="null" --redis-port="6379" --settings-ui=true
    php artisan p:environment:database --host="127.0.0.1" --port="3306" --database="panel" --username="pterodactyl" --password="$DBPASSWORD"
    output "Migrando base de datos.. Esto puede tomar algo de tiempo."
    php artisan migrate --seed --force
    php artisan p:user:make --email="$EMAIL" --username="$USERNAME" --name-first="$FIRSTNAME" --name-last="$LASTNAME" --password="$USERPASSWORD" --admin=1
    extra
}

composer(){
    output ""
    output "* INSTALACIÓN * "
    output ""
    output "Instalando Composer.. Esto se usa para operar el Panel."
    if  [ "$dist" =  "ubuntu" ] || [ "$dist" =  "debian" ]; then
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        files
    elif  [ "$dist" =  "fedora" ] ||  [ "$dist" =  "centos" ] || [ "$dist" =  "rhel" ] || [ "$dist" =  "rocky" ] || [ "$dist" = "almalinux" ]; then
        files
    fi
}

### Descargando archivos para Pterodactyl ###

files(){
    output "Descargando los archivos necesarios para Pterodactyl.."
    sleep 1s
    mkdir /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    cp .env.example .env
    command composer install --no-dev --optimize-autoloader --no-interaction
    php artisan key:generate --force
    configuration
}

### no he cambiado todavía ###

database(){
    firstname
}

### Instalación de paquetes necesarios para Pterodactyl ###

required(){
    output ""
    output "* INSTALACIÓN * "
    output ""
    output "Instalando paquetes..."
    output "Esto puede tardar un rato."
    output ""
    if  [ "$dist" =  "ubuntu" ]; then
        apt-get update
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        output "Instalación de dependencias"
        sleep 1s
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
        
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
        apt update
        apt-add-repository universe
        apt install certbot python3-certbot-nginx -y
        output "Instalación de PHP, MariaDB y NGINX"
        sleep 1s
        apt -y install php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
        database
    elif  [ "$dist" =  "debian" ]; then
        apt-get update
        apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release
        output "Instalación de dependencias"
        sleep 1s
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
        curl -fsSL  https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
        apt update -y
        
        apt-add-repository universe
        apt install certbot python3-certbot-nginx -y
        output "Instalación de PHP, MariaDB y NGINX"
        sleep 1s
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bas
        apt install -y php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
        database
    fi
}

begin(){
    output ""
    output "* INSTALACIÓN * "
    output ""
    output "¡Comencemos la instalación!"
    output "Continuando en 3 segundos.."
    output 
    sleep 3s
    composer
}

### Usuario administrador de pterodáctilo ###

password(){
    begin
}


username(){
    output ""
    output "Ingrese el nombre de usuario para la cuenta de administrador."
    output "Iniciará sesión con su nombre de usuario o su correo electrónico."
    read -r USERNAME
    password
}


lastname(){
    output ""
    output "Ingrese el apellido para la cuenta de administrador."
    read -r LASTNAME
    username
}

firstname(){
    output ""
    output "* CREACIÓN DE CUENTA * "
    output ""
    output "Para crear una cuenta en el Panel, necesitamos más información."
    output "No necesita escribir el nombre y apellido reales."
    output ""
    output "Ingrese el nombre de la cuenta de administrador."
    read -r FIRSTNAME
    lastname
}

### FQDN ###

continueanyway(){
    output ""
    output "Este error a veces puede ser un falso positivo."
    output "¿Quieres continuar de todos modos?"
    output "(Y/N):"
    read -r CONTINUE_ANYWAY

    if [[ "$CONTINUE_ANYWAY" =~ [Yy] ]]; then
        required
    fi
    if [[ "$CONTINUE_ANYWAY" =~ [Nn] ]]; then
        exit 1
    fi
}

fqdn(){
    output ""
    output "* PANEL URL * "
    output ""
    output "Ingrese su FQDN o IP para su Panel. Accederás al Panel con esto."
    output "Asegúrese de que su FQDN apunte a su IP con un registro A. De lo contrario, el script no podrá proporcionar la página web."
    read -r FQDN
    [ -z "$FQDN" ] && output "FQDN no puede estar vacío."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${FQDN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        output ""
        output "Su FQDN no se resuelve en la IP del servidor actual."
        output "Apunte la IP de su servidor a su FQDN."
        continueanyway
    else
        output "Su FQDN está apuntado correctamente. Continuo."
        required
    fi
}

### SSL ###

ssl(){
    output ""
    output "* SSL * "
    output ""
    output "¿Quieres usar SSL? Requiere un dominio."
    output "SSL cifra todos los datos en comparación con HTTP, que no lo hace. Siempre se recomienda SSL."
    output "Si no tiene un dominio y desea usar una IP para acceder, escriba N, ya que no puede tener SSL en una IP tan fácil."
    output "(Y/N):"
    read -r SSL_CONFIRM

    if [[ "$SSL_CONFIRM" =~ [Yy] ]]; then
        SSLSTATUS=true
        emailsslyes
    fi
    if [[ "$SSL_CONFIRM" =~ [Nn] ]]; then
        emailsslno
        SSLSTATUS=false
    fi
}

### SSL seleccione sí ##

emailsslyes(){
    output ""
    output "* CORREO *"
    output ""
    warning "Leer:"
    output "El script ahora le pide su correo electrónico. Se compartirá con Lets Encrypt para completar el SSL. También se utilizará para configurar el Panel."
    output "Si no está de acuerdo, detenga el guión."
    warning ""
    output "Por favor introduzca su correo electrónico"
    read -r EMAIL
    fqdn
}

### SSL seleccione no ###

emailsslno(){
    output ""
    output "* CORREO *"
    output ""
    warning "Leer:"
    output "El script ahora le pide su correo electrónico. Se utilizará para configurar el Panel."
    output "Si no está de acuerdo, detenga el guión."
    warning ""
    output "Por favor introduzca su correo electrónico"
    read -r EMAIL
    fqdn
}

### Selección de servidor web ###

web(){
    output ""
    output "* SERVIDOR WEB * "
    output ""
    output "¿Qué servidor web le gustaría usar?"
    output "[1] NGINX"
    output ""
    read -r option
    case $option in
        1 ) option=1
            output "Seleccionado: NGINX"
            ssl
            ;;
        * ) output ""
            warning "El script saldrá. Salida inesperada."
            sleep 1s
            options
    esac
}

### Panel de actualización ###

updatepanel(){
    output ""
    output "* PANEL DE ACTUALIZACIÓN *"
    output ""
    output "Utilice los Documentos oficiales en su lugar"
}

confirmupdatepanel(){
    cd /var/www/pterodactyl || exit || output "Directorio de pterodáctilos (/var/www/pterodactyl) no existe." || exit
    php artisan down || exit || output "ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    chmod -R 755 storage/* bootstrap/cache || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    composer install --no-dev --optimize-autoloader -n || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    php artisan view:clear || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    php artisan config:clear || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    php artisan migrate --force || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    chown -R www-data:www-data /var/www/pterodactyl/* || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    php artisan queue:restart || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    php artisan up || exit || output "¡ADVERTENCIA! El script se encontró con un error y lo detuvo por seguridad. El guión no se hace responsable de ningún daño." || exit
    output ""
    output "* ACTUALIZADO EXITOSAMENTE *"
    output ""
    output "El panel de pterodáctilo se ha actualizado correctamente."
}

### Actualizar alas ###

updatewings(){
    if ! [ -x "$(command -v wings)" ]; then
        echo "Se requiere Wings para actualizar ambos."
    fi
    curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
    chmod u+x /usr/local/bin/wings
    systemctl restart wings
    output ""
    output "* ACTUALIZADO EXITOSAMENTE *"
    output ""
    output "Wings se ha actualizado con éxito."
}

### Actualizar Pterodáctilo y Alas ###

updateboth(){
    if ! [ -x "$(command -v wings)" ]; then
        echo "Se requiere Wings para actualizar ambos."
    fi
    cd /var/www/pterodactyl || exit || advertencia "Directorio de pterodáctilos (/var/www/pterodactyl) ¡no existe!"
    php artisan down
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    chmod -R 755 storage/* bootstrap/cache
    composer install --no-dev --optimize-autoloader -n
    chown -R www-data:www-data /var/www/pterodactyl/*
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --force
    php artisan db:seed --force
    php artisan up
    php artisan queue:restart
    curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
    chmod u+x /usr/local/bin/wings
    systemctl restart wings
    output ""
    output "* ACTUALIZADO EXITOSAMENTE *"
    output ""
    output "Pterodactyl Panel and Wings se ha actualizado con éxito."
}

### Panel de desinstalación ###

uninstallpanel(){
    output ""
    output "¿Realmente desea eliminar Pterodactyl Panel? Se eliminarán todos los archivos y configuraciones. NO PUEDE recuperar sus archivos."
    output "(Y/N):"
    read -r UNINSTALLPANEL

    if [[ "$UNINSTALLPANEL" =~ [Yy] ]]; then
        sudo rm -rf /var/www/pterodactyl || exit || advertencia "¡El panel no está instalado!" # Removes panel files
        sudo rm /etc/systemd/system/pteroq.service # Removes pteroq service worker
        sudo unlink /etc/nginx/sites-enabled/pterodactyl.conf # Removes nginx config (if using nginx)
        sudo unlink /etc/apache2/sites-enabled/pterodactyl.conf # Removes Apache config (if using apache)
        sudo rm -rf /var/www/pterodactyl # Removing panel files
        systemctl restart nginx && systemctl restart apache2
        output ""
        output "* PANEL DESINSTALADO CON ÉXITO *"
        output ""
        output "Su panel ha sido eliminado. Ahora le quedan su base de datos y su servidor web."
        output "Si desea eliminar su base de datos, simplemente ingrese a MySQL y escriba DROP DATABASE (nombre de la base de datos);"
        output "El panel de pterodáctilo se ha eliminado correctamente."
    fi
}

### Desinstalar alas ###

uninstallwings(){
    output ""
    output "¿De verdad quieres eliminar Pterodactyl Wings? Se eliminarán todos los servidores y configuraciones del juego. NO PUEDE recuperar sus archivos."
    output "(Y/N):"
    read -r UNINSTALLWINGS

    if [[ "$UNINSTALLWINGS" =~ [Yy] ]]; then
        {
        sudo systemctl stop wings # Stops wings
        sudo rm -rf /var/lib/pterodactyl # Removes game servers and backup files
        sudo rm -rf /etc/pterodactyl  || exit || advertencia "¡Alas de pterodáctilo no instaladas!"
        sudo rm /usr/local/bin/wings || exit || advertencia "¡Las alas no están instaladas!" # Removes wings
        sudo rm /etc/systemd/system/wings.service # Removes wings service file
        } &> /dev/null
        output ""
        output "* ALAS DESINSTALADAS CON ÉXITO *"
        output ""
        output "Se han eliminado las alas."
        output ""
    fi
}

### cortafuegos ###

http(){
    output ""
    output "* CONFIGURACIÓN DEL CORTAFUEGOS * "
    output ""
    output "Se ha aplicado la regla de firewall HTTP y HTTPS."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        apt install ufw -Y
        ufw allow 80
        ufw allow 443
    fi
}

pterodactylports(){
    output ""
    output "* CONFIGURACIÓN DEL CORTAFUEGOS * "
    output ""
    output "Se ha aplicado la regla de firewall de todos los puertos de pterodáctilo."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        apt install ufw -y
        ufw allow 80
        ufw allow 443
        ufw allow 8080
        ufw allow 2022
    fi
}

mainmysql(){
    output ""
    output "* CONFIGURACIÓN DEL CORTAFUEGOS * "
    output ""
    output "Se ha aplicado la regla de firewall de MySQL."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        apt install ufw -y
        ufw alllow 3306
    fi
}

allfirewall(){
    output ""
    output "* CONFIGURACIÓN DEL CORTAFUEGOS * "
    output ""
    output "A todos se les ha aplicado la regla de firewall."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        apt install ufw -y
        ufw allow 80
        ufw allow 443
        ufw allow 8080
        ufw allow 2022
        ufw allow 3306
    fi
}

### Cambiar dominios ###

switch(){
    if  [ "$SSLSWITCH" =  "true" ]; then
        output ""
        output "* CAMBIAR DOMINIOS * "
        output ""
        output "El script ahora está cambiando su Dominio de Pterodactyl. Esto puede demorar un par de segundos para la parte de SSL, ya que se están generando los certificados SSL."
        rm /etc/nginx/sites-enabled/pterodactyl.conf
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/pterodactyl-nginx-ssl.conf || exit || advertencia "¡El panel de pterodáctilo no está instalado!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl stop nginx
        certbot certonly --standalone -d $DOMAINSWITCH --staple-ocsp --no-eff-email -m $EMAILSWITCHDOMAINS --agree-tos || exit || advertencia "Ocurrieron errores."
        systemctl start nginx
        output ""
        output ""
        output "* CAMBIAR DOMINIOS * "
        output ""
        output "Su dominio ha sido cambiado a $DOMAINSWITCH"
        output "Este script no actualiza la URL de su aplicación, puede"
        output "actualizarlo en /var/www/pterodactyl/.env"
        output ""
        output "Si usa certificados de Cloudflare para su panel, lea esto:"
        output "El script usa Lets Encrypt para completar el cambio de su dominio,"
        output "si normalmente usa certificados de Cloudflare,"
        output "puede cambiarlo manualmente en su configuración, que se encuentra en el mismo lugar que antes."
        output ""
        fi
    if  [ "$SSLSWITCH" =  "false" ]; then
        output ""
        output "* CAMBIAR DOMINIOS * "
        output ""
        output "Cambiando su dominio.. ¡Esto no tomará mucho tiempo!"
        rm /etc/nginx/sites-enabled/pterodactyl.conf || exit || output "Ocurrió un error. No se pudo eliminar el archivo." || exit
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/VexterLabs/Panel-Installer/main/configs/pterodactyl-nginx.conf || exit || advertencia "¡El panel de pterodáctilo no está instalado!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        output ""
        output ""
        output "* CAMBIAR DOMINIOS * "
        output ""
        output "Su dominio ha sido cambiado a $DOMAINSWITCH"
        output "Este script no actualiza la URL de su aplicación, puede"
        output "actualizarlo en /var/www/pterodactyl/.env"
        fi
}

switchemail(){
    output ""
    output "* CORREO *"
    output ""
    warning "Leer:"
    output "Para instalar su nuevo certificado de dominio en su Panel, su dirección de correo electrónico debe compartirse con Let's Encrypt."
    output "Le enviarán un correo electrónico cuando su certificado esté a punto de caducar. Un certificado dura 90 días a la vez y puede renovar sus certificados de forma gratuita y sencilla, incluso con este script."
    output ""
    output "Cuando creó su certificado para su panel anteriormente, también le pidieron su dirección de correo electrónico. Es exactamente lo mismo aquí, con su nuevo dominio."
    output "Por lo tanto, ingrese su correo electrónico. Si no tiene ganas de dar su correo electrónico, entonces el script no puede continuar. Presione CTRL + C para salir."
    output ""
    warning "Por favor introduzca su correo electrónico"

    read -r EMAILSWITCHDOMAINS
    switch
}

switchssl(){
    output ""
    output "* CAMBIAR DOMINIOS * "
    output ""
    output "Seleccione el que describe su panel:"
    warning "[1] Tengo un Panel con SSL"
    warning "[2] No tengo un Panel con SSL"
    read -r option
    case $option in
        1 ) option=1
            SSLSWITCH=true
            switchemail
            ;;
        2 ) option=2
            SSLSWITCH=false
            switch
            ;;
        * ) output ""
            output "Por favor ingrese una opción válida."
    esac
}

switchdomains(){
    output ""
    output "* CAMBIAR DOMINIOS * "
    output ""
    output "Ingrese el dominio (panel.mydomain.ltd) al que desea cambiar."
    read -r DOMAINSWITCH
    switchssl
}

### Renueva certificados ###

rewnewcertificates(){
    {
    sudo certbot renew
    } &> /dev/null
    output ""
    output "* RENOVAR CERTIFICADOS * "
    output ""
    output "Todos los certificados de Let's Encrypt que estaban listos para ser renovados han sido renovados."
}

### Opciones de cortafuegos ###

configureufw(){
    output ""
    output "* CONFIGURACIÓN DEL CORTAFUEGOS * "
    output ""
    output "Configuraciones de cortafuegos disponibles:"
    warning "[1] HTTP y HTTPS"
    warning "[2] Todos los puertos de pterodáctilo"
    warning "[3] MySQL"
    warning "[4] Todos ellos"
    read -r ufw
    case $ufw in
        1 ) ufw=1
            http
            ;;
        2 ) ufw=2
            pterodactlports
            ;;
        3 ) ufw=3
            mainmysql
            ;;
        4 ) ufw=4
            allfirewall
            ;;
        * ) output ""
            output "Por favor ingrese una opción válida."
    esac
}

### Comprobación del sistema operativo ###

oscheck(){
    output "* Comprobando tu sistema operativo..."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        output "* su sistema operativo, $dist, es totalmente compatible. Continuo.."
        output ""
        options
    else
        output "* su sistema operativo, $dist, ¡no es apoyado!"
        output "* Saliendo..."
        exit 1
    fi
}

### Opciones ###

options(){
    output "Seleccione su opción de instalación:"
    warning "[1] Panel de instalación. | Instala la última versión de Pterodactyl Panel"
    warning "[2] Instalar alas. | Instala la última versión de Pterodactyl Wings."
    warning "[3] Instalar PHPMyAdmin. | Instala PHPMyAdmin. (Se instala usando NGINX)"
    warning ""
    warning "[4] Panel de actualización. | Actualiza tu Panel a la última versión. Puede eliminar complementos y temas."
    warning "[5] Actualizar alas. | Actualiza tus Wings a la última versión."
    warning ""
    warning "[6] Desinstalar Wings. | Desinstala tus Wings. Esto también eliminará todos sus servidores de juegos."
    warning "[7] Panel de desinstalación. | Desinstala su Panel. Solo te quedará tu base de datos y tu servidor web."
    warning ""
    warning "[8] Renovar Certificados | Renueva todos los certificados de Lets Encrypt en esta máquina."
    warning "[9] Configurar cortafuegos | Configura UFW a tu gusto."
    warning "[10] Cambiar dominio de pterodáctilo | Cambia tu Dominio de Pterodáctilo."
    read -r option
    case $option in
        1 ) option=1
            start
            ;;
        2 ) option=2
            startwings
            ;;
        3 ) option=3
            startphpmyadmin
            ;;
        4 ) option=4
            updatepanel
            ;;
        5 ) option=5
            updatewings
            ;;
        6 ) option=6
            uninstallwings
            ;;
        7 ) option=7
            uninstallpanel
            ;;
        8 ) option=8
            renewcertificates
            ;;
        9 ) option=9
            configureufw
            ;;
        10 ) option=10
            switchdomains
            ;;
        * ) output ""
            output "Ingrese una opción válida del 1 al 10"
    esac
}

### Comienzo ###

clear
output ""
warning "Instalador de pterodáctilo @ v2.0"
warning "Copyright 2023, Eymer A, <eymersamp16@gmail.com>"
warning "https://github.com/eymersamp16/Pterodactyl-Installer-Spanish"
warning ""
warning "Este script no es responsable de ningún daño. El script ha sido probado varias veces sin problemas."
warning "Support Discord:eymer#3936."
warning "Este script solo funcionará en una instalación nueva. Proceda con precaución si no tiene una instalación nueva"
warning ""
warning "Le invitamos a informar errores o errores sobre este script. Estos se pueden informar en GitHub."
warning "¡Gracias por adelantado!"
warning ""
oscheck

#!/bin/bash
#!/usr/bin/env bash

########################################################################
#                                                                      #
#            Pterodactyl Installer, Updater, Remover and More          #
#            Copyright 2022, Malthe K, <me@malthe.cc>                  #
#            Copyright 2023, Eymer A, <eymersamp16@gmail.com>          #        
# https://github.com/guldkage/Pterodactyl-Installer/blob/main/LICENSE  #
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

### OUTPUTS ###

output(){
    echo -e '\e[36m'"$1"'\e[0m';
}

function trap_ctrlc ()
{
    output "Bye!"
    exit 2
}
trap "trap_ctrlc" 2

warning(){
    echo -e '\e[31m'"$1"'\e[0m';
}

### CHECKS ###

if [[ $EUID -ne 0 ]]; then
    output ""
    output "* ERROR *"
    output ""
    output "* Sorry, but you need to be root to run this script."
    output "* Most of the time this can be done by typing sudo su in your terminal"
    exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
    output ""
    output "* ERROR *"
    output ""
    output "cURL is required to run this script."
    output "To proceed, please install cURL on your machine."
    output ""
    output "Debian based systems: apt install curl"
    output "CentOS: yum install curl"
    exit 1
fi

### PHPMyAdmin Install Complete ###

phpmyadminweb(){
    if  [ "$SSLSTATUSPHPMYADMIN" =  "true" ]; then
        rm -rf /etc/nginx/sites-enabled/default
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/phpmyadmin-ssl.conf
        sed -i -e "s@<domain>@${FQDNPHPMYADMIN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf
        systemctl stop nginx || exit || output "An error occurred. NGINX is not installed." || exit
        certbot certonly --standalone -d $FQDNPHPMYADMIN --staple-ocsp --no-eff-email -m $PHPMYADMINEMAIL --agree-tos || exit || output "An error occurred. Certbot not installed." || exit
        systemctl start nginx || exit || output "An error occurred. NGINX is not installed." || exit

        apt install mariadb-server
        PHPMYADMIN_USER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
        mysql -u root -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_USER';" && mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"

        clear
        output ""
        output "* PHPMYADMIN SUCCESSFULLY INSTALLED *"
        output ""
        output "Thank you for using the script. Remember to give it a star."
        output "URL: https://$FQDNPHPMYADMIN"
        output ""
        output "Details for admin account:"
        output "Username: admin"
        output "Password: $PHPMYADMIN_USER"
        fi
    if  [ "$SSLSTATUSPHPMYADMIN" =  "false" ]; then
        rm -rf /etc/nginx/sites-enabled/default || exit || output "An error occurred. NGINX is not installed." || exit
        curl -o /etc/nginx/sites-enabled/phpmyadmin.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/phpmyadmin.conf || exit || output "An error occurred. cURL is not installed." || exit
        sed -i -e "s@<domain>@${FQDNPHPMYADMIN}@g" /etc/nginx/sites-enabled/phpmyadmin.conf || exit || output "An error occurred. NGINX is not installed." || exit
        systemctl restart nginx || exit || output "An error occurred. NGINX is not installed." || exit

        apt install mariadb-server
        PHPMYADMIN_USER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
        mysql -u root -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_USER';" && mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"

        clear
        output ""
        output "* PHPMYADMIN SUCCESSFULLY INSTALLED *"
        output ""
        output "Thank you for using the script. Remember to give it a star."
        output "URL: http://$FQDNPHPMYADMIN"
        output ""
        output "Details for admin account:"
        output "Username: admin"
        output "Password: $PHPMYADMIN_USER"
        fi
}

### PHPMyAdmin Install ###

phpmyadmininstall(){
    output ""
    output "Starting the installation of PHPMyAdmin"
    output "While the script is doing its work, please do not abort the installation. This can lead to issues on your machine."
    output "Instead, let the script install PHPMyAdmin. Then uninstall it after if you have changed your mind."
    sleep 1s
    if  [ "$dist" =  "ubuntu" ] || [ "$dist" =  "debian" ]; then
        mkdir /var/www/phpmyadmin && cd /var/www/phpmyadmin || exit || output "An error occurred. Could not create directory." || exit
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
    output "Do you want to continue anyway?"
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
    output "* PHPMYADMIN URL * "
    output ""
    output "Enter your FQDN or IP"
    output "Make sure that your FQDN is pointed to your IP with an A record. If not the script will not be able to provide the webpage."
    read -r FQDNPHPMYADMIN
    [ -z "$FQDNPHPMYADMIN" ] && output "FQDN can't be empty."
    IP=$(dig +short myip.opendns.com @resolver2.opendns.com -4)
    DOMAIN=$(dig +short ${FQDNPHPMYADMIN})
    if [ "${IP}" != "${DOMAIN}" ]; then
        output ""
        output "Your FQDN does not resolve to the IP of current server."
        output "Please point your servers IP to your FQDN."
        continueanywayphpmyadmin
    else
        output "Your FQDN is pointed correctly. Continuing."
        phpmyadmininstall
    fi
}

phpmyadminemailsslyes(){
    output ""
    output "* EMAIL *"
    output ""
    warning "Read:"
    output "The script now asks for your email. It will be shared with Lets Encrypt to complete the SSL."
    output "If you do not agree, stop the script."
    warning ""
    output "Please enter your email"
    read -r PHPMYADMINEMAIL
    fqdnphpmyadmin
}

phpmyadminssl(){
    output ""
    output "* SSL * "
    output ""
    output "Do you want to use SSL for PHPMyAdmin? This requires a domain."
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
    output "* AGREEMENT *"
    output ""
    output "The script will install PHPMYAdmin with the webserver NGINX."
    output "Do you want to continue?"
    output "(Y/N):"
    read -r AGREEPHPMYADMIN

    if [[ "$AGREEPHPMYADMIN" =~ [Yy] ]]; then
        phpmyadminssl
    fi
}

### Finish Panel Installation ###

finish(){
    clear
    warning ""
    warning "* PANEL SUCCESSFULLY INSTALLED *"
    warning ""
    warning "Thank you for using the script. Remember to give it a star."
    warning "The script has ended."
    warning "https://$FQDN or http://$FQDN to go to your Panel."
    warning ""
    warning "I hope you enjoy your new panel!"
    warning "Your login information for your new Panel:"
    warning ""
    warning "Email: $EMAIL"
    warning "Username: $USERNAME"
    warning "First Name: $FIRSTNAME"
    warning "Last Name: $LASTNAME"
    warning "Password: $USERPASSWORD"
    warning ""
    warning "You do not need to copy the password under here."
    warning "This password can also be seen in /var/www/pterodactyl/.env"
    warning "You will not use this password in your daily use,"
    warning "this script already configured it for you."
    warning ""
    warning "Database password: $DBPASSWORD"
    warning ""
    warning "Database Host for Nodes. If a server on your panel needs a database,"
    warning "it can be easily created through a database host"
    warning ""
    warning "Host: 127.0.0.1"
    warning "User: pterodactyluser"
    warning "Password: $DBPASSWORDHOST"
    warning ""
    warning "If you want to create databases on your Panel,"
    warning "you will need to insert this information into"
    warning "Your Admin Panel then Databases -> Create new"
    warning ""
    warning "Firewall:"
    warning "The Panel may not load if port 80 and 433 is not open."
    warning "Please check your firewall or rerun this script"
    warning "and select Firewall Configuration."
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

### WINGS ###

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
    output "Therefore, enter your email. If you do not feel like giving your email, then the script can not continue. Press CTRL + C to exit."
    read -r WINGSEMAIL
    wingsfqdn-ask
}

wingsfqdn-ask(){
    output ""
    output "* Wings FQDN * "
    output ""
    output "Ingrese FQDN para Wings."
    output "Asegúrese de que su FQDN apunte a su IP con un registro A. De lo contrario, el script no podrá proporcionar el servicio."
    read -r FQDNwingsurl
    [ -z "$FQDNwingsurl" ] && output "FQDN can't be empty."
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
        curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/wings.service
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

### Webserver ###

webserver(){
    if  [ "$SSLSTATUS" =  "true" ]; then
        command 1> /dev/null
        rm -rf /etc/nginx/sites-enabled/default
        output "Configuring webserver..."
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf
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
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf
        sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        finish
        fi
}

### Permissions ###

extra(){
    output "Changing permissions..."
    if  [ "$dist" =  "ubuntu" ] || [ "$dist" =  "debian" ]; then
        chown -R www-data:www-data /var/www/pterodactyl/*
        curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pteroq.service
        (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
        sudo systemctl enable --now redis-server
        sudo systemctl enable --now pteroq.service
        webserver
    elif  [ "$dist" =  "fedora" ] ||  [ "$dist" =  "centos" ] || [ "$dist" =  "rhel" ] || [ "$dist" =  "rocky" ] || [ "$dist" = "almalinux" ]; then
        chown -R nginx:nginx /var/www/pterodactyl/*
        curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pteroq-centos.service
        (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
        sudo systemctl enable --now redis-server
        sudo systemctl enable --now pteroq.service
        webserver
    fi
}

### Confiration of the Panel ###

configuration(){
    output "Setting up the Panel... Can be a long process."
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
    output "Migrating database.. this may take some time."
    php artisan migrate --seed --force
    php artisan p:user:make --email="$EMAIL" --username="$USERNAME" --name-first="$FIRSTNAME" --name-last="$LASTNAME" --password="$USERPASSWORD" --admin=1
    extra
}

composer(){
    output ""
    output "* INSTALLATION * "
    output ""
    output "Installing Composer.. This is used to operate the Panel."
    if  [ "$dist" =  "ubuntu" ] || [ "$dist" =  "debian" ]; then
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        files
    elif  [ "$dist" =  "fedora" ] ||  [ "$dist" =  "centos" ] || [ "$dist" =  "rhel" ] || [ "$dist" =  "rocky" ] || [ "$dist" = "almalinux" ]; then
        files
    fi
}

### Downloading files for Pterodactyl ###

files(){
    output "Downloading required files for Pterodactyl.."
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

### haven't changed yet ###

database(){
    firstname
}

### Installing required Packages for Pterodactyl ###

required(){
    output ""
    output "* INSTALLATION * "
    output ""
    output "Installing packages..."
    output "This may take a while."
    output ""
    if  [ "$dist" =  "ubuntu" ]; then
        apt-get update
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
        output "Installing dependencies"
        sleep 1s
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
        
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
        apt update
        apt-add-repository universe
        apt install certbot python3-certbot-nginx -y
        output "Installing PHP, MariaDB and NGINX"
        sleep 1s
        apt -y install php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
        database
    elif  [ "$dist" =  "debian" ]; then
        apt-get update
        apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release
        output "Installing dependencies"
        sleep 1s
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
        curl -fsSL  https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
        apt update -y
        
        apt-add-repository universe
        apt install certbot python3-certbot-nginx -y
        output "Installing PHP, MariaDB and NGINX"
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
            output "Selected: NGINX"
            ssl
            ;;
        * ) output ""
            warning "Script will exit. Unexpected output."
            sleep 1s
            options
    esac
}

### Update Panel ###

updatepanel(){
    output ""
    output "* UPDATE PANEL *"
    output ""
    output "Please use the official Docs instead"
}

confirmupdatepanel(){
    cd /var/www/pterodactyl || exit || output "Pterodactyl Directory (/var/www/pterodactyl) does not exist." || exit
    php artisan down || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    chmod -R 755 storage/* bootstrap/cache || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    composer install --no-dev --optimize-autoloader -n || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    php artisan view:clear || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    php artisan config:clear || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    php artisan migrate --force || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    chown -R www-data:www-data /var/www/pterodactyl/* || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    php artisan queue:restart || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    php artisan up || exit || output "WARNING! The script ran into an error and stopped the script for security. The script is not responsible for any damage." || exit
    output ""
    output "* SUCCESSFULLY UPDATED *"
    output ""
    output "Pterodactyl Panel has successfully updated."
}

### Update Wings ###

updatewings(){
    if ! [ -x "$(command -v wings)" ]; then
        echo "Wings is required to update both."
    fi
    curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
    chmod u+x /usr/local/bin/wings
    systemctl restart wings
    output ""
    output "* SUCCESSFULLY UPDATED *"
    output ""
    output "Wings has successfully updated."
}

### Update Pterodactyl and Wings ###

updateboth(){
    if ! [ -x "$(command -v wings)" ]; then
        echo "Wings is required to update both."
    fi
    cd /var/www/pterodactyl || exit || warning "Pterodactyl Directory (/var/www/pterodactyl) does not exist!"
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
    output "* SUCCESSFULLY UPDATED *"
    output ""
    output "Pterodactyl Panel and Wings has successfully updated."
}

### Uninstall Panel ###

uninstallpanel(){
    output ""
    output "Do you really want to delete Pterodactyl Panel? All files & configurations will be deleted. You CANNOT get your files back."
    output "(Y/N):"
    read -r UNINSTALLPANEL

    if [[ "$UNINSTALLPANEL" =~ [Yy] ]]; then
        sudo rm -rf /var/www/pterodactyl || exit || warning "Panel is not installed!" # Removes panel files
        sudo rm /etc/systemd/system/pteroq.service # Removes pteroq service worker
        sudo unlink /etc/nginx/sites-enabled/pterodactyl.conf # Removes nginx config (if using nginx)
        sudo unlink /etc/apache2/sites-enabled/pterodactyl.conf # Removes Apache config (if using apache)
        sudo rm -rf /var/www/pterodactyl # Removing panel files
        systemctl restart nginx && systemctl restart apache2
        output ""
        output "* PANEL SUCCESSFULLY UNINSTALLED *"
        output ""
        output "Your panel has been removed. You are now left with your database and web server."
        output "If you want to delete your database, simply go into MySQL and type DROP DATABASE (database name);"
        output "Pterodactyl Panel has successfully been removed."
    fi
}

### Uninstall Wings ###

uninstallwings(){
    output ""
    output "Do you really want to delete Pterodactyl Wings? All game servers & configurations will be deleted. You CANNOT get your files back."
    output "(Y/N):"
    read -r UNINSTALLWINGS

    if [[ "$UNINSTALLWINGS" =~ [Yy] ]]; then
        {
        sudo systemctl stop wings # Stops wings
        sudo rm -rf /var/lib/pterodactyl # Removes game servers and backup files
        sudo rm -rf /etc/pterodactyl  || exit || warning "Pterodactyl Wings not installed!"
        sudo rm /usr/local/bin/wings || exit || warning "Wings is not installed!" # Removes wings
        sudo rm /etc/systemd/system/wings.service # Removes wings service file
        } &> /dev/null
        output ""
        output "* WINGS SUCCESSFULLY UNINSTALLED *"
        output ""
        output "Wings has been removed."
        output ""
    fi
}

### Firewall ###

http(){
    output ""
    output "* FIREWALL CONFIGURATION * "
    output ""
    output "HTTP & HTTPS firewall rule has been applied."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        apt install ufw -Y
        ufw allow 80
        ufw allow 443
    fi
}

pterodactylports(){
    output ""
    output "* FIREWALL CONFIGURATION * "
    output ""
    output "All Pterodactyl Ports firewall rule has been applied."
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
    output "* FIREWALL CONFIGURATION * "
    output ""
    output "MySQL firewall rule has been applied."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        apt install ufw -y
        ufw alllow 3306
    fi
}

allfirewall(){
    output ""
    output "* FIREWALL CONFIGURATION * "
    output ""
    output "All of them firewall rule has been applied."
    if  [ "$dist" =  "ubuntu" ] ||  [ "$dist" =  "debian" ]; then
        apt install ufw -y
        ufw allow 80
        ufw allow 443
        ufw allow 8080
        ufw allow 2022
        ufw allow 3306
    fi
}

### Switch Domains ###

switch(){
    if  [ "$SSLSWITCH" =  "true" ]; then
        output ""
        output "* SWITCH DOMAINS * "
        output ""
        output "The script is now changing your Pterodactyl Domain. This may take a couple seconds for the SSL part, as SSL certificates are being generated."
        rm /etc/nginx/sites-enabled/pterodactyl.conf
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx-ssl.conf || exit || warning "Pterodactyl Panel not installed!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl stop nginx
        certbot certonly --standalone -d $DOMAINSWITCH --staple-ocsp --no-eff-email -m $EMAILSWITCHDOMAINS --agree-tos || exit || warning "Errors accured."
        systemctl start nginx
        output ""
        output ""
        output "* SWITCH DOMAINS * "
        output ""
        output "Your domain has been switched to $DOMAINSWITCH"
        output "This script does not update your APP URL, you can"
        output "update it in /var/www/pterodactyl/.env"
        output ""
        output "If using Cloudflare certifiates for your Panel, please read this:"
        output "The script uses Lets Encrypt to complete the change of your domain,"
        output "if you normally use Cloudflare Certificates,"
        output "you can change it manually in its config which is in the same place as before."
        output ""
        fi
    if  [ "$SSLSWITCH" =  "false" ]; then
        output ""
        output "* SWITCH DOMAINS * "
        output ""
        output "Switching your domain.. This wont take long!"
        rm /etc/nginx/sites-enabled/pterodactyl.conf || exit || output "An error occurred. Could not delete file." || exit
        curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/configs/pterodactyl-nginx.conf || exit || warning "Pterodactyl Panel not installed!"
        sed -i -e "s@<domain>@${DOMAINSWITCH}@g" /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        output ""
        output ""
        output "* SWITCH DOMAINS * "
        output ""
        output "Your domain has been switched to $DOMAINSWITCH"
        output "This script does not update your APP URL, you can"
        output "update it in /var/www/pterodactyl/.env"
        fi
}

switchemail(){
    output ""
    output "* EMAIL *"
    output ""
    warning "Read:"
    output "To install your new domain certificate to your Panel, your email address must be shared with Let's Encrypt."
    output "They will send you an email when your certificate is about to expire. A certificate lasts 90 days at a time and you can renew your certificates for free and easily, even with this script."
    output ""
    output "When you created your certificate for your panel before, they also asked you for your email address. It's the exact same thing here, with your new domain."
    output "Therefore, enter your email. If you do not feel like giving your email, then the script can not continue. Press CTRL + C to exit."
    output ""
    warning "Please enter your email"

    read -r EMAILSWITCHDOMAINS
    switch
}

switchssl(){
    output ""
    output "* SWITCH DOMAINS * "
    output ""
    output "Select the one that describes your panel:"
    warning "[1] I have a Panel with SSL"
    warning "[2] I do not have a Panel with SSL"
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
            output "Please enter a valid option."
    esac
}

switchdomains(){
    output ""
    output "* SWITCH DOMAINS * "
    output ""
    output "Please enter the domain (panel.mydomain.ltd) you want to switch to."
    read -r DOMAINSWITCH
    switchssl
}

### Renews certificates ###

rewnewcertificates(){
    {
    sudo certbot renew
    } &> /dev/null
    output ""
    output "* RENEW CERTIFICATES * "
    output ""
    output "All Let's Encrypt certificates that were ready to be renewed have been renewed."
}

### Firewall options ###

configureufw(){
    output ""
    output "* FIREWALL CONFIGURATION * "
    output ""
    output "Available firewall configurations:"
    warning "[1] HTTP & HTTPS"
    warning "[2] All Pterodactyl Ports"
    warning "[3] MySQL"
    warning "[4] All of them"
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
            output "Please enter a valid option."
    esac
}

### OS Check ###

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

### Options ###

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
            output "Please enter a valid option from 1-10"
    esac
}

### Start ###

clear
output ""
warning "Pterodactyl Installer @ v2.0"
warning "Copyright 2022, Malthe K, <me@malthe.cc>"
warning "Copyright 2023, Eymer A, <eymersamp16@gmail.com>"
warning "https://github.com/guldkage/Pterodactyl-Installer"
warning ""
warning "Este script no es responsable de ningún daño. El script ha sido probado varias veces sin problemas."
warning "Support Discord:eymer#3936."
warning "Este script solo funcionará en una instalación nueva. Proceda con precaución si no tiene una instalación nueva"
warning ""
warning "Le invitamos a informar errores o errores sobre este script. Estos se pueden informar en GitHub."
warning "¡Gracias por adelantado!"
warning ""
oscheck

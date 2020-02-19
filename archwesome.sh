#!/bin/sh

# Zen Installer Framework version 2.00
#
# Written by Jody James
#
#
#Maintained by Josiah Ward(aka spookykidmm)
#
# This program is free software, provided under the GNU General Public License
# as published by the Free Software Foundation. So feel free to copy, distribute,
# or modify it as you wish.
#
# Special Recognition to Carl Duff, as some code was adapted from the Architect Installer
# Special Recognition to 'angeltoast' as some code was adapted from the Feliz Installer
#
#
#Pulling dependencies
sudo pacman -Syy
##sudo pacman -S --noconfirm zenity
sudo pacman -S --noconfirm arch-install-scripts archiso pacman-contrib zenity

#
# Selecting the Drive

man_partition() {
##list=` lsblk -lno NAME,TYPE,SIZE,MOUNTPOINT | grep "disk" `

##zenity --info --height=500 --width=450 --title="$title" --text "Below is a list of the available drives on your system:\n\n$list" 
> .devices.txt
lsblk -lno NAME,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u > .devices.txt
sed -i 's/\<disk\>//g' .devices.txt
devices=` awk '{print "FALSE " $0}' .devices.txt `

#
> .devices1.txt
lsblk -lno NAME,TYPE,SIZE | grep 'disk' | awk '{print "/dev/" $1 " " $3}' | sort -u > .devices1.txt
devices1=` awk '{print "FALSE " $0}' .devices1.txt `
#

dev=$(zenity --list --ok-label="Siguiente" --cancel-label="Atras" --radiolist --height=500 --width=650 --title="$title" --text "Seleccione el disco que desea utilizar para la instalacion." --column Seleccione --column="Discos                 " --column Tamaño $devices1 )

if [ "$?" = "1" ]
then partition
fi

if [ "$dev" = "" ]
then man_partition
fi

# Partitioning
# Allow user to partition using gparted
zenity --question --height=200 --width=450 --ok-label="Deseo particionar" --cancel-label="Ya he particionado" --title="$title" --text "Necesita particionar $dev?\nDe ser asi formatee el disco o la particion si es necesario.\nEl instalador no formateara las particiones despues de esto.\nPuede utilizar particiones separadas para /boot /home y /root, tambien puede elegir entre particion swap o archivo."
if [ "$?" = "0" ]
	then gparted $dev
fi
root_part
}

root_part() {
	# Select root partition
	root_part=$(zenity --list --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text="Seleccione la particion para ROOT\nAdvertencia, la lista muestra todas las particiones disponibles.\nPor favor elige con cuidado." --column 'Seleccione' --column "Particiones                   " --column 'Tamaño' $(sudo fdisk -l $dev | grep dev | grep -v Disk | awk '{print $1 " " $5}' | awk '{ printf " FALSE ""\0"$0"\0" }'))
	#mounting root partition

if [ "$?" = "1" ]
then man_partition
fi

if [ "$root_part" = "" ]
then root_part
fi
> .root_part.txt
touch .root_part.txt    
echo $root_part >> .root_part.txt
swap_partition
}
swap_partition() {
	# Swap partition?
	zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text "\nDesea utilizar una particion swap?                         "
		if [ "$?" = "0" ]
		then swap_part=$(zenity --list  --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text="Seleccione la particion SWAP\nAdvertencia, la lista muestra todas las particiones disponibles.\nPor favor elige con cuidado." --column 'Seleccione' --column "Particiones                   " --column 'Tamaño' $(sudo fdisk -l $dev | grep dev | grep -v Disk | awk '{print $1 " " $5}' | awk '{ printf " FALSE ""\0"$0"\0" }'))

		if [ "$?" = "1" ]
		then root_part
		fi

		if [ "$swap_part" = "" ]
		then swap_partition
		fi
		mkswap $swap_part
		swapon $swap_part
		else
	zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text "Desea crear un archivo swap?. Este proceso puede demorar."
		if [ "$?" = "0" ]
	 	then swapfile="yes"
		ram=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}' | sed 's/\..*//')
		# Find where swap partition stops
		num=4000

		if [ "$ram" -gt "$num" ]
		then swap_space=4096
		else swap_space=$ram
		fi
	
		uefi_swap=$(($swap_space + 513))

		(echo "# Creando archivo swap..."
		touch /mnt/swapfile
		dd if=/dev/zero of=/mnt/swapfile bs=1M count=${swap_space}
		chmod 600 /mnt/swapfile
		mkswap /mnt/swapfile
		swapon /mnt/swapfile) | zenity --progress --title="$title" --text "Creando archivo swap..." --width=450 --pulsate --auto-close --no-cancel
		fi
		fi

boot_partition
}

boot_partition() {
	# Boot Partition?

		zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text "Desea utilizar una particion separada para /boot?"
		if [ "$?" = "0" ]
		then boot_part=$(zenity --list  --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text="Seleccione la particion para BOOT\nAdvertencia, la lista muestra todas las particiones disponibles.\nPor favor elige con cuidado." --column 'Seleccione' --column "Particiones                   " --column 'Tamaño' $(sudo fdisk -l $dev | grep dev | grep -v Disk | awk '{print $1 " " $5}' | awk '{ printf " FALSE ""\0"$0"\0" }'))

		if [ "$?" = "1" ]
		then swap_partition
		fi

		if [ "$boot_part" = "" ]
		then boot_partition
		fi		
			
		mkdir -p /mnt/boot
		mount $boot_part /mnt/boot

		fi

home_partition
}

home_partition() {
	# Home Partition?
		zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text "Desea utilizar una particion separada para /home?"
		if [ "$?" = "0" ]
		then home_part=$(zenity --list  --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text="Seleccione la particion para HOME\nAdvertencia, la lista muestra todas las particiones disponibles.\nPor favor elige con cuidado." --column 'Seleccione' --column "Particiones                   " --column 'Tamaño' $(sudo fdisk -l $dev | grep dev | grep -v Disk | awk '{print $1 " " $5}' | awk '{ printf " FALSE ""\0"$0"\0" }'))
		# mounting home partition
		if [ "$?" = "1" ]
		then swap_partition
		fi

		if [ "$home_part" = "" ]
		then boot_partition
		fi	
		mkdir -p /mnt/home
		mount $home_part /mnt/home
		fi

		configure
}

auto_partition() {
	##list=` lsblk -lno NAME,TYPE,SIZE,MOUNTPOINT | grep "disk" `

	##zenity --info --height=500 --width=450 --title="$title" --text "Below is a list of the available drives on your system:\n\n$list" 
	> .devices.txt
	lsblk -lno NAME,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u > .devices.txt
	sed -i 's/\<disk\>//g' devices.txt
	devices=` awk '{print "FALSE " $0}' .devices.txt `
	#
	> .devices1.txt
	lsblk -lno NAME,TYPE,SIZE | grep 'disk' | awk '{print "/dev/" $1 " " $3}' | sort -u > .devices1.txt
	devices1=` awk '{print "FALSE " $0}' .devices1.txt `
	#
	dev=$(zenity --list --ok-label="Siguiente" --cancel-label="Atras" --radiolist --height=500 --width=650 --title="$title" --text "Seleccione el disco que desea utilizar para la instalacion." --column Seleccione --column="Disco                 " --column Tamaño $devices1 )
	if [ "$?" = "1" ]
	then partition
	fi

	if [ "$dev" = "" ]
	then auto_partition
	fi

	zenity --question --height=120 --ok-label="Siguiente" --cancel-label="Atras" --width=650 --title="$title" --text "\nAdvertencia! Esto borrará todos los datos en $dev\. $dev1 Esta seguro que desea continuar?"
        yn="$?"
	> .root_part.txt
        touch .root_part.txt
        if [ "$SYSTEM" = "BIOS" ]
	then echo ${dev}"1" >> .root_part.txt
	else echo ${dev}"2" >> .root_part.txt
        fi 
	if [ "$yn" = "1" ]
	then partition
	fi

	# Find total amount of RAM
	ram=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}' | sed 's/\..*//')
	# Find where swap partition stops
	num=4000

	if [ "$ram" -gt "$num" ]
		then swap_space=4096
		else swap_space=$ram
	fi
	
	uefi_swap=$(($swap_space + 513))


	#BIOS or UEFI
    if [ "$SYSTEM" = "BIOS" ]
        then
	       (echo "# Formateando disco [BIOS]..."
		echo "25"
	        dd if=/dev/zero of=$dev bs=512 count=1
		echo "# Creando particiones [BIOS]..."
		echo "40"
	        Parted "mklabel msdos"
	        Parted "mkpart primary ext4 1MiB 100%"
	        Parted "set 1 boot on"
	        mkfs.ext4 -F ${dev}1
		echo "# Montando particiones [BIOS]..."
		echo "60"
	        mount ${dev}1 /mnt
		echo "# Creando archivo swap [BIOS]..."
		echo "80"		
		touch /mnt/swapfile
		dd if=/dev/zero of=/mnt/swapfile bs=1M count=${swap_space}
		chmod 600 /mnt/swapfile
		mkswap /mnt/swapfile
		swapon /mnt/swapfile
		echo "99"
		swapfile="yes") | zenity --progress --percentage=0 --title="$title" --width=450 --no-cancel --auto-close


	    else
            	(echo "# Formateando disco [UEFI]..."
		echo "25"
            	dd if=/dev/zero of=$dev bs=512 count=1
		echo "# Creando particiones [UEFI]..."
		echo "40"
            	Parted "mklabel gpt"
            	Parted "mkpart primary fat32 1MiB 513MiB"
		Parted "mkpart primary ext4 513MiB 100%"
		Parted "set 1 boot on"
		mkfs.fat -F32 ${dev}1
		mkfs.ext4 -F ${dev}2
		echo "# Montando particiones [UEFI]..."
		echo "60"
		mount ${dev}2 /mnt
		mkdir -p /mnt/boot
		mount ${dev}1 /mnt/boot
		echo "# Creando archivo swap [UEFI]..."
		echo "80"
		touch /mnt/swapfile
		dd if=/dev/zero of=/mnt/swapfile bs=1M count=${swap_space}
		chmod 600 /mnt/swapfile
		mkswap /mnt/swapfile
		swapon /mnt/swapfile
		echo "99"
		swapfile="yes") | zenity --progress --percentage=0 --title="$title" --width=450 --no-cancel --auto-close
	fi
	configure		
}

partition() {
	ans=$(zenity --list --radiolist --height=500 --width=650 --ok-label="Siguiente" --cancel-label="Salir" --title="$title" --text "¿Desea utilizar el particionamiento automático o desea particionar el disco usted mismo?\nEl Particionamiento automático borrará completamente el disco que seleccione e instalará Arch." --column Seleccione --column Opcion TRUE "Particionado Automatico" FALSE "Particionado Manual")

if [ "$ans" = "" ]
	then exit

fi
	if [ "$ans" = "Particionado Automatico" ]
	then auto_partition
	else
	man_partition
	fi

}

configure() {
# Getting Locale
country=$(zenity --list --radiolist --ok-label="Siguiente" --cancel-label="Atras" --title="$title" --height=500 --width=650 --column Seleccion --column Pais --text="Seleccion el codigo de su pais. Esto sera utilizado para buscar sevidores mas cerca de usted." TRUE TODOS FALSE AU FALSE AT FALSE BD FALSE BY FALSE BE FALSE BA FALSE BR FALSE BG FALSE CA FALSE CL FALSE CN FALSE CO FALSE HR FALSE CZ FALSE DE FALSE DK FALSE EE FALSE ES FALSE FR FALSE GB FALSE HU FALSE IE FALSE IL FALSE IN FALSE IT FALSE JP FALSE KR FALSE KZ FALSE LK FALSE LU FALSE LV FALSE MK FALSE NL FALSE NO FALSE NZ FALSE PT FALSE RO FALSE RS FALSE RU FALSE SU FALSE SG FALSE SK FALSE TR FALSE TW FALSE UA FALSE US FALSE UZ FALSE VN FALSE ZA)

if [ "$?" = "1" ]
then partition
fi
locales
}

locales() {
locales=$(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 | sort | awk '{ printf "FALSE ""\0"$0"\0" }')

locale=$(zenity --list --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text "Seleccione su idioma.\nPor defecto es Ingles Americano 'en_US.UTF-8'." --column Seleccion --column Idioma TRUE en_US.UTF-8 $locales)

if [ "$?" = "1" ]
then configure
fi
keyboard
}

keyboard() {
zenity --question --height=100 --width=450 --ok-label="Si" --cancel-label="No" --title="$title" --text="Desea cambiar el modelo de su teclado? Por defecto es pc105"
mod="$?"

if [ "$mod" = "0" ]
then model=$(zenity --list --radiolist --height=500 --ok-label="Siguiente" --cancel-label="Atras" --width=650 --title="$title" --text="Seleccione el modelo de su teclado" --column Seleccion --column Modelo $(localectl list-x11-keymap-models | awk '{ printf " FALSE ""\0"$0"\0" }'))

if [ "$?" = "1" ]
then locales
fi
if [ "$model" = "" ]
then keyboard
fi
fi
layout
}

layout() {
layout=$(zenity --list --radiolist --height=500 --ok-label="Siguiente" --cancel-label="Atras" --width=650 --title="$title" --text="Seleccione su idioma del teclado, el codigo de su pais" --column Seleccion --column Distribucion $(localectl list-x11-keymap-layouts | awk '{ printf " FALSE ""\0"$0"\0" }'))
if [ "$?" = "1" ]
then keyboard
fi
if [ "$layout" = "" ]
then layout
fi

variant
}

variant() {
zenity --question --height=100 --ok-label="Si" --cancel-label="No" --width=350 --title="$title" --text="Desea cambiar la variante de su teclado?         "
vary="$?"

if [ "$vary" = "0" ]
then variant=$(zenity --list --radiolist --height=500 --ok-label="Siguiente" --cancel-label="Atras" --width=650 --title="$title" --text="Seleccione su variante" --column Seleccion --column Variante $(localectl list-x11-keymap-variants | awk '{ printf " FALSE ""\0"$0"\0" }'))
if [ "$?" = "1" ]
then layout
fi
if [ "$variant" = "" ]
then variant
fi
fi
keymap
}
keymap() {
zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text="Viste tu keymap en alguna de las opciones anteriores?"
map="$?"

if [ "$map" = "1" ]
then keymap=$(zenity --list --radiolist --height=500 --ok-label="Siguiente" --cancel-label="Atras" --width=650 --ok-label="Siguiente" --cancel-label="Atras" --title="$title" --text="Seleccione su keymap" --column Seleccion --column Keymap $(localectl list-keymaps | awk '{ printf " FALSE ""\0"$0"\0" }'))
if [ "$?" = "1" ]
then variant
fi
if [ "$keymap" = "" ]
then keymap
fi

loadkeys $keymap
fi

setxkbmap $layout

if [ "$model" = "0" ] 
then setxkbmap -model $model 
fi

if [ "$vary" = "0" ] 
then setxkbmap -variant $variant
fi
# Getting Timezone
timezone
}
timezone() {
zones=$(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud | sort | awk '{ printf " FALSE ""\0"$0"\0" }')

zone=$(zenity --list --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text "Seleccione la zona de su pais." --column Seleccion --column Zona $zones)
if [ "$?" = "1" ]
then keymap
fi
if [ "$zone" = "" ]
then timezone
fi
subzones
}
subzones() {
subzones=$(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "$zone/" | sed "s/$zone\///g" | sort -ud | sort | awk '{ printf " FALSE ""\0"$0"\0" }')

subzone=$(zenity --list --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text "Seleccione su sub-zona." --column Seleccion --column Sub-Zona $subzones)
if [ "$?" = "1" ]
then timezone
fi
if [ "$subzone" = "" ]
then subzones
fi
clock
}

clock() {
# Getting Clock Preference
clock=$(zenity --list --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --title="$title" --text "Desea utilizar UTC o Local Time\nUTC es recomenado si no tienes dual boot con Windows." --column Seleccion --column Tiempo TRUE utc FALSE localtime)
if [ "$?" = "1" ]
then subzones
fi
hostnamez
}
# Getting hostname, username, root password, and user password
hostnamez() {
hname=$(zenity --entry --title="$title" --width=450 --ok-label="Siguiente" --cancel-label="Atras" --text "Por favor introduzca el hostname para su equipo.\nTodas las letras deben ser minusculas." --entry-text "instalarch")
if [ "$?" = "1" ]
then clock
fi
if [ "$hname" = "" ]
then hostnamez
fi
usernamez
}
usernamez(){
username=$(zenity --entry --title="$title" --width=450 --ok-label="Siguiente" --cancel-label="Atras" --text "Por favor introduzca el nombre de usuario para el nuevo usuario.\nTodo en letras minusculas." --entry-text "username")
if [ "$?" = "1" ]
then hostnamez
fi
if [ "$username" = "" ]
then usernamez
fi
root_password
}

root_password() {
rtpasswd=$(zenity --entry --title="$title" --width=450 --ok-label="Siguiente" --cancel-label="Atras" --text "Introduzca la contraseña para root." --hide-text)
rtpasswd2=$(zenity --entry --title="$title" --width=450 --text "Vuelva a introducirla." --hide-text)
	if [ "$rtpasswd" != "$rtpasswd2" ]
		then zenity --error --height=100 --width=350 --title="$title" --text "Las contraseñas no coinciden, vuelva a intentarlo."
		root_password
	fi
if [ "$?" = "1" ]
then usernamez
fi
if [ "$rtpasswd" = "" ]
then root_password
fi
user_password
}


user_password() {
userpasswd=$(zenity --entry --title="$title" --width=450 --ok-label="Siguiente" --cancel-label="Atras" --text "Introduzca la contraseña para $username." --hide-text)
userpasswd2=$(zenity --entry --title="$title" --width=450 --ok-label="Siguiente" --cancel-label="Atras" --text "Vuelva a introducir la contraseña para $username." --hide-text)
	if [ "$userpasswd" != "$userpasswd2" ]
		then zenity --error --height=100 --width=450 --title="$title" --text "Las contraseñas no coinciden, vuelva a intentarlo."
		user_password
	fi
if [ "$?" = "1" ]
then root_password
fi
if [ "$userpasswd" = "" ]
then user_password
fi
kernel
}

##

kernel() {
kernel=$(zenity --list  --ok-label="Siguiente" --cancel-label="Atras" --radiolist --height=500 --width=650 --title="$title" --text "Hay varios nucleos(kernel) disponibles:\n \n*El mas comun el el kernel linux.\nEste kernel es el más actualizado y proporciona el mejor soporte de hardware. Sin embargo, \npodría haber posibles errores en este núcleo, a pesar de las pruebas.\n \n*El kernel linux-lts esta enfocado mas en la estabilidad.\nSe basa en un núcleo antiguo, por lo que puede carecer de algunas características más nuevas.\n \n*El kernel linux-hardened esta enfocado en la seguridad\nContiene el parche de Grsecurity Patchset y PaX para una maxima seguridad.\n \n*El kernel linux-zen es el resultado de la colaboracion de hackers\npara proveer el mejor kernel posible para uso diario.\n \nSeleccione el kernel que desea instalar." --column "Seleccion" --column "Kernel" TRUE linux FALSE linux-lts FALSE linux-hardened FALSE linux-zen)

if [ "$?" = "1" ]
then user_password
fi
videocont
}
##

videocont() {
videocontroller=$(zenity --list --title="$title" --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --text "Seleccione su tarjeta grafica:" --column "Seleccion" --column "Controlador" --column "Descripcion" TRUE "xf86-video-vesa" "Controlador generico" FALSE "xf86-video-ati" "Controlador AMD ATI / Radeon - opensource" FALSE "xf86-video-amdgpu" "Controlador AMD Radeon (ultimos modelos) - opensource" FALSE "xf86-video-intel" "Graficas Intel - opensource" FALSE "xf86-video-nouveau" "Graficas nvidia - opensource" FALSE "nvidia" "Graficas envidia - propietario" FALSE "nvidia-390xx" "Graficas nvidia-390xx - propietario")
if [ "$?" = "1" ]
then kernel
fi
desktop
}

desktop() {
# Choosing Desktop
desktops=$(zenity --list --height=500 --width=650 --ok-label="Siguiente" --cancel-label="Atras" --title="$title" --radiolist --text "Cual entorno de escritorio desea instalar?" --column Seleccion --column Escritorio --column Descripcion FALSE "awesome" "Awesome WM + Pack Customizado")
if [ "$?" = "1" ]
then videocont
fi
displaymanager
}

displaymanager() {
dm=$(zenity --list --title="$title" --radiolist --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --text "Cual gestor de pantalla desea instalar?" --column "Select" --column "Display Manager" TRUE "sddm" FALSE "lxdm" FALSE "lightdm" FALSE "gdm")
if [ "$?" = "1" ]
then desktop
fi
revengerepo
}

revengerepo() {
zenity --question --title="$title" --ok-label="Si" --cancel-label="No" --height=100 --width=350 --text="Desea agregar el repositorio oficial de Instalarch?     "
rr="$?"
multilib
}

multilib() {
zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text="Desea habilitar los repositorios multilib? Puedes necesitar esto para Steam, Wine, o cualquier otro software 32-bit."
multilib="$?"
packagemanager
}

packagemanager() {
zenity --question --title="$title" --ok-label="Si" --cancel-label="No" --height=100 --width=450 --text="¿Desea instalar un administrador de paquetes gráfico? Esto le permitirá instalar y eliminar aplicaciones sin tener que lidiar con la línea de comando." 
pm="$?"
if [ "$pm" = "0" ] 
then  
pack=$(zenity --list --radiolist --title="$title" --ok-label="Siguiente" --cancel-label="Atras" --height=500 --width=650 --text="Que administrador de paquetes desea instalar?" --column Seleccion --column "Adm de paquetes" --column "Descripcion" FALSE "octopi" "Plasma o libreria qt" FALSE "pamac-aur" "Gnome o libreria gtk") 
if [ "$?" = "1" ]
then multilib
fi
if [ "$pack" = "" ]
then packagemanager
fi
fi

archuserrepo
}

archuserrepo() {
zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text "Desea instalar yay (AUR Herlper)?\nPodras instalar paquetes del repositorio de usuarios."
abs="$?"
bootloader
}


# allowing user to select extra applications
##rank=$(curl -s "https://www.archlinux.org/mirrorlist/?country="$country"&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 10 -)
##echo -e "$rank" > /etc/pacman.d/mirrorlist
##pacman -Syy


# bootloader?
bootloader() {
> .devices.txt
lsblk -lno NAME,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u > .devices.txt
sed -i 's/\<disk\>//g' .devices.txt
devices=` awk '{print "FALSE " $0}' .devices.txt `

> .devices1.txt
lsblk -lno NAME,TYPE,SIZE | grep 'disk' | awk '{print "/dev/" $1 " " $3}' | sort -u > .devices1.txt
devices1=` awk '{print "FALSE " $0}' .devices1.txt `
#

grub=$(zenity --question --height=100 --width=350 --ok-label="Si" --cancel-label="No" --title="$title" --text "Desea instalar un cargador de arranque?\nLa respuesta usualmente es si, a menos que tenga otro arrancador que desee conservar")
grb="$?"
if [ "$grb" = "0" ]
	then grub_device=$(zenity --list --radiolist --height=500 --ok-label="Siguiente" --cancel-label="Atras" --width=650 --title="$title" --text "Seleccione el disco para instalar el cargador de arranque." --column Seleccion --column "Disco        " --column Tamaño $devices1)
probe="$?"
if [ "$?" = "1" ]
then bootloader
fi
if [ "$grub_device" = "" ]
then bootloader
fi

fi
installing
}

# Installation
installing() {
zenity --question --height=150 --width=350 --ok-label="Continuar" --cancel-label="Abortar" --title="$title" --text "El proceso de instalacion esta por iniciar, todoas los paquetes seran descargados desde internet, asi que asegurese de contar con una conexion constante a internet.\nEste proceso puede demorar."

if [ "$?" = "1" ]
	then exit
else 
## (
# sorting pacman mirrors
(
echo "# Buscando los servidores mas rapidos..."
rank=$(curl -s "https://www.archlinux.org/mirrorlist/?country="$country"&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 10 -)
echo -e "$rank" > /etc/pacman.d/mirrorlist
echo -e "$rank" > .mirrors.txt
# updating pacman cache
echo "5"
echo "# Actualizando cache..."
pacman -Syy
echo "10"
arch_chroot "pacman -Syy"
echo "15"
#installing base
echo "# Instalando Base..."
pacstrap /mnt base bash nano vim-minimal vi linux-firmware cryptsetup e2fsprogs findutils gawk inetutils iproute2 jfsutils licenses linux-firmware logrotate lvm2 man-db man-pages mdadm pciutils procps-ng reiserfsprogs sysfsutils xfsprogs usbutils
echo "# Instalando kernel..."
echo "25"
if [ "$kernel" = "linux" ]
	then pacstrap /mnt base base-devel linux
elif [ "$kernel" = "linux-lts" ]
	then pacstrap /mnt base linux-lts base-devel
elif [ "$kernel" = "linux-hardened" ]
	then pacstrap /mnt base linux-hardened base-devel
elif [ "$kernel" = "linux-zen" ]
	then pacstrap /mnt base linux-zen base-devel

fi
echo "30"
) | zenity --progress --percentage=0 --title="$title" --auto-close --width=450 --no-cancel
#generating fstab
(
echo "# Generando tabla de particiones..."
genfstab -p /mnt >> /mnt/etc/fstab
if grep -q "/mnt/swapfile" "/mnt/etc/fstab"; then
sed -i '/swapfile/d' /mnt/etc/fstab
echo "/swapfile		none	swap	defaults	0	0" >> /mnt/etc/fstab
fi
) | zenity --progress --title="$title" --width=450 --no-cancel --pulsate --auto-close
# installing video and audio packages

(
echo "35"
echo "# Instalando complementos..."
pacstrap /mnt  mesa xorg-server xorg-apps xorg-xinit xorg-twm xterm xorg-drivers alsa-utils pulseaudio pulseaudio-alsa xf86-input-synaptics xf86-input-keyboard xf86-input-mouse xf86-input-libinput intel-ucode b43-fwcutter networkmanager nm-connection-editor network-manager-applet polkit-gnome ttf-dejavu gnome-keyring xdg-user-dirs gvfs
echo "40"
# virtualbox
echo "# Instalando escritorio..."
# installing chosen desktop
if [ "$desktops" = "Look at more window managers" ]
then pacstrap /mnt $wm
else pacstrap /mnt $desktops
fi
echo "45"
##
##
##
##
# cups
if [ "$cp" = "0" ]
	then pacstrap /mnt ghostscript gsfonts system-config-printer gtk3-print-backends cups cups-pdf cups-filters
arch_chroot "systemctl enable org.cups.cupsd.service"
fi
##
##
##
##

echo "# Habilitando servicios..."
# enabling network manager
arch_chroot "systemctl enable NetworkManager"
echo "50"
echo "# Actualizando pacman.conf..."
# adding revenge_repo
if [ "$rr" = "0"  ]
then 
echo -e "\n[revenge_repo]" >> /mnt/etc/pacman.conf;echo "SigLevel = Optional TrustAll" >> /mnt/etc/pacman.conf;echo "Server = https://gitlab.com/spookykidmm/revenge_repo/raw/master/x86_64" >> /mnt/etc/pacman.conf;echo -e "Server = https://downloads.sourceforge.net/project/revenge-repo/revenge_repo/x86_64\n" >> /mnt/etc/pacman.conf
echo "# Sincronizando base de datos..."
arch_chroot "pacman -Syy"
fi
echo "55"
# installing pamac-aur
if [ "$pm" = "0" ]

echo "# Instalando gestor de paquetees grafico..."
then echo -e "\t[spooky_aur]" >> /mnt/etc/pacman.conf;echo "SigLevel = Optional TrustAll" >> /mnt/etc/pacman.conf;echo -e "Server = https://raw.github.com/spookykidmm/spooky_aur/master/x86_64\n" >> /mnt/etc/pacman.conf
sudo pacman -Syy 
arch_chroot "pacman -Syy"
arch_chroot "pacman -S --noconfirm $pack"
fi
echo "60"
#multilib
if [ "$multilib" = "0" ]
then
echo "# Habilitando multilib..."
echo -e "\n[multilib]" >> /mnt/etc/pacman.conf;echo -e "Include = /etc/pacman.d/mirrorlist\n" >> /mnt/etc/pacman.conf
fi
echo "65"
# AUR
if [ "$abs" = "0" ]
	then if [ "$pm" = "0" ]
echo "# Instalando AUR Herlper..."
		 then arch_chroot "pacman -Syy"
		 	  arch_chroot "pacman -S --noconfirm yay"
	else echo -e "\n[spooky_aur]" >> /mnt/etc/pacman.conf;echo "SigLevel = Optional TrustAll" >> /mnt/etc/pacman.conf;echo -e "Server = https://raw.github.com/spookykidmm/spooky_aur/master/x86_64\n" >> /mnt/etc/pacman.conf 
    arch_chroot "pacman -Syy"
	arch_chroot "pacman -S --noconfirm yay"
	fi
fi
echo "70"
echo "# Instalando ucode..."
# installing bootloader
proc=$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')
if [ "$proc" = "GenuineIntel" ]
then pacstrap /mnt intel-ucode
elif [ "$proc" = "AuthenticAMD" ]
then arch_chroot "pacman -R --noconfirm intel-ucode"
pacstrap /mnt amd-ucode
fi
echo "75"
if [ "$grb" = "0" ]
	then 
		echo "# Instalando os-prober..."
		pacstrap /mnt os-prober
		echo "78"
		if [ "$SYSTEM" = 'BIOS' ]
		then echo "# Instalando Bootloader (BIOS)..."
		pacstrap /mnt grub
		arch_chroot "grub-install --target=i386-pc $grub_device"
		arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
		else
		echo "# Instalando Bootloader (UEFI)..."

		if [ "$ans" = "Particionado Automatico" ]
			then root_part=${dev}2
		fi

		[[ $(echo $root_part | grep "/dev/mapper/") != "" ]] && bl_root=$root_part \
		|| bl_root=$"PARTUUID="$(blkid -s PARTUUID ${root_part} | sed 's/.*=//g' | sed 's/"//g')

		arch_chroot "bootctl --path=/boot install"
		echo -e "default  Arch\ntimeout  10" > /mnt/boot/loader/loader.conf
		[[ -e /mnt/boot/initramfs-linux.img ]] && echo -e "title\tArch Linux\nlinux\t/vmlinuz-linux\ninitrd\t/initramfs-linux.img\noptions\troot=${bl_root} rw" > /mnt/boot/loader/entries/Arch.conf
		[[ -e /mnt/boot/initramfs-linux-lts.img ]] && echo -e "title\tArchLinux LTS\nlinux\t/vmlinuz-linux-lts\ninitrd\t/initramfs-linux-lts.img\noptions\troot=${bl_root} rw" > /mnt/boot/loader/entries/Arch-lts.conf
		[[ -e /mnt/boot/initramfs-linux-hardened.img ]] && echo -e "title\tArch Linux hardened\nlinux\t/vmlinuz-linux-hardened\ninitrd\t/initramfs-linux-hardened.img\noptions\troot=${bl_root} rw" > /mnt/boot/loader/entries/Arch-hardened.conf
		[[ -e /mnt/boot/initramfs-linux-zen.img ]] && echo -e "title\tArch Linux Zen\nlinux\t/vmlinuz-linux-zen\ninitrd\t/initramfs-linux-zen.img\noptions\troot=${bl_root} rw" > /mnt/boot/loader/entries/Arch-zen.conf
		fi
fi
echo "80"
# running mkinit
echo "# Ejecutando mkinitcpio..."
arch_chroot "mkinitcpio -p $kernel"
echo "85"

# installing chosen software
echo "# Installing chosen software packages..."
# Making Variables from Applications Lists

sleep 5

# Installing Selecting Applications


#root password
echo "# Configurando usuario root..."
touch .passwd
echo -e "$rtpasswd\n$rtpasswd2" > .passwd
arch_chroot "passwd root" < .passwd >/dev/null
rm .passwd

#adding user
echo "# Configurando nuevo usuario..."
arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash $username"
touch .passwd
echo -e "$userpasswd\n$userpasswd2" > .passwd
arch_chroot "passwd $username" < .passwd >/dev/null
rm .passwd
echo 90
#setting locale
echo "# Generando Locale..."
echo "LANG=\"${locale}\"" > /mnt/etc/locale.conf
echo "${locale} UTF-8" > /mnt/etc/locale.gen
arch_chroot "locale-gen"
export LANG=${locale}
echo "# Configurando mapa del teclado..."
#setting keymap
mkdir -p /mnt/etc/X11/xorg.conf.d/
echo -e 'Section "InputClass"\n\tIdentifier "system-keyboard"\n\tMatchIsKeyboard "on"\n\tOption "XkbLayout" "'$layout'"\n\tOption "XkbModel" "'$model'"\n\tOption "XkbVariant" ",'$variant'"\n\tOption "XkbOptions" "grp:alt_shift_toggle"\nEndSection' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
if [ "$map" = "1" ]
then echo KEYMAP=$keymap >> /mnt/etc/vconsole.conf
fi
echo "93"
#setting timezone
echo "# Configurando zona horaria..."
arch_chroot "rm /etc/localtime"
arch_chroot "ln -s /usr/share/zoneinfo/${zone}/${subzone} /etc/localtime"

#setting hw clock
echo "# Configurando hora del sistema..."
arch_chroot "hwclock --systohc --$clock"

#setting hostname
echo "# Configurando usuario..."
arch_chroot "echo $hname > /etc/hostname"

# setting n permissions
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# selecting shell
shell="zsh"
if [ "$shell" = "zsh" ]
then arch_chroot "pacman -S --noconfirm zsh zsh-syntax-highlighting zsh-completions grml-zsh-config;chsh -s /usr/bin/zsh $username"
elif [ "$shell" = "bash" ]
then arch_chroot "pacman -S --noconfirm bash;chsh -s /bin/bash $username"
elif [ "$shell" = "fish" ]
then arch_chroot "pacman -S --noconfirm fish;chsh -s /usr/bin/fish $username"
fi
echo "95"

# starting desktop manager

echo "# Configurando gestor de pantalla..."

if [ "$dm" = "lightdm" ]
then pacstrap /mnt lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings;arch_chroot "systemctl enable lightdm.service"
else pacstrap /mnt $dm;arch_chroot "systemctl enable $dm.service"
fi
echo "# Desmontando particiones..."

# unmounting partitions
umount -R /mnt
echo "100"
echo "# Instalacion finalizada!"
) | zenity --progress --percentage=0 --title="$title" --ok-label="Reiniciar" --width=450 --no-cancel
reboot
fi
}

# execution
# System Detection
if [[ -d "/sys/firmware/efi/" ]]; then
      SYSTEM="UEFI"
      else
      SYSTEM="BIOS"
fi


# Setting variables
title="Zen Installer Framework 2.00 $SYSTEM"

# Adapted from AIS. An excellent bit of code!
arch_chroot() {
    arch-chroot /mnt /bin/bash -c "${1}"
}

# Adapted from Feliz Installer
Parted() {
	parted --script $dev "$1"
}
# Greeting the user
zenity --question --height=500 --width=450 --title="$title" --ok-label="Siguiente" --cancel-label="Salir" --text "Welcome to the Zen Arch Installer.\n\nNext you will be prompted with a series of questions that will\nguide you through installing Arch Linux.\nYou will be asked if you want to use manual or auto partitioning.\nIf you select auto partitioning the drive that you select will be completely deleted\nand Arch will be installed. If you select manual, you will have the opportunity to partition the disk yourself\nand select which partitons to use for installation.\nClick 'yes' to begin or 'no' to exit."

if [ "$?" = "1" ]
	then exit
fi
partition

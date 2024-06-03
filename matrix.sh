#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   sleep 1
   exit 1
fi


# Function to display ASCII logo
display_logo() {
    cat << "EOF"
	    ┏━┓┏━┓━━━━┓━━━━┓━━━┓━━┓━┓┏━┓
	    ┃┃┗┛┃┃┏━┓┃┏┓┏┓┃┏━┓┃┫┣┛┓┗┛┏┛
	    ┃┏┓┏┓┃┃┃┃┃┛┃┃┗┛┗━┛┃┃┃┃┗┓┏┛┃
	    ┃┃┃┃┃┃┗━┛┃┃┃┃┃┃┏┓┏┛┃┃┃┏┛┗┓┃
	    ┃┃┃┃┃┃┏━┓┃┏┛┗┓┃┃┃┗┓┫┣┓┛┏┓┗┓
	    ┗┛┗┛┗┛┛┃┗┛┗━━┛┃┛┗━┛━━┛━┛┗━┛
EOF
}

# My statics
CONFIG_DIRECTORY='/etc/tinc/matrix'
CONFIG_PATH='/etc/tinc/matrix/tinc.conf'
HOST_DIRECTORY='/etc/tinc/matrix/hosts'
SSH_KEY='/root/.ssh/id_rsa'

# just press key to continue
press_key(){
 read -p "	Press Enter to continue..."
}

# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"
    
    # Define ANSI color codes
    local black="\033[30m"
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"
    local magenta="\033[35m"
    local cyan="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    # Select color code
    local color_code
    case $color in
        black) color_code=$black ;;
        red) color_code=$red ;;
        green) color_code=$green ;;
        yellow) color_code=$yellow ;;
        blue) color_code=$blue ;;
        magenta) color_code=$magenta ;;
        cyan) color_code=$cyan ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;  # Default case, no color
    esac
    # Select style code
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;  # Default case, normal text
    esac

    # Print the colored and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}

function show_progress {
	local bar_size=40
	local bar_char_done="#"
	local bar_char_todo="-"
	local bar_percentage_scale=2
	
    current="$1"
    total="$2"

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"

    if [ $total -eq $current ]; then
        echo -e ""
    fi
}

# Function to install unzip if not already installed
install_core() {
    if ! command -v tincd &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            colorize yellow "Matrix-Core is not installed. Installing...\n"
            apt-get update &> /dev/null
            apt-get install -y tinc  &> /dev/null
            colorize green "Matrix-Core installed successfully.\n"
            sleep 1
        else
            colorize red "Error: Unsupported package manager."
            press_key
            exit 1
        fi
    fi
}

install_boxes() {
    if ! command -v boxes &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            colorize yellow "Boxes is not installed. Installing...\n"
            #apt-get update &> /dev/null
            apt-get install -y boxes  &> /dev/null
            colorize green "Boxes installed successfully.\n"
            sleep 1
        else
            colorize red "Error: Unsupported package manager."
            press_key
            exit 1
        fi
    fi
}
install_lolcat() {
    if ! command -v lolcat &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            colorize yellow "Lolcat is not installed. Installing...\n"
            #apt-get update &> /dev/null
            apt-get install -y lolcat  &> /dev/null
            colorize green "Lolcat installed successfully.\n"
            sleep 1
        else
            colorize red "Error: Unsupported package manager."
            press_key
            exit 1
        fi
    fi
}
install_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            colorize yellow "sshpass is not installed. Installing...\n"
            #apt-get update &> /dev/null
            apt-get install -y sshpass  &> /dev/null
            colorize green "sshpass installed successfully.\n"
            sleep 1
        else
            colorize red "Error: Unsupported package manager."
            press_key
            exit 1
        fi
    fi
}
install_bc() {
    if ! command -v bc &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            colorize yellow "bc is not installed. Installing...\n"
            #apt-get update &> /dev/null
            apt-get install -y bc  &> /dev/null
            colorize green "bc installed successfully.\n"
            sleep 1
        else
            colorize red "Error: Unsupported package manager."
            press_key
            exit 1
        fi
    fi
}

#Install required packages
install_core
install_lolcat
install_boxes
install_sshpass
install_bc


#_________________________________________Configurating Main Node ___________________________________
configure_main_node(){
	clear
	colorize reset "		\033[1mMain Node Configuration\033[0m" bold | boxes -d ada-box | lolcat
	echo ''
	expert=false
	
	colorize green "	What do you prefer?\n" bold
	colorize yellow "	[1] Simple Mode?"
	colorize yellow "	[2] Expert Mode?" 
    echo -n "	[-] Enter your choice [1 or 2]: " | lolcat
    read -p  '' choice 
    echo ''
    
    if [[ $choice == "2" ]]; then
    	expert=true
	fi
	 if [[ $choice != "2" && $choice != "1" ]]; then
    	colorize yellow "	Easy Mode by default...\n" bold
	fi
	
	# Host Generator ______________________
	if [[ ! -d $HOST_DIRECTORY ]]; then
		mkdir -p $HOST_DIRECTORY
	fi
	
	# Node Name / Consider it as a static value ______________________
	node_name="main"
	colorize magenta "	[*] Node name: $node_name"
	echo ''
	
	# Device Name, Static value ______________________
 	device='/dev/net/tun' #No need to change it
 	
 	# Address Family / EXPERT value______________________
 	if $expert; then
  		read -p "	[-] Address family (ipv4|ipv6|any): " add_family
		if [ -z "$add_family" ]; then
    		add_family='any'
		fi
    	echo ''
    else
    	add_family='any'
    fi
    
    # Direct Only  / EXPERT value______________________
    if $expert; then
		read -p "	[-] Direct only (yes/no): " direct_only
		if [ -z "$direct_only" ]; then
    		direct_only='yes'
		fi
		echo ''
	else
		direct_only='yes'
	fi
    
    # Server IP / Get it from hostname______________________
    SERVER_IP=$(hostname -I | awk '{print $1}') #Easy !
    colorize magenta "	[*] Main Node IP Address: ${SERVER_IP}"
    echo ''
    
    # Subnet / Simple value  ______________________
    read -p "	[*] Subnet (172.16.1.1): " subnet
    if [ -z "$subnet" ]; then
    	colorize red "	Please enter a valid subnet.\n"
    	press_key
    	return 1
    else
       	subnet="${subnet}/32"
    fi
    echo ''	
    
    # Port / Simple value ______________________
    read -p "	[-] Port Number (2096): " port
    if [ -z "$port" ]; then
       port="2096"
    fi
    # Validate if the input is a valid port number 
	if ! [[ $port =~ ^[0-9]+$ && $port -ge 22 && $port -le 65535 ]]; then
  		colorize red "	Error: Please enter a valid port number between 22 and 65535.\n"
  		press_key
    	return 1
	fi
	echo ''
    
    
     # Configs file creator 
     show_progress 1 9 | lolcat
     echo "Name = $node_name" > $CONFIG_PATH
     echo "Device = $device" >> $CONFIG_PATH
     echo "AddressFamily = $add_family" >> $CONFIG_PATH
     echo "DirectOnly = $direct_only" >> $CONFIG_PATH
     echo "AutoConnect = yes" >> $CONFIG_PATH
    
     # Host file creator 
     show_progress 2 9 | lolcat
     HOST_FILE="${HOST_DIRECTORY}/${node_name}"
     echo "Address = $SERVER_IP" > $HOST_FILE
     echo "Subnet = $subnet" >> $HOST_FILE
     echo "Port = $port" >> $HOST_FILE
     
     #Generating ssh key
    show_progress 3 9 | lolcat
	if [[ ! -f $SSH_KEY ]]; then
		ssh-keygen -t rsa -f /root/.ssh/id_rsa -N "" -q &> /dev/null
	fi
	
	# Change sshd config
	show_progress 4 9 | lolcat
	sed -i 's/#GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config	&> /dev/null

	# Build RSA Keys
	show_progress 4 9 | lolcat
	tincd -n matrix -K4096 &> /dev/null
	
	# Create route subnet
	show_progress 5 9 | lolcat
    local route_subnet=$(echo $subnet | cut -d'.' -f1-3)
    local route_subnet="${route_subnet}.0/24"

	# Build tinc-up 
	show_progress 6 9 | lolcat
	cat <<EOF > "/etc/tinc/matrix/tinc-up"
#!/bin/bash
/sbin/ip link set \$INTERFACE up
/sbin/ip addr add $subnet dev \$INTERFACE
/sbin/ip route add $route_subnet dev \$INTERFACE
EOF

	# Build tinc-up 
	show_progress 7 9 | lolcat
	cat <<EOF > "/etc/tinc/matrix/tinc-down"
#!/bin/bash
/sbin/ip route del $route_subnet dev \$INTERFACE
/sbin/ip addr del $subnet dev \$INTERFACE
/sbin/ip link set \$INTERFACE down
EOF

	# Executable +x
	chmod +x /etc/tinc/matrix/tinc-{up,down} &> /dev/null

	# Start Servies
	show_progress 8 9 | lolcat
	systemctl enable tinc@matrix &> /dev/null
	systemctl start tinc@matrix &> /dev/null
	
	# Finsish it
	show_progress 9 9 | lolcat
	echo ''
	colorize green "	The main node configuration completed successfully \n" bold
	press_key
}

#_________________________________________Registring New Node ___________________________________
add_new_node(){
	clear
	# _____ Get node info and ssh to it_____
	colorize reset "		\033[1mPrimary Node Server Setup\033[0m" bold | boxes -d ada-box | lolcat 
	echo ''
	
	# Get user/password of node server
	colorize green "	Enter your node username/passowrd:\n" bold
	read -p "	[*] Enter your node IP Address: " host_ip

	
	# Check IPV4 is correct
    local valid_ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    if [[ $host_ip =~ $valid_ip_regex ]]; then
        # Check each octet to ensure it's between 0 and 255
        IFS='.' read -r -a octets <<< "$host_ip"
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                colorize red "	The IPv4 is not valid. aborting... \n" bold
                press_key
                return 1
            fi
        done
    else
        colorize red "	The IPv4 is not valid. aborting... \n" bold 
        press_key
        return 1
    fi
    

	read -p "	[-] Enter your username (root): " username	
	if [ -z "$username" ]; then
    	username="root"
    fi
    
    read -s -p "	[*] Enter your password [Hidden]: " password
    echo ''
    if [ -z $password ]; then
    	colorize red "	You didn't enter your password, aborting...\n" bold
		press_key
		return 1
    fi
	# Check public ssh key
	if [[ ! -f $SSH_KEY ]]; then
		colorize red "	No public key to trasnfer. configure main node first...\n"
		press_key
		return 1
	fi
    
    echo ''
    # Check SSH connectivity 
    colorize yellow "	Connecting to remote node on port 22...\n" bold
    sshpass -p $password ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no $username@$host_ip "whoami" &> /dev/null
    
    
    # Check the exit status of the SSH command
    if [[ $? -eq 0 ]]; then
        colorize green "	Connected to remote node successfully\n" bold
    else
        colorize red "	✖︎Error, wrong username/password\n" bold
        press_key
        return 1
    fi
 
    #Transfer public key
	sshpass -p $password ssh-copy-id -i ~/.ssh/id_rsa.pub $username@$host_ip >/dev/null 2>&1 
  	colorize green "	The public key added to remote node successfully" bold
  	sleep 2

	#_______________________Start Configuration__________________
	clear
	colorize reset "		\033[1mNew Node Registration\033[0m" bold | boxes -d ada-box | lolcat 
	echo ''
	expert=false
	colorize green "	What do you prefer?\n" bold
	colorize yellow "	[1] Simple Mode?"
	colorize yellow "	[2] Expert Mode?" 
    echo -n "	[-] Enter your choice [1 or 2]: " | lolcat
    read -p  '' choice 
    echo ''
    
    if [[ $choice == "2" ]]; then
    	expert=true
	fi
	 if [[ $choice != "2" && $choice != "1" ]]; then
    	colorize yellow "	Easy Mode by default...\n" bold
	fi
	
	# Node Name / simple value __________________________________
	read -p "	[*] Node name (must be unique): " node_name
 	if [ -z "$node_name" ]; then
    	colorize red "	The node name is mandatory.\n"
    	press_key
    	return 1
    fi
 
    if [[ -f "${HOST_DIRECTORY}/${node_name}" ]]; then
    	colorize red "	This node name is duplicate. you can't add it.\n"
    	press_key
   		return 1
    fi
   	
    pattern='^[a-zA-Z0-9_]+$'
	if [[ ! $node_name =~ $pattern ]]; then
    	colorized red "	The name must consist only of a-z, A-Z, 0-9 and underscore.\n"
    	press_key
    	return 1
	fi
	echo ''
	
	# Device Name / Static value by now _________________________
	device='/dev/net/tun'
 	
 	# Address Family / Expert value _______________________________
 	if $expert; then
  		read -p "	[-] Address family (ipv4|ipv6|any): " add_family
  		if [ -z "$add_family" ]; then
    		add_family='any'
    	fi
    	echo ''
    else
    	add_family='any'
    fi 	

    
    # Direct Only / Expert value _______________________________
    if $expert; then
   		read -p "	[-] Direct only (yes/no): " direct_only
   		if [ -z "$direct_only" ]; then
    		direct_only='yes'
    	fi	
    	echo ''	
    else
  		direct_only='yes'
  	fi
    	

    
    # Node IP  / We get it before _______________________________
    colorize normal "	[*] Node IP Address: ${host_ip}"
    echo ''
    
    # Subnet IP  / Simple value _______________________________
    read -p "	[*] Subnet (172.16.1.x): " subnet
    if [ -z "$subnet" ]; then
    	colorize red "	The subnet value is mandatory.\n"
    	press_key
    	return 1
    else
       	subnet="${subnet}/32"
    fi
    echo ''	
    
    # Port Number  / Simple value _______________________________
    read -p "	[-] Port Number (2096): " port
    if [ -z "$port" ]; then
    	port="2096"
    fi
    # Validate if the input is a valid port number 
	if ! [[ $port =~ ^[0-9]+$ && $port -ge 22 && $port -le 65535 ]]; then
  		colorize red "	Error: Please enter a valid port number between 22 and 65535.\n"
  		press_key
    	return 1
	fi
    echo ''
    
    # Create route subnet. may be due a silly code by me
    local route_subnet=$(echo $subnet | cut -d'.' -f1-3)
    local route_subnet="${route_subnet}.0/24" 
    
    # SSH into the remote server and use cat to create files
    colorize yellow "	Connecting to remote server...\n" bold
    sleep 1
    clear
    

#______________________ SSH COMMANDS ____________________

ssh -T $username@$host_ip << EOF
TERM=xterm clear

echo -e "1. Installing Packages..."
apt update &> /dev/null
apt install tinc -y &> /dev/null

echo -e "2. Generating conf file..."
mkdir -p /etc/tinc/matrix/hosts/ &> /dev/null
sudo tee /etc/tinc/matrix/tinc.conf &> /dev/null <<CONFIG
Name = $node_name
Device = $device
DirectOnly = $direct_only
AutoConnect = yes
AddressFamily = $add_family
CONFIG

echo -e "3. Generating host file..."
sudo tee /etc/tinc/matrix/hosts/$node_name &> /dev/null <<NODE
Address = $host_ip
Subnet = $subnet
Port = $port
NODE

echo -e "4. Generating RSA key file..."
yes '' | tincd -n matrix -K4096 &> /dev/null

echo -e "5. Configurating service files..."
sudo tee /etc/tinc/matrix/tinc-up &> /dev/null <<UP
#!/bin/bash
/sbin/ip link set \\\$INTERFACE   up
/sbin/ip addr add $subnet dev \\\$INTERFACE  
/sbin/ip route add $route_subnet dev \\\$INTERFACE  
UP

sudo tee /etc/tinc/matrix/tinc-down &> /dev/null <<DOWN
#!/bin/bash
/sbin/ip route del $route_subnet dev \\\$INTERFACE 
/sbin/ip addr del $subnet dev \\\$INTERFACE  
/sbin/ip link set \\\$INTERFACE   down
DOWN

echo -e "6. Create Matrix service..."
chmod +x /etc/tinc/matrix/tinc-{up,down} &> /dev/null
exit
EOF

#______________________ SSH CLOSED ____________________
	

	#Copy main config to node
	echo -e "7. Exchanging main key to node server ..."
	ssh -T $username@$host_ip sudo mkdir /tmp/ &> /dev/null
	scp  ${HOST_DIRECTORY}/main $username@$host_ip:/tmp/ &> /dev/null
	ssh -T $username@$host_ip sudo mv -v /tmp/main $HOST_DIRECTORY &> /dev/null

	# SSH into the remote server and read the contents of a file into a variable	
	echo -e "8. Exchanging node key to main server ..."
	node_with_key=$(ssh -T $username@$host_ip "cat ${HOST_DIRECTORY}/$node_name")
	echo "$node_with_key" > ${HOST_DIRECTORY}/$node_name 

	#start matrix service on node
	echo -e "9. Start Matrix serivce on the node server..."
	ssh -T $username@$host_ip "systemctl enable --now tinc@matrix" &> /dev/null
	# Maybe service exists before so restart it
	ssh -T $username@$host_ip "systemctl restart tinc@matrix" &> /dev/null
	
	
	# Check if the configuration exists in the file
	echo -e "10. Append ConnectTo values to main node..."
	if ! grep -q "ConnectTo = $node_name" $CONFIG_PATH; then
   		 echo "ConnectTo = $node_name" >> $CONFIG_PATH
	fi
	echo -e "11. Restart Matrix service on main server..."
	systemctl restart tinc@matrix &> /dev/null
	
	echo ''
	colorize green "The remote node configuration completed successfully \n" bold
	press_key
}


#_________________________________________Funcs Related to Status Checker ___________________________________
print_table_header() {
    printf "╔════════════╦══════════════╦════════════════╦════════════════╦════════════════╦════════════╗\033[0m\n" | lolcat -S 10
    printf "\e[36m\033[1m║ %-10s ║ %-12s ║ %-14s ║ %-14s ║ %-14s ║ %-10s ║\033[0m\n" "Node Name" "Local IP" "Public IP" "Local Network" "Public Network" "SSH Status" | lolcat -S 11
    printf "╠════════════╬══════════════╬════════════════╬════════════════╬════════════════╬════════════╬\033[0m\n" | lolcat -S 12
}

# Function to print table row
print_table_row() {
    printf "║ %-10s ║ %-12s ║ %-14s ║ %-32s ║ %-32s ║ %-28s ║\n" "$1" "$2" "$3" "$4" "$5" "$6"
        printf "╠════════════╬══════════════╬════════════════╬════════════════╬════════════════╬════════════╬\033[0m\n" 
}

perform_ping() {
    if ping -c 2 -i 0.2 "$1" &> /dev/null; then
    	colorize green "✔︎Online"
    else
    	colorize red "✖︎Offline"
    fi
}

perform_ssh_check() {
    if ssh -o BatchMode=yes -o ConnectTimeout=3 -T "$1" "exit" &> /dev/null; then
    	colorize green "✔︎OK"
    	return 0
    else
        colorize red "✖︎Error"
        return 1
    fi
}

#_________________________________________Node Health Monitor ___________________________________
check_node_status() {
    clear
    colorize normal "				\033[1mNode Health Monitor\033[0m		" bold  | boxes -d ada-box | lolcat 
    echo ''
    if [ -z "$(ls -A $HOST_DIRECTORY 2> /dev/null)" ]; then
         colorize red " There are no main server or nodes to display.\n" bold
         press_key
         return 1
    fi

    print_table_header
    for node in "${HOST_DIRECTORY}"/*; do
        node_name=$(basename "$node")
        public_ip=$(grep -oP '(?<=Address = )\S+' "$node")
        local_ip=$(grep -oP '(?<=Subnet = )[^/]*' "$node")
        public_ping=$(perform_ping "$public_ip")
        local_ping=$(perform_ping "$local_ip")
        ssh_status=$(perform_ssh_check "$public_ip")

        print_table_row "$node_name" "$local_ip" "$public_ip" "$local_ping" "$public_ping" "$ssh_status"
    done
    echo ''
    press_key
}

#_________________________________________NODE MANAGEMENT CENTER ___________________________________
node_mangment_center(){
	clear
    colorize normal "		\033[1mNode Administration Center\033[0m		" bold  | boxes -d ada-box | lolcat  
    echo ''
    colorize green "	List of your nodes:\n" bold
    deactive_nodes=()
    
    for node in "${HOST_DIRECTORY}"/*; do
    	node_name=$(basename "$node")
    	public_ip=$(grep -oP '(?<=Address = )\S+' "$node")
    	if perform_ssh_check "$public_ip" > /dev/null 2>&1 || [[ "$node_name" == "main" ]]; then
    	    colorize cyan "	[✓] $node_name" bold
    	else
    		colorize red "	[𐄂] $node_name" bold
    		deactive_nodes+=("$node_name")
    	fi
    done
    echo ''
    echo -n "	Enter your node name: " | lolcat
    read -p  '' todo_node 
    echo ''
    if [[ -z "$todo_node" ]]; then
    	 colorize red "	Null value...\n" bold
    	 press_key
    	 return 1
    fi
    	
    if echo "${deactive_nodes[@]}" | grep -qw "$todo_node"; then
    	colorize red "	Access to $todo_node node is not possible at this time\n" bold
        echo -ne "	\033[1m\033[33mDo you want to remove this node from database? (yes/no)\033[33m\033[1m " 
        read  confirm
        if [[ "$confirm" == "yes" ]]; then
            remove_garbage_node "$todo_node"
            return 3
        else
            colorize red "	Operarion cancelled by user\n" bold
            press_key
            return 2
        fi
    fi
    
    if [ ! -f ${HOST_DIRECTORY}/$todo_node ]; then
    	colorize red "	'$todo_node' not found in your registered nodes\n" bold
    	press_key
    	return
    fi

	clear
    colorize normal "		\033[1m$todo_node node Control Panel\033[0m		" bold  | boxes -d ada-box | lolcat 
    echo ''
    colorize green "	List of available commands:\n" bold
    colorize reset "	[1] Change Port Number" | lolcat -S 20
    colorize reset "	[2] Restart Matrix Service" | lolcat -S 30
    colorize reset "	[3] Reboot Node Server" | lolcat -S 40
    colorize reset "	[4] Remove Node completely" | lolcat -S 25
    colorize reset "	[5] Back to main menu" | lolcat -S 50
    
    echo ''
    echo -n "	Enter your choice [1-5]: " | lolcat
    read -p  '' choice 
    
    case $choice in
        1) change_port_number $todo_node ;;
		2) restart_matrix_service $todo_node;;
		3) reboot_node_server $todo_node;;
        4) remove_node $todo_node ;;
        5) return 1 ;;
        *) colorized red "	Invalid option!" && sleep 1 && return 1 ;;
    esac

	echo ''
}

#________________Change port func#_____________
change_port_number(){
	echo ''
	CONFIG_FILE=${HOST_DIRECTORY}/${1}
	port=$(grep -oP 'Port = \K\d+' "$CONFIG_FILE")
	colorize cyan "	Current port number: $port" bold
	read -p $'	\e[1;33mEnter new port number:\e[0m ' new_port
	
	# Validate if the input is a valid port number 
	if ! [[ $new_port =~ ^[0-9]+$ && $new_port -ge 22 && $new_port -le 65535 ]]; then
  		colorize red "	Error: Please enter a valid port number between 22 and 65535.\n"
  		press_key
    	return 1
	fi
	
	sed -i "s/Port = [0-9]*/Port = $new_port/" "$CONFIG_FILE"	
	if [[ $1 == "main" ]];then
		echo ''
		file_count=$(ls -d "$HOST_DIRECTORY"/* | wc -l)
		counter=1
		show_progress "$counter" "$file_count" | lolcat
	    for node in "${HOST_DIRECTORY}"/*; do
        	node_name=$(basename "$node")
        	if [[ $node_name != "main" ]]; then
        		ip_address=$(grep -oP '(?<=Address = )\S+' "$node")
        		ssh -o BatchMode=yes -T "$ip_address" "sed -i 's/Port = [0-9]*/Port = $new_port/' \"$CONFIG_FILE\"" &> /dev/null
        		ssh -o BatchMode=yes -T "$ip_address" "systemctl restart tinc@matrix"  &> /dev/null
        		((counter++))  # Increment the counter
        		show_progress "$counter" "$file_count" | lolcat
        	fi
   		 done
	else
		ip_address=$(grep -oP '(?<=Address = )\S+' $CONFIG_FILE)
		ssh -o BatchMode=yes -T "$ip_address" "sed -i 's/Port = [0-9]*/Port = $new_port/' \"$CONFIG_FILE\""   &> /dev/null
		ssh -o BatchMode=yes -T "$ip_address" "systemctl restart tinc@matrix"  &> /dev/null
	fi
	echo ''
	colorize green "	Port number updated to: $new_port\n" bold
	colorize green "	Matrix service restarted successfully" bold
	systemctl restart tinc@matrix &> /dev/null
	echo ''
	press_key
}

remove_garbage_node (){
    echo ''
    # not possible but just for safety, funny!
    if [[ "$1" == "main" ]]; then
        echo -e "\033[1mOMG, you did impossible possible!\033[0m"  | boxes -d nuke | lolcat
        echo ''
        press_key
        return 1
    fi
    
    local CONFIG_FILE=${HOST_DIRECTORY}/${1}
    sed -i "/ConnectTo = $S1/d" $CONFIG_PATH  &> /dev/null
	rm -rf "$CONFIG_FILE"  &> /dev/null
	echo -e  "	\033[1mGarbage fils of $1 node deleted from database successfully\033[0m" | boxes -d nuke | lolcat
	echo ''
	press_key
	return 0
    
}
#______________Remove node func_______________
remove_node(){
	echo ''
	echo -ne "	\033[0;33m\033[1mAre you to delete Matrix on $1 node? (yes/no)\033[0m\033[0m: "
    read answer 
	answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
	
	echo ''
	if [[ "$answer" != "yes" ]]; then
		colorize red "	The action cancelled by user \n"
		press_key
		return 1
	fi

	if [[ "$1" == "main" ]]; then
		systemctl stop tinc@matrix &> /dev/null
		systemctl disable tinc@matrix &> /dev/null
		rm -rf "$CONFIG_DIRECTORY" &> /dev/null
		clear
		echo -e  "	\033[1mMatrix on $1 node deleted successfully\033[0m"  | boxes -d nuke | lolcat
		echo ''
		press_key
		return 0
	
	else
		local CONFIG_FILE=${HOST_DIRECTORY}/${1}
		local public_ip=$(grep -oP '(?<=Address = )\S+' "$CONFIG_FILE")
		
		ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip" << EOF
TERM=xterm clear
systemctl stop tinc@matrix &> /dev/null
systemctl disable tinc@matrix &> /dev/null
rm -rf "$CONFIG_DIRECTORY" &> /dev/null
EOF
		sed -i "/ConnectTo = $S1/d" $CONFIG_PATH &> /dev/null
		rm -rf "$CONFIG_FILE"  &> /dev/null
		echo -e  "	\033[1mMatrix on $1 node deleted successfully\033[0m"  | boxes -d nuke | lolcat
		echo ''
		press_key
		return 0	
	fi
}

#______________Restart node func_______________
restart_matrix_service(){
	echo ''
	if [[ "$1" == "main" ]]; then
		systemctl restart tinc@matrix &> /dev/null
		colorize green "	Matrix service in $1 node restarted successfully \n" bold
		press_key
		return 0
	else
		local CONFIG_FILE=${HOST_DIRECTORY}/${1}
		local public_ip=$(grep -oP '(?<=Address = )\S+' "$CONFIG_FILE")
		ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip" "systemctl restart tinc@matrix" &> /dev/null
		colorize green "	Matrix service in $1 node restarted successfully \n" bold
		press_key
		return 0
	fi

}
#______________Reboot node func_______________
reboot_node_server(){
	echo ''
	if [[ "$1" == "main" ]]; then
		colorize red "	Rebooting main node is not allowed\n" bold
		press_key
		return 1
	else
		local CONFIG_FILE=${HOST_DIRECTORY}/${1}
		public_ip=$(grep -oP '(?<=Address = )\S+' "$CONFIG_FILE")
		ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip" "reboot" &> /dev/null
		colorize green "	Send reboot command to $1 node successfully \n" bold
		press_key
		return 0
	fi

}

#_________________________________________Tunneling Asisstant Wizard_______________________________________________
tunnel_helper(){
	clear
    colorize normal "		\033[1mTunnel Assistant Wizard\033[0m		" bold  | boxes -d ada-box | lolcat 
    echo ''
    colorize green "	Check your nodes availability:\n" bold
    deactive_nodes=()
    
    for node in "${HOST_DIRECTORY}"/*; do
    	local node_name=$(basename "$node")
    	local public_ip=$(grep -oP '(?<=Address = )\S+' "$node")
    	if perform_ssh_check "$public_ip" > /dev/null 2>&1 || [[ "$node_name" == "main" ]]; then
    	    colorize cyan "	[✓] $node_name" bold
    	else
    		colorize red "	[𐄂] $node_name" bold
    		deactive_nodes+=("$node_name")
    	fi
    done
    echo ''
    echo -ne "	\033[0;32m\033[1m[*] Enter your Source (Iran) node name:\033[1m\033[0m " 
    read iran_node 
    echo ''
    if [[ "$iran_node" == "main" ]]; then
    	colorize yellow "	IP forwarding is not allowed in main node for safety\n" bold
    	press_key
    	return 1
    fi
    if echo "${deactive_nodes[@]}" | grep -qw "$iran_node"; then
    	colorize red "	Access to $iran_node node is not possible at this time\n" bold
    	press_key
    	return 1
    fi
    
    if [ ! -f ${HOST_DIRECTORY}/$iran_node ]; then
    	colorize red "	'$iran_node' not found in your registered nodes\n" bold
    	press_key
    	return 1
    fi
    
    #______________Begin of Q
     echo "	════════════════════════════════════════════════════" | lolcat
	colorize yellow "	Do you want to add new rules or delete existing ones?\n" bold
	colorize green "	1. Add new rules" bold
	colorize red "	2. Delete existing rules\n" bold
	read -p "	Enter your choice (1 or 2): " choice

	if [ "$choice" == "2" ]; then
		echo ''
	    local CONFIG_FILE_IRAN=${HOST_DIRECTORY}/$iran_node
   		local public_ip_iran=$(grep -oP '(?<=Address = )\S+' $CONFIG_FILE_IRAN)
  		ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "iptables -t nat -F" &> /dev/null
  		colorize green "	All rules were successfully deleted from $iran_node\n" bold
  		press_key
  		return 0

	elif [ "$choice" != "1" ]; then
		echo ""
    	colorize red "	Invalid choice. Please enter 1 or 2.\n" bold
    	press_key
  		return 1
    fi
    echo "	════════════════════════════════════════════════════" | lolcat
    echo ''
	#________________END of Q
	
    echo -ne "	\033[0;32m\033[1m[*] Enter your Destination (Kharej) node name:\033[1m\033[0m " 
    read kharej_node 
    echo ''
    
    if echo "${deactive_nodes[@]}" | grep -qw "$kharej_node"; then
    	colorize red "	Access to $kharej_node node is not possible. ssh error occured.\n" bold
    	press_key
    	return 1
    fi
    
    if [ ! -f ${HOST_DIRECTORY}/$kharej_node ]; then
    	colorize red "	'$kharej_node ' not found in your registered nodes\n" bold
    	press_key
    	return 1
    fi
	
	
    echo -ne "	\e[36m\033[1m[*] Enter your Source (Iran) port number:\033[1m\033[0m " 
    read iran_port 
    echo ''
    
    # Validate if the input is a valid port number 
	if ! [[ $iran_port =~ ^[0-9]+$ && $iran_port -ge 22 && $iran_port -le 65535 ]]; then
  		colorize red "	Error: Please enter a valid port number between 22 and 65535.\n" bold
  		press_key
    	return 1
	fi
	

    echo -ne "	\e[36m\033[1m[*] Enter your Destination (Kharej) port number:\033[1m\033[0m " 
    read kharej_port 
    echo ''
    # Validate if the input is a valid port number 
	if ! [[ $kharej_port =~ ^[0-9]+$ && $kharej_port -ge 22 && $kharej_port -le 65535 ]]; then
  		colorize red "	Error: Please enter a valid port number between 22 and 65535.\n" bold
  		press_key
    	return 1
	fi
	
	echo -ne "	\e[95m\033[1m[-] Choose your transport [tcp/udp/both]:\033[1m\033[0m " 
    read transport 
    echo ''
    if [ -z "$transport" ]; then
        colorize yellow "	No option selected. Defaulting to 'both' \n" bold
        transport="both"
    elif [ "$transport" != "tcp" ] && [ "$transport" != "udp" ] && [ "$transport" != "both" ]; then
        echo yellow "	Invalid option selected. Defaulting to 'both' \n" bold
        transport="both"
    fi
    
    
    # We want just ssh to iran node, nothing to do with kharej server
    # This is important we tunnel over out local network
    local CONFIG_FILE_IRAN=${HOST_DIRECTORY}/$iran_node
    local local_iran_address=$(grep "Subnet =" $CONFIG_FILE_IRAN | awk -F '[ =/]' '{print $4}')
    local public_ip_iran=$(grep -oP '(?<=Address = )\S+' $CONFIG_FILE_IRAN)
    local CONFIG_FILE_KHAREJ=${HOST_DIRECTORY}/$kharej_node 
    local local_kharej_address=$(grep "Subnet =" $CONFIG_FILE_KHAREJ | awk -F '[ =/]' '{print $4}')
 
    
    # Run ip forward support on iran server
    ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "echo 1 > /proc/sys/net/ipv4/ip_forward" &> /dev/null
    ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "sysctl -p"   &> /dev/null
    ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "apt install iptables -y"   &> /dev/null
    ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "iptables -t nat -A POSTROUTING -j MASQUERADE"   &> /dev/null
    
    if [[ $transport == "tcp" ]]; then
        ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "iptables -t nat -A PREROUTING -p tcp --dport '$iran_port' -j DNAT --to-destination '$local_kharej_address':'$kharej_port'"  &> /dev/null
    
    elif [[ $transport == "udp" ]]; then
        ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "iptables -t nat -A PREROUTING -p udp --dport '$iran_port' -j DNAT --to-destination '$local_kharej_address':'$kharej_port'"  &> /dev/null
    else
    	ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "iptables -t nat -A PREROUTING -p tcp --dport '$iran_port' -j DNAT --to-destination '$local_kharej_address':'$kharej_port'"  &> /dev/null
    	ssh -T -o BatchMode=yes -o ConnectTimeout=3 "$public_ip_iran" "iptables -t nat -A PREROUTING -p udp --dport '$iran_port' -j DNAT --to-destination '$local_kharej_address':'$kharej_port'"  &> /dev/null        
    fi
    
    colorize green "	Port forwarding successfully established within the local network. \n" bold
	press_key
    
}


#_________________________________________Update Script______________________________

#Next update

#_________________________________________Main Menu and related functions______________
check_service_status(){
    if  systemctl is-active --quiet "tinc@matrix"; then
        echo -e "[﹡]    Matrix service status: Running            [﹡]" | lolcat -S 11
    else
        echo -e "[﹡]    Matrix service status: Stopped            [﹡]" | lolcat -S 11
    fi
}

# Function to display menu
display_menu() {
    clear
    display_logo | lolcat -S 40
    echo ''
    echo -e '[﹡]    Unified Virtual Private Network Manager   [﹡]' | lolcat -S 30 -i -p 50 -F 0.5 -t
    echo -e '[﹡]    Version: 1.0                              [﹡]' | lolcat -S 3
    echo -e '[﹡]    Developer: Musixal                        [﹡]' | lolcat -S 5
    echo -e '[﹡]    Telegram Channel: @Gozar_Xray             [﹡]' | lolcat -S 7
    echo -e '[﹡]    Github: github.com/Musixal/matrix-network [﹡]' | lolcat -S 9
	check_service_status
    
    echo ''
    colorize normal "	[1] Main Node Configuration" | lolcat -F 0.1 -S 10
    colorize normal "	[2] New Node Registration" | lolcat -S 20
    colorize normal "	[3] Node Health Monitor" | lolcat -S 30
    colorize normal "	[4] Node Administration Center" | lolcat -S 40
    colorize normal "	[5] Tunnel Assistant Wizard" | lolcat -S 50
    colorize normal "	[6] Update Utility" | lolcat -S 50
    echo -e "	[7] Exit" | lolcat -S 60
    echo ''
    echo "	══════════════════════════════════════" | lolcat
}

# Function to read user input
read_option() {
    echo -n "	Enter your choice: " | lolcat
    read -p  '' choice 
    case $choice in
        1) configure_main_node ;;
        2) add_new_node ;;
        3) check_node_status ;;
        4) node_mangment_center ;;
        5) tunnel_helper ;;
        6) colorize red "	Disabled for now!" bold && sleep 1 ;;
        7) exit 5 ;;
        *) colorize red "	Invalid option!" bold && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done


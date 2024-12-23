#!/bin/bash

ver=0.0.0
verS=0.0.0A
skipCommand=1

trap catch ERR

catch() {
    echo "Error: $1"
    exit -1
}

quit() {
    echo "Exiting remote-desktop..."
    exit 0
}

help() {
    echo -e "Command\tAction\nhelp\tShow available commands\nexit\tQuit the remote-desktop application\nremote-desktop\tInstall and run x11vnc for Ubuntu X11" | column -t -s $'\t'
}

if [[ "$(uname)" == "Darwin" ]]; then
    platform=darwin
    name=macOS
else
    if grep -q "Ubuntu" /etc/os-release;
    then
        platform=ubuntu
        name=Ubuntu
    else
        platform=linux
        name=Linux
    fi
fi

remote-desktop() {
    echo "Starting remote-desktop..."
    if ! command -v x11vnc &> /dev/null
    then
        echo "Installing x11vnc..."
        sudo apt update
        sudo apt install x11vnc
        echo "Installed x11vnc"
        remote-desktop
    else
        echo "x11vnc already installed"
    fi

    echo "Starting x11vnc..."
    ip=$(hostname -I)
    echo "Remote desktop is being configured. Once configured, use a remote desktop client with protocol VNC to connect to this machine remotely."
    echo "Local machine address: $ip"

    defaultPath=~/.vnc/passwd
    read -p "Path to VNC password file (for auto-detection): [default: $defaultPath] (type \"none\" if no password or to choose a different option) " path
    path=${path:-$defaultPath}
    echo "Selected path to VNC password: $path"

    if [ -e "$path" ] && [ "$path" != "none" ]; then
        echo "VNC password found"
        x11vnc -display :0 -ncache 10 -rfbauth $path
    else
        echo "VNC password not found"
        read -p "Do you want to create a new password file? (y/n): " choice

        case "$choice" in
            y|Y ) 
                echo "Creating VNC password file..."
                x11vnc -storepasswd
                echo "Starting x11vnc..."
                x11vnc -display :0 -ncache 10 -rfbauth $path
                ;;
            n|N )
                read -p "Do you want to use a temporary password? (y/n): " choice2
                case "$choice2" in
                    y|Y ) 
                        echo "Using temporary password..."
                        echo -n "Enter the password that will be used to access this device: "
                        read -s passwd
                        echo "Starting x11vnc..."
                        x11vnc -display :0 -ncache 10 -passwd $passwd
                        ;;
                    n|N )
                        echo "Not using password..."
                        read -p "Please confirm to run x11vnc with no password (not recommended) (opens your computer up to anyone on the network) (y/n): " choice3
                        case "$choice3" in
                            y|Y )
                                echo "Starting x11vnc..."
                                echo "WARNING! USING X11VNC WITH NO PASSWORD!"
                                x11vnc -display :0 -ncache 10
                                ;;
                            n|N )
                                remote-desktop
                                ;;
                            * )
                                catch "Invalid input: $choice3"
                                ;;
                        esac
                        ;;
                    * ) 
                        catch "Invalid input: $choice2"
                        ;;
                esac
                ;;
            * ) 
                catch "Invalid input: $choice"
                ;;
        esac
    fi
}

command-input() {
    echo ""
    echo "Type 'help' for commands"
    read -p ">> " user_input
    echo ""

    if [ -z "$user_input" ]; then
        quit
    else
        case "$user_input" in
            help)
                echo "remote-desktop Help Menu (for version $ver)"
                help
                ;;
            exit|quit|stop)
                quit
                ;;
            remote-desktop)
                echo "Running remote-desktop..."
                if [ "$platform" != "ubuntu" ]; then
                    echo "Error: Unsupported platform: $platform"
                    echo "Supported platforms: ubuntu"
                else 
                    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
                        remote-desktop
                    else
                        echo "Error: Unsupported environment: $XDG_SESSION_TYPE"
                        echo "Supported environments: X11"
                    fi
                fi
                echo "Ended remote-desktop run session"
                ;;
            *)
                echo "Invalid command"
                ;;
        esac
        command-input
    fi
}

echo "Welcome to Calebh101 remote-desktop for $name"
echo "remote-desktop $ver ($verS)"

if [ "$skipCommand" -gt 0 ]; then
    read -p "Start remote-desktop? (y/n): " choice4
    case "$choice4" in
        y|Y )
            echo "Calling remote-desktop..."
            remote-desktop
            ;;
        n|N )
            quit
            ;;
        * )
            catch "Invalid input: $choice4"
            ;;
    esac
else
    command-input
fi
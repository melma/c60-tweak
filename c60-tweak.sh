#!/bin/bash

changeFlag=0
rcFile="/etc/rc.local"
commandsSeq="modprobe msr;"
defaultParams="-p 0:0x22 -p 1:0x28,4 -p 2:0x2B"
tweakedParams="-p 0:0x28 -p 1:0x28,3 -p 2:0x38"

requestSudo() {
    sudo echo -n || {
        exit 1  
    }
}

checkCpu() {
    lscpu | grep -q "AMD C-60" || {
        echo "This is useful only for AMD C-60 processors"
        exit 2  
    }
}

checkUndervolt() {
    type undervolt &> /dev/null || {
        echo "Program 'undervolt' couldn't be found"
        exit 3
    }   
    commandsSeq+=`which undervolt`
}

checkMsr() {
    lsmod | grep -q msr || {
        type sudo modprobe msr &> /dev/null || {
            echo "MSR module couldn't be loaded"
            exit 4      
        }
    }
}

options() {
    echo "AMD C-60 Linux Tweak"
    echo "1 - Check current status"
    echo "2 - Undervolt and unlock turbo mode"
    echo "3 - Enable on system startup"
    echo "4 - Restore and disable"
    echo "5 - Quit"
}

selectOption() {
    while true; do
        echo -n "Select an option: "; read option
        case "$option" in
        1) checkStatus;;
        2) undervoltAndUnlockTurbo;;
        3) enableOnStartup;;
        4) restoreAndDisable;;
        5) exit 0;;
        *) echo "Unknown option";;
        esac
    done
}

checkStatus() {
    checkMsr
    if sudo undervolt -r | grep -zq ".*28.*28.*3\..*38.*"; then
        echo "Voltage is lowered and turbo mode is unlocked"
    else
        echo "Voltage is default and turbo mode is locked"
    fi
}

undervoltAndUnlockTurbo() {
    checkMsr
    if sudo undervolt $tweakedParams &> /dev/null; then
        echo "Lowered voltage and unlocked turbo mode"
        changeFlag=1
    else
        echo "Could not set new parameters"
        exit 5
    fi
}

enableOnStartup() {
    if grep -q "$commandsSeq" "$rcFile"; then
        echo "It's already enabled on system startup"
    elif [ $changeFlag = 0 ]; then
        echo "Use option no. 2 before enabling"
    else
        exitLine=`grep -n "^#*exit 0" "$rcFile" | cut -d : -f 1`
        if sudo sed -i "$exitLine""i$commandsSeq $tweakedParams" "$rcFile"; then
            echo "Enabled on system startup"    
        else
            echo "Could not enable on system startup"
            exit 6      
        fi
    fi
}

restoreAndDisable() {
    checkMsr
    if sudo undervolt $defaultParams &> /dev/null; then
        echo "Restored voltages and turbo mode default behavior"
        changeFlag=0
    else
        echo "Couldn't set parameters"
        exit 5
    fi
    commandsLine=`grep -n "$commandsSeq" "$rcFile" | cut -d : -f 1`
    if [ ! -z $commandsLine ]; then
        if sudo sed -i "$commandsLine""d" "$rcFile"; then
            echo "Disabled on system startup"   
        else
            echo "Couldn't disable on system startup"
            exit 6      
        fi
    else
        echo "It's not enabled on system startup"
    fi
}

requestSudo
checkCpu
checkUndervolt
checkMsr
options
selectOption

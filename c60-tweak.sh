#!/bin/bash

defaultParameters="-p 0:0x22 -p 1:0x28,4 -p 2:0x2B"
tweakedParameters="-p 0:0x28 -p 1:0x28,3 -p 2:0x38"
startupScriptFileName="c60-tweak-startup.sh"
undervoltProgramPath=""
tweaked=0

requestSudo() {
    sudo echo -n || {
        exit 1  
    }
}

checkCpu() {
    lscpu | grep -q "AMD C-60" || {
        echo "This is intended only for AMD C-60 processors"
        exit 2  
    }
}

checkUndervolt() {
    type undervolt &> /dev/null || {
        echo "Program 'undervolt' couldn't be found"
        exit 3
    }
    
    undervoltProgramPath=`which undervolt`
}

checkMsr() {
    lsmod | grep -q msr || {
        sudo modprobe msr &> /dev/null || {
            echo "MSR module couldn't be loaded"
            exit 4      
        }
    }
}

showOptions() {
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
    
    if sudo undervolt $tweakedParameters &> /dev/null; then
        echo "Lowered voltage and unlocked turbo mode"
        tweaked=1
    else
        echo "Couldn't set new parameters"
        exit 5
    fi
}

enableOnStartup() {
    if [ -f /etc/init.d/$startupScriptFileName ]; then
        echo "It's already enabled on system startup"
    elif [ $tweaked = 0 ]; then
        echo "Use option no. 2 before enabling on system startup"
    else
        c="#!/bin/bash\n"
        c=$c"### BEGIN INIT INFO\n"
        c=$c"# Default-Start: 2 3 4 5\n"
        c=$c"### END INIT INFO\n"
        c=$c"modprobe msr\n"
        c=$c"$undervoltProgramPath $tweakedParameters"
        
        sudo bash -c "echo -e '$c' > /etc/init.d/$startupScriptFileName"
        
        sudo chmod +x /etc/init.d/$startupScriptFileName
        sudo update-rc.d $startupScriptFileName defaults > /dev/null 2>&1
        sudo update-rc.d $startupScriptFileName enable > /dev/null 2>&1
        
        echo "Enabled on system startup"
    fi
}

restoreAndDisable() {
    checkMsr
    
    if sudo undervolt $defaultParameters &> /dev/null; then
        echo "Restored voltages and turbo mode default behavior"
        tweaked=0
    else
        echo "Couldn't restore voltages and turbo mode default behavior"
        exit 5
    fi
    
    if [ -f /etc/init.d/$startupScriptFileName ]; then
        sudo update-rc.d $startupScriptFileName disable > /dev/null 2>&1
        sudo update-rc.d $startupScriptFileName remove > /dev/null 2>&1
        sudo rm /etc/init.d/$startupScriptFileName
        
        echo "Disabled on system startup"
    else
        echo "It's not enabled on system startup"
    fi
}

requestSudo
checkCpu
checkUndervolt
checkMsr
showOptions
selectOption
## AMD C-60 Linux Tweak
This is a bash script for undervolting and unlocking turbo mode in AMD C-60 (from Brazos CPU family) on Linux. It was written because I noticed some problems with CPU state management in my AO722 netbook running Ubuntu.

The C-60 CPU has three states: P0, P1 and P2.
* P0 / 1.3 GHz / turbo mode
* P1 / 1.0 GHz / normal mode
* P2 / 0.8 GHz / eco mode

The turbo mode has never actually activated under heavy CPU load on Ubuntu 15.\*/16.* and any of 4.4.* kernels. The CPU kept toggling between P1 (1.0 GHz) and P2 (0.8 GHz), totally missing P0 (1.3 GHz) state. This has been validated with turbostat readings and several benchmarks.

With this script it's possible to lower the voltages to a set of stable values. Default values are 1.125 V for P0, 1.05 V for P1 and 1.0125 V for P2. Tweaked values, as lowered stable voltages, are 1.05 V for P0 and 0.85 V for P2. The script also overwrites normal mode with turbo mode. This results in slightly lower temperatures and CPU toggling between eco mode (0.8 GHz) and turbo mode (1.3 GHz) while ignoring lock on normal mode (1.0 GHz).

### Features
* checking current status
* undervolting and unlocking turbo mode
* saving changes and setting them on system startup
* reverting any changes

### Requirements
This script requires a GNU GPL program [undervolt](https://sourceforge.net/projects/undervolt/) (v0.4) written by Thierry Goubier. Compiled binary should be placed in `/usr/local/sbin/` or `/usr/local/bin/`.

### Usage
Make this script an executable via terminal with `chmod +x c60-tweak.sh`, then execute it with `sudo ./c60-tweak.sh` and follow on-screen instructions.
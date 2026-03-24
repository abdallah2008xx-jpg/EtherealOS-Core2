#!/usr/bin/env python3
"""
EtherealOS - Zero-Input Auto-Repair Launcher
Automatically feeds the root password to 'su' so the user never types anything.
"""
import os, pty, sys, time, subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESCUE_SCRIPT = os.path.join(SCRIPT_DIR, "Ethereal-Browser-Rescue.sh")
ROOT_PASSWORD = "abdallah"

def auto_repair():
    print("🪐 EtherealOS Zero-Input Repair Engine")
    print("======================================")
    print("🔑 Auto-authenticating as root...")
    print("")

    # Use pty to simulate terminal for su
    master_fd, slave_fd = pty.openpty()

    proc = subprocess.Popen(
        ["su", "-c", f"bash {RESCUE_SCRIPT}"],
        stdin=slave_fd,
        stdout=sys.stdout,
        stderr=sys.stderr
    )

    os.close(slave_fd)
    # Wait for password prompt
    time.sleep(0.5)
    # Send password
    os.write(master_fd, (ROOT_PASSWORD + "\n").encode())
    
    # Wait for completion
    proc.wait()
    os.close(master_fd)

    print("")
    print("🏆 Repair finished! Try opening Firefox or Thor now.")
    print("Press Enter to close...")
    try:
        input()
    except:
        time.sleep(3)

if __name__ == "__main__":
    auto_repair()

#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair (v4.1.0)
# FULLY AUTOMATIC - NO INPUT NEEDED
# ==========================================================

cd "$(dirname "$0")"

# Use Python to auto-feed root password to su
python3 auto-repair-launcher.py

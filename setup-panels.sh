#!/bin/bash

# Move the grouped-window-list to the bottom panel (panel2)
gsettings set org.cinnamon enabled-applets "['panel1:left:0:menu@cinnamon.org:0', 'panel1:right:0:systray@cinnamon.org:1', 'panel1:right:1:xapp-status@cinnamon.org:2', 'panel1:right:2:keyboard@cinnamon.org:3', 'panel1:right:3:network@cinnamon.org:4', 'panel1:right:4:sound@cinnamon.org:5', 'panel1:right:5:power@cinnamon.org:6', 'panel1:right:6:calendar@cinnamon.org:7', 'panel1:right:7:notifications@cinnamon.org:8', 'panel2:center:0:grouped-window-list@cinnamon.org:9']"

# Pin the apps!
# Cinnamon stores pinned apps in org.cinnamon.GroupedWindowList pinned-apps
# Or we can use python to set it if gsettings complains
# Let's use dconf
dconf write /org/cinnamon/change-applet-ids "true"

gsettings set org.cinnamon.GroupedWindowList pinned-apps "['nemo.desktop', 'www-client_firefox-bin.desktop', 'firefox-bin.desktop', 'firefox.desktop', 'gnome-terminal.desktop']"

# To guarantee it takes effect:
cinnamon --replace &

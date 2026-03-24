const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const St = imports.gi.St;

let injectedMenuItems = [];

function init(metadata) {
    // Required init block
}

function enable() {
    Main.panelManager.panels.forEach(function(panel) {
        if (panel.contextMenu) {
            // Create "Task Manager" matching Windows 11 style
            let item = new PopupMenu.PopupIconMenuItem("Task Manager", "utilities-system-monitor-symbolic", St.IconType.SYMBOLIC);
            
            item.connect('activate', function() {
                // Determine user's python path
                Util.spawnCommandLine("/usr/bin/python3 " + imports.gi.GLib.get_home_dir() + "/ethereal-update/Ethereal-TaskMgr.py");
            });
            
            // Insert at index 1 to avoid interfering with position 0 (Sometimes Troubleshoot or generic panel name)
            panel.contextMenu.addMenuItem(item, 1);
            
            injectedMenuItems.push({ panel: panel, item: item });
        }
    });
}

function disable() {
    injectedMenuItems.forEach(function(record) {
        if (record.item && record.item.actor) {
            record.item.destroy();
        }
    });
    injectedMenuItems = [];
}

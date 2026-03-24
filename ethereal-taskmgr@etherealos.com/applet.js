const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const Util = imports.misc.util;
const PopupMenu = imports.ui.popupMenu;
const St = imports.gi.St;
const Lang = imports.lang;

class EtherealTaskMgrApplet extends Applet.Applet {
    constructor(metadata, orientation, panel_height, instance_id) {
        super(orientation, panel_height, instance_id);
        
        // Hide the applet button itself (invisible in panel, only adds to right-click)
        this.actor.hide();
        this.setAllowedLayout(Applet.AllowedLayout.BOTH);
    }

    on_applet_clicked(event) {
        // Nothing when left-clicked - this is invisible
    }

    _buildContextMenu() {
        // Add Task Manager item to the right-click context menu
        let item = new PopupMenu.PopupIconMenuItem(
            "Task Manager",
            "utilities-system-monitor",
            St.IconType.FULLCOLOR
        );
        item.connect('activate', Lang.bind(this, function() {
            Util.spawnCommandLine("python3 " + GLib.get_home_dir() + "/.ethereal-update/Ethereal-TaskMgr.py");
        }));
        this._applet_context_menu.addMenuItem(item);
        
        let sep = new PopupMenu.PopupSeparatorMenuItem();
        this._applet_context_menu.addMenuItem(sep);
    }
}

function main(metadata, orientation, panel_height, instance_id) {
    return new EtherealTaskMgrApplet(metadata, orientation, panel_height, instance_id);
}

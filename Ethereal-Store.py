#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf
import os, sys, threading, json, urllib.request, shutil

CSS = b"""
window { background-color: transparent; }
#main-bg {
    background-color: rgba(15, 18, 28, 0.98);
    border-radius: 20px;
    border: 1px solid rgba(126, 215, 255, 0.2);
    box-shadow: 0 15px 50px rgba(0,0,0,0.8);
}
.title { color: #ffffff; font-size: 36px; font-weight: 900; text-shadow: 0 0 20px rgba(126, 215, 255, 0.5); margin: 20px 30px 5px 30px; }
.subtitle { color: #8892b0; font-size: 16px; margin: 0 30px 20px 30px; }

.app-card {
    background-color: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 16px;
    padding: 20px; margin: 15px;
    transition: all 300ms ease;
}
.app-card:hover {
    background-color: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(126, 215, 255, 0.3);
    box-shadow: 0 0 30px rgba(126, 215, 255, 0.15);
}

.app-name { color: #ffffff; font-size: 20px; font-weight: bold; }
.app-desc { color: #a3b2fa; font-size: 13px; margin-top: 5px; }

.install-btn {
    background: transparent; color: #00ff88; font-weight: bold; border-radius: 10px;
    border: 2px solid rgba(0,255,136, 0.4); padding: 8px 24px; transition: all 250ms;
}
.install-btn:hover { background: rgba(0,255,136, 0.1); box-shadow: 0 0 15px rgba(0,255,136, 0.3); }

.installed-btn {
    background: rgba(255,255,255,0.05); color: #8892b0; font-weight: bold; border-radius: 10px;
    border: 2px solid rgba(255,255,255, 0.1); padding: 8px 24px;
}

progressbar {
    border-radius: 10px; font-size: 10px; min-height: 6px;
}
progressbar trough {
    background-color: rgba(0,0,0, 0.5); border-radius: 10px;
}
progressbar progress {
    background-color: #00ff88; border-radius: 10px;
    box-shadow: 0 0 10px rgba(0,255,136,0.8);
}
"""

CATALOG = [
    {"id": "heroic", "name": "Heroic Games", "desc": "Epic, GOG & Amazon Games Launcher", "repo": "Heroic-Games-Launcher/HeroicGamesLauncher", "icon": "applications-games"},
    {"id": "freetube", "name": "FreeTube", "desc": "Private YouTube Client (No Ads)", "repo": "FreeTubeApp/FreeTube", "icon": "youtube"},
    {"id": "upscayl", "name": "Upscayl", "desc": "Free AI Image Upscaler", "repo": "upscayl/upscayl", "icon": "applications-graphics"},
    {"id": "localsend", "name": "LocalSend", "desc": "AirDrop for Linux (Share Files)", "repo": "localsend/localsend", "icon": "network-workgroup"},
    {"id": "rpcs3", "name": "RPCS3 Emulator", "desc": "PlayStation 3 Emulator", "repo": "RPCS3/rpcs3-binaries-linux", "icon": "applications-games"},
    {"id": "audacity", "name": "Audacity", "desc": "Professional Audio Editor", "repo": "audacity/audacity", "icon": "applications-multimedia"},
    {"id": "floorp", "name": "FloorP Browser", "desc": "Most Private Firefox Fork", "repo": "Floorp-Projects/Floorp", "icon": "web-browser"},
    {"id": "obs", "name": "OBS Project", "desc": "Live Streaming & Screen Recording", "repo": "obsproject/obs-studio", "icon": "camera-video"}
]

class AppStore(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ethereal App Store")
        self.set_default_size(1000, 700)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        if self.get_screen().get_rgba_visual() and self.get_screen().is_composited():
            self.set_visual(self.get_screen().get_rgba_visual())

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        main_box.set_name("main-bg")
        self.add(main_box)
        
        hdr = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        t = Gtk.Label(label="Ethereal Store", xalign=0); t.set_name("title")
        s = Gtk.Label(label="One-click Windows-style App Installation via AppImages", xalign=0); s.set_name("subtitle")
        hdr.pack_start(t, False, False, 0); hdr.pack_start(s, False, False, 0)
        main_box.pack_start(hdr, False, False, 0)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_box.pack_start(scroll, True, True, 0)
        
        self.flow = Gtk.FlowBox()
        self.flow.set_valign(Gtk.Align.START)
        self.flow.set_max_children_per_line(2)
        self.flow.set_min_children_per_line(1)
        self.flow.set_selection_mode(Gtk.SelectionMode.NONE)
        
        # Center the flowbox magically inside a scrolled
        align_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        align_box.pack_start(self.flow, True, True, 20)
        scroll.add(align_box)
        
        self.app_dir = os.path.expanduser("~/Applications")
        os.makedirs(self.app_dir, exist_ok=True)
        self.shortcut_dir = os.path.expanduser("~/.local/share/applications")
        os.makedirs(self.shortcut_dir, exist_ok=True)

        for app in CATALOG:
            self.build_card(app)

    def build_card(self, app):
        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); card.set_name("app-card")
        card.set_size_request(420, 120)
        
        # Icon
        icon = Gtk.Image.new_from_icon_name(app["icon"], Gtk.IconSize.DIALOG)
        icon.set_pixel_size(64); icon.set_margin_right(20)
        card.pack_start(icon, False, False, 0)
        
        # Details
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        vbox.set_valign(Gtk.Align.CENTER)
        
        name = Gtk.Label(label=app["name"], xalign=0); name.set_name("app-name")
        desc = Gtk.Label(label=app["desc"], xalign=0); desc.set_name("app-desc")
        
        self.pbar = Gtk.ProgressBar(); self.pbar.set_visible(False)
        self.pbar.set_margin_top(15)
        app["pbar"] = self.pbar
        
        vbox.pack_start(name, False, False, 0)
        vbox.pack_start(desc, False, False, 0)
        vbox.pack_start(self.pbar, False, False, 0)
        card.pack_start(vbox, True, True, 0)
        
        # Button
        btn = Gtk.Button()
        desktop_f = os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")
        
        if os.path.exists(desktop_f):
            btn.set_label("INSTALLED")
            btn.set_name("installed-btn")
            btn.set_sensitive(False)
        else:
            btn.set_label("INSTALL")
            btn.set_name("install-btn")
            btn.connect("clicked", self.on_install_clicked, app)
        
        btn.set_valign(Gtk.Align.CENTER)
        app["btn"] = btn
        card.pack_end(btn, False, False, 10)
        
        self.flow.add(card)

    def on_install_clicked(self, btn, app):
        btn.set_sensitive(False)
        btn.set_label("DOWNLOADING...")
        app["pbar"].set_visible(True)
        threading.Thread(target=self.download_app, args=(app,), daemon=True).start()

    def download_app(self, app):
        try:
            # 1. Ask GitHub API for latest release
            api_url = f"https://api.github.com/repos/{app['repo']}/releases/latest"
            req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode())
                
            dl_url = None
            asset_name = ""
            for asset in data.get('assets', []):
                # prioritize .AppImage! If not, .tar.xz or .zip if it contains binaries (AppStore limits usually focus on AppImage)
                if asset['name'].lower().endswith('.appimage'):
                    dl_url = asset['browser_download_url']
                    asset_name = asset['name']
                    break
                    
            if not dl_url:
                GLib.idle_add(self.install_failed, app, "No AppImage Found")
                return
                
            out_path = os.path.join(self.app_dir, asset_name)
            
            # 2. Download with progress
            def report(count, block_size, total_size):
                pct = min(1.0, count * block_size / total_size) if total_size > 0 else 0
                GLib.idle_add(app["pbar"].set_fraction, pct)
                
            urllib.request.urlretrieve(dl_url, out_path, reporthook=report)
            
            # 3. Make executable
            os.chmod(out_path, 0o755)
            
            # 4. Generate Desktop shortcut
            desktop_cont = f"""[Desktop Entry]
Name={app['name']}
Comment={app['desc']}
Exec="{out_path}"
Icon={app['icon']}
Terminal=false
Type=Application
Categories=Utility;
"""
            dfile = os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")
            with open(dfile, 'w') as f:
                f.write(desktop_cont)
            os.chmod(dfile, 0o755)
            
            GLib.idle_add(self.install_success, app)
            
        except Exception as e:
            GLib.idle_add(self.install_failed, app, str(e))

    def install_success(self, app):
        app["pbar"].set_visible(False)
        app["btn"].set_label("INSTALLED")
        app["btn"].set_name("installed-btn")
        app["btn"].set_sensitive(False)

    def install_failed(self, app, reason):
        app["pbar"].set_visible(False)
        app["btn"].set_label("FAILED")
        app["btn"].set_sensitive(True)
        print(f"[{app['name']}] Install Failed:", reason)

if __name__ == "__main__":
    try:
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        
        win = AppStore()
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()
    except Exception as fatal_error:
        import traceback
        err_msg = traceback.format_exc()
        err_win = Gtk.Window(title="App Store Crash Reporter")
        err_win.set_default_size(600, 400)
        scroll = Gtk.ScrolledWindow()
        l = Gtk.Label(label=f"Fatal Error:\n\n{err_msg}")
        l.set_selectable(True)
        l.set_halign(Gtk.Align.START)
        scroll.add(l)
        err_win.add(scroll)
        err_win.show_all()
        err_win.connect("destroy", Gtk.main_quit)
        Gtk.main()

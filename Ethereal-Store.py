#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, sys, threading, urllib.request, shutil

CSS = b"""
window { background-color: transparent; }
#main-bg {
    background-color: rgba(12, 14, 25, 0.98);
    border-radius: 20px;
    border: 1px solid rgba(126, 215, 255, 0.3);
    box-shadow: 0 15px 80px rgba(0,0,0,0.9);
}

.sidebar {
    background-color: rgba(0, 0, 0, 0.5);
    border-right: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 20px 0 0 20px;
    padding: 20px 10px;
}

list row.tab-row {
    background: transparent; color: #8892b0;
    padding: 16px 20px; margin: 4px 10px;
    border-radius: 12px; font-weight: bold; font-size: 15px;
    transition: all 250ms ease;
}
list row.tab-row:hover { background: rgba(255, 255, 255, 0.05); color: #ffffff; }
list row.tab-row:selected {
    background: rgba(126, 215, 255, 0.15);
    color: #7ed7ff; border-left: 4px solid #7ed7ff;
}

.search-bar { 
    background: rgba(255,255,255,0.05); color: white; border: 1px solid rgba(255,255,255,0.1); 
    border-radius: 12px; padding: 12px; font-size: 16px; margin: 15px 30px; 
}
.search-bar:focus { border: 1px solid #7ed7ff; box-shadow: 0 0 15px rgba(126,215,255,0.3); }

list.app-list { background: transparent; }
list row.app-row { background: transparent; transition: all 200ms; border-bottom: 1px solid rgba(255,255,255,0.02); }
list row.app-row:hover { background: rgba(255,255,255,0.02); }

.app-card { padding: 25px 30px; }

.app-icon { font-size: 48px; margin-right: 25px; }

.app-name { color: #f0f0fd; font-size: 24px; font-weight: 800; text-shadow: 0 0 10px rgba(126,215,255,0.2); }
.app-desc { color: #8892b0; font-size: 15px; margin-top: 6px; font-weight: 500; }

.install-btn {
    background: transparent; color: #00ff88; font-weight: bold; border-radius: 12px; font-size: 16px;
    border: 2px solid rgba(0,255,136, 0.5); padding: 10px 35px; transition: all 250ms;
}
.install-btn:hover { background: rgba(0,255,136, 0.15); box-shadow: 0 0 20px rgba(0,255,136, 0.4); }

.installed-btn {
    background: rgba(255,255,255,0.05); color: #8892b0; font-weight: bold; border-radius: 12px; font-size: 16px;
    border: 2px solid rgba(255,255,255, 0.1); padding: 10px 35px;
}

progressbar { border-radius: 10px; font-size: 10px; min-height: 8px; margin-top: 15px; }
progressbar trough { background-color: rgba(0,0,0, 0.5); border-radius: 10px; }
progressbar progress { background-color: #00ff88; border-radius: 10px; box-shadow: 0 0 15px rgba(0,255,136,0.8); }
"""

APPS = [
    {"id": "discord", "name": "Discord", "cat": "Internet", "desc": "Chat for Communities and Friends", "repo": "portapps/discord-portable", "icon": "discord"},
    {"id": "spotify", "name": "Spotify", "cat": "Media", "desc": "Music Player and Podcasts", "repo": "srevinsaju/Spotify-AppImage", "icon": "spotify"},
    {"id": "heroic", "name": "Heroic Games", "cat": "Games", "desc": "Epic, GOG & Amazon Games Launcher", "repo": "Heroic-Games-Launcher/HeroicGamesLauncher", "icon": "applications-games"},
    {"id": "freetube", "name": "FreeTube", "cat": "Media", "desc": "Private YouTube Client (No Ads)", "repo": "FreeTubeApp/FreeTube", "icon": "youtube"},
    {"id": "upscayl", "name": "Upscayl", "cat": "Media", "desc": "Free AI Image Upscaler", "repo": "upscayl/upscayl", "icon": "image-viewer"},
    {"id": "localsend", "name": "LocalSend", "cat": "Internet", "desc": "AirDrop for Linux (Share Files)", "repo": "localsend/localsend", "icon": "folder-share"},
    {"id": "audacity", "name": "Audacity", "cat": "Media", "desc": "Professional Audio Editor", "repo": "audacity/audacity", "icon": "audacity"},
    {"id": "vscodium", "name": "VSCodium", "cat": "Productivity", "desc": "Free Open Source VS Code", "repo": "VSCodium/vscodium", "icon": "vscodium"},
    {"id": "bitwarden", "name": "Bitwarden", "cat": "Internet", "desc": "Secure Password Manager", "repo": "bitwarden/clients", "icon": "bitwarden"},
    {"id": "obsidian", "name": "Obsidian", "cat": "Productivity", "desc": "Personal Knowledge Base", "repo": "obsidianmd/obsidian-releases", "icon": "obsidian"},
    {"id": "kdenlive", "name": "Kdenlive", "cat": "Media", "desc": "Pro Video Editor", "repo": "KDE/kdenlive", "icon": "kdenlive"},
    {"id": "anydesk", "name": "AnyDesk", "cat": "Internet", "desc": "Remote Desktop Software", "repo": "srevinsaju/anydesk-appimage", "icon": "anydesk"},
    {"id": "postman", "name": "Postman", "cat": "Productivity", "desc": "API Platform Toolkit", "repo": "srevinsaju/Postman-AppImage", "icon": "postman"},
    {"id": "firefox", "name": "Firefox", "cat": "Internet", "desc": "Fast & Private Browser", "repo": "srevinsaju/Firefox-AppImage", "icon": "firefox"},
    {"id": "thunderbird", "name": "Thunderbird", "cat": "Internet", "desc": "Email Client", "repo": "srevinsaju/Thunderbird-AppImage", "icon": "thunderbird"},
    {"id": "gimp", "name": "GIMP", "cat": "Media", "desc": "Image Editor", "repo": "srevinsaju/gimp-appimage", "icon": "gimp"},
    {"id": "libreoffice", "name": "LibreOffice", "cat": "Productivity", "desc": "Office Suite", "repo": "srevinsaju/LibreOffice-AppImage", "icon": "libreoffice"}
]

class AppStore(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ethereal Software Center")
        self.set_default_size(1200, 800)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        if self.get_screen().get_rgba_visual() and self.get_screen().is_composited():
            self.set_visual(self.get_screen().get_rgba_visual())

        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.set_name("main-bg")
        self.add(main_box)
        
        self.app_dir = os.path.expanduser("~/Applications")
        os.makedirs(self.app_dir, exist_ok=True)
        self.shortcut_dir = os.path.expanduser("~/.local/share/applications")
        os.makedirs(self.shortcut_dir, exist_ok=True)
        
        # Sidebar
        self.sidebar = Gtk.ListBox(); self.sidebar.set_name("sidebar"); self.sidebar.set_size_request(280, -1)
        self.sidebar.connect("row-activated", self.on_cat_changed)
        main_box.pack_start(self.sidebar, False, False, 0)
        
        cats = ["🔥 Discover All", "🌐 Internet", "🎮 Games", "🎬 Media", "💼 Productivity"]
        for c in cats:
            r = Gtk.ListBoxRow(); r.set_name("tab-row")
            r.add(Gtk.Label(label=c, xalign=0)); self.sidebar.add(r)
        
        # Main Area
        right_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        right_vbox.set_margin_bottom(20)
        main_box.pack_start(right_vbox, True, True, 0)
        
        # Header Box
        self.search = Gtk.SearchEntry(placeholder_text="Search Professional Apps..."); self.search.set_name("search-bar")
        self.search.connect("search-changed", self.on_search)
        right_vbox.pack_start(self.search, False, False, 10)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        right_vbox.pack_start(scroll, True, True, 0)
        
        self.listbox = Gtk.ListBox(); self.listbox.set_name("app-list")
        self.listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        scroll.add(self.listbox)
        
        self.cards = []
        for app in APPS: self.build_card(app)
        
        self.sidebar.select_row(self.sidebar.get_row_at_index(0))

    def build_card(self, app):
        row = Gtk.ListBoxRow(); row.set_name("app-row")
        
        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); card.set_name("app-card")
        
        # Use icon from theme with fallback
        icon_name = app.get("icon", "application-x-executable")
        icon = Gtk.Image.new_from_icon_name(icon_name, Gtk.IconSize.DIALOG)
        icon.set_pixel_size(48)
        icon.set_name("app-icon-image")
        card.pack_start(icon, False, False, 0)
        
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); vbox.set_valign(Gtk.Align.CENTER)
        name = Gtk.Label(label=app["name"], xalign=0); name.set_name("app-name")
        desc = Gtk.Label(label=app["desc"], xalign=0); desc.set_name("app-desc")
        
        self.pbar = Gtk.ProgressBar(); self.pbar.set_visible(False)
        app["pbar"] = self.pbar
        
        vbox.pack_start(name, False, False, 0)
        vbox.pack_start(desc, False, False, 0)
        vbox.pack_start(self.pbar, False, False, 5)
        card.pack_start(vbox, True, True, 0)
        
        btn = Gtk.Button()
        if os.path.exists(os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")):
            btn.set_label("INSTALLED"); btn.set_name("installed-btn"); btn.set_sensitive(False)
        else:
            btn.set_label("INSTALL"); btn.set_name("install-btn"); btn.connect("clicked", self.on_install, app)
        
        btn.set_valign(Gtk.Align.CENTER)
        app["btn"] = btn
        card.pack_end(btn, False, False, 20)
        
        row.add(card)
        app["row"] = row
        app["visible"] = True
        self.listbox.add(row)
        self.cards.append(app)

    def filter_apps(self, term, category):
        for app in self.cards:
            match = True
            if category and category != "Discover All":
                if app["cat"] not in category: match = False
            if term and term not in app["name"].lower() and term not in app["desc"].lower():
                match = False
            
            if match and not app["visible"]:
                app["row"].show()
                app["visible"] = True
            elif not match and app["visible"]:
                app["row"].hide()
                app["visible"] = False

    def on_search(self, search_entry):
        cat_row = self.sidebar.get_selected_row()
        cat = cat_row.get_child().get_label().split(" ", 1)[1] if cat_row else None
        self.filter_apps(search_entry.get_text().lower(), cat)

    def on_cat_changed(self, lb, row):
        cat = row.get_child().get_label().split(" ", 1)[1]
        self.filter_apps(self.search.get_text().lower(), cat)

    def on_install(self, btn, app):
        btn.set_sensitive(False); btn.set_label("LOCATING..."); btn.set_name("install-btn")
        app["pbar"].set_visible(True)
        threading.Thread(target=self.download_app, args=(app,), daemon=True).start()

    def download_app(self, app):
        try:
            # 1. Fetch latest release info using GitHub API with fallback
            api_url = f"https://api.github.com/repos/{app['repo']}/releases/latest"
            headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)', 'Accept': 'application/vnd.github.v3+json'}
            
            try:
                req = urllib.request.Request(api_url, headers=headers)
                resp = urllib.request.urlopen(req, timeout=15)
                import json
                release_data = json.loads(resp.read().decode('utf-8'))
                assets = release_data.get('assets', [])
            except:
                # Fallback: parse HTML page
                latest_url = f"https://github.com/{app['repo']}/releases/latest"
                req = urllib.request.Request(latest_url, headers={'User-Agent': 'Mozilla/5.0'})
                resp = urllib.request.urlopen(req, timeout=15)
                html = resp.read().decode('utf-8')
                assets = []
                for chunk in html.split('href="')[1:]:
                    if '.AppImage' in chunk and '/releases/download/' in chunk:
                        url = chunk.split('"')[0]
                        if not url.startswith('http'):
                            url = 'https://github.com' + url
                        assets.append({'browser_download_url': url, 'name': url.split('/')[-1]})
            
            # Find the best AppImage (prefer x86_64, avoid arm)
            dl_url = None
            filename = None
            for asset in assets:
                url = asset.get('browser_download_url', '')
                name = asset.get('name', '')
                if url and name.endswith('.AppImage'):
                    # Skip ARM versions
                    if 'arm' in name.lower() or 'aarch' in name.lower():
                        continue
                    dl_url = url
                    filename = name
                    break
            
            if not dl_url:
                GLib.idle_add(self.fail, app, "No compatible AppImage found")
                return
                
            out_path = os.path.join(self.app_dir, filename)
            
            GLib.idle_add(app["btn"].set_label, "DOWNLOADING...")
            
            # Download with progress
            def report(count, block, total):
                if total > 0:
                    pct = min(1.0, count * block / total)
                    GLib.idle_add(app["pbar"].set_fraction, pct)
                
            urllib.request.urlretrieve(dl_url, out_path, reporthook=report)
            os.chmod(out_path, 0o755)
            
            # Create desktop file with proper icon
            icon_name = app.get("icon", "application-x-executable")
            desktop_content = f"""[Desktop Entry]
Name={app['name']}
Comment={app['desc']}
Exec={out_path}
Icon={icon_name}
Terminal=false
Type=Application
Categories={app['cat']};
StartupNotify=true
"""
            dfile = os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")
            with open(dfile, 'w') as f:
                f.write(desktop_content)
            os.chmod(dfile, 0o755)
            
            # Mark desktop file as trusted (Cinnamon/GNOME)
            os.system(f'gio set "{dfile}" metadata::trusted true 2>/dev/null || true')
            
            # Update icon cache
            os.system('gtk-update-icon-cache -f ~/.local/share/icons/ 2>/dev/null || true')
            
            GLib.idle_add(self.succ, app)
            
        except Exception as e:
            import traceback
            error_msg = str(e)
            print(f"[{app['name']}] Install Failed:", error_msg)
            print(traceback.format_exc())
            GLib.idle_add(self.fail, app, error_msg)

    def succ(self, app):
        app["pbar"].set_visible(False)
        app["btn"].set_label("INSTALLED")
        app["btn"].set_name("installed-btn")

    def fail(self, app, msg):
        app["pbar"].set_visible(False)
        app["btn"].set_label("FAILED")
        app["btn"].set_sensitive(True)
        print(f"[{app['name']}] Install Failed:", msg)

if __name__ == "__main__":
    try:
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        
        win = AppStore()
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()
    except Exception as err:
        import traceback
        w = Gtk.Window()
        l = Gtk.Label(label=traceback.format_exc()); l.set_selectable(True)
        w.add(l); w.show_all(); w.connect("destroy", Gtk.main_quit)
        Gtk.main()

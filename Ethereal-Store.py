#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, sys, threading, urllib.request, json, ssl, re, time, tempfile, shutil

# --- DESIGN SYSTEM ---
CSS = b"""
window { background-color: transparent; }
#main-window {
    background: rgba(10, 12, 20, 0.95);
    border-radius: 24px;
    border: 1px solid rgba(126, 215, 255, 0.2);
    box-shadow: 0 20px 100px rgba(0,0,0,0.8);
}

.sidebar {
    background: rgba(0, 0, 0, 0.4);
    border-right: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 24px 0 0 24px;
    padding: 30px 15px;
}

.sidebar-title {
    color: #7ed7ff;
    font-size: 20px;
    font-weight: 900;
    margin-bottom: 30px;
    padding-left: 15px;
    letter-spacing: 1px;
}

list row.tab-row {
    background: transparent; color: #a0aec0;
    padding: 14px 20px; margin: 6px 10px;
    border-radius: 14px; font-weight: 600; font-size: 15px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
list row.tab-row:hover { background: rgba(255, 255, 255, 0.08); color: #ffffff; }
list row.tab-row:selected {
    background: linear-gradient(90deg, rgba(126, 215, 255, 0.2), transparent);
    color: #7ed7ff;
    border-left: 3px solid #7ed7ff;
}

.search-container { padding: 25px 40px; }
.search-bar { 
    background: rgba(255,255,255,0.06); color: white; 
    border: 1px solid rgba(255,255,255,0.1); 
    border-radius: 16px; padding: 14px 20px; font-size: 16px;
    transition: all 0.3s;
}
.search-bar:focus { 
    background: rgba(255,255,255,0.09);
    border-color: #7ed7ff; 
    box-shadow: 0 0 20px rgba(126,215,255,0.2); 
}

list.app-list { background: transparent; padding: 0 40px 40px 40px; }
list row.app-row { 
    background: rgba(255, 255, 255, 0.03); 
    border-radius: 20px;
    margin-bottom: 15px;
    border: 1px solid rgba(255,255,255,0.05);
    transition: all 0.3s;
}
list row.app-row:hover { 
    background: rgba(255, 255, 255, 0.06);
    transform: translateY(-2px);
    border-color: rgba(126, 215, 255, 0.3);
}

.app-card { padding: 20px 25px; }
.app-name { color: #f7fafc; font-size: 22px; font-weight: 800; }
.app-desc { color: #718096; font-size: 14px; margin-top: 4px; line-height: 1.4; }
.app-meta { color: #4a5568; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-top: 8px; }

.install-btn {
    background: #00ff88; color: #022c1b; font-weight: 800; 
    border-radius: 14px; padding: 10px 30px; border: none;
    transition: all 0.3s;
}
.install-btn:hover { background: #00e077; transform: scale(1.05); box-shadow: 0 0 25px rgba(0,255,136,0.3); }
.install-btn:disabled { background: rgba(255,255,255,0.1); color: #718096; }

.installed-btn {
    background: rgba(126, 215, 255, 0.1); color: #7ed7ff; 
    border: 1px solid rgba(126, 215, 255, 0.3);
    border-radius: 14px; padding: 10px 30px; font-weight: 800;
}

.failed-btn {
    background: rgba(255, 85, 85, 0.1); color: #ff5555; 
    border: 1px solid rgba(255, 85, 85, 0.3);
    border-radius: 14px; padding: 10px 30px; font-weight: 800;
}

progressbar { min-height: 6px; margin-top: 15px; }
progressbar trough { background-color: rgba(0,0,0, 0.3); border-radius: 10px; }
progressbar progress { 
    background: linear-gradient(90deg, #00ff88, #7ed7ff); 
    border-radius: 10px; 
}

.status-label { color: #7ed7ff; font-size: 12px; font-weight: 600; margin-top: 10px; }
"""

# --- APP DATABASE ---
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

class EtherealStore(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ethereal Software Center")
        self.set_default_size(1100, 750)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Transparent window support
        self.set_app_paintable(True)
        visual = self.get_screen().get_rgba_visual()
        if visual and self.get_screen().is_composited():
            self.set_visual(visual)

        # File paths
        self.app_dir = os.path.expanduser("~/Applications")
        os.makedirs(self.app_dir, exist_ok=True)
        self.shortcut_dir = os.path.expanduser("~/.local/share/applications")
        os.makedirs(self.shortcut_dir, exist_ok=True)

        # Layout
        self.main_container = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_container.set_name("main-window")
        self.add(self.main_container)

        self.setup_sidebar()
        self.setup_main_area()
        
        self.load_apps()

    def setup_sidebar(self):
        sidebar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        sidebar_box.get_style_context().add_class("sidebar")
        sidebar_box.set_size_request(240, -1)
        
        title = Gtk.Label(label="ETHEREAL")
        title.get_style_context().add_class("sidebar-title")
        title.set_xalign(0)
        sidebar_box.pack_start(title, False, False, 0)

        self.sidebar_list = Gtk.ListBox()
        self.sidebar_list.set_name("sidebar-list")
        self.sidebar_list.connect("row-activated", self.on_category_selected)
        sidebar_box.pack_start(self.sidebar_list, True, True, 0)

        categories = [
            ("🔥 Discover", "All"),
            ("🌐 Internet", "Internet"),
            ("🎮 Games", "Games"),
            ("🎬 Media", "Media"),
            ("💼 Productivity", "Productivity")
        ]

        for label, cat_id in categories:
            row = Gtk.ListBoxRow()
            row.set_name("tab-row")
            lbl = Gtk.Label(label=label, xalign=0)
            row.add(lbl)
            row.category_id = cat_id
            self.sidebar_list.add(row)

        self.main_container.pack_start(sidebar_box, False, False, 0)
        self.sidebar_list.select_row(self.sidebar_list.get_row_at_index(0))

    def setup_main_area(self):
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.main_container.pack_start(main_vbox, True, True, 0)

        # Search
        search_container = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        search_container.get_style_context().add_class("search-container")
        self.search_entry = Gtk.SearchEntry(placeholder_text="Search for applications...")
        self.search_entry.get_style_context().add_class("search-bar")
        self.search_entry.connect("search-changed", self.on_search_changed)
        search_container.pack_start(self.search_entry, True, True, 0)
        main_vbox.pack_start(search_container, False, False, 0)

        # App List Scroll
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_vbox.pack_start(scroll, True, True, 0)

        self.app_listbox = Gtk.ListBox()
        self.app_listbox.get_style_context().add_class("app-list")
        self.app_listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        scroll.add(self.app_listbox)

    def load_apps(self):
        self.app_widgets = []
        for app_data in APPS:
            row = self.create_app_row(app_data)
            self.app_listbox.add(row)
            self.app_widgets.append({"data": app_data, "row": row})
        self.show_all()

    def create_app_row(self, app):
        row = Gtk.ListBoxRow()
        row.get_style_context().add_class("app-row")

        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        card.get_style_context().add_class("app-card")
        
        # Icon
        icon_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        icon_img = Gtk.Image.new_from_icon_name(app.get("icon", "system-software-install"), Gtk.IconSize.DIALOG)
        icon_img.set_pixel_size(54)
        icon_box.pack_start(icon_img, True, True, 0)
        card.pack_start(icon_box, False, False, 15)

        # Info
        info_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        info_vbox.set_valign(Gtk.Align.CENTER)
        
        name_label = Gtk.Label(label=app["name"], xalign=0)
        name_label.get_style_context().add_class("app-name")
        
        desc_label = Gtk.Label(label=app["desc"], xalign=0)
        desc_label.get_style_context().add_class("app-desc")
        desc_label.set_line_wrap(True)
        desc_label.set_max_width_chars(60)

        meta_label = Gtk.Label(label=f"Category: {app['cat']} | Source: GitHub", xalign=0)
        meta_label.get_style_context().add_class("app-meta")

        # Progress elements
        pbar = Gtk.ProgressBar()
        pbar.set_visible(False)
        app["pbar_widget"] = pbar

        status_label = Gtk.Label(label="", xalign=0)
        status_label.get_style_context().add_class("status-label")
        status_label.set_visible(False)
        app["status_widget"] = status_label

        info_vbox.pack_start(name_label, False, False, 0)
        info_vbox.pack_start(desc_label, False, False, 0)
        info_vbox.pack_start(meta_label, False, False, 0)
        info_vbox.pack_start(pbar, False, False, 10)
        info_vbox.pack_start(status_label, False, False, 0)
        
        card.pack_start(info_vbox, True, True, 10)

        # Action Button
        btn_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        btn_box.set_valign(Gtk.Align.CENTER)
        
        btn = Gtk.Button()
        desktop_file = os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")
        
        if os.path.exists(desktop_file):
            btn.set_label("INSTALLED")
            btn.get_style_context().add_class("installed-btn")
            btn.set_sensitive(False)
        else:
            btn.set_label("INSTALL")
            btn.get_style_context().add_class("install-btn")
            btn.connect("clicked", self.start_install, app)
        
        app["btn_widget"] = btn
        btn_box.pack_start(btn, False, False, 0)
        card.pack_end(btn_box, False, False, 10)

        row.add(card)
        return row

    def on_category_selected(self, listbox, row):
        self.apply_filters()

    def on_search_changed(self, entry):
        self.apply_filters()

    def apply_filters(self):
        selected_row = self.sidebar_list.get_selected_row()
        category = selected_row.category_id if selected_row else "All"
        search_term = self.search_entry.get_text().lower()

        for item in self.app_widgets:
            app = item["data"]
            match_cat = (category == "All" or app["cat"] == category)
            match_search = (search_term in app["name"].lower() or search_term in app["desc"].lower())
            
            if match_cat and match_search:
                item["row"].show()
            else:
                item["row"].hide()

    def start_install(self, btn, app):
        btn.set_sensitive(False)
        btn.set_label("WORKING...")
        app["pbar_widget"].set_visible(True)
        app["status_widget"].set_visible(True)
        app["status_widget"].set_text("Locating package...")
        
        thread = threading.Thread(target=self.installer_thread, args=(app,), daemon=True)
        thread.start()

    def installer_thread(self, app):
        try:
            # Setup context
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            headers = {'User-Agent': 'Ethereal-Store/2.0'}

            repo = app["repo"]
            api_url = f"https://api.github.com/repos/{repo}/releases/latest"
            
            GLib.idle_add(app["status_widget"].set_text, "Checking GitHub...")
            
            try:
                req = urllib.request.Request(api_url, headers=headers)
                with urllib.request.urlopen(req, timeout=15, context=ctx) as response:
                    data = json.loads(response.read().decode())
                    assets = data.get("assets", [])
            except Exception as api_err:
                print(f"API Error: {api_err}")
                assets = [] # Fallback will handle

            dl_url = None
            filename = None

            # Better Matching Logic
            patterns = [
                r".*x86_64.*\.AppImage$",
                r".*amd64.*\.AppImage$",
                r".*\.AppImage$"
            ]

            for pattern in patterns:
                for asset in assets:
                    name = asset.get("name", "")
                    if re.match(pattern, name, re.IGNORECASE):
                        if "arm" in name.lower() or "aarch" in name.lower(): continue
                        dl_url = asset.get("browser_download_url")
                        filename = name
                        break
                if dl_url: break

            if not dl_url:
                # Last resort fallback URL construction
                GLib.idle_add(app["status_widget"].set_text, "Using fallback URL...")
                tag = data.get("tag_name", "latest") if 'data' in locals() else "latest"
                repo_name = repo.split("/")[-1]
                dl_url = f"https://github.com/{repo}/releases/download/{tag}/{repo_name}-{tag}-x86_64.AppImage"
                filename = f"{repo_name}.AppImage"

            GLib.idle_add(app["status_widget"].set_text, f"Downloading {filename}...")
            
            # Atomic download: use a temporary file first
            temp_fd, temp_path = tempfile.mkstemp(dir=self.app_dir, suffix=".AppImage.tmp")
            os.close(temp_fd)
            
            try:
                # Download Logic
                req_dl = urllib.request.Request(dl_url, headers=headers)
                with urllib.request.urlopen(req_dl, timeout=120, context=ctx) as response:
                    total_size = int(response.headers.get('Content-Length', 0))
                    downloaded = 0
                    with open(temp_path, 'wb') as f:
                        while True:
                            chunk = response.read(65536)
                            if not chunk: break
                            f.write(chunk)
                            downloaded += len(chunk)
                            if total_size > 0:
                                pct = downloaded / total_size
                                GLib.idle_add(app["pbar_widget"].set_fraction, pct)
                
                # Verify download size if possible
                if total_size > 0 and downloaded < total_size:
                    raise Exception("Download interrupted: incomplete file")
                    
                # Atomic move to final destination
                save_path = os.path.join(self.app_dir, filename)
                shutil.move(temp_path, save_path)
            except Exception as dl_err:
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                raise dl_err

            # Post Install
            os.chmod(save_path, 0o755)
            GLib.idle_add(app["status_widget"].set_text, "Creating shortcuts...")
            
            # Desktop File
            desktop_content = f"""[Desktop Entry]
Name={app['name']}
Comment={app['desc']}
Exec={save_path}
Icon={app.get('icon', 'system-software-install')}
Terminal=false
Type=Application
Categories={app['cat']};
Keywords=Ethereal;App;
"""
            d_path = os.path.join(self.shortcut_dir, f"ethereal_{app['id']}.desktop")
            with open(d_path, 'w') as f:
                f.write(desktop_content)
            os.chmod(d_path, 0o755)
            
            GLib.idle_add(self.on_install_success, app)
            
        except Exception as e:
            GLib.idle_add(self.on_install_failed, app, str(e))

    def on_install_success(self, app):
        app["pbar_widget"].set_visible(False)
        app["status_widget"].set_text("Installation Complete!")
        app["btn_widget"].set_label("INSTALLED")
        app["btn_widget"].get_style_context().remove_class("install-btn")
        app["btn_widget"].get_style_context().add_class("installed-btn")
        app["btn_widget"].set_sensitive(False)

    def on_install_failed(self, app, error):
        print(f"FAILED: {error}")
        app["pbar_widget"].set_visible(False)
        # Show specific error in status and tooltip
        err_short = error[:50] + ("..." if len(error) > 50 else "")
        app["status_widget"].set_text(f"Error: {err_short}")
        app["btn_widget"].set_label("RETRY")
        app["btn_widget"].set_tooltip_text(f"Full Error: {error}")
        app["btn_widget"].get_style_context().remove_class("install-btn")
        app["btn_widget"].get_style_context().add_class("failed-btn")
        app["btn_widget"].set_sensitive(True)

if __name__ == "__main__":
    style_provider = Gtk.CssProvider()
    style_provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        style_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    win = EtherealStore()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

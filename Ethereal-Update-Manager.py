#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, sys, threading, subprocess, time

# --- DESIGN SYSTEM ---
CSS = b"""
window { background-color: transparent; }
#main-window {
    background: rgba(10, 12, 20, 0.98);
    border-radius: 28px;
    border: 1px solid rgba(126, 215, 255, 0.15);
    box-shadow: 0 25px 80px rgba(0,0,0,0.9);
}

.header { padding: 40px; }
.title { color: #7ed7ff; font-size: 28px; font-weight: 900; letter-spacing: 1px; }
.subtitle { color: #718096; font-size: 14px; margin-top: 5px; }

.step-card {
    background: rgba(255, 255, 255, 0.03);
    border-radius: 18px;
    margin: 0 40px 10px 40px;
    padding: 18px 25px;
    border: 1px solid rgba(255, 255, 255, 0.05);
    transition: all 0.3s;
}
.step-card.active {
    background: rgba(126, 215, 255, 0.08);
    border-color: rgba(126, 215, 255, 0.3);
}
.step-card.done { opacity: 0.6; }

.step-name { color: #f7fafc; font-size: 16px; font-weight: 700; }
.step-status { color: #7ed7ff; font-size: 12px; font-weight: 600; text-transform: uppercase; }

.progress-container { padding: 30px 40px; }
progressbar trough { background-color: rgba(0,0,0, 0.4); border-radius: 12px; min-height: 10px; }
progressbar progress { 
    background: linear-gradient(90deg, #00f2fe, #4facfe); 
    border-radius: 12px; 
}

.log-container {
    background: rgba(0, 0, 0, 0.3);
    margin: 20px 40px 40px 40px;
    padding: 15px;
    border-radius: 16px;
    border: 1px solid rgba(255, 255, 255, 0.05);
}
textview text { background-color: transparent; color: #a0aec0; font-family: 'Monospace'; font-size: 12px; }

.start-btn {
    background: linear-gradient(135deg, #00f2fe 0%, #4facfe 100%);
    color: #000; font-weight: 900; 
    border-radius: 16px; padding: 15px 40px; border: none;
    font-size: 16px; transition: all 0.3s;
}
.start-btn:hover { transform: scale(1.02); box-shadow: 0 0 30px rgba(79, 172, 254, 0.4); }
.start-btn:disabled { background: rgba(255,255,255,0.1); color: #4a5568; }
"""

class UpdateStep:
    def __init__(self, id, name, arg):
        self.id = id
        self.name = name
        self.arg = arg
        self.status = "Pending"
        self.widget = None
        self.status_label = None

class EtherealUpdateManager(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ethereal Update Center")
        self.set_default_size(900, 700)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Transparent window setup
        self.set_app_paintable(True)
        visual = self.get_screen().get_rgba_visual()
        if visual and self.get_screen().is_composited():
            self.set_visual(visual)

        self.steps = [
            UpdateStep(1, "🌍 Verify Connection", "--network"),
            UpdateStep(2, "⚙️ Environment Check", "--env"),
            UpdateStep(3, "⬇️ Pull Latest Patches", "--pull"),
            UpdateStep(4, "🔧 Install Core Scripts", "--scripts"),
            UpdateStep(5, "🧹 Cleanup Desktop", "--clean"),
            UpdateStep(6, "📂 Deploy New Launchers", "--deploy"),
            UpdateStep(7, "🎨 Update Icons & Fonts", "--icons"),
            UpdateStep(8, "🛡️ System Polish & Theme", "--polish")
        ]

        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.main_box.set_name("main-window")
        self.add(self.main_box)

        self.setup_ui()

    def setup_ui(self):
        # Header
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        header.get_style_context().add_class("header")
        
        title = Gtk.Label(label="Ethereal Update Center")
        title.get_style_context().add_class("title")
        title.set_xalign(0)
        
        subtitle = Gtk.Label(label="Modular system updates and performance patches")
        subtitle.get_style_context().add_class("subtitle")
        subtitle.set_xalign(0)
        
        header.pack_start(title, False, False, 0)
        header.pack_start(subtitle, False, False, 0)
        self.main_box.pack_start(header, False, False, 0)

        # Steps List
        self.steps_listbox = Gtk.ListBox()
        self.steps_listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        self.steps_listbox.set_background_color = Gdk.RGBA(0,0,0,0)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.add(self.steps_listbox)
        self.main_box.pack_start(scroll, True, True, 10)

        for step in self.steps:
            row = self.create_step_row(step)
            self.steps_listbox.add(row)

        # Progress
        progress_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        progress_box.get_style_context().add_class("progress-container")
        
        self.overall_progress = Gtk.ProgressBar()
        self.overall_progress.set_fraction(0.0)
        progress_box.pack_start(self.overall_progress, False, False, 0)
        
        self.main_box.pack_start(progress_box, False, False, 0)

        # Actions
        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        actions.set_center_widget(None)
        actions.set_margin_bottom(30)
        
        self.start_btn = Gtk.Button(label="START SYSTEM UPDATE")
        self.start_btn.get_style_context().add_class("start-btn")
        self.start_btn.connect("clicked", self.on_start_clicked)
        
        btn_box = Gtk.Box()
        btn_box.set_center_widget(self.start_btn)
        self.main_box.pack_start(btn_box, False, False, 20)

    def create_step_row(self, step):
        row = Gtk.ListBoxRow()
        row.get_style_context().add_class("step-card")
        
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        
        name_label = Gtk.Label(label=step.name, xalign=0)
        name_label.get_style_context().add_class("step-name")
        
        status_label = Gtk.Label(label=step.status, xalign=1)
        status_label.get_style_context().add_class("step-status")
        
        box.pack_start(name_label, True, True, 0)
        box.pack_end(status_label, False, False, 0)
        
        row.add(box)
        step.widget = row
        step.status_label = status_label
        return row

    def on_start_clicked(self, btn):
        self.start_btn.set_sensitive(False)
        self.start_btn.set_label("UPDATING SYSTEM...")
        thread = threading.Thread(target=self.run_update, daemon=True)
        thread.start()

    def run_update(self):
        total_steps = len(self.steps)
        for i, step in enumerate(self.steps):
            GLib.idle_add(self.update_step_ui, step, "Working", True)
            
            # Execute the modular bash script step
            cmd = ["bash", "/usr/local/bin/Ethereal-Update.sh", step.arg]
            # If not in /usr/local/bin yet (first run), use local
            if not os.path.exists("/usr/local/bin/Ethereal-Update.sh"):
                cmd = ["bash", "Ethereal-Update.sh", step.arg]
                
            try:
                process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                stdout, stderr = process.communicate()
                
                if process.returncode == 0:
                    GLib.idle_add(self.update_step_ui, step, "Done", False)
                else:
                    GLib.idle_add(self.update_step_ui, step, "Error", False)
                    GLib.idle_add(self.show_error, f"Step '{step.name}' failed:\n{stderr}")
                    return
            except Exception as e:
                GLib.idle_add(self.show_error, str(e))
                return

            GLib.idle_add(self.overall_progress.set_fraction, (i+1) / total_steps)
            time.sleep(0.5)

        GLib.idle_add(self.finish_update)

    def update_step_ui(self, step, status, active):
        step.status_label.set_text(status)
        if active:
            step.widget.get_style_context().add_class("active")
        else:
            step.widget.get_style_context().remove_class("active")
            step.widget.get_style_context().add_class("done")

    def show_error(self, msg):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text="Update Failed",
        )
        dialog.format_secondary_text(msg)
        dialog.run()
        dialog.destroy()
        self.start_btn.set_sensitive(True)
        self.start_btn.set_label("RETRY UPDATE")

    def finish_update(self):
        self.start_btn.set_label("SYSTEM UP TO DATE")
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="Update Complete",
        )
        dialog.format_secondary_text("EtherealOS has been successfully updated to the latest version.")
        dialog.run()
        dialog.destroy()

if __name__ == "__main__":
    style_provider = Gtk.CssProvider()
    style_provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        style_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    win = EtherealUpdateManager()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

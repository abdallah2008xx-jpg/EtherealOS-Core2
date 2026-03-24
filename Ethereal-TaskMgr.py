#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os, glob, cairo, time, math, subprocess

CSS = b"""
window { background-color: transparent; }
#main-bg {
    background-color: rgba(12, 14, 25, 0.95);
    border-radius: 20px;
    border: 1px solid rgba(126, 215, 255, 0.25);
    box-shadow: 0 15px 50px rgba(0,0,0,0.9);
}
.sidebar {
    background-color: rgba(0, 0, 0, 0.5);
    border-right: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 20px 0 0 20px;
    padding: 15px 5px;
}
list row.tab-row {
    background: transparent; color: #8892b0;
    padding: 14px 20px; margin: 4px 10px;
    border-radius: 12px; font-weight: bold; font-size: 14px;
    transition: all 250ms ease;
}
list row.tab-row:hover { background: rgba(255, 255, 255, 0.05); color: #ffffff; }
list row.tab-row:selected {
    background: rgba(126, 215, 255, 0.15);
    color: #7ed7ff; border-left: 4px solid #7ed7ff;
}

/* Processes Data Grid */
.header-row {
    color: #a3b2fa; font-weight: bold; font-size: 13px;
    padding: 12px 16px; border-bottom: 2px solid rgba(255,255,255,0.08);
}
.process-card {
    background-color: transparent; border-radius: 8px;
    margin: 3px 12px; padding: 10px 16px;
    border-bottom: 1px solid rgba(255,255,255,0.02);
    transition: all 200ms ease;
}
.process-card:hover { background-color: rgba(255, 255, 255, 0.06); }
.proc-title { color: #ffffff; font-weight: bold; font-size: 13px; }
.proc-sub { color: #8892b0; font-size: 12px; }

.val-safe { color: #00ff88; font-weight: bold; }
.val-warn { color: #ffaa00; font-weight: bold; }
.val-crit { color: #ff3333; font-weight: bold; text-shadow: 0 0 10px rgba(255, 50, 50, 0.6); }

button.kill-btn {
    background: transparent; color: #ff5555; border-radius: 8px;
    border: 1px solid rgba(255, 80, 80, 0.4); padding: 5px 12px;
    font-weight: bold; transition: all 200ms;
}
button.kill-btn:hover { background: rgba(255, 80, 80, 0.9); color: white; box-shadow: 0 0 15px rgba(255,80,80,0.5); }

/* Giant Performance Dashboards */
.dash-title { color: #ffffff; font-size: 38px; font-weight: 800; text-shadow: 0 0 20px rgba(126, 215, 255, 0.3); }
.dash-subtitle { color: #8892b0; font-size: 18px; font-weight: 300; margin-bottom: 20px; }
.dash-box {
    background-color: rgba(0, 0, 0, 0.3);
    border: 1px solid rgba(255,255,255,0.05);
    border-radius: 16px; padding: 25px; margin: 10px 20px;
}
.dash-stat-title { color: #a3b2fa; font-size: 14px; }
.dash-stat-val { color: #ffffff; font-size: 28px; font-weight: bold; margin-top: 5px; }

/* Startup Apps */
.startup-card {
    background-color: rgba(255,255,255,0.03); border-radius: 12px;
    margin: 8px 20px; padding: 18px; border-left: 4px solid #7ed7ff;
    transition: all 200ms;
}
.startup-card:hover { background-color: rgba(255,255,255,0.06); }
switch { background: #333; border-radius: 14px; min-width: 50px; }
switch:checked { background: #00ff88; box-shadow: 0 0 15px rgba(0,255,136,0.3); }
"""

# CSS is loaded inside __main__ to ensure exceptions are caught.

class SysTracker:
    def __init__(self):
        self.procs = {}; self.last_total_cpu = self.get_total_cpu()
        self.gpu_name = self.get_gpu_name()
    def get_total_cpu(self):
        try:
            with open('/proc/stat') as f: return sum([float(c) for c in f.readline().strip().split()[1:]])
        except: return 0
    def get_gpu_name(self):
        try:
            out = subprocess.check_output("lspci | grep -i vga", shell=True).decode()
            return out.split(':')[-1].strip().split('(')[0][:30]
        except: return "Unknown GPU"
    def get_disk_usage(self):
        try:
            st = os.statvfs('/')
            total = st.f_blocks * st.f_frsize
            free = st.f_bavail * st.f_frsize
            return total - free, total
        except: return 0, 1
    def update(self):
        cur_total = self.get_total_cpu(); delta = cur_total - self.last_total_cpu
        self.last_total_cpu = cur_total
        sys_cpu = 0
        try:
            with open('/proc/stat') as f: idle = float(f.readline().strip().split()[4])
            if hasattr(self, 'last_idle'):
                sys_cpu = 100.0 * (1.0 - (idle - self.last_idle) / delta) if delta > 0 else 0
            self.last_idle = idle
        except: pass
        
        mem_tot, mem_avail = 1, 0
        try:
            with open('/proc/meminfo') as f:
                for line in f:
                    if line.startswith("MemTotal:"): mem_tot = int(line.split()[1])
                    if line.startswith("MemAvailable:"): mem_avail = int(line.split()[1])
        except: pass
        
        cur_procs = {}
        for pidf in glob.glob('/proc/[0-9]*'):
            pid = os.path.basename(pidf)
            try:
                with open(pidf + '/stat') as f: stat = f.read().split()
                name = stat[1][1:-1]; utime, stime = float(stat[13]), float(stat[14])
                total_time = utime + stime; rss_kb = int(stat[23]) * 4
                cpu_p = 0.0
                if pid in self.procs and delta > 0:
                    cpu_p = 100.0 * (total_time - self.procs[pid]['time']) / delta
                cur_procs[pid] = {'pid': pid, 'name': name[:20], 'time': total_time, 'cpu': cpu_p, 'mem_kb': rss_kb}
            except: pass
            
        self.procs = cur_procs
        output = [p for p in self.procs.values() if p['mem_kb'] > 1000]
        output.sort(key=lambda x: (x['cpu'], x['mem_kb']), reverse=True)
        return output, sys_cpu, mem_tot, mem_tot - mem_avail

class MassiveLiveGraph(Gtk.DrawingArea):
    def __init__(self, c_top, c_bot):
        super().__init__()
        self.set_size_request(-1, 280); self.history = [0.0]*100; self.phase = 0.0
        self.c_top = c_top; self.c_bot = c_bot
        GLib.timeout_add(30, self.tick)
    def add_point(self, val):
        self.history.pop(0); self.history.append(val)
    def tick(self):
        self.phase += 0.08; self.queue_draw(); return True
    def do_draw(self, cr):
        w, h = self.get_allocated_width(), self.get_allocated_height()
        cr.set_source_rgba(0,0,0,0); cr.paint()
        pat = cairo.LinearGradient(0, 0, 0, h)
        pat.add_color_stop_rgba(0, *self.c_top); pat.add_color_stop_rgba(1, *self.c_bot)
        cr.move_to(0, h); step = w / (len(self.history) - 1)
        
        # Grid lines
        cr.set_source_rgba(255,255,255,0.05)
        for i in range(1, 5):
            cr.move_to(0, h * (i/5)); cr.line_to(w, h * (i/5)); cr.stroke()
            
        for i, val in enumerate(self.history):
            y = h - (val / 100.0 * h) + math.sin(self.phase + i*0.1) * 3.0
            cr.line_to(i * step, max(0, min(h, y)))
        cr.line_to(w, h); cr.close_path(); cr.set_source(pat); cr.fill()
        
        cr.set_line_width(3.0); cr.set_source_rgba(*self.c_top[:3], 1.0); cr.move_to(0, h)
        for i, val in enumerate(self.history):
            y = h - (val / 100.0 * h) + math.sin(self.phase + i*0.1) * 3.0
            cr.line_to(i * step, max(0, min(h, y)))
        cr.stroke()

class TaskManager(Gtk.Window):
    def __init__(self):
        super().__init__(title="EtherealOS Task Manager")
        self.set_default_size(1050, 750); self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        if self.get_screen().get_rgba_visual() and self.get_screen().is_composited():
            self.set_visual(self.get_screen().get_rgba_visual())

        self.tracker = SysTracker()
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_box.set_name("main-bg"); self.add(self.main_box)

        # Tab Sidebar
        self.sidebar = Gtk.ListBox(); self.sidebar.set_name("sidebar"); self.sidebar.set_size_request(240, -1)
        self.sidebar.connect("row-activated", self.on_tab_changed)
        self.main_box.pack_start(self.sidebar, False, False, 0)
        
        # Each item is its OWN FULL PAGE NOW!
        self.tabs = [
            ("🧩 Processes", "processes"),
            ("⚙️ CPU Processor", "cpu"),
            ("🧠 RAM Memory", "ram"),
            ("💽 SSD Storage", "disk"),
            ("📺 GPU Graphics", "gpu"),
            ("🚀 Startup Apps", "startup")
        ]
        
        for lbl, name in self.tabs:
            r = Gtk.ListBoxRow(); r.set_name("tab-row")
            r.add(Gtk.Label(label=lbl, xalign=0)); self.sidebar.add(r)

        self.stack = Gtk.Stack(); self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(350)
        self.main_box.pack_start(self.stack, True, True, 0)

        self.build_processes_page()
        self.build_dashboard_cpu()
        self.build_dashboard_ram()
        self.build_dashboard_disk()
        self.build_dashboard_gpu()
        self.build_startup_page()

        self.sidebar.select_row(self.sidebar.get_row_at_index(0))
        self.update_data()
        GLib.timeout_add(1500, self.update_data)

    def on_tab_changed(self, lb, row):
        self.stack.set_visible_child_name(self.tabs[row.get_index()][1])

    # --- PROCESSES PAGE ---
    def build_processes_page(self):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        # Giant header for process page
        hdr = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        hdr.set_margin_top(20); hdr.set_margin_left(20); hdr.set_margin_bottom(10)
        t = Gtk.Label(label="Processes", xalign=0); t.set_name("dash-title")
        s = Gtk.Label(label="Live view of everything running on EtherealOS", xalign=0); s.set_name("dash-subtitle")
        hdr.pack_start(t, False, False, 0); hdr.pack_start(s, False, False, 0)
        vbox.pack_start(hdr, False, False, 0)

        # table headers
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); hbox.set_name("header-row")
        for text, w, align in [("Name", 250, 0), ("PID", 80, 0), ("CPU %", 100, 1), ("Memory", 120, 1), ("Action", 100, 1)]:
            l = Gtk.Label(label=text); l.set_xalign(align); l.set_size_request(w, -1)
            hbox.pack_start(l, text=="Name", text=="Name", 0)
        vbox.pack_start(hbox, False, False, 0)
        sys_scroll = Gtk.ScrolledWindow(); sys_scroll.set_vexpand(True)
        self.proc_list = Gtk.ListBox(); self.proc_list.set_selection_mode(Gtk.SelectionMode.NONE)
        sys_scroll.add(self.proc_list)
        vbox.pack_start(sys_scroll, True, True, 0)
        self.stack.add_named(vbox, "processes")

    # --- GIANT DASHBOARD FACTORY ---
    def create_giant_dashboard(self, page_id, title_text, sub_text, graph_c_top, graph_c_bot):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        
        # Header
        hdr = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        hdr.set_margin_top(30); hdr.set_margin_left(20); hdr.set_margin_bottom(20)
        t = Gtk.Label(label=title_text, xalign=0); t.set_name("dash-title")
        s = Gtk.Label(label=sub_text, xalign=0); s.set_name("dash-subtitle")
        hdr.pack_start(t, False, False, 0); hdr.pack_start(s, False, False, 0)
        
        # Giant Graph
        graph = MassiveLiveGraph(graph_c_top, graph_c_bot)
        
        # Giant Stats Box
        stats_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=80)
        stats_box.set_name("dash-box")
        
        def add_stat(label):
            b = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            l1 = Gtk.Label(label=label, xalign=0); l1.set_name("dash-stat-title")
            v1 = Gtk.Label(label="0", xalign=0); v1.set_name("dash-stat-val")
            b.pack_start(l1, False, False, 0); b.pack_start(v1, False, False, 0)
            stats_box.pack_start(b, False, False, 0)
            return v1
        
        v1 = add_stat("Primary Stat")
        v2 = add_stat("Secondary Stat")
        
        vbox.pack_start(hdr, False, False, 0)
        vbox.pack_start(graph, True, True, 10)
        vbox.pack_start(stats_box, False, False, 20)
        
        self.stack.add_named(vbox, page_id)
        return graph, v1, v2, stats_box

    def build_dashboard_cpu(self):
        self.gr_cpu, self.st_cpu_util, self.st_cpu_up, stats_box = self.create_giant_dashboard(
            "cpu", "CPU Processor", "Central Processing Unit Usage",
            (0.49, 0.84, 1.0, 0.8), (0.1, 0.1, 0.3, 0.2)
        )
        stats_box.get_children()[0].get_children()[0].set_text("Utilization")
        stats_box.get_children()[1].get_children()[0].set_text("System Uptime")

    def build_dashboard_ram(self):
        self.gr_ram, self.st_ram_use, self.st_ram_tot, stats_box = self.create_giant_dashboard(
            "ram", "RAM Memory", "Random Access Memory Consumption",
            (0.8, 0.4, 1.0, 0.8), (0.3, 0.1, 0.4, 0.2)
        )
        stats_box.get_children()[0].get_children()[0].set_text("In Use")
        stats_box.get_children()[1].get_children()[0].set_text("Total Installed")

    def build_dashboard_disk(self):
        self.gr_disk, self.st_disk_used, self.st_disk_tot, stats_box = self.create_giant_dashboard(
            "disk", "SSD / Disk Drive", "System Root Partition Storage",
            (0.0, 1.0, 0.5, 0.8), (0.0, 0.3, 0.1, 0.2)
        )
        stats_box.get_children()[0].get_children()[0].set_text("Space Used")
        stats_box.get_children()[1].get_children()[0].set_text("Total Capacity")

    def build_dashboard_gpu(self):
        self.gr_gpu, self.st_gpu_name, self.st_gpu_status, stats_box = self.create_giant_dashboard(
            "gpu", "GPU Graphics", "Graphics Processing Unit",
            (1.0, 0.6, 0.2, 0.8), (0.4, 0.2, 0.0, 0.2)
        )
        stats_box.get_children()[0].get_children()[0].set_text("Adapter")
        stats_box.get_children()[1].get_children()[0].set_text("Status")

    # --- STARTUP APPS PAGE ---
    def build_startup_page(self):
        scroll = Gtk.ScrolledWindow()
        self.startup_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        
        hdr = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        hdr.set_margin_top(30); hdr.set_margin_left(20); hdr.set_margin_bottom(20)
        t = Gtk.Label(label="Startup Engine", xalign=0); t.set_name("dash-title")
        s = Gtk.Label(label="Manage what boots alongside your system", xalign=0); s.set_name("dash-subtitle")
        hdr.pack_start(t, False, False, 0); hdr.pack_start(s, False, False, 0)
        self.startup_vbox.pack_start(hdr, False, False, 0)
        
        scroll.add(self.startup_vbox); self.stack.add_named(scroll, "startup")
        self.load_startup_apps()

    def load_startup_apps(self):
        adir = os.path.expanduser('~/.config/autostart')
        if not os.path.exists(adir): return
        for f in os.listdir(adir):
            if f.endswith('.desktop'):
                path = os.path.join(adir, f)
                name, enabled = f, True
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
                        cont = fp.read()
                        if 'Hidden=true' in cont or 'X-GNOME-Autostart-enabled=false' in cont: enabled = False
                        for line in cont.splitlines():
                            if line.startswith('Name='): name = line[5:]
                    
                    card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); card.set_name("startup-card")
                    lbl = Gtk.Label(label=name); lbl.set_name("dash-stat-val"); lbl.set_xalign(0); lbl.set_margin_bottom(5)
                    sub = Gtk.Label(label=f"File: {f}"); sub.set_name("proc-sub"); sub.set_xalign(0)
                    v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
                    v.pack_start(lbl, False, False, 0); v.pack_start(sub, False, False, 0)
                    sw = Gtk.Switch(); sw.set_active(enabled); sw.set_valign(Gtk.Align.CENTER)
                    sw.connect("notify::active", self.on_startup_toggle, path)
                    card.pack_start(v, True, True, 0); card.pack_end(sw, False, False, 10)
                    self.startup_vbox.pack_start(card, False, False, 0)
                except Exception as e:
                    pass
        self.startup_vbox.show_all()

    def on_startup_toggle(self, switch, gparam, filepath):
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f: lines = f.readlines()
            out = [l for l in lines if not l.startswith('Hidden=') and not l.startswith('X-GNOME-Autostart-enabled=')]
            if not switch.get_active(): out.extend(["Hidden=true\n", "X-GNOME-Autostart-enabled=false\n"])
            with open(filepath, 'w', encoding='utf-8') as f: f.writelines(out)
        except Exception as e: print(e)

    # --- UPDATER ---
    def update_data(self):
        try:
            procs, cpu_pct, mem_tot, mem_used = self.tracker.update()
            cur_page = self.stack.get_visible_child_name()
            
            # Always update graphs so they don't break
            self.gr_cpu.add_point(cpu_pct)
            mem_pct = (mem_used / mem_tot) * 100.0 if mem_tot > 0 else 0
            self.gr_ram.add_point(mem_pct)
            disk_used, disk_tot = self.tracker.get_disk_usage()
            disk_pct = (disk_used / disk_tot) * 100.0 if disk_tot > 0 else 0
            self.gr_disk.add_point(disk_pct)
            self.gr_gpu.add_point(20) # Auto wave
            
            # CPU
            if cur_page == "cpu":
                self.st_cpu_util.set_text(f"{cpu_pct:.1f} %")
                try:
                    with open('/proc/uptime', 'r') as f: 
                        t = int(float(f.readline().split()[0]))
                        self.st_cpu_up.set_text(f"{t//3600}:{(t%3600)//60:02d}:{t%60:02d}")
                except:
                    t = int(time.clock_gettime(time.CLOCK_BOOTTIME))
                    self.st_cpu_up.set_text(f"{t//3600}:{(t%3600)//60:02d}:{t%60:02d}")
                
            # RAM
            if cur_page == "ram":
                self.st_ram_use.set_text(f"{(mem_used/1024/1024):.1f} GB ({mem_pct:.0f}%)")
                self.st_ram_tot.set_text(f"{(mem_tot/1024/1024):.1f} GB Installed")
                
            # Disk
            if cur_page == "disk":
                self.st_disk_used.set_text(f"{(disk_used/1024/1024/1024):.1f} GB ({disk_pct:.0f}%)")
                self.st_disk_tot.set_text(f"{(disk_tot/1024/1024/1024):.1f} GB Capacity")
                
            # GPU
            if cur_page == "gpu":
                self.st_gpu_name.set_text(self.tracker.gpu_name)
                self.st_gpu_status.set_text("Active & Running")
                
            # Processes Grid
            if cur_page == "processes":
                for row in self.proc_list.get_children(): self.proc_list.remove(row)
                for p in procs[:40]:
                    row = Gtk.ListBoxRow(); row.override_background_color(Gtk.StateFlags.NORMAL, Gdk.RGBA(0,0,0,0))
                    box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); box.set_name("process-card")
                    
                    ln = Gtk.Label(label=p['name']); ln.set_name("proc-title"); ln.set_xalign(0); ln.set_size_request(250, -1)
                    lp = Gtk.Label(label=str(p['pid'])); lp.set_name("proc-sub"); lp.set_xalign(0); lp.set_size_request(80, -1)
                    lc = Gtk.Label(label=f"{p['cpu']:.1f}%"); lc.set_xalign(1); lc.set_size_request(100, -1)
                    lc.set_name("val-crit" if p['cpu'] > 20 else "val-warn" if p['cpu'] > 5 else "val-safe")
                    lm = Gtk.Label(label=f"{(p['mem_kb']/1024.0):.1f} MB"); lm.set_xalign(1); lm.set_size_request(120, -1)
                    lm.set_name("val-crit" if p['mem_kb']/1024.0 > 1000 else "val-warn" if p['mem_kb']/1024.0 > 400 else "val-safe")
                    
                    bb = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL); bb.set_size_request(100, -1)
                    btn = Gtk.Button(label="End Task"); btn.set_name("kill-btn"); btn.set_halign(Gtk.Align.END)
                    btn.connect("clicked", lambda b,pid=p['pid'],bx=box,rw=row: [bx.get_style_context().add_class("killed"), GLib.timeout_add(150, lambda: os.kill(int(pid), 9) or self.proc_list.remove(rw) and False)])
                    bb.pack_end(btn, False, False, 0)
                    
                    box.pack_start(ln, True, True, 0); box.pack_start(lp, False, False, 0)
                    box.pack_start(lc, False, False, 0); box.pack_start(lm, False, False, 0)
                    box.pack_start(bb, False, False, 0)
                    row.add(box); self.proc_list.add(row)
                self.proc_list.show_all()
        except Exception as e:
            print("Ethereal-TaskMgr Error:", e)
        return True

if __name__ == "__main__":
    try:
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        
        win = TaskManager()
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()
    except Exception as fatal_error:
        import traceback
        err_msg = traceback.format_exc()
        
        err_win = Gtk.Window(title="Task Manager Crash Reporter")
        err_win.set_default_size(600, 400)
        
        scroll = Gtk.ScrolledWindow()
        l = Gtk.Label(label=f"Fatal Initialization Error:\n\n{err_msg}")
        l.set_selectable(True)
        l.set_halign(Gtk.Align.START)
        scroll.add(l)
        err_win.add(scroll)
        
        err_win.show_all()
        err_win.connect("destroy", Gtk.main_quit)
        Gtk.main()

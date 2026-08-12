"""Map a bare X11 window carrying WM_WINDOW_ROLE=Deskterm.

Stand-in for gnome-terminal in the containerized smoke test (see
container_smoke.sh) - gnome-terminal needs a D-Bus session, which the
throwaway container doesn't have. The role property must be set before the
window is mapped so devilspie2 sees it on the window-open event.
"""

from __future__ import annotations

import time

from Xlib import X, Xatom, display

d = display.Display()
screen = d.screen()
window = screen.root.create_window(
    0,
    0,
    320,
    240,
    0,
    screen.root_depth,
    X.InputOutput,
    X.CopyFromParent,
    background_pixel=screen.white_pixel,
)
window.set_wm_name("deskterm-e2e")
window.set_wm_class("deskterm-e2e", "Deskterm")
window.change_property(d.intern_atom("WM_WINDOW_ROLE"), Xatom.STRING, 8, b"Deskterm")
window.map()
d.flush()
time.sleep(60)

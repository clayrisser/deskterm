-- deskterm devilspie2 rule: pin the terminal window with the X window role
-- "Deskterm" as the desktop background (positioned at the origin, maximized,
-- visible on all workspaces).
if get_window_role() == "Deskterm" then
	set_window_position(0, 0)
	maximize()
	set_window_type("WINDOW_TYPE_DESKTOP")
	pin_window()
	focus_window()
end

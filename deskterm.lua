debug_print(get_screen_geometry());

if (get_application_name()=="Terminal") then
	if (get_window_role()=="Deskterm") then
		undecorate_window();
		set_window_position2(0, 0);
		maximize();
		pin_window();
		set_window_below();
		set_skip_pager(true);
		set_skip_tasklist(true);
		focus_window();
	end
end

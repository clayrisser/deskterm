apt-get install -y devilspie2

tee -a /etc/skel/.profile<<EOF
devilspie2
sleep 4s
gnome-terminal --window-with-profile=DesktopTerminal --role=DesktopTerminal --hide-menubar
EOF

mkdir /etc/skel/.config/
mkdir /etc/skel/.config/devilspie2/
mv deskterm.lua /etc/skel/.config/devilspie2/

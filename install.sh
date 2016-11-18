apt-get install -y devilspie2

tee -a ~/.profile<<EOF
devilspie2 &
sleep 4s
gnome-terminal --window-with-profile=Deskterm --role=Deskterm --hide-menubar
EOF

mkdir -p ~/.config/devilspie2/
wget -P ~/.config/devilspie2/ https://raw.githubusercontent.com/jamrizzi/deskterm/master/deskterm.lua

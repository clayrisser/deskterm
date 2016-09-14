apt-get install -y devilspie2

tee -a ~/.profile<<EOF
devilspie2
sleep 4s
gnome-terminal --window-with-profile=Deskterm --role=Deskterm --hide-menubar
EOF

mkdir ~/.config/
mkdir ~/.config/devilspie2/
mv deskterm.lua ~/.config/devilspie2/

cd ../ && rm -rf ./deskterm/

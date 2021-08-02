#!/bin/bash 


echo "Give me some super user access"
sudo -v


while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
for file in *sh *rb 
do
  chmod a+rx "$file"
  sudo ln -s "$file" /usr/local/bin
done
exit 0

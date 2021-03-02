#!/bin/sh

echo "Give me some super user access"
sudo -v


while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
				if["$(uname)" == "Linux"]; then
								# TODO
				fi
exit 0

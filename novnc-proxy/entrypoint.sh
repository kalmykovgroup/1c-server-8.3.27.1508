#!/bin/bash
exec websockify --web /usr/share/novnc/ 0.0.0.0:80 "$VNC_TARGET"

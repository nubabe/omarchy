ICON_DIR="$HOME/.local/share/applications/icons"

omarchy-tui-install "Disk Usage" "bash -c 'dust -r; read -n 1 -s'" float "$ICON_DIR/Disk Usage.png"
# omarchy-tui-install "Docker" "lazydocker" tile "$ICON_DIR/Docker.png"
omarchy-tui-install "YouTube" "youtube-tui" float "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/youtube.png"
omarchy-tui-install "Spotify" "spotify-player" float "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/spotify.png"

# tuis added by install script

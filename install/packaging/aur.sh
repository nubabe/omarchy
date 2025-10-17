# Install all base packages
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-aur.packages" | grep -v '^$')
yay -S --noconfirm --needed --removemake "${packages[@]}"

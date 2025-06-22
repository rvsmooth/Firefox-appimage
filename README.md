# Firefox-appimage
Unofficial AppImages built on top of the official portable builds (Stable, ESR, Beta, Devedition, Nightly).

The AppImages are created by extracting the official archives, with the only addition of a .desktop file, an icon and an AppRun (three essential elements for an AppImage).

It contains configs from betterfox, cachyOS browser. So it's private out-of-the-box.

### Installation
To install or upgrade, simply run
```
curl -fsSL https://raw.githubusercontent.com/rvsmooth/Firefox-appimage/refs/heads/main/install.sh | bash
```

### Uninstall
To uninstall, run
```
rm ~/.local/bin/{firefox,Firefox*.appimage}  ~/.local/share/applications/firefox.desktop}
```

#!/bin/bash

# Fix permissions as per the docs: <https://spicetify.app/docs/advanced-usage/installation/#spotify-installed-from-flatpak>
sudo chmod a+wr /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
sudo chmod a+wr -R /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify/Apps


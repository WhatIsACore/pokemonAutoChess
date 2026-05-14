#!/bin/sh
# Patches the server to redirect large unpacked asset categories to GitHub CDN.
# Run before `npm run build`.

GITHUB="https://raw.githubusercontent.com/keldaanCommunity/pokemonAutoChess/master/app/public/src/assets"
MUSIC="https://raw.githubusercontent.com/keldaanCommunity/pokemonAutoChessMusic/master"
AC="app/app.config.ts"

# Redirect large unpacked asset categories to GitHub CDN (insert before express.static)
awk -v gh="$GITHUB" -v mu="$MUSIC" '
/app\.use\(express\.static\(clientSrc\)\)/ {
  print "    app.use(\"/assets/portraits\", (req, res) => res.redirect(301, \"" gh "/portraits\" + req.url))"
  print "    app.use(\"/assets/tilesets\", (req, res) => res.redirect(301, \"" gh "/tilesets\" + req.url))"
  print "    app.use(\"/assets/posters\", (req, res) => res.redirect(301, \"" gh "/posters\" + req.url))"
  print "    app.use(\"/assets/musics\", (req, res) => res.redirect(301, \"" mu "\" + req.url))"
}
{ print }
' "$AC" > "$AC.tmp" && mv "$AC.tmp" "$AC"

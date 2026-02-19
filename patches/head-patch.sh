#!/bin/sh
# Run before `npm run build`.

cp patches/assets/scribble.png app/public/src/assets/ui/favicon.ico
cp patches/assets/scribble.png app/public/src/assets/ui/scribble.png

# Change page title
sed -i "s/<title>Pokemon: Auto Chess<\/title>/<title>Smeargle's Auto Chess<\/title>/" app/views/index.html

# Replace login screen logo with scribble.png and keep crisp pixel art edges
sed -i 's|assets/ui/pokemon_autochess_final.svg|assets/ui/scribble.png|' app/public/src/pages/auth.tsx
sed -i 's/object-fit: contain;/object-fit: contain;\n  image-rendering: pixelated;\n  min-width: 256px;/' app/public/src/pages/auth.css

# Replace "Pokémon Auto Chess" h1 text in all translation files
for f in app/public/dist/client/locales/*/translation.json; do
  sed -i "s/\"pokemon_auto_chess\": \"[^\"]*\"/\"pokemon_auto_chess\": \"Smeargle's Auto Chess\"/" "$f"
done

# Replace sidebar logo and title
MS="app/public/src/pages/component/main-sidebar/main-sidebar.tsx"
sed -i 's|assets/ui/colyseus-icon.png|assets/ui/scribble.png|' "$MS"
sed -i "s|<h1>Pokemon Auto Chess</h1>|<h1>Smeargle's Auto Chess</h1>|" "$MS"

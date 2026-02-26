#!/bin/sh
# Adds "Megastack" special game rule: removes the 3-item limit on Pokemon.
# Run before `npm run build`.

SGR="app/types/enum/SpecialGameRule.ts"
EN="app/public/dist/client/locales/en/translation.json"

# 1. Add enum member + translations
sed -i '/EVERYONE_IS_HERE = "EVERYONE_IS_HERE",/a\  MEGASTACK = "MEGASTACK",' "$SGR"

sed -i '/"EVERYONE_IS_HERE": "Everyone is here !",/a\		"MEGASTACK": "★ Megastack",' "$EN"
sed -i '/"EVERYONE_IS_HERE": "All the additional picks are available immediately",/a\		"MEGASTACK": "Pokemon can hold unlimited items!",' "$EN"

# 2. Patch item-limit locations

# game-commands.ts — drag-drop full-items check
GC="app/rooms/commands/game-commands.ts"
sed -i '1s|^|import { getMaxItemCount } from "../core/item-limits"\n|' "$GC"
sed -i 's/pokemon\.items\.size >= 3 &&/pokemon.items.size >= getMaxItemCount(this.state.specialGameRule) \&\&/' "$GC"

# pokemon-entity.ts — addItem() guard
PE="app/core/pokemon-entity.ts"
sed -i '1s|^|import { getMaxItemCount } from "./item-limits"\n|' "$PE"
sed -i 's/this\.items\.size >= 3 ||/this.items.size >= getMaxItemCount(this.player?.specialGameRule) ||/' "$PE"

# evolution-rules.ts — two occurrences
ER="app/core/evolution-rules.ts"
sed -i '1s|^|import { getMaxItemCount } from "./item-limits"\n|' "$ER"
sed -i 's/pokemonEvolved\.items\.size >= 3/pokemonEvolved.items.size >= getMaxItemCount(player.specialGameRule)/g' "$ER"

# effects/items.ts — three occurrences
EI="app/core/effects/items.ts"
sed -i '1s|^|import { getMaxItemCount } from "../item-limits"\n|' "$EI"
sed -i 's/pokemon\.items\.size >= 3/pokemon.items.size >= getMaxItemCount(player.specialGameRule)/g' "$EI"
sed -i 's/p\.items\.size < 3/p.items.size < getMaxItemCount(pokemon.player?.specialGameRule)/' "$EI"

# effects/passives.ts — two occurrences
EP="app/core/effects/passives.ts"
sed -i '1s|^|import { getMaxItemCount } from "../item-limits"\n|' "$EP"
sed -i 's/p\.items\.size < 3/p.items.size < getMaxItemCount(entity.player?.specialGameRule)/' "$EP"
sed -i 's/entity\.items\.size < 3/entity.items.size < getMaxItemCount(entity.player?.specialGameRule)/' "$EP"

# abilities/abilities.ts — Thief ability
AA="app/core/abilities/abilities.ts"
sed -i '1s|^|import { getMaxItemCount } from "../item-limits"\n|' "$AA"
sed -i 's/pokemon\.items\.size < 3/pokemon.items.size < getMaxItemCount(pokemon.player?.specialGameRule)/' "$AA"

# simulation.ts — Wonder Box
SM="app/core/simulation.ts"
sed -i '1s|^|import { getMaxItemCount } from "./item-limits"\n|' "$SM"
sed -i 's/pokemon\.items\.size < 3/pokemon.items.size < getMaxItemCount(pokemon.player?.specialGameRule)/' "$SM"

#!/bin/sh
# Adds Little Cup special game rule.
# Run before `npm run build`.

SGR="app/types/enum/SpecialGameRule.ts"

# Insert LITTLE_CUP after the first enum member
sed -i '/EVERYONE_IS_HERE = "EVERYONE_IS_HERE",/a\  LITTLE_CUP = "LITTLE_CUP",' "$SGR"

# Add English translations
EN="app/public/dist/client/locales/en/translation.json"
sed -i '/"EVERYONE_IS_HERE": "Everyone is here !",/a\		"LITTLE_CUP": "Little Cup",' "$EN"
sed -i '/"EVERYONE_IS_HERE": "All the additional picks are available immediately",/a\		"LITTLE_CUP": "No evolutions",' "$EN"

# Block all evolutions when Little Cup is active
ER="app/core/evolution-rules.ts"

# Add SpecialGameRule import
sed -i '/^import { logger } from "..\/utils\/logger"/a\import { SpecialGameRule } from "../types/enum/SpecialGameRule"' "$ER"

# Early-return in tryEvolve if Little Cup is active
sed -i '/tryEvolve(/,/): void | Pokemon {/ {
  /): void | Pokemon {/a\    if (player.specialGameRule === SpecialGameRule.LITTLE_CUP) return
}' "$ER"

# Also block canEvolveIfGettingOne to prevent bench space bypass
sed -i '/canEvolveIfGettingOne(pokemon: Pokemon, player: Player): boolean {/a\    if (player.specialGameRule === SpecialGameRule.LITTLE_CUP) return false' "$ER"

# Hide evolution shine/shimmer in shop portraits when Little Cup is active
PP="app/public/src/pages/component/game/game-pokemon-portrait.tsx"
sed -i '/import { CountEvolutionRule } from "..\/..\/..\/..\/..\/core\/evolution-rules"/a\import { SpecialGameRule } from "../../../../../types/enum/SpecialGameRule"' "$PP"
sed -i 's/const willEvolve =/const willEvolve = specialGameRule === SpecialGameRule.LITTLE_CUP ? false :/' "$PP"
sed -i 's/const shouldShimmer =/const shouldShimmer = specialGameRule === SpecialGameRule.LITTLE_CUP ? false :/' "$PP"

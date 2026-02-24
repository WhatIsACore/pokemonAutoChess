#!/bin/sh
# Adds the Randomizer special game rule (randomized synergies per pokemon family).
# Run before `npm run build`.

# Add RANDOMIZER to SpecialGameRule enum after first member
SGR="app/types/enum/SpecialGameRule.ts"
sed -i '/EVERYONE_IS_HERE = "EVERYONE_IS_HERE",/a\  RANDOMIZER = "RANDOMIZER",' "$SGR"

# Add English translations
EN="app/public/dist/client/locales/en/translation.json"
sed -i '/"EVERYONE_IS_HERE": "Everyone is here !",/a\		"RANDOMIZER": "★ Randomizer",' "$EN"
sed -i '/"EVERYONE_IS_HERE": "All the additional picks are available immediately",/a\		"RANDOMIZER": "Each Pokemon family has randomized synergies!",' "$EN"

# Add roomSeed field to Player
PL="app/models/colyseus-models/player.ts"
sed -i '/specialGameRule: SpecialGameRule | null = null/a\  roomSeed: string = ""' "$PL"
sed -i '/this.specialGameRule = state.specialGameRule/a\    this.roomSeed = state.preparationId' "$PL"

# Patch PokemonFactory to shuffle synergies when Randomizer is active
PF="app/models/pokemon-factory.ts"

# Add imports
sed -i '/^import { logger } from "..\/utils\/logger"/a\import { getShuffledSynergy } from "../core/synergy-shuffle"\nimport { SpecialGameRule } from "../types/enum/SpecialGameRule"' "$PF"

# After pokemon creation, apply synergy shuffle if player has RANDOMIZER rule
sed -i '/pokemon.maxHP = pokemon.hp/a\      if (custom && "roomSeed" in custom && custom.specialGameRule === SpecialGameRule.RANDOMIZER) {\n        const types = Array.from(pokemon.types.values())\n        pokemon.types.clear()\n        types.forEach(t => pokemon.types.add(getShuffledSynergy(custom.roomSeed, name, t)))\n      }' "$PF"

# Add synergy shuffle import to pokemon.ts
PKM="app/models/colyseus-models/pokemon.ts"
sed -i '/^import { entity, Schema, SetSchema, type } from "@colyseus\/schema"/a\import { getShuffledSynergy } from "../../core/synergy-shuffle"' "$PKM"

# Patch removeItems to use shuffled native types under Randomizer
sed -i '/const nativeTypes = new PokemonClasses\[this.name\](this.name).types/c\    const _rawNativeTypes = new PokemonClasses[this.name](this.name).types\n    const nativeTypes = player.specialGameRule === SpecialGameRule.RANDOMIZER\n      ? new SetSchema<Synergy>(Array.from(_rawNativeTypes.values()).map(t => getShuffledSynergy(player.roomSeed, this.name, t)))\n      : _rawNativeTypes' "$PKM"

# Patch removeItemEffect in pokemon-entity.ts to use shuffled default types
PE="app/core/pokemon-entity.ts"
sed -i '/^import { getPokemonData } from "..\/models\/precomputed\/precomputed-pokemon-data"/a\import { getShuffledSynergy } from "./synergy-shuffle"' "$PE"
sed -i 's/const default_types = getPokemonData(this.name).types/const _raw_default_types = getPokemonData(this.name).types\n    const default_types = this.player \&\& this.player.specialGameRule === SpecialGameRule.RANDOMIZER\n      ? _raw_default_types.map(t => getShuffledSynergy(this.player!.roomSeed, this.name, t))\n      : _raw_default_types/' "$PE"

# Add synergy shuffle import to shop.ts
SH="app/models/shop.ts"
sed -i '/^import { getPokemonData } from ".\/precomputed\/precomputed-pokemon-data"/a\import { getShuffledSynergy } from "../core/synergy-shuffle"' "$SH"

# Patch shop filterCandidates to use shuffled types for stage 10/20 propositions
sed -i 's/const hasSynergyWanted =/const hasSynergyWanted = player.specialGameRule === SpecialGameRule.RANDOMIZER\n          ? synergyWanted === undefined || types.some(t => getShuffledSynergy(player.roomSeed, pkm, t) === synergyWanted)\n          :/' "$SH"

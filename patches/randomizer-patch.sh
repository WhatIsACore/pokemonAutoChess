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
sed -i '/specialGameRule: SpecialGameRule | null = null/a\  @type("string") roomSeed: string = ""' "$PL"
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

# Add roomSeed to IPlayer interface
sed -i '/lightY: number/a\  roomSeed: string' "app/types/index.ts"

# --- Client-side display patches ---

# Patch game-pokemon-portrait.tsx: shuffle types on factory-created pokemon for shop display
PP="app/public/src/pages/component/game/game-pokemon-portrait.tsx"
sed -i '/^import PokemonFactory from/a\import { shufflePokemonTypes } from "../../utils/shuffled-pokemon-data"' "$PP"
# Add a useMemo after hooks to shuffle types on factory-created pokemon (and evolution pokemon)
sed -i '/const isOnAnotherBoard/i\  useMemo(() => {\n    if (pokemon && typeof props.pokemon === "string") {\n      shufflePokemonTypes(pokemon, specialGameRule, connectedPlayer?.roomSeed)\n    }\n  }, [pokemon, props.pokemon, specialGameRule, connectedPlayer?.roomSeed])\n' "$PP"

# Also shuffle evolution pokemon types (computed after hooks, not in a useMemo)
sed -i '/pokemonEvolution = PokemonFactory.createPokemonFromName(evolution/a\  shufflePokemonTypes(pokemonEvolution, specialGameRule, connectedPlayer?.roomSeed)' "$PP"

# Patch synergy-detail-component.tsx: use shuffled per-type table and pokemon data
SD="app/public/src/pages/component/synergy/synergy-detail-component.tsx"
sed -i '/^import { getPokemonData }/d' "$SD"
sed -i '/^import { PRECOMPUTED_POKEMONS_PER_TYPE_AND_CATEGORY }/c\import { getDisplayPerTypeAndCategory, getDisplayPokemonData } from "../../utils/shuffled-pokemon-data"' "$SD"
sed -i 's/PRECOMPUTED_POKEMONS_PER_TYPE_AND_CATEGORY\[/getDisplayPerTypeAndCategory(specialGameRule, spectatedPlayer?.roomSeed ?? "")[/g' "$SD"
sed -i 's/getPokemonData(\([^)]*\))/getDisplayPokemonData(specialGameRule, spectatedPlayer?.roomSeed ?? "", \1)/g' "$SD"

# Patch duo portrait: use shuffled pokemon data
DP="app/public/src/pages/component/game/game-pokemon-duo-portrait.tsx"
sed -i '/^import { getPokemonData }/a\import { getDisplayPokemonData } from "../../utils/shuffled-pokemon-data"' "$DP"
sed -i '/selectSpectatedPlayer, useAppSelector/s/selectSpectatedPlayer/selectConnectedPlayer, selectSpectatedPlayer/' "$DP"
# Insert hooks BEFORE the duo computation line (which will reference them)
sed -i '/const duo = PkmDuos/i\  const connectedPlayer = useAppSelector(selectConnectedPlayer)\n  const specialGameRule = useAppSelector((state) => state.game.specialGameRule)' "$DP"
sed -i 's/const duo = PkmDuos\[props.duo\].map((p) => getPokemonData(p))/const duo = PkmDuos[props.duo].map((p) => getDisplayPokemonData(specialGameRule, connectedPlayer?.roomSeed ?? "", p))/' "$DP"

# Patch regional pokemons panel: use shuffled pokemon data
RP="app/public/src/pages/component/game/game-regional-pokemons.tsx"
sed -i '/^import { getPokemonData }/a\import { getDisplayPokemonData } from "../../utils/shuffled-pokemon-data"' "$RP"
sed -i '/const spectatedPlayer/a\  const specialGameRule = useAppSelector((state) => state.game.specialGameRule)' "$RP"
sed -i 's/getPokemonData(\([^)]*\))/getDisplayPokemonData(specialGameRule, connectedPlayer?.roomSeed ?? "", \1)/g' "$RP"

# Patch additional pokemons panel: use shuffled pokemon data
AP="app/public/src/pages/component/game/game-additional-pokemons.tsx"
sed -i '/^import { getPokemonData }/a\import { getDisplayPokemonData } from "../../utils/shuffled-pokemon-data"' "$AP"
sed -i 's/getPokemonData(\([^)]*\))/getDisplayPokemonData(specialGameRule, currentPlayer?.roomSeed ?? "", \1)/g' "$AP"

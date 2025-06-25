import { Schema, model } from "mongoose"
import protobuf from "protobufjs"
import { PkmByIndex } from "../../types/enum/Pokemon"
import { Synergy } from "../../types/enum/Synergy"
import { GameMode } from "../../types/enum/Game"
import { Emotion } from "../../types"


const root = protobuf.loadSync(`${__dirname}/../proto/detailed-statistic.proto`)
const DetailedStatisticMessage = root.lookupType("DetailedStatistic")

export interface Pokemon {
  name: string
  avatar: string
  items: string[]
}
export interface IDetailedStatistic {
  playerId: string
  name: string
  avatar: string
  rank: number
  elo: number
  time: number
  nbplayers: number
  pokemons: Pokemon[]
  synergies: Map<Synergy, number>
  gameMode: GameMode
}
interface IDetailedStatisticPacked {
  playerId: string
  time: number
  gameMode: GameMode
  data?: Buffer
}
interface PokemonBinarySchema {
  avatar: string
  emotion: Emotion
  items: string[]
}
interface IDetailedStatisticBinarySchema {
  name: string
  avatar: string
  emotion: Emotion
  rank: number
  elo: number
  nbplayers: number
  pokemons: PokemonBinarySchema[]
  synergies: Array<Synergy>
  synergyLevels: Array<number>
}

const DetailedStatisticProtobuf = new Schema(
  {
    id: { type: String },
    time: { type: Number },
    gameMode: { type: String },
    data: {
      type: Buffer,
      required: true
    }
  },
  {
    statics: {
      createEncoded(doc: IDetailedStatistic) {
        const avatar = doc.avatar.split('/')
        
        const data: IDetailedStatisticBinarySchema = {
          name: doc.name,
          avatar: avatar[0],
          emotion: avatar[1] as Emotion,
          rank: doc.rank,
          elo: doc.elo,
          nbplayers: doc.nbplayers,
          pokemons: new Array<PokemonBinarySchema>(),
          synergies: new Array<Synergy>(),
          synergyLevels: new Array<number>()
        }
        
        // compress pokemon avatars
        doc.pokemons.forEach(pokemon => {
          const pkmAvatar = pokemon.avatar.split('/')
          data.pokemons.push({
            avatar: pkmAvatar[0],
            emotion: pkmAvatar[1] as Emotion,
            items: pokemon.items
          })
        })
        
        // convert synergy map to arrays
        doc.synergies.forEach((value, key) => {
          data.synergies.push(key)
          data.synergyLevels.push(value)
        })
        const message = DetailedStatisticMessage.create(data)
        
        const packedDoc: IDetailedStatisticPacked = {
          playerId: doc.playerId,
          time: doc.time,
          gameMode: doc.gameMode,
          data: Buffer.from(DetailedStatisticMessage.encode(message).finish())
        }
        this.create(packedDoc)
      }
    }
  }
)

export default model("DetailedStatisticProtobuf", DetailedStatisticProtobuf, "detailed-statistic-protobuf")


DetailedStatisticProtobuf.post('init', function (doc: IDetailedStatisticPacked & IDetailedStatistic) {
  if (!doc.data) return;
  const decoded = DetailedStatisticMessage.decode(doc.data);
  const json = DetailedStatisticMessage.toObject(decoded, {
    longs: String,
    enums: String,
    defaults: true,
  }) as IDetailedStatisticBinarySchema;
  
  doc.elo = json.elo;
  doc.name = json.name;
  doc.rank = json.rank;
  doc.nbplayers = json.nbplayers;
  doc.avatar = `${json.avatar}/${json.emotion}`
  doc.pokemons = new Array<Pokemon>()
  
  json.pokemons.forEach(pokemon => {
    let name = PkmByIndex[pokemon.avatar]
    if (name == null) name = PkmByIndex[pokemon.avatar.replace('-0001', '')]  // not found? try shiny
    doc.pokemons.push({
      name: name,
      avatar: `${pokemon.avatar}/${pokemon.emotion}`,
      items: pokemon.items
    })
  })
  
  doc.synergies = new Map<Synergy, number>();
  for (let i in json.synergies)
    doc.synergies.set(json.synergies[i], json.synergyLevels[i])
  
  delete doc.data
});
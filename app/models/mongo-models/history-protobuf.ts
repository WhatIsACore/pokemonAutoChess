import { Schema, model } from "mongoose"
import protobuf from "protobufjs"
import { components } from "../../api-v1/openapi"
import { PkmByIndex } from "../../types/enum/Pokemon"

const root = protobuf.loadSync("../proto/history.proto")
const HistoryMessage = root.lookupType("History")

const HistoryProtobuf = new Schema(
  {
    id: { type: String },
    startTime: { type: Number },
    endTime: { type: Number },
    data: {
      type: Buffer,
      required: true
    }
  }
)

HistoryProtobuf.pre('validate', function (next) {  
  const doc = this as components["schemas"]["GameHistory"] & { data?: Buffer }
  
  if (doc.players) {
    let players: any[] = doc.players;
    
    // compress avatars
    players.forEach(player => {
      const avatar = player.avatar.split('/')
      player.avatar = avatar[0]
      player.emotion = avatar[1]
      player.pokemons.forEach(pokemon => {
        pokemon.avatar = avatar[0]
        pokemon.emotion = avatar[1]
      })
    })
    
    const message = HistoryMessage.create({players: players})
    doc.data = Buffer.from(HistoryMessage.encode(message).finish())
  }
  
  next()
})

HistoryProtobuf.post('init', function (doc: components["schemas"]["GameHistory"] & { data?: Buffer }) {
  if (!doc.data) return;
  const decoded = HistoryMessage.decode(doc.data);
  const json = HistoryMessage.toObject(decoded, {
    longs: String,
    enums: String,
    defaults: true,
  });
  
  // decompress avatars
  json.players.forEach(player => {
    player.avatar = `${player.avatar}/${player.emotion}`
    delete player.emotion
    player.pokemons.forEach(pokemon => {
      pokemon.name = PkmByIndex[pokemon.avatar]
      if (pokemon.name == null) pokemon.name = PkmByIndex[pokemon.avatar.replace('-0001', '')]  // not found? try shiny
      pokemon.avatar = `${pokemon.avatar}/${pokemon.emotion}`
      delete pokemon.emotion
    })
  })
  
  doc.players = json.players;
});

export default model<components["schemas"]["GameHistory"]>("History", HistoryProtobuf)

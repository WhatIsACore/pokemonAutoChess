import { Schema, model } from "mongoose"
import protobuf from "protobufjs"
import { components } from "../../api-v1/openapi"

const root = protobuf.loadSync("../proto/history.proto")

const historyProtobuf = new Schema(
  {
    id: { type: String },
    startTime: { type: Number },
    endTime: { type: Number },
    data: {
      type: Buffer,
      required: true
    }
  },
  {
    toJSON: {
      transform: async function (doc, ret) {
        delete ret._id
        delete ret.__v
        delete ret.data
        const History = root.lookupType("History")
        const message = History.decode(doc.data)
        ret.players = History.toObject(message)
      }
    }
  }
)

export default model<components["schemas"]["GameHistory"]>("History", historyProtobuf)

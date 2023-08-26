import Crypto from "node:crypto"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"
import Zephyr from "@dashkite/zephyr"

hash = ( it ) ->
  result = Crypto.createHash "sha1"
  for await text from it
    result.update text
  result.digest "hex"

Hash =

    generate: Fn.tee ( context ) ->
      context.source.hash = hash [ context.input ]
    
    store: Fn.tee ( context ) ->
      Zephyr.update ".genie/hashes.yaml", ( hashes ) ->
        hashes[ context.source.path ] = context.source.hash
      
    changed: Fn.tee ( context ) ->
      { data } = await Zephyr.read ".genie/hashes.yaml"
      context.changed =
        ( data[ context.source.path ] != context.source.hash )
      
File =

  hash: It.map Hash.generate

  store: It.map Hash.store

  changed: Fn.flow [
    It.resolve It.map Fn.flow [
      Hash.generate
      Hash.changed
    ]
    It.select ( context ) -> context.changed
    It.tap Hash.store
  ]

# TODO combinator for dealing with a whole project
    

export { File }
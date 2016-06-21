module Link (Link, Id, decodeLinks, encodeLinks) where

import Dict
import Json.Decode exposing ((:=))
import String


type alias Id =
  String


type alias Link =
  { id : String
  , title : String
  , url : String
  , excerpt : Maybe String
  , favorite : Bool
  , keep : Bool
  }


decodeLink : Json.Decode.Decoder Link
decodeLink =
  Json.Decode.object6
    Link
    ("item_id" := Json.Decode.string)
    ("given_title" := Json.Decode.string)
    ("given_url" := Json.Decode.string)
    (Json.Decode.maybe ("excerpt" := Json.Decode.string))
    ("favorite" := sbool)
    (Json.Decode.succeed False)


decodeLinks : Json.Decode.Decoder (Dict.Dict String Link)
decodeLinks =
  Json.Decode.at [ "list" ] (Json.Decode.dict decodeLink)


encodeLinks links =
  let
    encodeLink link =
      Json.Encode.object
        [ ( "id", Json.Encode.string link.id )
        , ( "title", Json.Encode.string link.title )
        , ( "url", Json.Encode.string link.url )
        ]
  in
    Json.Encode.list <| List.map encodeLink links


sbool =
  let
    toBool result =
      case result of
        Ok int ->
          Ok (int == 1)

        Err err ->
          Err err
  in
    Json.Decode.customDecoder Json.Decode.string (toBool << String.toInt)

module Triage where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing ((:=))
import Task exposing (Task, andThen, onError, succeed)

actions : Signal.Mailbox Action
actions =
    Signal.mailbox NoOp

model : Signal Model
model = Signal.foldp update emptyModel actions.signal

main =
    Signal.map view model

type alias Model =
    { links: List Link }

type alias Link =
    { title: String
    , url: String
    , favorite: Bool
    , keep: Bool
    }

emptyModel : Model
emptyModel =
    { links = [] }

view : Model -> Html
view model =
    div []
        [ h2 []
            [ text "Selection # of #" ],
          ul []
            (List.map linkItem model.links)]

linkItem : Link -> Html
linkItem link =
    li []
        [ text link.title ]

type Action = Keep String Bool
            | Fav String Bool
            | SetLinks (List Link)
            | NoOp

update : Action -> Model -> Model
update action model =
    case action of
        Keep id isKeeped ->
            let updateLink l = if l.url == id then { l | keep = isKeeped } else l
            in
                { model | links = List.map updateLink model.links }

        Fav id isFavorite ->
            let updateLink l = if l.url == id then { l | favorite = isFavorite } else l
            in
                { model | links = List.map updateLink model.links }

        SetLinks links' ->
            { model | links = links' }

        NoOp ->
            model

link : Json.Decode.Decoder Link
link =
    Json.Decode.object4 Link
        ("title" := Json.Decode.string)
        ("link" := Json.Decode.string)
        ("keep" := Json.Decode.bool)
        ("favorite" := Json.Decode.bool)

get : Task Http.Error (List Link)
get =
    Http.get (Json.Decode.list link) "./static/data.json"

port runner : Task Http.Error ()
port runner =
    -- get `onError` (\err -> Debug.crash (always "bouh" (Debug.log "euh" err)))
    get `andThen` (\links -> Signal.send actions.address (SetLinks (Debug.log "links" links)))

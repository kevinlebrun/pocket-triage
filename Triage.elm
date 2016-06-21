module Triage (..) where

import Char exposing (fromCode)
import Dict
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Encode
import Keyboard
import Link exposing (..)
import Selector
import StartApp
import Task exposing (Task, andThen, onError, succeed)


actions : Signal.Mailbox Action
actions =
  Signal.mailbox NoOp


app =
  StartApp.start
    { init = ( emptyModel, Effects.none )
    , view = view
    , update = update
    , inputs = [ keyboard, actions.signal ]
    }


model : Signal Model
model =
  app.model


main =
  app.html


type alias Model =
  { links : List Link
  , snapshot : Selector.Model
  , page : Int
  , perPage : Int
  , deleted : List Link
  , token : Maybe String
  , done : Bool
  }


emptyModel : Model
emptyModel =
  { links = []
  , snapshot = Selector.initialModel []
  , page = 1
  , perPage = 10
  , deleted = []
  , token = Debug.log "token" getToken
  , done = False
  }


view : Signal.Address Action -> Model -> Html
view address model =
  -- TODO refactor
  if model.token == Nothing then
    -- TODO refactor with proper Anonymous tag
    div
      [ class "container" ]
      [ p [] [ text "You are not logged!" ]
      , a [ href "http://localhost:8080/oauth/request" ] [ text "Login to continue" ]
      ]
  else if model.done then
    div
      [ class "container" ]
      [ p [] [ text "Well done! No more work right now." ]
      , p [] [ text ("You deleted " ++ (toString <| List.length model.deleted) ++ " items") ]
      ]
  else if List.isEmpty model.links then
    div
      [ class "container" ]
      [ p [] [ text "Loading..." ]
      ]
  else
    div
      [ class "container" ]
      [ stats model
      , Selector.view model.snapshot
      ]


stats : Model -> Html
stats model =
  let
    total =
      List.length model.links

    deleted =
      List.length model.deleted
  in
    div
      []
      [ p
          [ class "stats__summary" ]
          [ text ("page " ++ (toString model.page) ++ " of " ++ (toString (total // model.perPage)))
          , text (" (" ++ (toString total) ++ " items)")
          ]
      , p [ class "stats__progress" ] [ text ((toString deleted) ++ " deleted") ]
      ]


type Action
  = NoOp
  | Next
  | Link Selector.Action
  | OnReceiveLinks (List Link)
  | HttpError String


takeSnapshot page n links =
  List.take 10 <| List.drop ((page - 1) * 10) links


update : Action -> Model -> ( Model, Effects Action )
update action model =
  case action of
    Next ->
      let
        page =
          model.page + 1

        toDelete ( id, link ) =
          if link.keep || link.favorite then
            Nothing
          else
            Just link

        deleted =
          List.filterMap toDelete model.snapshot.links

        snapshot =
          Selector.initialModel <| takeSnapshot page model.perPage model.links

        effect =
          case model.token of
            Nothing ->
              Effects.none

            Just token ->
              deleteEffect token deleted
      in
        if List.isEmpty snapshot.links then
          ( { model | done = True }, effect )
        else
          ( { model
              | snapshot = snapshot
              , page = page
              , deleted = model.deleted ++ deleted
            }
          , effect
          )

    Link action' ->
      ( { model | snapshot = Selector.update action' model.snapshot }, Effects.none )

    OnReceiveLinks links' ->
      ( { model
          | links = links'
          , snapshot = Selector.initialModel <| takeSnapshot model.page model.perPage links'
          , done = List.isEmpty links'
        }
      , Effects.none
      )

    HttpError error ->
      ( always {model | token = Nothing} <| Debug.log "error" error , Effects.none )

    NoOp ->
      ( model, Effects.none )


authed verb token url body =
  Http.send
    Http.defaultSettings
    { verb = verb
    , headers = [ ( "token", token ) ]
    , url = url
    , body = body
    }


get : String -> Task Http.Error ()
get token =
  (Http.fromJson Link.decodeLinks
    <| authed "GET" token "http://localhost:8080/links" Http.empty
  )
    `andThen` (\dict -> succeed (Dict.values dict))
    `andThen` (OnReceiveLinks >> Signal.send actions.address)
    `onError` (toString >> HttpError >> Signal.send actions.address)



-- TODO move into Link.elm


linksValue links =
  let
    linkValue link =
      Json.Encode.object
        [ ( "id", Json.Encode.string link.id )
        , ( "title", Json.Encode.string link.title )
        , ( "url", Json.Encode.string link.url )
        ]
  in
    Json.Encode.list <| List.map linkValue links


delete token links =
  authed "DELETE" token "http://localhost:8080/links" (Http.string (Json.Encode.encode 0 <| linksValue links))
    `onError` (\err -> Debug.crash (always "Error!" (Debug.log "Error: " err)))


deleteEffect token links =
  delete token links
    |> Task.toResult
    |> Task.map (always NoOp)
    |> Effects.task



-- SIGNALS


keyboard : Signal Action
keyboard =
  let
    keyToAction key =
      let
        char =
          fromCode key
      in
        if char == ' ' then
          Next
        else
          Link (Selector.keyToAction key)
  in
    Signal.map keyToAction Keyboard.presses


port runner : Signal (Task Http.Error ())
port runner =
  let
    areLinksEmpty model =
      List.isEmpty model.links

    validToken model =
      case model.token of
        Just token ->
          Just token

        Nothing ->
          Nothing
  in
    Signal.map (\token -> get token) <| Signal.filterMap validToken "" <| Signal.filter areLinksEmpty emptyModel model


port getToken : Maybe String
port tasks : Signal (Task Effects.Never ())
port tasks =
  app.tasks

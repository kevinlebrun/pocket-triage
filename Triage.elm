module Triage exposing (..)

import Char exposing (fromCode)
import Dict
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Keyboard
import Link exposing (..)
import Selector
import Task exposing (Task, andThen, onError, succeed)
import Ports


main : Program { token : Maybe String }
main =
  Html.App.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init flags =
  let
    cmd =
      case flags.token of
        Just token ->
          doGetLinks token
        Nothing ->
          Cmd.none
  in
    ( emptyModel flags.token, cmd )


type alias Model =
  { links : List Link
  , snapshot : Selector.Model
  , page : Int
  , perPage : Int
  , deleted : List Link
  , token : Maybe String
  , done : Bool
  }


emptyModel : Maybe String -> Model
emptyModel token =
  { links = []
  , snapshot = Selector.initialModel []
  , page = 1
  , perPage = 10
  , deleted = []
  , token = Debug.log "token" token
  , done = False
  }


view : Model -> Html Msg
view model =
  if model.token == Nothing then
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
      , Html.App.map Link <| Selector.view model.snapshot
      , button [onClick Next] [text "Next"]
      ]


stats : Model -> Html Msg
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


type Msg
  = NoOp
  | Next
  | Link Selector.Msg
  | OnReceiveLinks (List Link)
  | HttpError String


takeSnapshot page n links =
  List.take 10 <| List.drop ((page - 1) * 10) links


update : Msg -> Model -> ( Model, Cmd Msg )
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

        cmd =
          case model.token of
            Nothing ->
              Cmd.none

            Just token ->
              Cmd.batch [doDelete token deleted, Ports.deletedLinks deleted]
      in
        if List.isEmpty snapshot.links then
          ( { model | done = True }, cmd )
        else
          ( { model
              | snapshot = snapshot
              , page = page
              , deleted = model.deleted ++ deleted
            }
          , cmd
          )

    Link action' ->
      ( { model | snapshot = Selector.update action' model.snapshot }, Cmd.none )

    OnReceiveLinks links' ->
      ( { model
          | links = links'
          , snapshot = Selector.initialModel <| takeSnapshot model.page model.perPage links'
          , done = List.isEmpty links'
        }
      , Cmd.none
      )

    HttpError error ->
      ( always {model | token = Nothing} <| Debug.log "error" error , Cmd.none )

    NoOp ->
      ( model, Cmd.none )


authed verb token url body =
  Http.send
    Http.defaultSettings
    { verb = verb
    , headers = [ ( "token", token ) ]
    , url = url
    , body = body
    }


getLinks : String -> Task Http.Error (List Link)
getLinks token =
  (Http.fromJson Link.decodeLinks
    <| authed "GET" token "http://localhost:8080/links" Http.empty
  )
    `andThen` (\dict -> succeed (Dict.values dict))

doGetLinks token =
  Task.perform (toString >> HttpError) OnReceiveLinks <| getLinks token

delete token links =
  (authed "DELETE" token "http://localhost:8080/links" <| Http.string <| encodeLinks links)
    `onError` (\err -> Debug.crash (always "Error!" (Debug.log "Error: " err)))


doDelete token links =
  Task.perform (always NoOp) (always NoOp) <| delete token links


-- SUBSCRIPTIONS


keyboard : Sub Msg
keyboard =
  let
    keyToMsg key =
      if key == 13 then
        Next
      else
        Link (Selector.keyToMsg key)
  in
    Keyboard.presses keyToMsg

subscriptions model =
  keyboard

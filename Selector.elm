module Selector (..) where

import Char exposing (fromCode, KeyCode)
import Keyboard
import Link exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import String


type alias Model =
  { links : List ( Id, Link )
  , selected : Maybe Id
  }


initialModel : List Link -> Model
initialModel links =
  let
    byIds =
      List.map (\link -> ( link.id, link )) links
  in
    { links = byIds
    , selected = Maybe.map .id <| List.head links
    }


view : Model -> Html
view model =
  div
    [ class "links" ]
    [ div [] (List.map (linkItem model.selected) model.links)
    ]


linkItem : Maybe Id -> ( Id, Link ) -> Html
linkItem selected ( _, link ) =
  let
    isSelected link =
      case selected of
        Nothing ->
          False

        Just id ->
          link.id == id

    classes =
      [ ( "link", True )
      , ( "link--selected", isSelected link )
      , ( "link--keep", link.keep )
      , ( "link--favorite", link.favorite )
      ]

    title link =
      if String.isEmpty link.title then
        link.url
      else
        link.title

    excerpt =
      case link.excerpt of
        Nothing ->
          ""

        Just excerpt ->
          excerpt
  in
    div
      [ classList classes ]
      [ a [ href link.url, target "_blank" ] [ text <| title link ]
      , p [ class "link__excerpt" ] [ text excerpt ]
      ]



-- UPDATE


type Action
  = NoOp
  | Up
  | Down
  | Keep


update : Action -> Model -> Model
update action model =
  case action of
    Down ->
      let
        findNext : Id -> List ( Id, Link ) -> Maybe ( Id, Link )
        findNext selected list =
          case list of
            x :: xs ->
              if (fst x) == selected then
                List.head xs
              else
                findNext selected xs

            [] ->
              Nothing
      in
        case model.selected of
          Nothing ->
            model

          Just id ->
            { model | selected = Maybe.map fst <| Maybe.oneOf [ findNext id model.links, List.head model.links ] }

    Up ->
      let
        findPrev : Id -> List ( Id, Link ) -> Maybe ( Id, Link )
        findPrev selected list =
          case list of
            x :: y :: xs ->
              if (fst y) == selected then
                Just x
              else
                findPrev selected (y :: xs)

            x :: [] ->
              Just x

            [] ->
              Nothing
      in
        case model.selected of
          Nothing ->
            model

          Just id ->
            { model | selected = Maybe.map fst <| Maybe.oneOf [ findPrev id model.links, List.head <| List.reverse model.links ] }

    Keep ->
      let
        update' selected ( id, link ) =
          if id == selected then
            ( id, { link | keep = not link.keep } )
          else
            ( id, link )
      in
        case model.selected of
          Nothing ->
            model

          Just id ->
            { model | links = List.map (update' id) model.links }

    NoOp ->
      model



-- SIGNALS


keyToAction : KeyCode -> Action
keyToAction key =
  let
    char =
      fromCode key
  in
    if char == 'j' then
      Down
    else if char == 'k' then
      Up
    else if char == ' ' then
      Keep
    else
      NoOp


keyboard : Signal Action
keyboard =
  Signal.map keyToAction Keyboard.presses

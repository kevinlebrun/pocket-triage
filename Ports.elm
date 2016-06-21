port module Ports exposing (..)

import Link exposing (Link)


port deletedLinks : List Link -> Cmd msg

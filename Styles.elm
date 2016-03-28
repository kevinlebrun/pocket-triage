module Styles (..) where

import Html exposing (..)


styles =
  let
    css =
      """
.container {
  margin: auto;
  width: 70%;
}

.stats__summary {
  float: left;
  padding-left: 5px;
}

.stats__progress {
  float: right;
  padding-right: 5px;
}

.links {
  clear: both;
}

.link {
  padding: 5px;
}

a, a:link, a:hover, a:visited {
  color: black;
  text-decoration: none;
}

.link--selected, .link--selected a {
  background-color: #0F5CBF;
  color: white;
}

.link--keep, .link--keep a {
  background-color: #F25C05;
  color: white;
}

.link--favorite, .link--favorite a {
  background-color: #F2CD13;
  color: white;
}

.link__excerpt {
  font-style: italic;
  font-size: 0.8em;
}
"""
  in
    node "style" [] [ text css ]

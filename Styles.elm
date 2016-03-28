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
  border-left: 5px solid transparent;
}

a, a:link, a:hover, a:visited {
  color: black;
  text-decoration: none;
}

.link--selected, .link--selected a {
  background-color: #0F5CBF;
  color: white;
}

.link--keep {
  border-left: 5px solid #F25C05;
}

.link--favorite {
  border-left: 5px solid #F2CD13;
}

.link__excerpt {
  font-style: italic;
  font-size: 0.8em;
}
"""
  in
    node "style" [] [ text css ]

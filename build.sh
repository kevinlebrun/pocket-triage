#!/bin/bash
elm make Triage.elm --output static/triage.js
go-bindata -prefix static static/

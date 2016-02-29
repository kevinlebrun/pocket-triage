#!/bin/bash
elm make Triage.elm --output static/triage.js
go run server.go

#!/bin/bash


OF=$(mktemp)
PORT=13831
# Eval `1`
# Expect a string response of 1
curl -o $OF -d "1" -X POST http://localhost:$PORT/e
echo "RESP <$(cat $OF)>"

# Command `print 'hi'`.
# Expect an empty response
curl -o $OF -d "print 'hi'" -X POST http://localhost:$PORT/c
echo "RESP <$(cat $OF)>"




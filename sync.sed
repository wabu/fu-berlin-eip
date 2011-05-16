#!/bin/sed -f
:a
  N
  /\n\s*$/{
    n
  }
  ba

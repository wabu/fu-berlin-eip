#!/usr/bin/env sed -f
:a
  N
  /\n\s*$/{
    n
  }
  ba

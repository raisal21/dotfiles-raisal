#!/usr/bin/env bash

if (($# == 0)); then
  exec opencode --continue
fi

exec opencode "$@"

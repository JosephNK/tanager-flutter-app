#!/bin/bash
(
  DIR_VAR="$1"

  cd $DIR_VAR

  flutter packages pub run build_runner watch --delete-conflicting-outputs
)
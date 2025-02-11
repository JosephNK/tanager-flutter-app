#!/bin/bash
(
  cd app/

  flutter pub run flutter_native_splash:create --flavor production
  flutter pub run flutter_native_splash:create --flavor development
  flutter pub run flutter_native_splash:create --flavor staging
  flutter pub run flutter_native_splash:create --flavor qa
)
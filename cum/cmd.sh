#!/bin/bash

./csv2rss.sh ./cum/feed.csv \
  --repo-dir "cum" \
  --title "Cum Town" \
  --description "A podcast about having sex with your dad" \
  --delimiter $'\x1F'

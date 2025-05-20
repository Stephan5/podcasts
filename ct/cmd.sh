#!/bin/bash

./csv2rss.sh ./ct/feed.csv \
  --repo-dir "ct" \
  --title "Cum Town" \
  --description "A podcast about having sex with your dad" \
  --delimiter $'\x1F'

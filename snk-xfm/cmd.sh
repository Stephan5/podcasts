#!/bin/bash

./csv2rss.sh ./snk-xfm/feed.csv \
  --repo-dir "snk-xfm" \
  --title "SNK XFM" \
  --description "Simon Pegg, Nick Frost and Karl Pilkington on XFM." \
  --delimiter ";"

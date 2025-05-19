#!/bin/bash

./csv2rss.sh ./mssp/feed.csv \
  --repo-dir "mssp" \
  --title "Matt and Shane's Secret Podcast" \
  --description "Grab onto this fast moving train and witness two comedians rise to victory and splendor." \
  --delimiter ";"

./append-items.sh ./mssp/feed.xml ./mssp/extra-items.xml ./mssp/feed.xml
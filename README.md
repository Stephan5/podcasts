# Podcasts
![](https://github.com/Stephan5/podcasts/actions/workflows/main.yml/badge.svg)
## Feeds
A collection of self-hosted podcast feeds for my own use, to ensure all the hottest 'casts are preserved.

## Scripts
A collection of scripts to process podcast metadata and generate RSS feeds.

For example, you can onboard a new podcast by either:
* building your own CSV and running the `csv2rss.sh` script
* taking an existing feed and generating a CSV using `rss2csv.sh` and then running the `csv2rss.sh` script

You also can feed your CSV into `selfhost.sh` to upload the files to your own S3 bucket. 

CSVs detailing each episode must be of the form "title,description,date,url" using the delimiter of your choice. 

### csv2rss.sh
This script takes a CSV file of podcast episodes along with other podcast details and outputs an XML feed file
The CSV must be of the form: title,description,date,url
The description is optional and can be left blank. 
You then pass in details like the podcast title and description to the script as named args

```shell
 $ pwd 
 /Users/REDACTED/REDACTED/podcasts

 $ cat ./feed/shower-cast/feed.csv
  title;description;date;url
  Welcome to the cast;Our very first epsiode!;Sat, 24 May 2025 03:21:23 GMT;https://example.com/ep1.mp3
  Hot and cold;The second one;Sat, 31 May 2025 05:21:23 GMT;https://example.com/ep2.mp3
 
 $ ./script/csv2rss.sh ./feed/shower-cast/feed.csv \
     --delimiter ";" \
     --title "Shower Cast" \
     --description "The hottest takes in the coldest showers"
```

This should generate a valid XML file in the shower-cast directory.

Requirements:
 * xmllint (brew install libxml2)
 * xmlstarlet (brew install xmlstarlet)

## TODO
- [x] Generate for all directories
- [x] Add script for append arbitrary pre-formatted items 
- [x] Add some rudimentary tests
- [x] Only bump `pubDate` and `lastBuildDate` if there are changes to the file (if it already exists)
- [x] Add script to convert CSV to self-hosted 
- [x] Support local file URLs in selfhost.sh
- [x] Pull out common functions
- [x] remove need for repo-dir argument in scripts
- [x] Onboard RSK XFM, Athletico Mince, and TFTM
- [x] Onboard The Basement Yard
- [ ] Allow output directory / file to be passed in as an argument
- [ ] Support updating existing feeds with new episodes from external feed

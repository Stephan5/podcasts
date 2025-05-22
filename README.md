# rss
![](https://github.com/Stephan5/rss/actions/workflows/main.yml/badge.svg)
## Feeds

A collection of self-hosted podcast feeds for my own use, to ensure all the best 'dudes rock' content can live forever in safety while the rest of the internet decays around it.

> [!IMPORTANT]  
> It's the most convoluted, ridiculous, RACIST, piece of material ever to be uttered on radio!
>
> Play it again!

## Scripts
A collection of scripts to process podcast metadata and generate RSS feeds.

For example, you can onboard a new podcast by either:
* building your own CSV and running the `csv2rss.sh` script
* taking an existing feed and generating a CSV using `rss2csv.sh` and then running the `csv2rss.sh` script

You can feed the CSV into `selfhost.sh` to upload the files to your own S3 bucket. 

### csv2rss.sh
This script takes a CSV file of podcast episodes along with other podcast details and outputs an XML feed file
The CSV must be of the form: title,description,date,link
Where either ordinal or description are optional.

```shell
 $ pwd 
 /Users/REDACTED/REDACTED/rss
 
 $ ./script/csv2rss.sh ./feed/mssp/feed.csv \
     --delimiter ";" \
     --title "Matt and Shane's Secret Podcast" \
     --description "Grab onto this fast moving train and witness two comedians rise to victory and splendor." \
     --image-link "https://is5-ssl.mzstatic.com/image/thumb/Music128/v4/00/fe/d2/00fed269-058c-1fc9-7c52-061940ee7e93/source/1200x630bb.jpg"
```

Requirements:
 * Run from the top-level of the `rss` repo.
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

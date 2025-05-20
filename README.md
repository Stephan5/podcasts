# rss



## csv2rss.sh
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
Where "repo-dir" is the directory you would like to store your output file and consequently forms part of the feed URL

Requirements:
 * Run from the top-level of the `rss` repo.
 * xmllint (brew install libxml2)
 * xmlstarlet (brew install xmlstarlet)

## TODO
- [x] Generate for all directories
- [x] Add script for append arbitrary pre-formatted items 
- [ ] Add some rudimentary tests
- [x] Only bump `pubDate` and `lastBuildDate` if there are changes to the file (if it already exists)
- [x] Add script to convert CSV to self-hosted 
- [x] Support local file URLs in selfhost.sh
- [x] Pull out common functions
- [ ] Convert to Python scripts (?!)
- [x] remove need for repo-dir argument in scripts

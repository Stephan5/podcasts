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
This script takes a CSV file of podcast episodes along with other podcast details and outputs an XML feed file.
The CSV must be of the form: title,description,date,url. The description is optional and can be left blank.
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

This should generate a valid XML file in the shower-cast directory:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:wfw="http://wellformedweb.org/CommentAPI/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0" xmlns:spotify="http://www.spotify.com/ns/rss" xmlns:podcast="https://podcastindex.org/namespace/1.0" xmlns:media="http://search.yahoo.com/mrss/" version="2.0">
  <channel>
    <atom:link href="https://raw.githubusercontent.com/Stephan5/podcasts/refs/heads/main/feed/shower-cast/feed.xml" rel="self" type="application/rss+xml"/>
    <title>Shower Cast</title>
    <description>&lt;p&gt;The hottest takes in the coldest showers &lt;/p&gt;&lt;br/&gt;&lt;br/&gt;&lt;p&gt;Generated using Stephan5/podcasts.&lt;/p&gt;</description>
    <language>en-gb</language>
    <copyright>none</copyright>
    <link>https://github.com/Stephan5/podcasts/tree/main/feed/shower-cast</link>
    <image>
      <url>https://raw.githubusercontent.com/Stephan5/podcasts/refs/heads/main/feed/shower-cast/image.jpg</url>
      <title>Shower Cast</title>
      <link>https://github.com/Stephan5/podcasts/tree/main/feed/shower-cast</link>
    </image>
    <generator>Stephan5/podcasts</generator>
    <ttl>1440</ttl>
    <lastBuildDate>Sat, 24 May 2025 00:03:36 +0100</lastBuildDate>
    <pubDate>Sat, 24 May 2025 00:03:36 +0100</pubDate>
    <item>
      <link>https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_MP3.mp3?id=2</link>
      <guid>https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_MP3.mp3?id=2</guid>
      <title>1: Welcome to the cast</title>
      <description>Our very first epsiode!&lt;br/&gt;&lt;br/&gt;&lt;a href="https://github.com/Stephan5/podcasts" rel="nofollow noopener" target="_blank"&gt;Generated using Stephan5/podcasts&lt;/a&gt;</description>
      <pubDate>Sat, 24 May 2025 03:21:23 GMT</pubDate>
      <enclosure url="https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_MP3.mp3?id=2" length="103016" type="audio/mpeg"/>
    </item>
    <item>
      <link>https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_MP3.mp3?id=2</link>
      <guid>https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_MP3.mp3?id=2</guid>
      <title>2: Hot and cold</title>
      <description>The second one&lt;br/&gt;&lt;br/&gt;&lt;a href="https://github.com/Stephan5/podcasts" rel="nofollow noopener" target="_blank"&gt;Generated using Stephan5/podcasts&lt;/a&gt;</description>
      <pubDate>Sat, 31 May 2025 05:21:23 GMT</pubDate>
      <enclosure url="https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_MP3.mp3?id=2" length="103016" type="audio/mpeg"/>
    </item>
  </channel>
</rss>
```

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

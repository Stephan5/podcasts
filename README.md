# Podcasts
![](https://github.com/Stephan5/podcasts/actions/workflows/main.yml/badge.svg)
## Feeds
A collection of self-hosted podcast feeds for my own use, to ensure all the hottest 'casts are preserved.

## CLI

A Go CLI (`podcasts`) that replaces the legacy bash scripts. Build it with:

```shell
make build
# binary is written to build/podcasts
```

Or manually:

```shell
go build -o build/podcasts ./cmd
```

CSVs use `title`, `description`, `date`, `url` columns with the ASCII unit separator (`\x1F`) as the default delimiter. Dates must be RFC 2822 format.

### Commands

#### `csv2rss` — CSV → RSS XML feed

Each feed directory contains a `feed.json` that holds the podcast metadata. `csv2rss` loads it automatically; any flags you pass override the config.

```shell
# Uses feed.json in the same directory — no flags needed
./build/podcasts csv2rss ./feed/shower-cast/feed.csv

# Flags override feed.json values
./build/podcasts csv2rss ./feed/shower-cast/feed.csv --title "Override Title"
```

**`feed.json` format:**
```json
{
  "title": "Shower Cast",
  "description": "The hottest takes in the coldest showers",
  "author": "Someone",
  "delimiter": ";"
}
```

Optional fields: `delimiter` (default `\u001f`), `website_url`, `image_url`, `feed_url`.

Generates `feed.xml` alongside the CSV. Default URLs (feed, image, website) are derived from the GitHub repo path. Skips writing if feed content hasn't changed.

#### `rss2csv` — RSS XML → CSV

```shell
./build/podcasts rss2csv ./feed/shower-cast/feed.xml --repo-dir shower-cast
```

Parses an existing RSS XML feed and writes a CSV file sorted by publication date.

#### `selfhost` — Upload episodes to S3

```shell
./build/podcasts selfhost absolutely-mental --bucket my-podcast-bucket
./build/podcasts selfhost absolutely-mental --bucket my-podcast-bucket --region eu-west-2
./build/podcasts selfhost absolutely-mental --bucket my-podcast-bucket --prefix rss
```

Looks up `feed/<slug>/feed.csv` automatically. Downloads remote audio files and uploads them to S3 with numbered, slugified filenames (`001-episode-title.mp3`). Updates the CSV with the new S3 URLs in-place. Override the feed directory with `--feed-dir`.

#### `selfhost-orphans` — Find unreferenced S3 files

```shell
./build/podcasts selfhost-orphans absolutely-mental \
    --bucket my-podcast-bucket \
    --fail-on-orphans \
    --delete-orphans
```

Looks up `feed/<slug>/feed.csv` automatically. Compares S3 objects under the feed prefix against URLs in the CSV. Reports and optionally deletes orphaned files. Exits with code `2` if orphans found and `--fail-on-orphans` is set. Override the feed directory with `--feed-dir`.

#### `archive` — Download episodes locally

```shell
./build/podcasts archive ./feed/shower-cast ./archive/output
```

Downloads all episode audio to `output/shower-cast/items/` and writes a `local.csv` with `file://items/<filename>` URLs.

#### `pubdate` — Reformat date column

```shell
./build/podcasts pubdate ./feed/shower-cast/feed.csv --input-format "%b %d, %Y"
```

Parses dates using a strftime format and rewrites them as RFC 2822 (`Mon, 02 Jan 2006 03:00:00 GMT`). Backs up the original to `.old`.

#### `regenerate` — Regenerate feeds from feed.json

Each feed directory needs a `feed.json` (see `csv2rss` above) and a `feed.csv`. No `cmd.sh` required.

```shell
# Regenerate all feeds
./build/podcasts regenerate

# Regenerate a single feed
./build/podcasts regenerate --feed matt-and-shane

# Regenerate all except some
./build/podcasts regenerate --exclude "some-feed,another-feed"

# Specify a custom feed directory
./build/podcasts regenerate --feed-dir ./feed
```

### Testing

```shell
make test               # unit tests (internal/... cmd/...)
make test-integration   # build binary + run black-box integration tests in test/
make test-all           # both
```

## TODO
- [ ] Support updating existing feeds with new episodes from external feed
- [ ] Re-enable proper enclosure MIME type detection per file extension (`.m4a` → `audio/x-m4a`, `.wav` → `audio/wav` etc.) — currently hardcoded to `audio/mpeg` to match legacy bash behaviour; see `internal/urlutil/urlutil.go` `MimeTypeForExtension`

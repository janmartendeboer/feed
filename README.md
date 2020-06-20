# Introduction

*Feed* is a feed parser and emitter. It can be used as a command line alternative
to RSS readers.

# How to use

The feed container requires 2 volumes to be mounted in order to work as intended:

| Volume       | Suggested mount                 | Description |
|:-------------|:--------------------------------|:------------|
| `/app/cache` | `-v /tmp/feed-cache:/app/cache` | Store the feed items that have been seen before. |
| `/feeds`     | `-v $HOME/feeds:/feeds`         | Your feed configuration files. |

Run the feed parser and emitter as follows:

```bash
docker run \
  -v /tmp/feed-cache:/app/cache \
  -v $HOME/feeds:/feeds \
  johmanx10/feed
```

This will output new feed items, one on each line, encoded in JSON.

To make the most use of this output, it should be piped to another program,
like the one in `examples/notify-send.php`. This example processes the JSON
messages and forwards them to the `notify-send` program. The result of this is
a desktop notification for each new feed entry.

To try this, run the following: [^1]

```bash
docker run \
  -v /tmp/feed-cache:/app/cache \
  -v $HOME/feeds:/feeds \
  johmanx10/feed | examples/notify-send.php
```

[^1]: You need to have [PHP ^7.4 installed](https://www.php.net/manual/en/install.php) for this example.

If you set a scheduled task to run that command every minute, you get notified
of any new feed entries as they roll in.

# Create a feed

To create a feed, create a new JSON file according to our
[feed schema](https://raw.githubusercontent.com/johmanx10/feed/main/schemas/feeds.json).

Store it in your `feeds/` folder as a file ending in `.json`.

```json
{
  "$schema": "https://raw.githubusercontent.com/johmanx10/feed/main/schemas/feeds.json",
  "enabled": true,
  "name": "Tweakers.net Nieuws",
  "url": "http://feeds.feedburner.com/tweakers/mixed",
  "documentPath": "channel.item[*]",
  "projection": {
    "title": "title",
    "url": "guid",
    "date": "pubDate",
    "description": "description",
    "image": "'https://tweakers.net/logo.png'"
  },
  "filters": [
    "contains(category, 'Nieuws') || category == 'Nieuws'"
  ]
}
```

| Property       | Type    | Required | Description |
|:---------------|:--------|:--------:|:------------|
| `enabled`      | Boolean | Y        | Whether the feed will be processed or ignored. |
| `name`         | String  | Y        | The name of your feed configuration. |
| `url`          | String  | Y        | The URL of the feed. |
| `documentPath` | String  | Y        | The expression [^2] that determines how to find items in the document. |
| `projection`   | Object  | N        | Determine the structure of the output and map it to the input. |
| `projection.*` | String  | N        | The expression [^2] that determines how to find the value of the property. |
| `filters`      | Array   | N        | Filters to prevent matching items from being emitted. |
| `filters[*]`   | String  | N        | The expression [^2] that matches against the current item. |

[^2]: Expressions are [JMESPath expressions](https://jmespath.org/).

See also:

- [Nu.nl example feed](feeds/nu-nl.json) (Disabled)
- [Tweakers.net example feed](feeds/tweakers.json) (Enabled)

#!/usr/bin/env php
<?php

/**
 * This example parses the JSON encoded news items and forwards them to the
 * notify-send program, in order to get desktop notifications for any new item.
 *
 * Run this example by sending data to its STDIN.
 * E.g.:
 *  docker run \
 *   -v /tmp/feed-cache:/app/cache \
 *   -v $PWD/feeds:/feeds \
 *   johmanx10/feed 2>/dev/null \
 *   | examples/notify-send.php;
 */

/**
 * Get a local image path for the given feed item.
 *
 * @param stdClass $item
 *
 * @return string
 */
function getImage(stdClass $item): string
{
    /** @var string[] $imageCache */
    static $imageCache = [];

    if (!array_key_exists($item->image, $imageCache)) {
        // Store the image file locally.
        $image       = @tempnam('images', 'thumbnail');
        $imageDest   = fopen($image, 'wb');
        $imageSource = fopen(
            $item->image,
            'rb',
            false,
            stream_context_create(
                [
                    'ssl' => [
                        'verify_peer' => false
                    ]
                ]
            )
        );

        stream_copy_to_stream($imageSource, $imageDest);
        fclose($imageSource);
        fclose($imageDest);

        $imageCache[$item->image] = $image;
    }

    return $imageCache[$item->image];
}

$commands = [];

// Process input.
while (!feof(STDIN)) {
    $line = fgets(STDIN);

    if (empty($line)) {
        continue;
    }

    // Decode the item.
    $item  = json_decode($line);
    $image = getImage($item);

    // Send a notification to the desktop.
    $commands[] = sprintf(
        'notify-send -a "johmanx10/feed" -i %s -u low %s %s',
        escapeshellarg($image),
        escapeshellarg($item->description),
        escapeshellarg($item->url)
    );

}

// If there are commands, execute them now.
if (count($commands) > 0) {
    system(
        implode(
            ' && sleep 3 && ',
            $commands
        ) . ' &'
    );
}

##About

Simple bash script that converts all ebooks found in a directory to any specified format/device profile.
Post conversion the books are added to [Calibre](https://calibre-ebook.com), embedded metadata updated, and polished.

Note: as per the Calibre docs, polishing only works for AZW3 or EPUB formats.

## Configuration Options

/etc/defaults/calibre or environment variables

`DOWNLOADS`
Location of newly downloaed ebooks
`LIBRARY`
Path to calibre library
`CALIBRE_PATH`
Path to calibre installation
`CACHE_FILE`
Cache file that prevents re-polishing every book on each run
`CONVERT_FORMATS`
Valid formats to convert
`OUTPUT_FORMAT`
Desired ebook output format extension
`PROFILE`
Device profile: 'kindle_pw' for kindle paperwhite

## Example usage

[LazyLibrarian](https://github.com/lazylibrarian/LazyLibrarian) with "Calibre Auto Add" directory set to DOWNLOADS.

Install this script as a cron which moniors DOWNLOADS and takes action when new books arrive

```
*/10 * * * * /usr/local/bin/updatecalibre.sh &>> /tmp/update.log
```

The calibre mobile web GUI works well enough on kindle devices to directly download your freshly formated and polished azw3 ebooks.

This could also be modifed as a sabnzbd post processing script, or future enhancements could inlcude emailing the books directly to a kindle device.



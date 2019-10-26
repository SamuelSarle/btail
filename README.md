# Btail

Tail logs from a point in time. To find where to start btail uses binary search.
The end point can also be defined as a date. Alternatively you can get only n amount of lines using `--lines n`. If both the end date and a maxium are defined btail will stop at whichever comes first.

## Use

Example `btail --from_date 2019/08/04 test.log`

#### CLI options

| Option | Description |
| ------- | ------------ |
| --from_date | Define start as a date string () |
| --days_ago  | Define start as n days ago from today |
| --to_date | Define end as a date string |
| --days | Days forward from start of print |
| --lines | Print maximum of n lines |
| --help | Print help message |
| --test | Run tests |

#### Supported date formats:

* `YYYY/MM/DD HH:MM:SS`
* `DD/MM/YYYY HH:MM:SS`
* `Thu Jan  1 00:00:00 1970`

The first two can use any of `\s : / \ -` as their field seperator. `HH:MM:SS` is also optional.

## License

This is free and unencumbered software released into the [public domain](https://raw.githubusercontent.com/SamuelSarle/btail/master/LICENSE).

# Spare Cores Navigator Data Dumps

This repository contains filtered data dumps of the Spare Cores Navigator database,
collected via the [Spare Cores Crawler](https://github.com/sparecores/sc-crawler) tool.

The crawler is scheduled to run every 5 minutes to update spot prices of most
vendors (e.g. Azure lookups are slow so we cannot do that so frequently), and
hourly to update all region, availability zone, server, storage, traffic etc
vendor data at the supported vendors.

The most recent version of the collected data is available in a single
compressed SQLite database file. See the References section for exact location.

This repository contains JSON dumps of selected tables of this database to
facilitate data exploration and change tracking of records via git diffs. Note
that pricing and benchmark data is excluded due to repository size limits and
the high update frequency of these datasets.

## License

The data records published in this repository and the referenced SQLite database file are
licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

In case you are not comfortable with these licensing terms, please contact us
to discuss your needs.

## Use

- The JSON dumps of this repo are tagged with the version number of the
  `sparecores-crawler` tool that was used to generate them. In case you need a
  compatible dataset for an earlier version of the Crawler, you can check the
  tags and use the corresponding commit.
- Although most tables are included in this repository, some tables are excluded
  due to repository size limits and the high update frequency of these datasets.
  If you need pricing and benchmark data, you can use the SQLite database file
  referenced below.
- In case of Python, we recommend using the `sparecores-data` package to access
  the data, as it comes with helpers to automatically fetch the latest version
  of the database file and update it periodically in a background thread.
- For other languages or in case you are looking for a managed database
  solution, you can use our public Navigator API to query the data.

## Repository Structure

The repository is updated via the `dump` command of the `sparecores-crawler`
tool. In short, it creates a folder for each table of the SQLite database and
dumps each record as a prettified JSON file, named after its primary keys.

Example path for the `t3a.small` server record by `AWS`:

```
server/aws/t3a.small.json
```

Example to count the number of monitored servers with 200+ vCPUs:

```bash
$ find server -name '*.json' -exec cat {} \; | jq -c 'select(.vcpus > 200)' | wc -l
30
```

## Further References

- [`sparecores-crawler` documentation](https://sparecores.github.io/sc-crawler/)
- [Database schemas](https://dbdocs.io/spare-cores/sc-crawler)
- [Latest SQLite database release](https://sc-data-public-40e9d310.s3.amazonaws.com/sc-data-all.db.bz2)
- [sparecores-data Python package](https://pypi.org/project/sparecores-data/)
- [Navigator API](https://keeper.sparecores.net/docs)
- [sparecores.com](https://sparecores.com)

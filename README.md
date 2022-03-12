# The Launch Darkly Sync Utility

This utility will manage your Launch Darkly flags using a configuration file.

It will create the flags if they don't exist and then turn on/off the flags based on the status.

## Installation

To install using [brew on Mac or Linux](https://brew.sh/):

Install ldsync
```sh
brew tap drujensen/ldsync
brew install ldsync
```

You will need to a [Launch Darkly API access token](https://docs.launchdarkly.com/home/account-security/api-access-tokens) to use this utility.

Add this to your shell profile or set this environment variable before using:
```sh
export LDSYNC_TOKEN="{API access token}"
```

Next, create a config file in `config/ldsync.yml`.

Here is an example:
```yaml
project: {project-key}
environment: {environment-key}
flags:
  EXAMPLE_ON_FLAG:
    name: "Example On Flag"
    status: true
  EXAMPLE_OFF_FLAG:
    name: "Example Off Flag"
    status: false
```

The following environment variables are supported:
  LDSYNC_TOKEN - Launch Darkly Access Token
  LDSYNC_PROJECT - Launch Darkly Project Key
  LDSYNC_ENVIRONMENT - Launch Darkly Environment Key

## Usage

Usage: ldsync
    -v, --version                    Show version
    -h, --help                       Show help
    -c FILE, --config=FILE           Path to the config file

## Development

This was built using the [Crystal Language](https://crystal-lang.org/).

To build the application:
```bash
crystal build src/ldsync.cr
```

To run the application:
```bash
bin/ldsync
```

## Contributing

1. Fork it (<https://github.com/drujensen/ldsync/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Dru Jensen](https://github.com/drujensen) - creator and maintainer

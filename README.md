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

You should add this token to your shell profile or set this environment variable before using:
```sh
export LD_TOKEN="{API access token}"
```

## Usage

To start off, we need to create a config file.  The default location of the config file is: `config/ldconfig.yml`

### Initialize config file

To create an example config file:
```sh
ldsync init
```

If you need to specify a different location, you will need to use the `-c` flag:
```sh
ldsync init -c example.yml
```

Here is what the config file looks like:
```yaml
project: {project-key}
environment: {environment-key}
flags:
- key: example-flag
  name: Example Flag
  enabled: true
```

### Push to Launch Darkly

After setting up the config file, you can push the changes to Launch Darkly.  This will create the project, environment, flags, and value.  If the resource already exists, it will skip it. Your access token will need permission to create the resources that do not already exist.

To push the changes:
```sh
ldsync push
```

### Pull from Launch Darkly

If you make changes in Launch Darkly UI and you want to pull those changes down into the config file, you can do that will the pull command.  This will replace all the flags in the config file with the ones setup in Launch Darkly.  It will pull the settings based on the environment you have chosen.

To pull the changes:
```sh
ldsync pull
```

## Enviroment Variables

There are cases where you want to override the Token, Project or Environment.  You can do this using environment variables.
The following environment variables are supported:
```sh
LD_TOKEN={Launch Darkly Access Token}
LD_PROJECT={Launch Darkly Project Key}
LD_ENVIRONMENT={Launch Darkly Environment Key}
```

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

# homebrew-opensource

The Springer Nature open source Homebrew tap.

Status: active. Hosts formulae for Springer Nature's open-source command-line tools.

## Supported platforms

- macOS and Linux, wherever [Homebrew](https://brew.sh) itself is supported.

## Install

Add this tap, then install a formula from it:

```sh
brew tap springernature/opensource
brew install <formula>
```

or in one step:

```sh
brew install springernature/opensource/<formula>
```

## Available formulae

- [`opencode-copilot-credit-estimator`](Formula/opencode-copilot-credit-estimator.rb) (alias: `occe`) — terminal UI for estimating GitHub Copilot AI credit usage from [opencode](https://opencode.ai) session logs.

## Usage

Once installed, each tool is available as its own command, e.g.:

```sh
opencode-copilot-credit-estimator --help
```

See each project's own repository/README for full usage details.

## License

Released under the [MIT License](LICENSE).

## Maintenance & support

Maintained by Springer Nature on a best-effort basis. New formulae are added as further Springer Nature open-source CLI tools are released. Bug reports and pull requests are welcome via [GitHub Issues](https://github.com/springernature/homebrew-opensource/issues). There is no guaranteed response time or SLA.

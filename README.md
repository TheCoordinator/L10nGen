# iOS L10n Generator

A command line tool to generate localisation files and sources for Loco iOS Loco App.

## Installation

Best way to install is via mint

### [Mint](https://github.com/yonaskolb/mint)

```sh
$ mint install https://github.com/TheCoordinator/L10nGen.git@1.0.0
```

Or via `Mintfile`

```
https://github.com/TheCoordinator/L10nGen.git@1.0.0
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

**Use CLI**

```sh
$ git clone https://github.com/TheCoordinator/L10Gen.git
$ cd L10nGen
$ swift run L10nGen --config .l10ngen.yml
```

## Usage

### Mint

```sh
mint run TheCoordinator L10nGen --config .l10ngen.yml
```

### Swift Package Manager

```sh
$ cd L10nGen
$ swift run L10nGen --config .l10ngen.yml
```

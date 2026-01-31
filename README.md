# Use Castle Game Engine in CI/CD like GitHub Actions

Script [setup_castle_engine](./setup_castle_engine) to easily setup:

- [Castle Game Engine](https://castle-engine.io/)

- and [FPC (Free Pascal Compiler](https://www.freepascal.org/) (with [recommended version for CGE](https://github.com/castle-engine/castle-fpc/))

- and [Lazarus](https://www.lazarus-ide.org/) (with [recommended version for CGE](https://github.com/castle-engine/castle-lazarus/)). Note that Lazarus is not installed by default (because regular CGE projects don't need it), pass `--install-lazarus=true` to install it.

The primary usage is within CI/CD, like [GitHub Actions](https://castle-engine.io/github_actions) (but also other CI/CD systems).

## Details what it does

Overall goal: After the `setup_castle_engine` script is called, you can use `castle-engine package` within your CI job to package your project.

The script enhances the `$PATH` variable (and sets up a few other environment variables) to include FPC and CGE build tool by:

- enhancing `$GITHUB_ENV` and `$GITHUB_PATH` (if defined, within GitHub Actions)

- and generating `setup_castle_engine_env.sh` (this is useful for non-GitHub Action CI, and even within GHA to define variables within the same step).

Details what it does:

- Get and setup FPC recommended to use with CGE.

    Downloads FPC (to fpc/ subdir) from our [castle-fpc](https://github.com/castle-engine/castle-fpc) releases which have prebuild FPC binary + FPC sources.

    And sets up `fpc.cfg` to use it properly (see `castle-fpc/README.md` docs). The environment variable `$PPC_CONFIG_PATH` will point to it.

- Get and setup CGE in recommended way for CI/CD.

    This downloads CGE sources from the `snapshot` tag by default (latest engine that passed automatic tests) and builds our [build tool ("castle-engine")](https://castle-engine.io/build_tool) and sets `$CASTLE_ENGINE_PATH` and `$PATH` to use it.

## Usage

Simply checkout this repo, and run `setup_castle_engine`.

This is a _bash_ script. On GitHub-hosted runners, _bash_ is available on all systems, including Windows (through MSys2).

## Usage example in GitHub Actions

```yaml
...
defaults:
  run:
    shell: bash

jobs:
  build:
    name: Build Project using castle-build-ci
    strategy:
      matrix:
        runner: [
          ubuntu-latest,
          windows-latest
        ]
    runs-on: ${{ matrix.runner }}
    steps:
      - name: Checkout application
        uses: actions/checkout@v6

      - name: Setup Castle Game Engine
        run: |
          cd /tmp/ # temporary directory, to be separate from the current project files
          git clone https://github.com/castle-engine/castle-build-ci.git \
            --depth=1 --single-branch --branch=master
          castle-build-ci/install_dependencies
          castle-build-ci/setup_castle_engine

      - name: Package
        run: castle-engine package --verbose
```

More complete example in the workflow within this repo, which is our own test: [.github/workflows/test.yml](.github/workflows/test.yml).

## Optional command-line arguments:

- `--os=<os>`

    OS (operating system) name, following the FPC naming conventions. This specifies both source and target OS. See [castle-fpc/build_fpc](https://github.com/castle-engine/castle-fpc/blob/master/build_fpc) script documentation for details why it is useful, (despite specifying both source and target OS). We auto-detect it if not specified.

- `--cpu=<cpu>`

    CPU (processor, architecture) name, following the FPC naming conventions. This specifies both source and target CPU. We auto-detect it if not specified.

- `--castle-engine-version=<git-branch-or-tag>`

    Castle Game Engine version (GIT [branch](https://github.com/castle-engine/castle-engine/branches) or [tag name](https://github.com/castle-engine/castle-engine/tags)). We use `snapshot` by default.

- `--fpc-version=stable|unstable`

    FPC version to use. See [castle-fpc](https://github.com/castle-engine/castle-fpc) for the exact meaninig of `stable` and `unstable`, in short:

    - `stable` is the "best stable" FPC version that we test with CGE. Equals now FPC 3.2.2 on most platforms, and 3.2.3 (from `fixes_3_2` branch) some some exceptions.

    - `unstable` is a particular tested commit of the FPC `main` branch, with FPC 3.3.1.

    We use `stable` by default.

- `--install-castle-engine=true|false`

    Install _Castle Game Engine_. Enabled by default.

- `--install-fpc=true|false`

    Install _FPC (Free Pascal Compiler)_. Enabled by default.

    Note that you need `fpc` to install CGE or Lazarus, so if you pass `--fpc=false` we assume that you have installed FPC in your CI job in some other way (e.g. `apt-get install fpc` on Linux). We also assume it's a version [supported by CGE](https://castle-engine.io/supported_compilers.php#section_fpc_version).

- `--install-lazarus=true|false`

    Install _Lazarus_. Disabled by default.

Example execution with parameters:

```
setup_castle_engine --os=linux --cpu=x86_64 --castle-engine-version=v7.0-alpha.3
```

## Current directory

Current directory when this is called matters:

- We will create `fpc/` and `castle-engine/` subdirs there.

- We will create `setup_castle_engine_env.sh` there.

- In CI jobs, it is most comfortable to use a temporary directory like `/tmp/`, also to clone this repo (`castle-build-ci`) into a temporary directory. See above for example usage.

## Environment variables and usage outside of GitHub Actions

The script defines a few environment variables which should "survive" to the next steps.

- The variable definitions are written to `setup_castle_engine_env.sh`, which is a bash script that you can `source` to load the variables.

- We also write variables (except `PATH`) following [GitHub Actions conventions](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#environment-files) to `$GITHUB_ENV`.

- We also write path extensions to `$GITHUB_PATH`. See [github_actions_prepend_path.md](github_actions_prepend_path.md) for more information.

There are 2 practical conclusions:

- If you want to rely on new environment variables within the _same CI step_, you need to `source setup_castle_engine_env.sh` after running `setup_castle_engine`.

    This goes for both usage in GitHub Actions and in other CI systems.

    Like this:

    ```shell
    castle-build-ci/setup_castle_engine ...
    source setup_castle_engine_env.sh
    ```

- To use this script outside of _GitHub Actions_, do `source setup_castle_engine_env.sh` to load the variables at the beginning of all future steps to have the variables available.

## Alternatives to setup FPC and CGE in CI/CD

This is by far not the way to setup FPC and CGE in CI/CD.

Alternatives:

- You can use our [Docker images](https://castle-engine.io/docker) that give you ready FPC and CGE tools, with cross-compilers for various platforms.

    It's more powerful in some ways than this script. E.g. Docker has FPC with cross-compiler for Android, and Android build toolchain.

    However, our Docker images cannot be used to make macOS builds. This script can.

- Or you can get only FPC using:
  - [setup-lazarus action](https://github.com/gcarreno/setup-lazarus)
  - Or by installing it in runners from packages, like `brew install fpc` (macOS) or `apt-get install fpc` (Linux).

- Or you can get only CGE by:
  - just `git clone` the [CGE repository](https://github.com/castle-engine/castle-engine/) and build the _build tool_ following [instructions](https://castle-engine.io/compiling_from_source.php). This is what we do in the 2nd part of `setup_castle_engine` script for you, but it's really not difficult to do it yourself :)
  - downloading [binary release](https://github.com/castle-engine/castle-engine/releases/snapshot) using `curl` or `wget` in your script.

## See also: Apple signing scripts

As a bonus, see [apple/README.md](apple/README.md) for scripts to sign and notarize macOS applications.

If you make macOS applications, you can use these scripts to have your application signed and notarized automatically in CI/CD.

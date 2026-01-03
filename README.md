# Use Castle Game Engine in CI/CD like GitHub Actions

Script [setup_castle_engine](./setup_castle_engine) to easily setup:

- [Castle Game Engine](https://castle-engine.io/)

- and [FPC (Free Pascal Compiler](https://www.freepascal.org/) (with [recommended version for CGE](https://github.com/castle-engine/castle-fpc/)).

The primary usage is within CI/CD, like [GitHub Actions](https://castle-engine.io/github_actions) (but also other CI/CD systems).

## Usage

Simply checkout this repo, and run `setup_castle_engine`.

This is a _bash_ script. On GitHub-hosted runners, _bash_ is available on all systems, including Windows (through MSys2).

Gets CGE code from `snapshot` branch (latest bleeding edge version that passed auto-tests).

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
        include:
          - runner: ubuntu-latest
            build_os: linux
            build_cpu: x86_64
          - runner: windows-latest
            build_os: win64
            build_cpu: x86_64
    runs-on: ${{ matrix.runner }}
    steps:
      - name: Checkout application
        uses: actions/checkout@v6
        with:
          # We need to checkout main application to the app/
          # subdirectory of the workspace, to not collide (and not clean)
          # repos castle-engine/ and fpc/ which we will also place in
          # $GITHUB_WORKSPACE.
          path: app/

      - name: Setup Castle Game Engine
        run: |
          git clone https://github.com/castle-engine/castle-build-ci.git \
            --depth=1 --single-branch --branch=master
          castle-build-ci/install_dependencies_github_hosted_runner
          castle-build-ci/setup_castle_engine ${{ matrix.build_os }} ${{ matrix.build_cpu }}

      - name: Package
        run: cd app && castle-engine package --verbose
```

More complete example in the workflow within this repo, which is our own test: [.github/workflows/test.yml](.github/workflows/test.yml).

## Environment variables and usage outside of GitHub Actions

The script defines a few environment variables which should "survive" to the next steps. It is done following [GitHub Actions conventions](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#environment-files), so it writes the variables to `$GITHUB_ENV`.

To use this script outside of _GitHub Actions_, just
- define `GITHUB_ENV` to point to some writeable file location.
- `source $GITHUB_ENV` in the next steps to load the variables.

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


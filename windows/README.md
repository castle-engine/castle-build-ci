# Scripts to sign Windows applications using Azure Artifact Signing

## There are many ways to sign on Windows, these scripts show just one of them

There are multiple ways to sign Windows applications. In general, you want to

1. buy a certificate
  (or get someone like SignPath to sign for you, if you have OSS project),

2. perform the signing
  (using signtool from Windows SDK, or jsign + osslsigncode, or a dedicated
  GitHub Action like SignPath).

These scripts perform signing using the solution we chose for [Castle Game Engine](https://castle-engine.io/) distribution:

- _Azure Artifact Signing_ from Microsoft.

    ( _Why not SignPath?_ We experimented with SignPath, but then we could not sign [FPC releases we build and ship with CGE](https://github.com/castle-engine/castle-fpc) since FPC is a 3rd-party project for us. It would be nice if we could just use official FPC releases, but we need newer versions -- FPC >= 3.2.3 for macOS / Raspberry Pi, and even newer FPC with WebAssembly support for [our web target](https://castle-engine.io/web). So for now, we need to build and thus sign own FPC releases. )

- We use `signtool` from Windows SDK, and the ArtifactSigning DLL from Microsoft.

    We also experimented with cross-platform `jsign` + `osslsigncode`, they rock and can be used with _Azure Artifact Signing_. But in the end we didn't need this option for now.

## Usage

In short: In your CI workflow, like [GitHub Actions](https://castle-engine.io/github_actions) workflow, call `setup_signing` and then `sign_executable` scripts from this directory to sign your Windows executables.

Note that _Azure Artifact Signing_ requires to be logged-in to Azure, like by Azure CLI `az login`. See Azure docs how to be logged-in inside CI like GitHub actions. The recommended way to do this uses _federated credentials_ and GitHub secrets, and is in turn limited to specific branches. So you typically sign only specific branches.

## Example

```yaml
# Login to Azure.
# sign_executable (SignTool or jsign inside) depend on this to sign executables
# with Azure Artifact Signing.
- name: Azure Login (Windows)
  if: ${{ runner.os == 'Windows' && github.ref == 'refs/heads/master' }}
  uses: azure/login@v3
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

- name: Sign (Windows)
  if: ${{ runner.os == 'Windows' && github.ref == 'refs/heads/master' }}
  env:
    AZURE_ENDPOINT: ${{ vars.AZURE_ENDPOINT }}
    AZURE_CODESIGNING_ACCOUNT_NAME: ${{ vars.AZURE_CODESIGNING_ACCOUNT_NAME }}
    AZURE_CERTIFICATE_PROFILE_NAME: ${{ vars.AZURE_CERTIFICATE_PROFILE_NAME }}
  run: |
    export AZURE_SIGNING_CLIENT_PARENT="$RUNNER_TEMP/sign-tools/"
    /tmp/castle-build-ci/windows/setup_signing
    /tmp/castle-build-ci/windows/sign_executable \
      "`castle-engine output executable-name`.exe"
```

## Script documentation

`setup_signing` simply installs ArtifactSigning DLL from Microsoft
into `$AZURE_SIGNING_CLIENT_PARENT` directory.

`sign_executable` signs executables (given on the command line).

- Multiple files can be provided as parameters on command line, to sign at once.
- Directory can be provided to find all `*.exe`, `*.dll` inside it (recursively).
- All filenames and directory names are expected to be native Windows paths
  (not Cygwin paths), absolute or relative.

These are bash scripts, suitable for all bash flavors on Windows
(_Cygwin_, _MSys2_, _Git Bash_).

They run on Windows (like your normal Windows system,
or a Windows runner (GH-hosted or self-hosted) in GitHub Actions).
Require Windows as we use Azure DLL, and SignTool from Windows SDK,
which are Windows-only.
(An equivalent is possible using `jsign` + `osslsigncode`, but in the end
we didn't need it for now.)

Requirements:

- SignTool from Windows SDK in `C:\Program Files (x86)\Windows Kits\10\bin\10.*\x64\signtool.exe`
  (this is already installed in GHA runners)

- Being logged-in to Azure, like by Azure CLI `az login`.
  See Azure docs how to be logged-in inside CI like GitHub actions.

- Environment variable `AZURE_SIGNING_CLIENT_PARENT` must point
  to a directory where the ArtifactSigning DLL from Microsoft will be installed
  by `setup_signing` and then used by `sign_executable`.

    This directory doesn't have to exist before `setup_signing`,
    it will be created if needed.

    It can be really any directory, it can be a temporary directory
    if you are on an ephemeral CI runner (like GitHub Actions)
    and so you always call `setup_signing` before `sign_executable`.
    Example is `$RUNNER_TEMP/sign-tools/`.

- Additional environment variables provide metadata for signing.
  Must be synchronized with your Azure Artifact Signing configuration:

    - `AZURE_ENDPOINT` - for example `plc.codesigning.azure.net`
    - `AZURE_CODESIGNING_ACCOUNT_NAME` - for example `cge-artifact-signer`
    - `AZURE_CERTIFICATE_PROFILE_NAME` - for example `cge-sign-releases`

    These variables are used to generate a JSON metadata for signing,
    as documented in Azure docs:
    https://learn.microsoft.com/en-us/azure/artifact-signing/how-to-signing-integrations .

    `SignTool` takes this metadata as a JSON file, while `jsign` takes them
    as command line parameters. Provide them as environment variables,
    and forget about differences between `SignTool` and `jsign`.

    Note that the values visible above are not secret.
    You can place them in repo files, or as repo variables
    (like GitHub Actions `vars`).

## Why express this as bash scripts, not GitHub Actions?

There are already [GitHub Actions to sign Windows executables using Azure](https://github.com/Azure/artifact-signing-action). I prefer to wrap it in reusable bash scripts, because:

- It allows to perform signing in the middle of another script. For example:

    - Signing can be done in the middle of [castle-fpc/build_fpc](https://github.com/castle-engine/castle-fpc/blob/master/build_fpc).

    - Signing can be done in the middle of [castle-engine/.../pack_release.sh](https://github.com/castle-engine/castle-engine/blob/master/tools/internal/pack_release/pack_release.sh).

    Both above scripts perform multiple steps, and signing is just one of them. If signing was a GitHub Action, we would need to split the script in two, reinitializing variables. This makes maintenance harder, and we would need more and more splits for platform-specific needs: e.g. Apple requires, after signing, also to notarize the application bundle (so, split the `pack_release.sh` script more). On Windows, InnoSetup needs to sign uninstaller.

    Doing such "splitting scripts" means that we move logic from bash scripts to YAML files in GitHub Actions. YAML files would get longer and more complex, and would execute smaller and simpler bash scripts. I prefer to keep the logic in bash scripts.

- Moreover, it gives us some independence from GitHub Actions. To some extent, these scripts are useful in other CI systems, or even locally on our own Windows machine.

    It keeps the door open for [full migration from GitHub to Codeberg](https://castle-engine.io/wp/2026/01/18/engine-downloads-with-bundled-fpc-for-all-platforms-castle-build-ci-to-easily-use-ci-with-our-engine-woodpecker-codeberg-ci-examples-and-impressions/).


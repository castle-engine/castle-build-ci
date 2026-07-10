# Scripts to sign Windows applications using Azure Artifact Signing

## There are many ways to sign on Windows, these scripts show just one of them

There are multiple ways to sign Windows applications. In general, you want to

1. buy a certificate
  (or get someone like SignPath to sign for you, if you have OSS project),

2. perform the signing
  (using signtool from Windows SDK, or jsign + osslsigncode, or a dedicated
  GitHub Action like SignPath).

These script perform signing using the solution we chose for [Castle Game Engine](https://castle-engine.io/) distribution:

- _Azure Artifact Signing_ from Microsoft.

    ( _Why not SignPath?_ We experimented with SignPath, but then we could not sign [FPC releases we build and ship with CGE](https://github.com/castle-engine/castle-fpc) since FPC is a 3rd-party project for us. It would be nice if we could just use official FPC releases, but we need newer versions -- FPC >= 3.2.3 for macOS / Raspberry Pi, and even newer FPC with WebAssembly support for [our web target](https://castle-engine.io/web). So for now, we need to build and thus sign own FPC releases. )

- We use `signtool` from Windows SDK, and the ArtifactSigning DLL from Microsoft.

    We also experimented with cross-platform `jsign` + `osslsigncode`, they rock and can be used with _Azure Artifact Signing_. But in the end we didn't need this option for now.

## Usage

In short: In your CI workflow, like [GitHub Actions](https://castle-engine.io/github_actions) workflow, call `setup_signing` and then `sign_executable` scripts from this directory to sign your Windows executables.

Note that _Azure Artifact Signing_ requires to be logged-in to Azure, like by Azure CLI `az login`. See Azure docs how to be logged-in inside CI like GitHub actions. The recommended way to do this uses _federated credentials_ and GitHub secrets, and is in turn limited to specific branches. So you typically sign only specific branches.

## Example

```yaml
# Login using Azure, SignTool depends on this to sign executables with Azure Artifact Signing.
- name: Azure Login (Windows)
  if: ${{ runner.os == 'Windows' && ( github.ref == 'refs/heads/master' || github.ref == 'refs/heads/test-windows-signing' ) }}
  uses: azure/login@v3
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

- name: Sign (Windows)
  if: ${{ runner.os == 'Windows' && ( github.ref == 'refs/heads/master' || github.ref == 'refs/heads/test-windows-signing' ) }}
  run: |
    export AZURE_SIGNING_METADATA="windows-signing/azure_metadata.json"
    export AZURE_SIGNING_CLIENT_PARENT="$RUNNER_TEMP/sign-tools/"
    /tmp/castle-build-ci/windows/setup_signing
    /tmp/castle-build-ci/windows/sign_executable \
      "`castle-engine output executable-name`.exe"
```

## Script documentation

`setup_signing` simply installs ArtifactSigning DLL from Microsoft
into `$AZURE_SIGNING_CLIENT_PARENT` directory.

`sign_executable` signs executables (given on command line).
Multiples files can be provided as parameters on command line, to sign at once.
Filenames are expected to be Windows executables (EXE, DLL, etc)
with native paths (not Cygwin paths), absolute or relative.

Both are bash scripts, suitable for all bash flavors on Windows
(_Cygwin_, _MSys2_, _Git Bash_).

They run on Windows (like your normal Windows system,
or a Windows runner (GH-hosted or self-hosted) in GitHub Actions).
Require Windows as we use Azure DLL, and SignTool from Windows SDK,
which are Windows-only.
(An equivalent is possible using `jsign` + `osslsigncode`, but in the end
we didn't need it for now.)

Requirements:

- SignTool from Windows SDK in `C:\ProgramFiles(x86)\Windows Kits\10\bin\10.*\x64\signtool.exe`
  (this is already installed in GHA runners)

- Being logged-in to Azure, like by Azure CLI `az login`.
  See Azure docs how to be logged-in inside CI like GitHub actions.

- `AZURE_SIGNING_METADATA` environment variable must be set to
  JSON metadata for signing.
  See https://learn.microsoft.com/en-us/azure/artifact-signing/how-to-signing-integrations .

  This looks like:

  ```
  {
    "Endpoint": "https://plc.codesigning.azure.net",
    "CodeSigningAccountName": "cge-artifact-signer",
    "CertificateProfileName": "cge-sign-releases"
  }
  ```

# Scripts to sign (and notarize) macOS applications

These scripts perform the complete process of _signing_ and _notarizing_  macOS applications.

- [Signing](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac) means we use `codesign` to confirm that the executables are created by a trusted developer.

- [Notarizing](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow?language=objc) means applications are uploaded to Apple servers for further verification.

You want to perform the above steps, to have macOS application that runs "out of the box" for users without any warnings / errors from Apple.

NOTE: In order to use this, you must be [Apple Developer (100 USD per year)](https://developer.apple.com/).

## Usage

In the simplest case, once you have cloned https://github.com/castle-engine/castle-build-ci to `/tmp/` in your runner, you just do a step like this:

```yaml
- name: Sign and Notarize (macOS)
  if: ${{ runner.os == 'macOS' }}
  env:
    # for codesigning
    APPLE_IDENTITY: ${{ vars.APPLE_IDENTITY }}
    APPLE_BUILD_CERTIFICATE_BASE64: ${{ secrets.APPLE_BUILD_CERTIFICATE_BASE64 }}
    APPLE_P12_PASSWORD: ${{ secrets.APPLE_P12_PASSWORD }}
    APPLE_KEYCHAIN_PASSWORD: ${{ secrets.APPLE_KEYCHAIN_PASSWORD }}
    # for notarization
    APPLE_ID: ${{ vars.APPLE_ID }}
    APPLE_TEAM_ID: ${{ vars.APPLE_TEAM_ID }}
    APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
  run: |
    /tmp/castle-build-ci/apple/setup_signing
    /tmp/castle-build-ci/apple/sign_notarize_bundle \
      castle-model-viewer.app castle-model-viewer
```

You will need to setup some [secrets and variables](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) in your GitHub repository (or organization) settings, as seen above. Follow the [Installing an Apple certificate on macOS runners for Xcode development](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications) for links how to do it.

NOTE: The above split into GitHub _secrets_ and _variables_ is just an example. Our scripts just expect appropriate environment variables to be set, how you achieve it is up to you.

Full example: See the [Castle Model Viewer](https://castle-engine.io/castle-model-viewer) workflow for GitHub Actions: https://github.com/castle-engine/castle-model-viewer/blob/master/.github/workflows/build.yml

## Background and a small Apple rant

Apple makes runnning unsigned applications harder and harder for users. Whether it's motivated, at this point, by real security concerns (don't run applications from devs you don't trust, whether they are signed or not), or by their obsessive need to control everything that is distributed in the Apple ecosystem, is another question which I leave for you to decide.

- Older macOS versions forced users to perform unintuitive UX to run unsigned applications (double-clicking would not allow it, but right-click + open would have the option to still run unsigned).

- Latest macOS versions take it a step further, showing very misleading error message: _""xxx.app" is damaged and can’t be opened. You should move it to the Bin"_. Nothing is actually damaged, just the application is placed in a "quarantine" and its unsigned. As a workaround, users now have to execute in _Terminal_ command like this:

  ```shell
  # for Castle Model Viewer
  xattr -cr ~/Downloads/castle-model-viewer.app
  # for Castle Game Engine (all applications inside)
  xattr -cr ~/Downloads/castle_game_engine/
  ```

But for the casual user, this looks more and more difficult, and also alarming, to do such tricks before using your application. So it's better to follow Apple recommendations, pay them 100 USD annually, and use scripts from this directory (which work automatically and are tested in CI) to sign and "notarize" your applications.

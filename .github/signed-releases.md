# Release automation

The **Release Please** workflow calls SevenTwo's [shared signed release workflow](https://github.com/seventwo-studio/.github/blob/94665c6663d78c16a3b174e3513bb4a2ff06c4e8/docs/signed-releases.md). Keep that workflow name: Docker publishing listens for its successful completion.

Before adopting the caller, install **SevenTwo Releases** on this repository and configure:

- Actions variable `RELEASE_APP_CLIENT_ID`: the App's public Client ID.
- Actions secret `RELEASE_APP_PRIVATE_KEY`: the App's PEM private key.

Each run mints an installation token scoped to Runner, creates or updates release PRs as the App bot, and verifies commit signatures. This satisfies the enterprise's signed-commit rule while allowing release PRs to trigger required CI.

Merge the shared workflow PR before this migration PR. Then manually dispatch **Release Please** on `main` and verify the App bot's commit is **Verified**, all required PR checks run, and the signature rule allows merging. Keep `RELEASE_PLEASE_TOKEN` until that live cutover succeeds; the new workflow does not use it. Do not revoke a PAT used elsewhere.

The same shared workflow can be used by personal and other SevenTwo repositories, with separate App installations and explicit repository selection. See the shared documentation for configuration and credential rotation.

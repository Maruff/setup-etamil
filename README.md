# setup-etamil

A GitHub Action that installs the [eTamil](https://etamil.in) compiler on the
runner and can check your `.qmz` files.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: Maruff/setup-etamil@v1
    with:
      version: latest          # or 1.4.2
      check: "src/**/*.qmz"    # optional: etamil --check on each, fail on errors
  - run: etamil src/main.qmz
```

| Input | Default | |
|---|---|---|
| `version` | `latest` | A release such as `1.4.2`, or `latest`. |
| `check` | none | Glob of files to check. `--check` lexes, parses and type-checks and never runs the program. |

Output: `version`, the version installed. The action also sets `ETAMIL_PATH`, so
`இறக்கு "nUlakam/..."` resolves in later steps.

Runners: Linux (x64, arm64), macOS (x64, arm64), Windows (x64). Each download is
checked against the SHA-256 published with the release.

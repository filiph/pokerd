# Release Process

This project uses a fully automated release pipeline powered by GitHub Actions. When a new version tag is pushed, the pipeline automatically:

1. Compiles native executables for macOS (ARM64), Linux (x64, ARM64), and Windows (x64, ARM64).
2. Creates a GitHub Release with the compiled binaries attached.
3. Publishes the package to `pub.dev` using OIDC authentication.
4. Updates the Homebrew tap (`filiph/homebrew-tap`) to point to the new release.

## How to Release a New Version

To trigger this pipeline, follow these manual steps:

1. **Bump the version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.15
   ```

2. **Update the Changelog** by adding a new section at the top of `CHANGELOG.md`. The header must exactly match the new version:
   ```markdown
   ## 1.0.15
   
   - Describe your changes here.
   ```

3. **Commit and Tag** the release. The tag must start with `v`:
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "chore: release 1.0.15"
   git tag v1.0.15
   ```

4. **Push** the commit and the tag to GitHub:
   ```bash
   git push origin main
   git push origin v1.0.15
   ```

Once pushed, you can monitor the progress in the **Actions** tab on GitHub.

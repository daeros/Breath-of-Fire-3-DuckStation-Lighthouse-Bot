# Publishing to GitHub

Suggested repository name:

```text
bof3-lighthouse-bot
```

Suggested description:

```text
AutoHotkey v2 timing helper for the Breath of Fire III Lighthouse boiler minigame in DuckStation.
```

Suggested topics:

```text
breath-of-fire-3
breath-of-fire-iii
duckstation
autohotkey
autohotkey-v2
playstation
ps1
automation
```

## Create the repository with Git

From a terminal opened inside this folder:

```bash
git init
git add .
git commit -m "Release v1.0.0"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/bof3-lighthouse-bot.git
git push -u origin main
```

Create the empty repository on GitHub before running the `git remote add` command.

## Tag v1.0.0

```bash
git tag -a v1.0.0 -m "BOF3 Lighthouse Bot v1.0.0"
git push origin v1.0.0
```

## Create the GitHub Release

On GitHub:

1. Open the repository.
2. Click **Releases**.
3. Click **Draft a new release**.
4. Choose tag `v1.0.0`.
5. Title it `BOF3 Lighthouse Bot v1.0.0`.
6. Paste the contents of `RELEASE_NOTES_v1.0.0.md`.
7. Attach `BOF3-Lighthouse-Bot-v1.0.0.ahk`.
8. Optionally attach `BOF3-Lighthouse-Bot-v1.0.0.zip`.
9. Publish the release.

## GitHub CLI alternative

If `gh` is installed and authenticated:

```bash
gh repo create bof3-lighthouse-bot --public --source=. --remote=origin --push
git tag -a v1.0.0 -m "BOF3 Lighthouse Bot v1.0.0"
git push origin v1.0.0
gh release create v1.0.0   BOF3-Lighthouse-Bot-v1.0.0.ahk   BOF3-Lighthouse-Bot-v1.0.0.zip   --title "BOF3 Lighthouse Bot v1.0.0"   --notes-file RELEASE_NOTES_v1.0.0.md
```

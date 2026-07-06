# Wiki Setup Guide

This wiki content is stored in `.github/wiki/`. GitHub Wikis are separate git repositories. To sync this content to your GitHub wiki:

## One-Time Setup

```bash
# On GitHub: go to your repo → Wiki → Create the first page
# Then clone the wiki repo:

git clone https://github.com/samsesh/OpenHostingNOC.wiki.git
```

## Sync Content

```bash
# Copy wiki files
cp .github/wiki/*.md OpenHostingNOC.wiki/

# Push to GitHub
cd OpenHostingNOC.wiki
git add .
git commit -m "Sync wiki content"
git push
```

## Auto-Sync via GitHub Actions

Add this workflow to `.github/workflows/sync-wiki.yml`:

```yaml
name: Sync Wiki
on:
  push:
    branches: [main]
    paths:
      - '.github/wiki/**'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: leonstafford/git-auto-push-wiki@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          wiki_dir: .github/wiki
```

## Wiki Files

| File | Purpose |
|---|---|
| `Home.md` | Landing page |
| `_Sidebar.md` | Navigation sidebar |
| `_Footer.md` | Footer for all pages |
| `*.md` | Individual page content |
| `images/` | Screenshots and diagrams |

# milestone.github.io

My personal blog: [https://milestone.topics.it](https://milestone.topics.it)

Start with:  `jekyll serve --force_polling [--incremental] [--drafts]` on BashOnWindows to enable live rebuild, aka `--watch`

## Install Jekyll on Windows Linux Subsystem (Ubuntu)

### Get Ubuntu up to date and install Ruby

```bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y build-essential ruby-full
```

### update ruby gems and install Jekyll

```bash
sudo gem update –-system
sudo gem install jekyll bundler
sudo gem install jekyll-sitemap
sudo gem install jekyll-redirect-from
```

# milestone.github.io

My personal blog available @ [https://milestone.topics.it](https://milestone.topics.it)

Start with:  `jekyll serve --force_polling [--incremental] [--drafts]` on BashOnWindows to enable live rebuild, aka `--watch`

## How to run locally using Jekyll on Windows Linux Subsystem (Ubuntu)

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

## How to run locally using Jekyll Docker container

Use the following docker compose in the root directory:

```
services:
  jekyll:
    # can be moved to latest as soon as 4.3.0 is out. It fixes https://github.com/jekyll/jekyll/issues/9066
    image: jekyll/jekyll:4.2.0
    command: jekyll serve --watch --force_polling --verbose --livereload --incremental
    ports:
      - 4000:4000
    volumes:
      - .:/srv/jekyll
```

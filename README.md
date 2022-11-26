# milestone.github.io

My personal blog available @ [https://milestone.topics.it](https://milestone.topics.it)

Either install Jekyll locally or use VS Code Dev Containers. Once installed, start with:

```
jekyll serve --watch --force_polling --verbose --livereload --incremental [--drafts]
```

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

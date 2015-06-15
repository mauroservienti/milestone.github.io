---
layout: post
title: "Moving away from Blogger: comments using Disqus"
author: Mauro Servienti
tags:
- Jekyll
- Disqus
---

One of the issues that I needed to face when I decided to move my blog from `Blogger` to `GitHub Pages` using `Jekyll` is how to preserve comments on posts.

### Please welcome Disqus

[Disqus](https://disqus.com/) is a discussion (or forum) platform that can be integrated in any content available on the web.
In order to integrate something with Disqus the only requirement is that `the` something can be uniquely identified, and a blog post `permalink` is an amazing unique identifier :-)

One of the interesting things that Disqus can do is to integrate itself with Blogger and keep blog post comments synchronized with Disqus comments. Automatically Discqus will utilize the post `permalink` as the comments unique identifier.

Once Disqus is in sync with Blogger the blog content can be safely moved to another platform.

### Adding Disqus to Jekyll

Adding Disqus to Jekyll is as easy as adding the following snippet to the Jekyll post template:

```
<div id="disqus_thread"></div>
<script type="text/javascript">
    /* * * CONFIGURATION VARIABLES * * */
    var disqus_shortname = 'milestonetopicsit';
    
    /* * * DON'T EDIT BELOW THIS LINE * * */
    (function() {
        var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
        dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
    })();
</script>
<noscript>
	Please enable JavaScript to view the <a href="https://disqus.com/?ref_noscript" rel="nofollow">comments powered by Disqus.</a>
</noscript>
```

But for imported posts it is not enough, comments won't show up using the above, the commenting form will be displayed but existing comments no. The issue is that the Blogger generated `permalink` is not the same as the Jekyll one: `easy peasy`, once again.

Jekyll supports `permalink` customization also at the post level, what the [Blogger import tool](http://import.jekyllrb.com/docs/blogger/) does is to append to each imported post a [YAML](http://yaml.org/) header such as the following:

```
blogger_orig_url: http://milestone.topics.it/2013/04/ravendb-worker-role-on-windows-azure.html
```

to identify the Blogger original URL, what I simply did is to update each imported post adding a `permalink` header as well:

```
blogger_orig_url: http://milestone.topics.it/2013/04/ravendb-worker-role-on-windows-azure.html
permalink: /2013/04/ravendb-worker-role-on-windows-azure.html
```

The `permalink` header, when used at the post level, overrides the Jekyll default `permalink` generation behavior for that specific post adding 2 great benefits to the new blog:

* Old links are still supported, so all the posts linked anywhere will work as expected;
* Synchronized Disqus comments show up appended to the posts they belong to;   

.m

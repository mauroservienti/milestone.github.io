---
layout: page
permalink: /resources/external-articles/
title: External Articles
---

# External Articles

Articles published on other platforms and publications.

---

{% assign articles = site.external-articles | sort: "date" | reverse %}
{% for article in articles %}
### [{{ article.title }}]({{ article.url }})

<small>{{ article.date | date: "%B %d, %Y" }} — {{ article.publisher }}</small>

{{ article.abstract }}

---

{% endfor %}

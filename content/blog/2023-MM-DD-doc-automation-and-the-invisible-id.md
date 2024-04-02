+++
title = "Doc Automation and the Invisible ID"
slug = "doc-automation-and-the-invisible-id"
# date = 2023-07-26
draft = true

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["coding", "docs"]
+++

## Confluence

At the time the project that I worked on Had a pragma that everything is automated. This minute that everything was configured as code inside of our singular repository. We had a polyglot support utilizing basal for our build system and even our external facing sass resource had internal automations for infrastructure as code. Within our code base we also wanted to maintain a high level of documentation across all of our components services and more. We were also in atlassian shop and so our primary documentation resource internally across the organization was confluence.

We made use of markdown documents and a tool called XYZ in order to maintain documentation and synchronize it with our confluence space. One of the early blockers we ran into in this approach was the requirement for unique document names across the entirety of the confluence space. So for example we wouldn't be able to name a document authentication in two separate components of our system.

So let's work our way through potential solutions. One thought that we had was that we would preface everything with the current component that the documentation was for. At a high level we very likely wouldn't run into conflicts however it would generate unnecessary text in every page and generally reduce the overall user experience for developers. Lastly it would also cause a very high number of overlap if you searched by a certain word that happened to be one shared in a component. We didn't love the solution and we looked for alternatives.

One thing that we investigated as potential option here was what characters are supported within the confluence system. I thought came to mind there are plenty of encoded characters that are zero width, providing the illusion that they are actually not there in actuality they do contain bites and are part of the overall content of that title. A quick test was performed using a few different characters copied from the confluence page with two separate titles otherwise entirely duplicate outside of the zero width characters.

We had a working proposal that did not impact search results and provided a seamless experience when navigating through the confluence user interface. Now we also needed a manner of automating this process that would provide uniqueness between these strings as well. For this we were able to use the full path excluding the file name seeing as two documents with duplicate titles would be in separate spaces

So we had content that allowed us to uniquely identify our page, however there is a maximum limitation to the overall titles of confluence pages. So we had to standardize the length of these titles in such a way that would not limit actual title content that's visible to users. The system that we came up with utilized hashing of that directory context, which would then be converted into hexadecimal and mapped to an octet zero width character.

The final solution was a document identifier composed entirely of zero width characters invisible to the user embedded at the beginning of every document title.

You can visit the package repository on my GitHub called invisible hash.
+++
title = "Contributing to Open Source: A Stab at Go"
date = 2023-07-27
draft = true

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["open source", "coding", "packer", "openstack"]
+++

In 2018, I had been diving further into Go, a relatively new language at the time from Google. I was interested in taking it a step further and contributing to a well known and professional open source project based in Go from a reputable team that could provide me reviews and advice. As a system admin and software engineer, I was already familiar with the tool [Packer] from HashiCorp and had used it personally on several occasions. Based on this, I decided to start there.

## Finding work

With open source code, and especially in a well maintained project, it is very straightforward to find feature requests and bugs that need help. So, I dug through their [Issue List on GitHub](https://github.com/hashicorp/packer/issues). I found a [feature request](https://github.com/hashicorp/packer/issues/6464) I thought was interesting regarding the [OpenStack] integration for Packer.

> Add support to select most recent source image when name is provided

This was something that felt very approachable to me, for the following reasons:

1. An enhancement of existing code
2. A feature that has been implemented for an existing integration

I wasn't at the point of making huge architectural decisions around these things with Go, so these provided me certain handrails to getting an initial change request proposal together.

## Planning

I discussed with other members of the community on the issue to determine further requirements and design strategy, and eventually set off on the implementation.



<!-- References -->

[Packer]: https://www.packer.io/
[OpenStack]: https://www.openstack.org/
+++
title = "Automating NLP Model Development with Dialogflow"
slug = "automate-dialogflow-nlp"
# date = 2023-07-26
draft = true

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["ml", "nlp", "automation", "swe"]
+++

## Dialogflow

Dialogflow is a natural language processing system developed by Google. It provides all the constructs necessary in order to define a natural language processing model that can intelligently infer what a user is saying, but also providing various functionality on top of this including sentiment analysis and any recognition and more

At the time I was working on the Davis assistant project at dynatrace. After joining the team, assisting with our project automation, typescript migration, and devops enhancements, one of my proposed projects was to completely automate our natural language processing definitions in such a way that it would also be entirely reusable inside of our code base. Thus Not only would we have safe deployments and consistent definitions, they would be utilized inside of our apis and hook directly into the domain logic of our system.

Various tools were looked at in terms of how to support such a feature. Infrastructure is code tools at the time didn't support general purpose programming languages and general platforms, it was typically one or the other. Because of that a custom solution was the final option for how we would implement such functionality.

The project was entirely in typescript as previously mentioned and thus the tool itself would need to be reusable inside of that code. Since we controlled all of the components of our system we didn't need to implement this tool and such a manner to support a polyglot environment generating json definitions or the like. 
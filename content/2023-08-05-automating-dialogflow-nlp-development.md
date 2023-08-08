+++
title = "Automating NLP Model Development with Dialogflow"
slug = "automate-dialogflow-nlp"
date = 2023-08-05

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["ml", "nlp", "automation", "swe"]
+++

## Dialogflow

[Dialogflow] is a natural language processing system developed by Google. It provides all the constructs necessary in order to define a natural language processing model that can intelligently infer what a user is saying, but also providing various functionality on top of this including sentiment analysis and any recognition and more

At the time I was working on the [Davis Assistant][] project at Dynatrace. After joining the team, I assisted with our project automation, TypeScript migration, and DevOps enhancements. One of my proposed projects thereafter was to completely automate our natural language processing definitions in such a way that it would also be entirely reusable inside of our codebase. Thus, not only would we have safe deployments and consistent definitions, they would be utilized inside of our APIs and hook directly into the domain logic of our system. As an example, this means the same enums powering various event definitions in Dialogflow training phrases could also be utilized in logic in our API handlers relating to them.

## Dialogflow's Natural Language Processing Model

I won't do a deep dive into this subject, as it's now been several years and I definitely wouldn't call myself an expert on it at this point. However, this gives you an idea of the various elements involved in defining an NLP model with Dialogflow, which is what the later solution automates.

### Entities

Referred to as Entity Types, these allow you to control how the user input data gets extracted. There are many predefined entity, which I'll refer to as _default entities_ later on in the automation. The entity type allows us to define many entries for a single entity, or synonyms. So you could recognize multiple specific _types_ of **fruit**, like strawberries grapes and oranges, as a **fruit** entity.

### Intents

An Intent will categorize the intention of the user interaction. What these eventually break down for us, in the context of a tool like Davis Assistant, are the various user journeys of interactions with the bot. Think of the sentence "Show me the **Apdex** for **Production** over the **last week**". We might have broken down that user journey as "application performance".

For an Intent you can specify a number of _training phrases_ and _parameters_. The _training phrases_ can reference various entity types, custom or default, parts, and more. These become particularly useful as defined variables since many of the training phrases we'll build out end up being permutations of the same input parameters, sometimes including a date or sometimes including an application name, etc. The _parameters_ allow you to specify parts of the user input that you might want to extract, effectively acting as parameters to the intent _handlers_ in our service.

### Events

While intents are typically matched when users provide some input phrase, we can also utilize events to trigger intents. This is particularly useful for directing user interactions in a similar fashion to invoking callbacks on various functionality in a system.

### Context

An important component of our design was to support specific user's and their data only during the lifecycle of their requests. When someone from Average Joe Gym says "Hey Google, talk to Davis Assistant" and asks a question about their website, we don't need data about their tenant leaking into the rest of our user's requests. We can utilize a context to fulfill metadata relevant to processing user input, such as application and service names and more that are available inside the Dynatrace tenants. We fulfill this context prior to executing the user action as best as possible so that user's can naturally interact with Davis Assistant. Otherwise, references to your applications, like "the blog", simply mean nothing to us.

### Webhooks

Webhooks are very common in the industry today, and we can utilize them with Dialogflow to allow them to direct the processed user input to our services. When user input is processed and in intent and its parameters are determined, we'll receive a request to our Router which handles the validation and forwarding of the request to our internal service for handling and responding to user interactions.

## Research

Various tools were looked at in terms of how to support such a feature. Infrastructure-as-Code tools at the time didn't support general purpose programming languages and general platforms, it was typically one or the other. Newer projects today may not have this limitation, such as Pulumi, but because of that a custom solution was the final option for how we would implement such functionality.

Our stack was now entirely in TypeScript as previously mentioned, and so the tool itself would need to be reusable inside of that code. Since we controlled all of the components of our system we didn't need to implement this tool and such a manner to support a polyglot environment generating JSON definitions or the like. This gave us a lot of power and simplified the overall solution more, as opposed to requiring a code generator component as part of the integration.

## Dialogflow and NodeJS

Google provided a NodeJS SDK for Dialogflow under the NPM package [nodejs-dialogflow]. This _was_ a purely JavaScript package when this work started, and in our time utilizing Dialogflow we contributed the [@types/dialogflow] package in the [DefinitelyTyped] repository, helped facilitate resolution around [typing chaos][dialogflow-typing-chaos] during a package migration, and eased others over to the new [@google-cloud/dialogflow] package after its release.

## Migration Phase

One component of the project was the ability to synchronize the definitions in our code to Dialogflow servers, but during the development phase of the project we also had to be able to continue utilizing the Dialogflow UI. As such, I also implemented a capability for importing Dialogflow resources and automatically generating all of the necessary entity types, contexts, events, intents, and more. You could simply export the Dialogflow project to a file and then run:

```bash
# given you had installed `@0xc/dialogflow-as-code
dialogflow-as-code -i ./export-dir -o ./src/dialogflow
```

And you now had an entire set of Dialogflow-as-Code source code in TypeScript that defined **all** of your project resources. This functionality made the continuous integration of UI changes into our source code possible until we flipped the responsibilities, eventually making our source code the source of truth for our Dialogflow project. We still had the ability to triage issues in the web interface when necessary, but due to the change our environment inconsistencies dropped significantly.

## Example Time

> You can find out more about each of these types of resources on [the Dialogflow documentation site](https://cloud.google.com/dialogflow/cx/docs/concept).

```ts
// Sample Entity Type Builder
export const etFruit = entityType()
  .d("fruit")
  .e([syn("apple"), syn("strawberry")])
  .k(ek.list)
  .build();

// Sample Entity Type
export const etSample: EntityType = {
  displayName: "sample",
  entities: [{ value: "sample", synonyms: ["piece", "swab", "choice"] }],
  kind: "KIND_MAP",
  autoExpansionMode: "AUTO_EXPANSION_MODE_DEFAULT",
};

// Sample Context Builder
export const cxFruit = cx()
  .n("fruit-context")
  .lc(5)
  .p("date-time-original", "string_value")
  .build();

// Sample Events
export enum Event {
  FEEDBACK = "FEEDBACK",
  YES = "YES",
  NO = "NO",
}

// Sample Intent
// prettier-ignore
export const ntFruitInfo = intent("fruitInfo")
  .priority(Priority.LOW)
  .webhook(true)
  .trainingPhrases([
    tp(["describe the ", pb("sample"), " of ", etFruit, " over ", det("date-time")]),
    tp(["how was the ", pb("sample"), " of ", etFruit]),
    tp([pb("sample"), " of ", etFruit, " ", det("date-time")]),
    tp([pb("sample"), " of ", etFruit]),
    tp(["what was the ", pb("sample"), " of ", etFruit, " ", det("date-time"), "?"]),
    tp(["what was the ", pb("sample"), " of ", etFruit]),
  ])
  .messages([
    msg("text").set(["I'm sorry Dave, I can't do that"]).build(),
    msg("text").set(["Second response"]).build(),
  ])
  .events([Event.FEEDBACK])
  .outputContexts([cxFruit])
  .followUpOf(ntFruitReminder);

// Sample Resource Build and Sync Script
const svcAcctKeyJson: string = "./service-account-key.json";
const svcAcctConfig: DialogflowServiceAccount = require(`.${svcAcctKeyJson}`);
Container.set(KEY_FILENAME, svcAcctKeyJson);
Container.set(DIALOGFLOW_CONFIG, svcAcctConfig);

const resources = Container.get(DialogflowBuilder)
  .entityTypes([etSample, etFruit])
  .intents([ntFruitInfo, ntFruitReminder])
  .build();

Container.get(DialogflowCreator).sync(resources);
```

## Wrap-up

The outcome of the project: Dialogflow-as-Code. This package was made available as `@0xc/dialogflow-as-code` on the NPM registry through an open source project on [my GitHub][DAC source].

<!-- References -->

[Dialogflow]: https://cloud.google.com/dialogflow/
[nodejs-dialogflow]: https://github.com/googleapis/nodejs-dialogflow
[DefinitelyTyped]: https://github.com/DefinitelyTyped/DefinitelyTyped
[@google-cloud/dialogflow]: https://www.npmjs.com/package/@google-cloud/dialogflow
[dialogflow-typing-chaos]: https://github.com/DefinitelyTyped/DefinitelyTyped/pull/39627
[Davis Assistant]: https://www.Dynatrace.com/news/blog/davis-assistant-is-now-smarter-than-ever/
[DAC source]: https://github.com/tcarrio/dialogflow-as-code
+++
title = "OpenFeature Introduction"
slug = "openfeature-introduction"
date = 2023-08-07

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["swe", "open source", "feature flags"]
+++

## What Are Feature Flags

Feature flags are a way to dynamically control the capabilities of software, often with granularity to specific users, regions, and more. Flagging empowers companies to experiment with new features, and companies like Spotify, Duolingo, and Google use these heavily to prove out their hypotheses around generating better user experiences and products. It can be as simple as flipping the title of a landing page to an entire suite of features in the product- the possibilities are almost endless.

This is often times pretty simple, and in the code could be done with a simple `if/else` block:

```tsx
const {flagService} = useContext('FeatureFlagging');

const isNewExperience = flagService.isOn('new-experience');

if (isNewExperience) {
  return <NewComponent {...props} />;
} else {
  return <Component {...props} />;
}
```

And there you have it. You now have a dynamically response interface based on logic determined by your feature flagging service. None of the above code related to any existing tool in particular, but what this post will do is get you acquainted with a new open source project called OpenFeature which you can get started with today.

## What is OpenFeature

OpenFeature is a project that defines an **open specification** for feature flagging SDK behaviors to support consistent developer experiences backed by any feature flagging vendor in the ecosystem. The project provides an open source, vendor-agnostic SDK for many languages, which vendors can support with **providers** to back the flagging logic and **hooks** to enhance with various capabilities in the feature flagging lifecycle. The SDK is an implementation upon the OpenFeature specification, and can be configured against any one of the available providers for that language. If you're interested, take a look on their [ecosystem] page, which lets you search across different types like server-side and client-side, technologies like Go, JavaScript, and PHP, Vendors like Split and CloudBees, and more.

### Providers

OpenFeature itself is a specification with vendor-agnostic open source packages for various languages. The vendors provide the feature flag evaluation component of the architecture though- and you'll need one. These can be backed by open source projects, companies' SDKs like LaunchDarkly and Split, or an in-house flagging system. You can develop your application against the OpenFeature interfaces and swap out providers across environments- easily allowing your local dev system utilize environment variable configurations where production is backed by an enterprise solution. Find out more on providers [here][providers].

### Hooks

The flag evaluation lifecyle is well documented in OpenFeature, and supports _hooks_, which can enhance or augment a flag evaluation. Perhaps you want to inject a logger in staging or provide tracing capabilities with OpenTelemetry. All of this is easily doable by utilizing a hooks package or writing your own hook against the interface. You can read more on the hooks lifecycle [here][hooks].

## Getting Started

This will depend on your language of choice, so I'll provide a couple of examples. The first will be JavaScript, with a focus on client-side use cases. The next will be a server-side reference with PHP. You can find more samples in the [technologies] page as well.

### Client-side JavaScript

These utilize a pattern in OpenFeature called _static context_. What this amounts to is that there is just the current user, the one interacting with the web client, so there doesn't need to be as highly dynamic of a flag evaluation system backing the OpenFeature client.

Start off by installing the package to your project. Here I'll use `yarn`:

```bash
yarn add @openfeature/js-sdk
```

Now you can start working with the SDK by coding the following:

```ts
import { OpenFeature } from '@openfeature/js-sdk';

const client = OpenFeature.getClient();

const isNewExperience = await client.getBooleanValue('new-experience', false);

if (isNewExperience) {
  // ...
}
```

This is very similar to the above example, but needs the magic sauce to actually _provide_ the logic- an OpenFeature **provider**.

#### Wire Up A Provider

You need a provider to back the flag evaluation in the OpenFeature SDK. These are pluggable, and anything that adheres to the defined Provider interface can fulfill this contract. I'll pull in a specific provider, just as an example. In my case I'll use the [Split] provider. The Split provider has a peer dependency on the Split SDK as well, so I will install them both with:

```bash
yarn add @splitsoftware/openfeature-js-split-provider @splitsoftware/splitio
```

Now that we have a provider, we can update our code example above accordingly:

```ts
import { OpenFeature } from '@openfeature/js-sdk';
import { SplitFactory } from '@splitsoftware/splitio';
import { OpenFeatureSplitProvider } from '@splitsoftware/openfeature-js-split-provider';

// The key that authorizes the Split client to connect to the Split API
const SPLIT_AUTHORIZATION_KEY = 'your-split-auth-key';

const client = OpenFeature.getClient();

const splitClient = SplitFactory({core: {authorizationKey}}).client();
const provider = new OpenFeatureSplitProvider({splitClient});

OpenFeature.setProvider(provider);

// With the provider set, let's get to work
const isNewExperience = await client.getBooleanValue('new-experience', false);

if (isNewExperience) {
  // ...
}
```

### Server-side PHP

As mentioned, several languages are supported, including .NET, Go, and more. In this example we'll utilize the PHP SDK since I wrote it.

Let's assume you're using `composer` like every other PHP project- then you would install the SDK by running:

```bash
composer require open-feature/sdk
```

This will pull in the package and update your `composer.json` and `composer.lock` accordingly.

Now, to utilize the SDK, you will simply retrieve an instance from the SDK:

```php
<?php

use Api\Controller;
use Api\Method;
use Api\Route;
use OpenFeature\OpenFeatureClient;

#[Route("/cats")]
class CatsController extends Controller
{
  public function __construct(
    private readonly OpenFeatureClient $client
  ) {}

  #[Method\Get]
  public function actionFavorite(): UI
  {
    $userId = $this->getUserIdFromRequest();

    $favoriteCat = $this->client->getStringValue('favorite-cat', 'Nebelung', [
      'user-id' => $userId,
    ]);
    
    return [
      'favoriteCat' => $favoriteCat,
    ];
  }
}
```

Now when the OpenFeature client evaluates the flag for the request, it'll pass some evaluation context as well, which includes the user's ID if it exists. The provider will utilize this to determine what the correct value to return will be, which allows us to provide consistent experiences at the user-level. As long as the same user is accessing the API, they will receive the same behavior.

> Note: This example removed the steps of instantiating a provider and instead utilized inversion of control to allow the framework to provide the necessary OpenFeature client instead. The process is similar to that shown in the JS SDK.

### Hooks Manual Instrumentation

Just like you can set a provider in your OpenFeature SDK, you can also add hooks. The hooks are executed in a particular ordered defined by the specification, such that you can expect the behavior in the JavaScript SDK to be identical to that of the PHP SDK, Go SDK, etc.

When adding hooks, you can do so at any level of the OpenFeature SDK: API, Client, Provider, and invocation. How these are each evaluated is defined in the [hook ordering][] specification.

Here we will add the [validators] hook for PHP, available in the [php-sdk-contrib] repository:

```bash
composer require open-feature/validators-hook
```

And we can utilize the hook at each of the mentioned levels by doing:

```php
<?php

use OpenFeature\Hooks\Validators\RegexpValidatorHook;
use OpenFeature\OpenFeatureAPI;

// Custom hook
$hexadecimalValidator = new RegexpValidatorHook('/^[0-9a-f]+$/');

// API
$api = OpenFeatureAPI::getInstance();
$api->addHooks($hexadecimalValidator);

// Client
$client = $api->getClient('hooks-test');
$client->addHooks($hexadecimalValidator);

// Provider
$provider = new ExampleProvider();
$provider->addHooks($hexadecimalValidator);

// Invocation
$client->resolveStringValue('test-flag', 'deadbeef', null, new EvaluationOptions([$hexadecimalValidator]));
```

Easy as that! The higher up you place the hook, the more _universal_ it becomes across your application. Make sure to keep this in mind as applying something at the API-level will impact _every evaluation_ in the entire application.

### Hooks: Observability with OpenTelemetry

Something that you might find useful as a developer pushing code to production is how the behavior of the feature flagging system may impact your users. Perhaps you want to know whether the evaluation in the provider, or what value was determined for a given request. Well, you can utilize observability tools like OpenTelemetry to accomplish that.

There are a couple of observability hooks already provided, and both of them utilize the PSR-4 autoloader functionality for PHP. The convenience of this is that all it takes is having the package _installed_ and you'll get the hook set at the API-level to trace _all_ evaluations, following the standard practices defined in e.g. OpenTelemetry's Semantic Conventions.

So, install the package:

```bash
composer require open-feature/otel-hook
```

And autoload as you normally would! This example follows the standard practice of autoloading at the entrypoint of your PHP application:

```php
<?php

declare(strict_types=1);

use OpenFeature\OpenFeatureAPI;

putenv('OTEL_PHP_AUTOLOAD_ENABLED=true');
putenv('OTEL_TRACES_EXPORTER=otlp');
putenv('OTEL_EXPORTER_OTLP_PROTOCOL=grpc');
putenv('OTEL_METRICS_EXPORTER=otlp');
putenv('OTEL_EXPORTER_OTLP_METRICS_PROTOCOL=grpc');
putenv('OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4317');
putenv('OTEL_PHP_TRACES_PROCESSOR=batch');
putenv('OTEL_PROPAGATORS=b3,baggage,tracecontext');

echo 'autoloading SDK example starting...' . PHP_EOL;

// Composer autoloader will execute SDK/_autoload.php which will register global instrumentation from environment configuration
require dirname(__DIR__) . '/vendor/autoload.php';

$client = OpenFeatureAPI::getInstance()->getClient('dev.openfeature.contrib.php.demo', '1.0.0');

$version = $client->getStringValue('dev.openfeature.contrib.php.version-value', 'unknown');

echo 'Version is ' . $version;
```

As you can see, there were no **explicit actions** necessary. However, the OpenTelemetry hook is set up at the API-level and providing tracing based on the configuration of your OTel exporter.

<!-- References -->

[ecosystem]: https://openfeature.dev/ecosystem
[technologies]: https://openfeature.dev/docs/reference/technologies/
[hooks]: https://openfeature.dev/specification/sections/hooks
[providers]: https://openfeature.dev/specification/sections/hooks
[hook ordering]: https://openfeature.dev/specification/sections/hooks#requirement-441
[validators]: https://packagist.org/packages/open-feature/validators-hook
[php-sdk-contrib]: https://github.com/open-feature/php-sdk-contrib
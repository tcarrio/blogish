+++
title = "Domain-Driven Design Patterns: Entities, Repositories, and More"
slug = "ddd-entities-repositories-etc"
# date = 2023-07-26
draft = true

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["coding", "swe", "ddd"]
+++

What this post is, and what is isn't.

This post is:

- A brief intro to what [DDD] is.
- Covering some tactical design patterns for DDD.

This post is not:

- Covering strategic design patterns, e.g. [Event Storming]

[Domain-driven design (DDD)][DDD] is an approach I've taken on various projects historical and one that I'm still not sure I've entirely _mastered_. There is a lot of nuance to DDD, namely the matter of buy-in from stakeholders across the organization, truly working hand-in-hand with domain experts, assuming you have them- and if you don't, then also building up that expertise in your team- and finally championing that mentality across all of the silos in your workplace. _Everyone_ needs to be on board, and that's just from a _strategic_ design standpoint. Practicing domain-driven design is hard, much like software engineering can be in general, but it's also a foreign concept to many developers out there.

The core of domain-driven design, in my own words:

> Domain-driven design is about designing your software in the way the business domain is structured, from the terminology used by each context of your product to the naming of your programming constructs.

By most DDD practicioners' standards: your domain experts should be able to understand what's happening in your code without being a programmer. This relates only to the domain portion of your code, and in many architectural approachs to software such as [hexagonal architecture], you would have that complete separation of the core domain logic from any application or infrastructure logic. These often pair well DDD, and there are many examples of implementing tactical DDD patterns online.

## Reading Resources

The absolute classics are the original [Eric Evans blue book, Domain-Driven Design: Tackling Complexity in the Heart of Software][blue book], and the [Vaughn Vernon red book Implementing Domain-Driven Design][red book].

## Identifying the structure of the business domain

This is the part I mentioned this post would NOT be. I'll only cover some terminology that will be useful within this post:

- **Domain**: Outside of DDD, this is defined as "a specified sphere of activity or knowledge", which captures the essence well. This encapsulates both _what_ your product does, and _how_ it does it.
- **Subdomain**: Your domain often will be split up into various subdomains, especially if it is as a whole a very broad concept. There are several types of subdomains, including _core_, _supporting_, and _generic_ subdomains. The _core_ subdomain would be the primary focus of your product and the value it offers that makes it great. A _supporting_ subdomain is important for the product to succeed, but not the primary focus. A _generic_ subdomain contains nothing _special_ to the organization, but is necessary for the solution to work (think IAM or ERP platforms).
- **[Ubiquitous Language][]**: Specific to each bounded context, the language is agreed upon and standard for how to refer to each component in the system. Domain experts and software engineers can easily discuss features because the ubiquitous language is consistent from design to implementation. As you can imagine, this takes a lot of interaction between domain experts and the programmers building the software.
- **[Bounded Context][]**: This is a specific subset of the overall domain where ubiquitous language is consistent. Often times the best structure for bounded contexts is 1:1 with subdomains of your system, but like many things in SWE this is situational. Not only is this a specific context, but there is well defined boundary for the context. This separates the components of your system linguistically, so the same terminology such as "Account" may not mean the same thing between two contexts, such as "Checkings" context and "Savings" context for a "Banking" domain. 
- **Context Map**: These define what the boundaries of the various contexts are, how contexts will communicate, how mappings between entities and other constructs will be done between contexts (e.g. translating the ubiquoutous language), how to protect against unwanted changes in upstream contexts, or how to ensure stability for downstream contexts.

That is a lot to gather without much _context_, and if you are interested in the strategic design elements you should read more on it from the [blue book][] and/or [red book][].

## Domain Objects

Even in 2003, Evans' [classified][evans classification] some of the still relevant types of domain objects you'll find in domain-driven design. These classifications include:

- **Entities**: A distinctly identifiable object.
- **Value Objects**: An object that matters only as an combination of its properties. There is no identifier for a value object, only what it contains.
- **Services**: Typically stateless, these can provide a standalone operation within the context your domain.

Types from other patterns such as enterprise architecture, layered architecture, design patterns and more have been mostly adopted into domain-driven design as well, and you'll commonly see many of the following:

- **Aggregates**: An entity that defines the transactional boundary of logical operations within a context. It controls the entities beneath it, exposes functionality to domain logic that can impact those entities, but does not allow access to those nested entities. When the aggregate is persisted, the operations of root aggregate entity and all of the related entities must all successfully complete or the transaction will be rolled back. In this way, aggregates are atomic.
- **Domain Events**: Events that signify specific, important happenings within a bounded context. This is a common way to communicate across bounded contexts while also reducing coupling of services.
- **Repositories**: An abstraction over a collection of domain entities. This typically follows a collection-like or persistence-based approach. The repository mediates between the domain and data-mapping layers of the system.
- **Factory**: A creational design pattern, which in its simplest form is an object that creates other objects. There are more specific subsets of the Factory pattern that support polymorphic return types as well.

Depending on which DDD tactical design patterns you implement, you may also end up seeing terminology like CQRS. We'll hold off on diving any deeper for now.

### A working example

> TODO: Implement the working example..

The following adapts some of the code from a Destiny bot project a friend of mine was working on. The code was originally in JavaScript at the time and I thought I would convert it to utilize more domain-driven design patterns instead. This is very WIP still, but it's a start.

```typescript
export class User {
  constructor(
    public readonly bungieAccount: BungieAccount,
    public readonly destinyCharacter: DestinyCharacter,
    public readonly socialConnector: SocialConnector,
  ) { }
}

export class BungieAccount {
  constructor(
    public readonly id: string,
    public readonly username: string,
    public readonly refreshToken: JsonWebToken,
  ) { }
}

export class JsonWebToken {
  constructor(
    public readonly header: Map<string, any>,
    public readonly payload: Map<string, any>,
    public readonly signature: string,
    public readonly expiryDate: Date,
    public readonly rawToken: string,
  ) { }
}

export interface JwtParser {
  parse(rawToken: string): JsonWebToken;
}

export class JsonWebTokenFactory {
  constructor(private readonly parser: JwtParser) {}

  fromRawToken(rawToken: string): JsonWebToken {
    // here we are not using some "jwt" package but instead relying
    // on an instance conforming to the JwtParser interface. Since
    // this specifically does not exist in the core entity it will
    // not be coupled to the domain module.
    const token = this.parser.parse(rawToken);

    return new JsonWebToken(
      token.header,
      token.payload,
      token.signature,
      new Date(token.payload.get('exp')),
      rawToken,
    );
  }
}

export class DestinyCharacter {
  constructor(
    public readonly id: string,
    public readonly accountId: string,
  ) { }
}

export class SocialConnector {
  constructor(
    public readonly id: string,
    public readonly channelId: string,
  ) { }
}

// using repository to load a User

interface Logger {
  log: (...args: any[]) => void;
  debug: (...args: any[]) => void;
  error: (...args: any[]) => void;
}

interface MongooseSchema<T> {
  exists(criteria: Partial<T>): Command<boolean>;
  updateOne(criteria: Partial<T>, operation: MongooseOperation<T>, callback: (error?: Error) => any): Promise<void>;
}

interface MongooseOperation<T> {
  $set: Partial<T>;
}

interface Command<T> {
  exec(): Promise<T>;
}

interface UserSchema {
  bungie_membership_id: string;
  bungie_username: string;
  destiny_character_id: string;
  destiny_id: string;
  discord_channel_id: string;
  discord_id: string;
  refresh_expiration: string;
  refresh_token: string;
}

interface PersistenceObject {
  save(): Promise<void>;
}

type PersistenceObjectFactory<T> = (model: T) => PersistenceObject;

interface Repository<T> {
  add(model: T): Promise<void>;
  update(model: T): Promise<void>;
  delete(model: T): Promise<void>;
}

interface UserRepository extends Repository<User> {
  existsByUsername(username: string): Promise<boolean>;
}

export class MongoUserRepository implements UserRepository {
  constructor(
    private readonly schema: MongooseSchema<UserSchema>,
    private readonly factory: PersistenceObjectFactory<User>,
    private readonly logger: Logger,
  ) { }

  async add(user: User): Promise<void> {
    const userModel = this.factory(user);

    await userModel.save();
  }

  async update(user: User): Promise<void> {
    const { destinyCharacter, bungieAccount } = user;

    const updateModel = {
      destiny_id: destinyCharacter.accountId,
      destiny_character_id: destinyCharacter.id,
      refresh_expiration: bungieAccount.refreshToken.expiryDate.toISOString(),
      refresh_token: bungieAccount.refreshToken.rawToken,
    };

    await this.schema.updateOne(
      { bungie_membership_id: bungieAccount.id },
      { $set: updateModel },
    )
  }

  async delete(user: User) {
    await this.schema.deleteOne({ bungie_membership_id: user.bungieAccount.id });
  }

  async existsByUsername(username: string): Promise<boolean> {
    return await this.schema.exists({ bungie_username: username }).exec() ? true : false;
  }
}
```


<!-- References -->

[DDD]: https://martinfowler.com/bliki/DomainDrivenDesign.html
[Event Storming]: https://en.wikipedia.org/wiki/Event_storming
[Bounded Context]: https://martinfowler.com/bliki/BoundedContext.html
[Ubiquitous Language]: https://martinfowler.com/bliki/UbiquitousLanguage.html
[evans classification]: https://martinfowler.com/bliki/EvansClassification.html

[blue book]: https://www.amazon.com/gp/product/0321125215
[red book]: https://www.amazon.com/gp/product/0321834577
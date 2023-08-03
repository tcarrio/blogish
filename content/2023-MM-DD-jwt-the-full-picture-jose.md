+++
title = "JSON Web Tokens: The Full Picture"
slug = "jwt-the-full-picture-jose"
date = 2023-08-02
draft = true

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["swe", "cryptography"]
+++

JSON Web Tokens, commonly abbreviated as JWTs, are a standard that is a part of the JSON Object Signing and Encryption (JOSE) set of standards. There is a lot to break down here, depending on what you want to accomplish. JWTs are often conflated with a combination of these standards, which include:

- JSON Web Algorithms (JWA): Defines **cryptographic algorithms** and **identifiers** used across JOSE standards.
- JSON Web Keys (JWK): Defines the JSON representation format for **cryptographic keys**.
- JSON Web Encryption (JWE): Defines the JSON structure for representing **encrypted** content using JWA.
- JSON Web Signatures (JWS): Defines the JSON structure for representing **cryptographical veriable signatures** of content using JWA.
- JSON Web Tokens (JWT): Defines subject claims using JSON structures. These claims can be optionally protected via JWE or JWS.

That is a mouthful to say the least, but maybe you're starting to see how there is a lot more to JWTs than you might originally think, especially when you go to a site like [jwt.io][] that provides an opinionated example of a JSON Web Token protected with a JSON Web Signature. In fact, that page doesn't even allow you to showcase an example of an unprotected JSON Web Token (e.g. `"alg": "none"` in the header), so you can sort of understand just how JWTs have been adopted (and it has _something_ to do with security).

## JWT: The Most Basic Case

A JSON Web Token can optionally utilize no other JOSE protection (JWS/JWE)- which is the simplest use case. The additional protections sort of build on top of this. To start, a JSON Web Token consists of a **header**, in the form of a JSON Web Key, and a **payload**, a JSON object which contains subject claims. The JWK header defines what algorithm is used for the JWT, and the basic case is that there is none.

```
header: { "alg": "none" }
payload: { "sub": "user@example.test" }
```

Now, while technically JSON is used to define all of the structured data in JSON Web Tokens, the delivery format is entirely URL safe. Each of the parts of a JWT are encoded in a common manner:

```
base64UrlEncode(
  utf8Encode(
    JSONObject
  )
)
```
> Note: Binary data formats within the payload need to be worked around in their own way, and are not covered as part of the specification.

That encoding mechanism is applied individually to the header and payload, and the end result of each concatenated with `.`s.

```
header  = '{"alg":"none"}'
payload = '{"sub":"user@example.test"}'

'{"alg":"none"}' => 'eyJhbGciOiJub25lIn0K'
'{"sub":"user@example.test"}' => 'eyJzdWIiOiJ1c2VyQGV4YW1wbGUudGVzdCJ9Cg'

jwt = 'eyJhbGciOiJub25lIn0K.eyJzdWIiOiJ1c2VyQGV4YW1wbGUudGVzdCJ9Cg'
       ## encoded header ## ########### encoded payload ##########    
```

## Some helpful links

You can dig more into the official specification of JSON Web Tokens in IETF's [RFC-7519][]. The JWT specification builds upon two other important standards, which are JSON Web Signatures (JWS) defined in [RFC-7515][] and JSON Web Encryption (JWE) defined in [RFC-7516][]

A great playground space for messing around with JWT's is [jwt.io][]. They have an interactive JSON Web Token editor that shows the raw JWT and a breakdown of its parts, even so far as allowing you to verify signatures.

There is a short/long summary of the JOSE standards on StackOverflow [here][JOSE-SO] as well, which I also found helpful when RFCs got a bit too boring.

## The Structure of a JWT

We'll dig into each of the components of a JSON Web Token:

- Header
- Payload
- Signature

### Header

The header of a JSON Web Token defines the type of hashing mechanism. This can be based on HMAC in combination with a common hashing algorithm like Shaw 512 or asymmetric key cryptography such as RSA. The former allows for an opaque secret value to be used for generating the JWT signature which is also used to verify it. The latter utilizes public/private key cryptography that allows you to generate a secret with a private key and utilize a public key, one that can be known by anyone without risking security around the tokens, to verify the signature of the JSON Web Token.

### Payload

The payload of a JSON Web Token can contain any valid json object, Jwt's do not have any further intrinsic limitations, but standards that build upon JWTs such as OpenID Connect use JWTs to provide stateless context in an access or identity token that can be utilized by resource servers or OAuth clients.

### Signature

Looking back at the header, we can reference the utilized **algorithm** and **token type**. 

<!-- References -->

[RFC-7515]: https://datatracker.ietf.org/doc/html/rfc7515
[RFC-7516]: https://datatracker.ietf.org/doc/html/rfc7516
[RFC-7519]: https://datatracker.ietf.org/doc/html/rfc7519
[jwt.io]: https://jwt.io
[JOSE-SO]: https://stackoverflow.com/questions/74257560/what-is-the-difference-between-jose-jwa-jwe-jwk-jws-and-jwt
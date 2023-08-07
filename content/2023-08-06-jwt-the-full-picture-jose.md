+++
title = "JSON Web Tokens: The Full Picture"
slug = "jwt-the-full-picture-jose"
date = 2023-08-02

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["swe", "cryptography"]
+++

JSON Web Tokens, commonly abbreviated as JWTs, are a standard that is a part of the JSON Object Signing and Encryption (JOSE) set of standards. There is a lot to break down here, depending on what you want to accomplish. JWTs are often conflated with a combination of these standards, which include:

- [JSON Web Algorithms (JWA)][RFC-7518]: Defines **cryptographic algorithms** and **identifiers** used across JOSE standards.
- [JSON Web Keys (JWK)][RFC-7517]: Defines the JSON representation format for **cryptographic keys**.
- [JSON Web Encryption (JWE)][RFC-7516]: Defines the JSON structure for representing **encrypted** content using JWA.
- [JSON Web Signatures (JWS)][RFC-7515]: Defines the JSON structure for representing **cryptographical veriable signatures** of content using JWA.
- [JSON Web Tokens (JWT)][RFC-7519]: Defines subject claims using JSON structures. These claims can be optionally protected via JWE or JWS.

That is a mouthful to say the least, but maybe you're starting to see how there is a lot more to JWTs than you might originally think, especially when you go to a site like [jwt.io][] that provides an opinionated example of a JSON Web Token protected with a JSON Web Signature. In fact, that page doesn't even allow you to showcase an example of an unprotected JSON Web Token (e.g. `"alg": "none"` in the header), so you can sort of understand just how JWTs have been adopted (and it has _something_ to do with security).

## A Simple JWT: Starting with a Basic Example

A JSON Web Token can optionally utilize no other JOSE protection (JWS/JWE)- which is the simplest use case. The additional protections sort of build on top of this. To start, a JSON Web Token consists of a **header**, in the form of a JSON Web Key, and a **payload**, a JSON object which contains subject claims. The JWK header defines what algorithm is used for the JWT, and the basic case is that there is none.

```
header: { "alg": "none" }
payload: { "sub": "user@example.test" }
```

Now, while technically JSON is used to define all of the structured data in JSON Web Tokens, the delivery format is entirely URL safe. Each of the parts of a JWT are encoded in a common manner:

```python
base64UrlEncode(
  utf8Encode(
    JSONObject
  )
)
```
> Note: Binary data formats within the payload need to be worked around in their own way, and are not covered as part of the specification.

That encoding mechanism is applied individually to the header and payload, and the end result of each concatenated with `.`s.

```python
header  = '{"alg":"none"}'
payload = '{"sub":"user@example.test"}'

'{"alg":"none"}' => 'eyJhbGciOiJub25lIn0K'
'{"sub":"user@example.test"}' => 'eyJzdWIiOiJ1c2VyQGV4YW1wbGUudGVzdCJ9Cg'

jwt = 'eyJhbGciOiJub25lIn0K.eyJzdWIiOiJ1c2VyQGV4YW1wbGUudGVzdCJ9Cg'
       ## encoded header ## ########### encoded payload ##########    
```

As you can see, there are only two parts to this. This differs from a JWT you might see used in OpenID Connect OAuth flows, which will typically construct JWTs with some type of _secret_ to support _validation_ of tokens, a functionality of JSON Web Signatures. Let's start to put together the building blocks to these cryptographic components of the JOSE standards.

## JSON Web Algorithms, or "Definitions We'll Need For Everything Else, Really"

Somewhere we need to define what `"alg"` and `"enc"` and all of these header keys _mean_. That's what JWA, JSON Web Algorithms, defines. The header is primarily reserved for all of the cryptographic functionality, and being able to read this metadata to determine how to decrypt or validate tokens is one of the strong suits of JWTs.

The standard is defined in [RFC-7518][], and that will provide all of the information you need on various supported algorithms, but I'll give a few examples here to cover the use cases I'll preset across this document.

As we'll get to later, these definitions support the functionality of JSON Web Signatures (JWS) and JSON Web Encryption (JWE). The RFC is similarly broken down to cover each of these cases:

## JSON Web Signatures (JWS)

JWS is focused on providing _verifiable_ data. The metadata in the header will dictate how to verify the payload of the JWT using the _signature_ appended to it.

You can provide the following (case-insensitive) values for `"alg"` keys in the header, which will apply a cryptographic signature utilizing the described algorithm:

- **HS256**: HMAC using SHA-256
- **HS384**: HMAC using SHA-384
- **HS512**: HMAC using SHA-512
- **RS256**: RSASSA-PKCS1-v1_5 using SHA-256
- **RS384**: RSASSA-PKCS1-v1_5 using SHA-384
- **RS512**: RSASSA-PKCS1-v1_5 using SHA-512
- **ES256**: ECDSA using P-256 and SHA-256
- **ES384**: ECDSA using P-384 and SHA-384
- **ES512**: ECDSA using P-521 and SHA-512
- **PS256**: RSASSA-PSS using SHA-256 and MGF1 with SHA-256
- **PS384**: RSASSA-PSS using SHA-384 and MGF1 with SHA-384
- **PS512**: RSASSA-PSS using SHA-512 and MGF1 with SHA-512
- **none**: No digital signature or MAC performed

### Symmetric Hashing

HMAC, Hash-based Message Authentication Codes, are useful when you can utilize _shared_ secrets. That is, the party creating the JWT and the party consuming the JWT both know of a secret value that is used to generate the signature and later verify it. When both parties are familiar with the secret and have communicated this securely, this form of cryptography is still hardened against man-in-the-middle attacks, since any intercepting party cannot manipulate the token and pass it on- once the body has changed the signature would no longer be valid. This is true outside of the very, _very_ small probability of a hash collision. In the example of the weakest encryption suggested, which is SHA-256, that relates to 256 bits. In terms of how big a number that equates to, well, to quote Douglas Adams:

> You just won't believe how vastly, hugely, mind-bogglingly big it is.

But if you _must_ know, `2^256 = 115,792,089,237,316,195,423,570,985,008,687,907,853,269,984,665,640,564,039,457,584,007,913,129,639,936`, which happens to be a *mind-boggingly big* number.

A SHA-256 collision is about as likely as getting one Powerball ticket **four** weeks in a row and winning the maximum jackpot **every time**.

I think it's landed by now, and I'm just having fun with numbers now so I digress..

### Asymmetric Hashing

Also known as public-private key cryptography, asymmetric hashing allows you to have a party whose familiar with a _generative_ secret, and the consuming parties can be configured with a _validation_ secret. This approach is hardened not just against man-in-the-middle (MITM) attacks but also disallows the consumer to manipulate the JWT in any way either.

You will often see approaches like this utilized in OAuth systems since you can't allow an OAuth client to not just validate access tokens but _manipulate_ them in any way they would like.

Asymmetric algorithms power many tools we make use of today; it enables a [secure TLS handshake][TLS RFC], [secure shells][SSH RFC], extends and protects [email communication][GPG], and more.

### No Hashing

Like we had shown in our example above, you can also specify not to use any algorithm. This would amount to no signature being generated at all, so you're just passing a base64 encoded JSON object with some additional JSON metadata.

If you're using this approach, you _probably_ shouldn't even be using JWTs, unless that's an imposed requirement and you are **absolutely certain** there are no security requirements on the exchanged data.

## JSON Web Encryption (JWE)

In contrast to JWS, JWE is focused on protecting the data in transit. Where JWS protects your data from being manipulated in transit, JWE also protects your data from being **read** in transit. Only someone who has the necessary secrets to perform the decryption described by the metadata in the header will be able to do this.

In the header, the `"alg"` field will be used to describe the encryption algorithm, each respective one may include additional header fields accordingly. See the full specification under the JWE section of the JWA specification [here](https://datatracker.ietf.org/doc/html/rfc7518#section-4).

- **RSA1_5**: RSAES-PKCS1-v1_5
- **RSA-OAEP**: RSAES OAEP using default parameters
- **RSA-OAEP-256**: RSAES OAEP using SHA-256 and MGF1 with SHA-256
- **A128KW**: AES Key Wrap with default initial value using 128-bit key
- **A192KW**: AES Key Wrap with default initial value using 192-bit key
- **A256KW**: AES Key Wrap with default initial value using 256-bit key
- **dir**: Direct use of a shared symmetric key as the CEK
- **ECDH-ES**: Elliptic Curve key agreement using Concat KDF
- **ECDH-ES+A128KW**: ECDH-ES using Concat KDF and CEK wrapped with A128KW
- **ECDH-ES+A192KW**: ECDH-ES using Concat KDF and CEK wrapped with A192KW
- **ECDH-ES+A256KW**: ECDH-ES using Concat KDF and CEK wrapped with A256KW
- **A128GCMKW**: Key wrapping with AES GCM using 128-bit key
- **A192GCMKW**: Key wrapping with AES GCM using 192-bit key
- **A256GCMKW**: Key wrapping with AES GCM using 256-bit key
- **PBES2-HS256+A128KW**: PBES2 with HMAC SHA-256 and "A128KW" wrapping
- **PBES2-HS384+A192KW**: PBES2 with HMAC SHA-384 and "A192KW" wrapping
- **PBES2-HS512+A256KW**: PBES2 with HMAC SHA-512 and "A256KW" wrapping

I won't dive much farther into these, the important note here is that the header metadata maintains the definition for how these encryptions are applied, thus how the client would understand how to decrypt them.

## The Structure of a JWT

**Required**:

- Header (defines whether to use JWS/JWE/none)
- Payload

**Optional**:

- Signature (JWS)

### Header

The header of a JSON Web Token defines the cryptographic mechanism, as discussed in JWS/JWE. This can be based on HMAC in combination with a common hashing algorithm like SHA-512 or asymmetric key cryptography such as RSA. The former allows for an opaque secret value to be used for generating the JWT signature which is also used to verify it. The latter utilizes public/private key cryptography that allows you to generate a secret with a private key and utilize a public key, one that can be known by anyone without risking security around the tokens, to verify the signature of the JSON Web Token.

### Payload

The payload of a JSON Web Token can contain any valid json object, Jwt's do not have any further intrinsic limitations, but standards that build upon JWTs such as OpenID Connect use JWTs to provide stateless context in an access or identity token that can be utilized by resource servers or OAuth clients.

### Signature

Looking back at the header, we can reference the utilized **algorithm** and **token type**. 

## JSON Web Keys

These specify how to define cryptographic keys, typically used in combination with JWS/JWE. This builds upon specification for JWA, and can be utilized to provide JSON Web Key Sets, which consumers of secured JWTs can reach out to in order to retrieve metadata for verifying tokens, as an example.

The RFC for for JSON Web Key includes [an example in Appendix A](https://www.rfc-editor.org/rfc/rfc7517#appendix-A), which offers both elliptic curve and RSA _public_ keys for validating a JWT against its signature by the defined header metadata.

This piece of magic provides the mechanism for verification of JWS-secured JWTs with OAuth / OpenID Connect.

An example of this in the wild would be Auth0's JWKS. One is exposed for every customer, but because of the security provided by asymmetric cryptography, this _public_ key serves no special purpose outside of verification of tokens. You cannot construct a JWT with a public key that can be verified by other consumers using that public key, so it's still secure against attack vectors such as MITM.

## Additional reading

You can dig more into the official specification of JSON Web Tokens in IETF's [RFC-7519][]. The JWT specification builds upon two other important standards, which are JSON Web Signatures (JWS) defined in [RFC-7515][] and JSON Web Encryption (JWE) defined in [RFC-7516][]

A great playground space for messing around with JWT's is [jwt.io][]. They have an interactive JSON Web Token editor that shows the raw JWT and a breakdown of its parts, even so far as allowing you to verify signatures.

There is a short/long summary of the JOSE standards on StackOverflow [here][JOSE-SO] as well, which I also found helpful when RFCs got a bit too boring.

<!-- References -->

[RFC-7515]: https://datatracker.ietf.org/doc/html/rfc7515
[RFC-7516]: https://datatracker.ietf.org/doc/html/rfc7516
[RFC-7517]: https://datatracker.ietf.org/doc/html/rfc7517
[RFC-7518]: https://datatracker.ietf.org/doc/html/rfc7518
[RFC-7519]: https://datatracker.ietf.org/doc/html/rfc7519
[jwt.io]: https://jwt.io
[JOSE-SO]: https://stackoverflow.com/questions/74257560/what-is-the-difference-between-jose-jwa-jwe-jwk-jws-and-jwt

[TLS RFC]: https://datatracker.ietf.org/doc/html/rfc8446
[SSH RFC]: https://datatracker.ietf.org/doc/html/rfc4253
[GPG]: https://gnupg.org/
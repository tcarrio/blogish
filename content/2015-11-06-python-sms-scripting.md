+++
title = "Python SMS scripting"
slug = "python-sms-scripting"
date = "2015-06-11"

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["sms", "python", "scripting", "requests"]
+++

## Foreword from the future :magic-hands:

This post is a simple summary of how you can accomplish SMS text messaging via web APIs. Services exist today like Twilio that are massively popular, but a decade ago these were not _as_ stable or accessible. This post is based on source code from my [**py2sms** repository][py2sms], which showcased how you could do this.

## The goal

We're going to build a simple script showcasing how you can send text messages with Python. The service I'm going to utilize for this is [eztexting]. This will utilize a popular HTTP library and be implemented for Python 3.

## The API

The API for sending SMS messages with [eztexting] allows you to POST data to an endpoint with your authentication info (username/password), a list of numbers, and the message content. The format is optional, and in this case we're going to prefer JSON since it's straightforward to define Python dictionaries and serialize them to JSON with the `json` package.

## HTTP requests

While Python has standard libraries for working with HTTP, they can feel _clunky_ in regards to developer experience. You have to handle a lot of defaults and calls and objects to do this yourself. Due to this, I'm going to rely on [requests], a popular HTTP request library for Python. **requests** touts itself as "HTTP for Humans. An elegant and simple HTTP library for Python, built for human beings." I would request this for anyone not doing low-level networking type of work with Python, and even then consider whether you really need to subject yourself to the world of `urllib`` and `http`.

## Coding it up

### API Credentials

This is just a proof of concept, so in this solution I'm going to have a very basic approach to secrets management and the overall script safety. To start off, we're going to need a way to load credentials without embedding them in our version control. In my case, I define a `credentials` file which I configure `git` to ignore with a `.gitignore` entry:

```
# .gitignore:
/credentials
```

Now I can throw my username and password for eztexting in there

```
# /credentials
a_username
def1n1t3lyMyP@ssword
```

### Dependencies

Now let's make sure we have our dependencies. In my case I'm using `requests`, `pprint`, and `json`. The first two need to be installed in your system. There are better ways to do this than global installs, like a virtualenv. You would run this inside there:

```bash
pip install requests pprint
```

And then you can import these with

```py
import json
import pprint
import requests
```

### HTTP Requests

Next, we'll create an HTTP request with the necessary URL and body using my credentials:

```py
cred = open('credentials', 'r').readlines()
addr = "https://app.eztexting.com/sending/messages?format=json"
number = str(pnumber)
message= str(msg)
content = {
    'User': cred[0].strip(), 
    'Password': cred[1].strip(),
    'PhoneNumbers[]': '555-123-4567,
    'Message': 'Hello world'
}

r = requests.post(addr,data=content)
```

This technically works as is, other than eztexting blowing up about the number. A successful response is going to be indicated with a 204, 'No Content', HTTP status code.

### Wrapping it all up

Let's check the status and log errors, and finally parameterize the logic so it can be called as a function by other modules. Here's the final code afterward:

```python
#  _____   __     __  ___     _____   __  __    _____ 
# |  __ \  \ \   / / |__ \   / ____| |  \/  |  / ____|
# | |__) |  \ \_/ /     ) | | (___   | \  / | | (___  
# |  ___/    \   /     / /   \___ \  | |\/| |  \___ \ 
# | |         | |     / /_   ____) | | |  | |  ____) |
# |_|         |_|    |____| |_____/  |_|  |_| |_____/ 
#                                                     


import json
import pprint
import requests
# 'pip install requests' to install this library


with open('credentials','r') as c:
		cred = c.readlines()

def sms(pnumber,msg):
	addr = "https://app.eztexting.com/sending/messages?format=json"
	number = str(pnumber)
	message= str(msg)
	content = {
		'User': cred[0].strip(), 
		'Password': cred[1].strip(),
		'PhoneNumbers[]': number,
		'Message': message}
	pprint.pprint(content)
	r = requests.post(addr,data=content)
	if r.status_code != 204:
		pprint.pprint(r.json())
	else:
		print("Status code 204: No content returned")

# To send a text message call the function with
# sms(phonenumber,'sending this text message')
# sms(5551235555,'Hello World!')
```

<!-- References -->
[py2sms]: https://github.com/tcarrio/py2sms
[eztexting]: https://eztexting.com
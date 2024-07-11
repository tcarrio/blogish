+++
title = "SSH Key Management"
slug = "ssh-key-management"
date = "2022-02-21"

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["ssh", "security"]
+++

## Table of Contents:

1. [Checking for existings keys](#checking-for-existing-ssh-keys)
2. [Generating a new SSH key](#generating-a-new-ssh-key)
3. [Adding your SSH key to the ssh-agent](#adding-your-ssh-key-to-the-ssh-agent)

## Checking for existing SSH keys

Before you generate an SSH key, you can check to see if you have any existing SSH keys.

1. Open Git Bash.

2. Enter `ls -al ~/.ssh` to see if existing SSH keys are present:

  ```bash
  # Lists the files in your .ssh directory, if they exist
  ls -al ~/.ssh
  ```

3. Check the directory listing to see if you already have a public SSH key.

By default, the filenames of the public keys are one of the following, based on the SSH key type:

* id_dsa.pub
* id_ecdsa.pub
* id_ed25519.pub
* id_rsa.pub

If you don't have an existing public and private key pair, or don't wish to use any that are available to connect to GitHub, then generate a new SSH key.
If you see an existing public and private key pair listed (for example id_rsa.pub and id_rsa) that you would like to use to connect to GitHub, you can add your SSH key to the ssh-agent.

After you've checked that you don't have an existing SSH key or you simply want a new one, you can generate a new SSH key to use for authentication, then add it to the ssh-agent.

## Generating a new SSH key

This will generate a key that is generally compatible with most system to date while using a more state of the art algorithm, ED25519. 

1. Open Terminal.

2. Paste the text below, substituting in your GitHub email address.

  ```bash
  # Creates a new ssh key, using the provided email as a label
  $ ssh-keygen -t ed25519 -b 4096 -C "your_email@example.com"
  > Generating public/private ed25519 key pair.
  ```

3. When you're prompted to "Enter a file in which to save the key," press Enter. This accepts the default file location.

  ```bash
  > Enter a file in which to save the key (/Users/you/.ssh/id_ed25519): [Press enter]
  ```

4. At the prompt, type a secure passphrase. For more information, see "Working with SSH key passphrases".

  ```bash
  > Enter passphrase (empty for no passphrase): [Type a passphrase]
  > Enter same passphrase again: [Type passphrase again]
  ```

## Adding your SSH key to the ssh-agent

Before adding a new SSH key to the ssh-agent, you should have checked for existing SSH keys and generated a new SSH key.

1. Ensure ssh-agent is enabled:

  ```bash
  # start the ssh-agent in the background
  $ eval "$(ssh-agent -s)"
  > Agent pid 59566
  ```

  > ℹ️ If you are using the **Fish shell**, recent versions support the following alternative:
  > ```
  > $ eval "$(ssh-agent -c)" 

2. Add your SSH key to the ssh-agent. If you used an existing SSH key rather than generating a new SSH key, you'll need to replace id_ed25519 in the command with the name of your existing private key file.

  ```bash
  $ ssh-add ~/.ssh/id_ed25519
  ```
  If you will be using this for GitHub, continue. Otherwise, enjoy your new ssh key.
  
  
## Adding your key to your GitHub Account

Visit [this GitHub article](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account). 

## References

[Github: Generating an SSH key](https://help.github.com/articles/generating-an-ssh-key/)
[ED25519](https://ed25519.cr.yp.to/)


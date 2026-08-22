# API endpoint for authorized keys managmenet across a fleet of VMS

## Table of contents
- [Overview](#overview)
- [Port Map](#port-map)
- [Cold Start](#cold-start)
- [Security Caveats](#security-caveats)

## Overview
This originally started as a recreation of an API endpoint in Java + Spring Boot for managing
the authorized_key files across a fleet of servers, but then it quickly grew into something 
else. Let me explain the throught process briefly.

**Okay, I'll need Java + Spring Boot for the API endpoint, what version of the JDK is that?**<br />
Oh, great, it's different from what I currently use for other projects, I'll have to rely on my
IDE to handle the different versions. I look forward to competing versions fighting over JAVA_HOME.

**How many servers am I going to have to simulate for this?**<br />
More than a few, plus quite a bit of user/perm/key configuration on each mock server, for each
role group of users. These docker files are going to get unwieldy, fast.

**I'm going to need a lot bash scripts for this.**<br />
I always make so many syntax mistakes in bash scripts. I need to install a linter (ShellCheck).

**Some of these are way too complex for bash scripts, especially if I need to modify them later. I need Python.**<br />
Well, better get a bunch of python utilities through pip installed.

**If I want a simple web based UI for the front end, that's TypeScript + Vite. Better get node installed.**<br />
Again, different version of node than what I have. Better install nvm so I can swap.

## Virtual environment
While there are a lot of tools to mitigate these, they are largely different for each tool, some
aren't supported across all platforms, and worst of all, another user who doesn't have any of this
installed has to deal with installation, permissions, version management, etc. Soon, the PATH
envrionmental variable starts to look like a package.json file.

**Why aren't you using a docker container as the main development hub for this?**

And so, here are the basic concepts this project uses to solve this virtualized environment problem as cleanly
as I could manage:
* Packer + ansible + docker for manageable container provisioning and images
* A main toolbox container (DooD) that is effecitvely just a glorified virtualized environment
for all the tools needed to do everything except the actual Java development. 

## Host OS dependencies
* Docker desktop for windows and macOS, Docker Engine for Linux
* JDK 21 for building the API endpoint (still pending)

## Toolchain
* A LOT of openSSH
* Docker
* Ansible
* Packer
* JDK 21 + Spring Boot
* PostgreSQL
* python3 for more complex scripting

## Important directories
* /packer  - This is where the toolbox will keep it's packer image configuration files
  * /packer/scripts - It's a lot safer and easier to do 'provisioner "shell"' with a script than an inline
* /tools/toolbox - Docker file for the toolbox container, this is where you'll run things from
  * /tools/toolbox/Dockerfile - Edit this to add/remove packages from your toolbox 
  * /tools/toolbox/scripts - Lots of scripts that can save you time and effort
* .gitattributes - I'm calling this out because Window's CRLF line remain a contant timesink for me, and this file helps with that. Before you've commited, remember, ```sed -i 's/\r$//' [filename]``` is your friend.
* compose.yml - Setups up the toolbox container and it's attached network. Don't forget to attach any containers you create to this network or you won't be able to SSH to them.

## That's all great. How do I actually run this as quickly as possible
Note: Still in active development, more to come

### Build the main development toolbox

```bash
docker compose run --rm toolbox bash
```

That will start a fresh process that will remove itself when you're finished. But once you're inside your toolbox container:
```bash
ansible --version # ansible is installed
ssh -V # SSH is installed
packer --version # packer is installed
docker ps # yes that's every docker container running on your machine, and yes that's terrifying
```

### Generate a master key

```bash
mkdir keys
# No password
ssh-keygen -t ed25519 -f keys/master_key -N "" -C "master@demo"
```

### Build the packer images from your toolbox container
```bash
packer init packer  # Install any plugins your .hcl needs, the 2nd packer here is the packer folder, it will find the .hcl file inside
packer build packer/base.pkr.hcl
```

### Start it up
```bash
docker run -d --name throwaway --network demo-net simple-server:demo-trixie-slim
ping throwaway
ssh -i keys/master_key deploy@throwaway

# should show the deploy user id
deploy@${container-id}:~$ id

# should show root, notice the lack of a password for sudo
deploy@${container-id}:~$ sudo id
```

If you've had to do this a couple of times in a single session (ask me how I know), and your known_keys file is blocking you
```ssh -i keys/master_key -o StrictHostKeyChecking=no deploy@throwaway```

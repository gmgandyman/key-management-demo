# API endpoint for authorized keys management across a fleet of VMs

## Table of contents
- [Overview](#overview)
- [Virtual environment, but not really](#virtual-environment-but-not-really)
- [Dependencies](#dependencies)
- [Important Directories](#important-directories)
- [Cold Start](#cold-start)
- [Clean Slate](#clean-slate)
- [Final Thoughts](#final-thoughts)

## Overview
This originally started as a demo/personal recreation of an API endpoint in Java + Spring Boot for managing
the authorized_key files across a fleet of servers, but then it quickly grew into something 
else. Let me explain the thought process briefly.

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

**If I want a simple web-based UI for the front end, that's TypeScript + Vite. Better get node installed.**<br />
Again, different version of node than what I have. Better install nvm so I can swap.

## Virtual environment, but not really
While there are a lot of tools to mitigate these, they are largely different for each tool, some
aren't supported across all platforms, and worst of all, another user who doesn't have any of this
installed has to deal with installation, permissions, version management, etc. Soon, the PATH
environmental variable starts to look like a package.json file.

**Why aren't you using a docker container as the main development hub for this?**

And so, here are the basic concepts this project uses to solve this virtualized environment problem as cleanly
as I could manage:
* Packer + ansible + docker for manageable container provisioning and images
* A main toolbox container (DooD) that is effectively just a glorified virtualized environment
for all the tools needed to do everything except the actual Java development. 

## Dependencies
* Docker Desktop for Windows and macOS, Docker Engine for Linux
* JDK 21 for building the API endpoint (still pending)
* Running on the same filesystem as your docker daemon/socket (sorry, no docker over SSL)

### Software stack
* Docker
* Packer
* Ansible
* A LOT of openSSH
* JDK 21 + Spring Boot
* PostgreSQL
* python3 for more complex scripting

## Important directories
* /ansible - Day 2 provisioning automation
* /packer  - This is where the toolbox will keep its packer image configuration files
  * /packer/scripts - It's a lot safer and easier to do 'provisioner "shell"' with a script than an inline one
* /tools/toolbox - Dockerfile for the toolbox container, this is where you'll run things from
  * /tools/toolbox/Dockerfile - Edit this to add/remove packages from your toolbox 
  * /tools/toolbox/scripts - Lots of scripts that can save you time and effort
* .gitattributes - I'm calling this out because Windows' CRLF line endings remain a constant timesink for me, and this file helps with that. Before you've committed, remember, ```sed -i 's/\r$//' [filename]``` is your friend.
* compose.yml - Sets up the toolbox container and its attached network. Don't forget to attach any containers you create to this network or you won't be able to SSH to them.

## Cold Start
That's all great. How do I actually run this as quickly as possible?

Note: Still in active development, more to come

### 1 time setup stuff
```bash
docker network create --subnet 10.20.30.0/24 demo-net
```

### Set up your terminal with some environment variables and helper bash functions
```bash
source load-bash-functions.sh
```

### Build the main development toolbox

```bash
start-toolbox
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
Note that the 2nd parameter here is the packer/ directory
```bash
bash tools/toolbox/scripts/build-packer.sh
```

#### What do I do if my containers won't run
```docker run -it --rm --entrypoint bash {name}:{tag}``` is your friend. 
So is ``` /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n``` from inside the
running container.

### Boot up the postgres-db container
```bash
# Notice the lack of a --build parameter here
docker compose up -d
ping postgres-db
ssh -i keys/master_key deploy@postgres

# If you've had to do this a couple of times in a single session (ask me how I know), and your known_hosts file is blocking you
ssh -i keys/master_key -o StrictHostKeyChecking=no deploy@postgres-db

# should show the deploy user id
deploy@${container-id}:~$ id

# should show root, notice the lack of a password for sudo
deploy@${container-id}:~$ sudo id

exit
```

### Setup the user public/private keys

```bash
tools/toolbox/scripts/create-keys.sh
```
This will create public/private keypairs for users Alice through Eve.

However, you will notice that in the .gitignore file, I have carved out exceptions for keys.yml
under the ansible/inventory/host_vars. You'll need to generate those yourself. I have
templates available at tools/ansible-key-files. You just need to copy the
appropriate public key values inside. You want to setup:

* ansible/inventory/host_vars/apache2-python/keys.yml
* ansible/inventory/host_vars/nginx-proxy-passthru/keys.yml
* ansible/inventory/host_vars/postgres-db/keys.yml

If you want to verify you have this setup correctly, you can run:
```bash
cd ansible
ansible-inventory --host ${hostname}
```

It will report all the ansible variables for that hose, and under authorized_users,
you should see the users and their public keys. Postgres and Nginx should only have
Alice (admin), but apache2-python should have Alice, David, and Eve. (Bob and Charlie
have to wait for now...)

### Verify key deployments work

```bash
ssh -i keys/users/alice alice@postgres-db
ssh -i keys/users/alice alice@nginx-proxy-passthru
ssh -i keys/users/alice alice@apache2-python

ssh -i keys/users/david david@apache2-python
ssh -i keys/users/eve eve@apache2-python
```

### Verify the apache2-python wsgi works
```bash
# Check Apache + python WSGI for each site
curl http://apache2-python:8181
curl http://apache2-python:8182
curl http://apache2-python:8183

# Check Nginx with the TLS self signed cert, but not strict hostname check
curl -k https://nginx-proxy-passthru:9081/
curl -k https://nginx-proxy-passthru:9082/
curl -k https://nginx-proxy-passthru:9083/
```

## Shutdown
Don't forget to run ```docker compose down``` before leaving the toolbox container.

### Clean Slate
If you sourced the bash-functions.sh script file, you can run the following bash function to remove any image files
that the toolbox or packer have created. Note that this includes unbound volume data, which is
where the Postgres tables are stored.

```bash
reset-to-blank
```

## Final thoughts

So where does that leave this?

* This is a very barebones, traditional IDP, but nowhere near good enough.
* Docker compose down/up resets a container back to a pristine state, and so 
  requires an ansible-playbook --limit run every time. Not exactly speedy.
* User and key management is not going to be scalable. It's already a PitA. Even worse,
  it required that entire Java API endpoint for key management. I'm recreating
  an entire authentication solution when these things already exist. So it's
  back to the drawing board with this to get OICD built in instead.
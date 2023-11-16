# ansible-docker-lab
Example of setting up a managed node as docker container

*Note: this lab won't cover on how docker works*

! Для русскоязычной версии перейдите по: [README_rus.md](./README_rus.md)

## About lab

In this lab you can take a try on how to setup a remote machine and dive deep on how the automation systems like Ansible, Gitlab CI, Jenkins work inside, underneath the yaml file.

This lab consists of 3 parts + 1 task: 

1. [Setting up environment](#setting-up-env) – docker for remote host simulation, ansible installation.
2. [Rolling out sample project and automation system on the docker "remote host"](#rolling-out-sample-project-and-automation-system)
3. Digging deeper on how automation systems works inside with [https://github.com/nikitarub/automation_qa](https://github.com/nikitarub/automation_qa) 

Task:

* [Create a backup playbook for `random.log` file of the sample project](#task-create-a-backup-playbook-for-randomlog-file-of-the-sample-project)

## Setting up env

### Setting up ssh (mac tutorial)

We are going to use docker as an emulation of a remote machine. And to have a ssh connection to the machine (wich will be used via Ansible) we need to set up ssh key.

1. Create an ssh key for connecting to docker container:
```bash
$ ssh-keygen -t ed25519 -C "my_docker_ubuntu_key"

Generating public/private ed25519 key pair.
Enter file in which to save the key (/Users/your_pc/.ssh/id_ed25519): ./my_docker_ubuntu_key
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ./my_docker_ubuntu_key
Your public key has been saved in ./my_docker_ubuntu_key.pub
The key fingerprint is:
...
```

Here I'm using a project's root folder for keys just to simplify example


### Starting docker container

*will take aprox. 222MB of storage*

1. Build container
```bash
docker build -t sshubuntu .
```
2. Start container
```bash
docker run --name sshserver  -d -p 2022:22 -p 3000:3000 -p 5001:5000 sshubuntu
```

Ports 3000 and 5001 will be used for the automation system and the sample projects.


### Connecting to container via ssh

1. Connecting to container
```bash
$ ssh -i my_docker_ubuntu_key sshuser@localhost -p 2022

The authenticity of host '[localhost]:2022 ([::1]:2022)' can't be established.
ED25519 key fingerprint is SHA256:fingerprint.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes

Warning: Permanently added '[localhost]:2022' (ED25519) to the list of known hosts.
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.49-linuxkit aarch64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

sshuser@hash:~$ 
```
2. Done 

To exit from ssh simply `exit` in ssh terminal

---
**WARNING:**

```
It is strictly not recommended to use ssh connection to docker container. But it is just an example for Ansible playbook, so we can simulate a "real world" server setup.
```

### Getting IP of the container (optional)

This step is optional in case a `localhost` adress won't work with ansible inventory.

**For modern docker:**
```bash
$ docker inspect \
  -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sshserver

172.17.0.2
```

For old: 
```bash
$ docker inspect \
  --format '{{ .NetworkSettings.IPAddress }}' sshserver

172.17.0.2
```

## Setting up ansible

### Install ansible

Just do like the docs said:
```bash
pipx install --include-deps ansible
```

Or: 
```bash
python3 -m pip install --user ansible
```

Macbook users hint: **command not found: ansible**

Sometimes on Macs after install you can get there is an issue with $PATH, and can use this fix:

```
export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH
```


## Using ansible

### Checking if everything works

1. Listing hosts
```bash
$ ansible all --list-hosts -i inventory/example.yaml

  hosts (1):
    localhost
```

2. Ping for connection
```bash
$ ansible all -m ping -i inventory/example.yaml     

localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```


## Rolling out sample project and automation system

Now when a docker container has been started it's time to set it up.

### Clonning sample project and automation tool into docker

#### But first  we need a Github personal access token(PAT) to be able to clone a repos

It is as simple as the Github's ssh. Basically we are going to be okay with a [fine grained personal access token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)

After you have created a token you need to create a `inventory/secrets.yaml` file with a structure like this:

```yaml
example:
  vars:
    github_username: your_github_user
    github_pat_token: your_github_pat
    ansible_sudo_pass: pass
```

ansible_sudo_pass – you can keep it as is

#### Back to cloning repos

To run a repositories setup process on a remote host (a.k.a. docker) simply use (the steps are described in [./playbooks/repo_setup.yaml](./playbooks/repo_setup.yaml)):

```bash
ansible-playbook -i inventory/example.yaml -i inventory/secrets.yaml  playbooks/repo_setup.yaml
```

It will install git tool on Ubuntu, add github to known hosts and clone the repos ([automation tool](https://github.com/nikitarub/automation_qa) and a [sample project](https://github.com/nikitarub/automation_qa_target)).


Now if we connect to our "remote host again": 
```bash
ssh -i my_docker_ubuntu_key sshuser@localhost -p 2022
```

And list some files we'll se the repos:

```
$ ls
project

$ ls project/
automation_qa  automation_qa_target
```

### Installing repos dependancies

We can also define the deps installation process with Ansible. The steps of deps installation described in [./playbooks/deps_install.yaml](./playbooks/deps_install.yaml):

```bash
ansible-playbook -i inventory/example.yaml -i inventory/secrets.yaml  playbooks/deps_install.yaml
```

Now we have installed dependancies of each project and a tmux terminal as well (will be easier to navigate in ssh).


#### Running the projects

Connect to a remote host again:

```bash
ssh -i my_docker_ubuntu_key sshuser@localhost -p 2022
```

and go into `tmux` [(more about tmux)](https://github.com/tmux/tmux/wiki) terminal:
```bash
tmux

# after you can attach to last terminal session with
tmux attach
```

Now we can start an automation tool (in the same tmux window) in webhook mode with explain, [more about how the tool works](https://github.com/nikitarub/automation_qa):

```bash
$ cd project/
$ python3 automation_qa/src/main.py -m webhook --explain
[   INFO][ /home/sshuser/project/automation_qa/src/common/explain.py:16        ]: Setting explain mode to True
[   INFO][ /home/sshuser/project/automation_qa/src/main.py:52                  ]: starting webhook
INFO:     Started server process [2608]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
```

Voila, we have our automation tool running in webhook mode, accesable on [http://0.0.0.0:3000/docs](http://0.0.0.0:3000/docs). You can go and check it in a browser. 

##### Now let's start a sample project.

In the tmux hit `CTRL+b then C` –it will create a new window in tmux (to switch between windows use `CTRL+b then W` and arrow keys).

```bash
$ cd project/automation_qa_target
$ sh start.sh 
INFO:     Uvicorn running on http://0.0.0.0:5000 (Press CTRL+C to quit)
INFO:     Started reloader process [2610] using watchgod
INFO:     Started server process [2612]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

Now we have a sample project running in 5001 port. Go to your browser to [http://0.0.0.0:5001/docs](http://0.0.0.0:5001/docs). 

Here try the `/slow` handle with **log** set as `true`. It will generate a `random.log` file in projet's root (a.k.a. `/home/sshuser/project/automation_qa_target/random.log`).

#### Cloning sample (target) repo with an automation tool

Go to your tmux terminal and change window via `CTRL+b then W` to a window with a running automation tool. Now press `CTRL+C` to stop the service.

Now we need to start it in a production mode (not explain):

```bash
$ python3 automation_qa/src/main.py -m webhook
[   INFO][ /home/sshuser/project/automation_qa/src/main.py:52                  ]: starting webhook
INFO:     Started server process [2608]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
```

Same, on the page `http://0.0.0.0:3000/docs` press a "Try it" button on `/github_webhook` handle. It well run a sample project clone into `target_test_project` folder.

And it was an example of the same task as Ansible did, but with our automation tool using a webhook, that can be triggered by Github.


## TASK: Create a backup playbook for `random.log` file of the sample project

On the step of [running a sample project](#now-lets-start-a-sample-project) we used a `/slow?log=true` handle to make a random.log file.

The task is to create a backup of a`random.log` file on the host machine using Ansible.

In a [./playbooks/backup.yaml](./playbooks/backup.yaml) you have a template of a playbook to be used in this task.

After you're done with a yaml simply use:

```bash
ansible-playbook -i inventory/example.yaml -i inventory/secrets.yaml  playbooks/backup.yaml
```

As a result you need to have a random.log file copied to your host machine.

---

**Resources:**
* [Setting up ssh to docker](https://goteleport.com/blog/shell-access-docker-container-with-ssh-and-docker-exec/)





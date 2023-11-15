# ansible-docker-lab
Example of setting up a managed node as docker container


## Setting up env

### Setting up ssh (mac tutorial)
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

Here I'm using a project root folder for keys just to simplify example


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


### Connecting to conteiner via ssh

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


---

**Resources:**
* [Setting up ssh to docker](https://goteleport.com/blog/shell-access-docker-container-with-ssh-and-docker-exec/)





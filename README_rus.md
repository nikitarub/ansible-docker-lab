# ansible-docker-lab
Пример настройки управляемого узла в качестве докер-контейнера с помощью Ansible

*Примечание: в этой лабораторной работе не рассматривается принцип работы Docker*


## О лабораторной

В этой лабораторной работе вы можете попробовать настроить удаленный компьютер и углубиться в то, как системы автоматизации, такие как Ansible, Gitlab CI, Jenkins, работают под капотом файла yaml.

Лабораторная работа состоит из 3 частей + 1 задание:

1. [Настройка среды](#настройка-окружения) – докер для моделирования удаленного хоста, установка ansible.
2. [Развертывание тестового проекта и системы автоматизации на «удаленном хосте» докера](#развертывание-тестового-проекта-и-системы-автоматизации)
3. Углубиться в то, как работают системы автоматизации, на примере [https://github.com/nikitarub/automation_qa](https://github.com/nikitarub/automation_qa).

Задание:

* [Создайте резервную копию файла `random.log` примера проекта](#задача-создать-резервную-копию-файла-«randomlog»-примера-проекта)

## Настройка окружения

### Настройка ssh (руководство для Mac)

Мы собираемся использовать Docker в качестве эмуляции удаленной машины. И чтобы иметь ssh-соединение с машиной (которое будет использоваться через Ansible), нам нужно настроить ssh-ключ.

1. Создайте ssh-ключ для подключения к докер-контейнеру:
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

Здесь я использую корневую папку проекта для ключей, просто чтобы упростить пример.


### Запускаем docker container

*займет примерно. 222MB на диске*

1. Сборка контейнера
```bash
docker build -t sshubuntu .
```
2. Запуск контейнера
```bash
docker run --name sshserver  -d -p 2022:22 -p 3000:3000 -p 5001:5000 sshubuntu
```

Порты 3000 и 5001 будут использоваться для системы автоматизации и тестового проекта.


### Подключение к контейнеру через ssh

1. Подключаемся к контейнеру
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
2. Готово 

To exit from ssh simply  in ssh terminal
Чтобы выйти из ssh, используйте `exit` команду в терминале ssh.

---
**ПРЕДУПРЕЖДЕНИЕ:**

```
Категорически не рекомендуется использовать обычное ssh-соединение с докер-контейнером. Но это всего лишь пример для сборника сценариев Ansible, поэтому мы так будем моделировать настройку с помощью докер, как "реального" сервера.
```


### Получение IP контейнера (необязательно)

Этот шаг является необязательным, если адрес `localhost` не работает с ansible-инвентарем.

**Для современного докера:**
```bash
$ docker inspect \
  -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sshserver

172.17.0.2
```

Для старого: 
```bash
$ docker inspect \
  --format '{{ .NetworkSettings.IPAddress }}' sshserver

172.17.0.2
```

## Настройка ansible

### Установка ansible

Просто делайте, как сказано в документации:
```bash
pipx install --include-deps ansible
```

Или: 
```bash
python3 -m pip install --user ansible
```

Проблема: **command not found: ansible**

Иногда на компьютерах Mac после установки возникает проблема с $PATH, и вы можете использовать это фикс:

```
export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH
```


## Использование ansible

### Проверяем, что все настроили нормально

1. Выводим спискок удаленный машин
```bash
$ ansible all --list-hosts -i inventory/example.yaml

  hosts (1):
    localhost
```

2. Пинганём эти машины (докер)
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


## Развертывание тестового проекта и системы автоматизации

Теперь, когда докер-контейнер запущен, пришло время его настроить.

### Клонирование примера проекта и инструмента автоматизации в Docker

#### Но сначала нам нужен токен личного доступа Github (PAT), чтобы иметь возможность клонировать репозитории.

Это так же просто, как ssh в Github. По сути, нас устроит[fine grained personal access token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)

После создания токена вам необходимо создать файл inventory/secrets.yaml со следующей структурой:

```yaml
example:
  vars:
    github_username: your_github_user
    github_pat_token: your_github_pat
    ansible_sudo_pass: pass
```

ansible_sudo_pass – можно оставить как есть, а другие параметры поменять под свои

#### Обратно к клонированию репозиторием

Чтобы запустить процесс установки репозиториев на удаленном хосте (a.k.a. Docker), просто используйте (шаги описаны в разделе [./playbooks/repo_setup.yaml](./playbooks/repo_setup.yaml)):

```bash
ansible-playbook -i inventory/example.yaml -i inventory/secrets.yaml  playbooks/repo_setup.yaml
```

Он установит инструмент git в Ubuntu, добавит github.com к известным хостам и cклонирует репозитории ([automation tool](https://github.com/nikitarub/automation_qa) и  [sample project](https://github.com/nikitarub/automation_qa_target)).


Теперь, если мы снова подключимся к нашему «удаленному хосту»:
```bash
ssh -i my_docker_ubuntu_key sshuser@localhost -p 2022
```

И вывдем файлы, то увидим:

```
$ ls
project

$ ls project/
automation_qa  automation_qa_target
```

Наши склонированные репозитории

### Установка зависимостей репозиториев

Мы также можем определить процесс установки зависимостей с помощью Ansible. Шаги установки зависимостей, описанны в[./playbooks/deps_install.yaml](./playbooks/deps_install.yaml):

```bash
ansible-playbook -i inventory/example.yaml -i inventory/secrets.yaml  playbooks/deps_install.yaml
```

Теперь мы установили зависимости каждого проекта, а также терминал tmux (по ssh будет легче ориентироваться в окнах).


#### Запускаем проекты

Снова подключитесь к удаленному хосту:

```bash
ssh -i my_docker_ubuntu_key sshuser@localhost -p 2022
```

и войдите в терминал `tmux` [(подробнее про tmux)](https://github.com/tmux/tmux/wiki):
```bash
tmux

# после вы сможете заново подключатся к сесси tmux, если закройте ssh сессию
tmux attach
```

Теперь мы можем запустить инструмент автоматизации (в том же окне tmux) в режиме webhook с explain [подробнее о том, как работает инструмент](https://github.com/nikitarub/automation_qa):

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

Вуаля, у нас есть наш инструмент автоматизации, работающий в режиме веб-перехватчика, доступный по адресу [http://0.0.0.0:3000/docs](http://0.0.0.0:3000/docs). Вы можете пойти и проверить это в браузере.

##### Теперь запустим тестовый проект.

В tmux нажмите `CTRL+b затем C` — в tmux создастся новое окно (для переключения между окнами используйте `CTRL+b затем W` и клавиши со стрелками).

```bash
$ cd project/automation_qa_target
$ sh start.sh 
INFO:     Uvicorn running on http://0.0.0.0:5000 (Press CTRL+C to quit)
INFO:     Started reloader process [2610] using watchgod
INFO:     Started server process [2612]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

Теперь у нас есть пример проекта, работающего на порту 5001. Откройте в браузере страницу [http://0.0.0.0:5001/docs](http://0.0.0.0:5001/docs).

Здесь попробуйте использовать API ручку `/slow` с параметром **log**, установленным как `true`. Он создаст файл «random.log» в корне проекта (полный путь `/home/sshuser/project/automation_qa_target/random.log``).

#### Клонирование репозитория тестового проекта с помощью инструмента автоматизации

Перейдите к терминалу tmux и с помощью `CTRL+b затем W` измените окно на окно с работающим инструментом автоматизации. Теперь нажмите `CTRL+C`, чтобы остановить службу.

Теперь нам нужно запустить его в производственном режиме (не объяснять):
```bash
$ python3 automation_qa/src/main.py -m webhook
[   INFO][ /home/sshuser/project/automation_qa/src/main.py:52                  ]: starting webhook
INFO:     Started server process [2608]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
```

То же самое: на странице http://0.0.0.0:3000/docs нажмите кнопку «Попробовать» на API `/github_webhook`. Он запустить клонирование тестового проекта в папку target_test_project.

И это был пример той же задачи, что и Ansible, но с нашим инструментом автоматизации, запущенным в режиме webhook, который может быть стриггерирован Github.


## ЗАДАЧА: Создать резервную копию файла «random.log» примера проекта.

На этапе [запуска тестового проекта](#запускаем-проекты) мы использовали ручку `/slow?log=true` для создания файла random.log.

Задача — создать резервную копию файла `random.log` на хост-машине с помощью Ansible.

In a [./playbooks/backup.yaml](./playbooks/backup.yaml) you have a template of a playbook to be used in this task.

В файле [./playbooks/backup.yaml](./playbooks/backup.yaml) у вас есть шаблон, который может пригодиться в этой задаче.

Когда шаблон доделали можно запустить через:

```bash
ansible-playbook -i inventory/example.yaml -i inventory/secrets.yaml  playbooks/backup.yaml
```

В результате вы должны получить файл `random.log` на вашей локальной машине

---

**Источники:**
* [Setting up ssh to docker](https://goteleport.com/blog/shell-access-docker-container-with-ssh-and-docker-exec/)





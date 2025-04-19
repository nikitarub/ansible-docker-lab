FROM python:3.11
RUN apt update && apt install  openssh-server sudo -y
# Create a user “sshuser” and group “sshgroup”
RUN groupadd sshgroup 
# && useradd -ms /bin/bash -g sshgroup sshuser
RUN useradd -ms /bin/bash sshuser -g sshgroup && echo "sshuser:pass" | chpasswd && adduser sshuser sudo
# Create sshuser directory in home
RUN mkdir -p /home/sshuser/.ssh
# Copy the ssh public key in the authorized_keys file. The idkey.pub below is a public key file you get from ssh-keygen. They are under ~/.ssh directory by default.
COPY my_docker_ubuntu_key.pub /home/sshuser/.ssh/authorized_keys
# change ownership of the key file. 
RUN chown sshuser:sshgroup /home/sshuser/.ssh/authorized_keys && chmod 600 /home/sshuser/.ssh/authorized_keys
# Start SSH service
RUN service ssh start
# Expose docker port 22
EXPOSE 22
COPY automation_qa_target/ /home/sshuser/automation_qa_target_from_build
CMD ["/usr/sbin/sshd","-D"]

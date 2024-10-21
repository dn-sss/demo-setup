sudo apt-get update && \
curl -fsSL https://get.docker.com -o get-docker.sh && \
sudo sh get-docker.sh && \
sudo gpasswd -a $USER docker && \
newgrp docker && \
rm ./get-docker.sh && \
sudo reboot now
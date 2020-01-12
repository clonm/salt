apt-transport-https:
  pkg.latest

ca-certificates:
  pkg.latest

{% if salt['pillar.get']('docker:release', None) == 'docker-ce' %}

docker-package:
  pkg.removed:
    - name: docker

docker-engine-unhold:
  cmd.run:
    - name: apt-mark unhold docker-engine
    - onlyif: dpkg -s docker-engine

docker-engine:
  pkg.removed:
    - require:
      - cmd: docker-engine-unhold

docker.io:
  pkg.removed

# docker-repository:
#   pkgrepo.managed:
#     - name: deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
#     - file: /etc/apt/sources.list.d/docker-repository.list
#     - key_url: https://download.docker.com/linux/ubuntu/gpg
#     - require_in:
#       - pkg: docker-ce
#
docker-ce:
  pkg.installed

{% else %}

docker-repository:
  pkgrepo.managed:
    - humanname: Docker
    {% if grains['oscodename'] == 'bionic' %}
    - name: deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable
    {% elif grains['oscodename'] == 'xenial' %}
    - name: deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
    {% elif grains['oscodename'] == 'trusty' %}
    - name: deb [arch=amd64] https://download.docker.com/linux/ubuntu trusty stable
    {% endif %}
    - keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
    - keyserver: keyserver.ubuntu.com
    - require_in:
      - pkg: docker-engine

docker-engine:
  pkg.installed:
    {% if grains['oscodename'] == 'bionic' %}
    # docker-engine isn't used anymore. just check the docker-ce version.
    - name: docker-ce
    - version: 18.03.1~ce~3-0~ubuntu
    {% elif grains['oscodename'] == 'xenial' %}
    - name: docker-engine
    - version: 1.12.5-0~ubuntu-xenial
    {% elif grains['oscodename'] == 'trusty' %}
    - name: docker-engine
    - version: 1.8.3-0~trusty
    {% endif %}
    - hold: True

{% endif %}

python-docker:
  pip.installed:
    - name: docker==4.1.0
    - reload_modules: True
    - require:
      - sls: pip

docker-compose:
  pip.installed:
    - name: docker-compose==1.25.1
    - require:
      - sls: pip

/srv/docker:
  file.directory:
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

/srv/tmp/docker:
  file.directory:
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

/srv/log:
  file.directory:
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

/srv/repositories:
  file.directory:
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

/srv/storage:
  file.directory:
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

docker-configuration-file:
  file.managed:
    {% if grains['oscodename'] == 'xenial' or grains['oscodename'] == 'bionic' %}
    - name: /etc/systemd/system/docker.service.d/10-execstart.conf
    - source: salt://docker/10-execstart.conf
    {% elif grains['oscodename'] == 'trusty' %}
    - name: /etc/default/docker
    - source: salt://docker/docker.conf
    {% endif %}
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - require:
      {% if salt['pillar.get']('docker:release', None) == 'docker-ce' %}
      - pkg: docker-ce
      {% else %}
      - pkg: docker-engine
      {% endif %}

docker:
  service.running:
    - require:
      - file: /srv/docker
      - file: /srv/tmp/docker
      - file: /srv/log
      - file: /srv/repositories
    - watch:
      - file: docker-configuration-file

docker-available:
  cmd.run:
    - name: while ! docker ps; do sleep 1; done >/dev/null
    - timeout: 15
    - require:
      - service: docker

container-from-pid:
  file.managed:
    - name: /usr/local/bin/container-from-pid
    - source: salt://docker/container-from-pid.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

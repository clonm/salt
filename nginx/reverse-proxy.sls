single-host-reverse-proxy-image:
  docker.pulled:
    - name: tozd/nginx-proxy
    - tag: latest
    - force: True
    - require:
      - sls: docker.base

single-host-reverse-proxy-container:
  docker.running:
    - name: single-host-reverse-proxy
    - hostname: single-host-reverse-proxy
    - image: tozd/nginx-proxy
    - ports:
        80/tcp:
          HostIp: {{ pillar['network']['address'] }}
          HostPort: 80
        443/tcp:
          HostIp: {{ pillar['network']['address'] }}
          HostPort: 443
    - restart_policy:
        Name: always
    - require:
      - docker: single-host-reverse-proxy-image

iptables-single-host-reverse-proxy-policy:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - source: 0.0.0.0/0
    - dports:
      - 80
      - 443
    - proto: tcp
    - save: True
    - require:
      - pkg: iptables

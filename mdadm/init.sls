mdadm:
  pkg.latest:
    - require:
      - sls: mailer
  service.running:
    - watch:
      - pkg: mdadm

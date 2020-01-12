lm-sensors:
  pkg.latest

sensord:
  pkg.latest:
    - require:
      - pkg: lm-sensors

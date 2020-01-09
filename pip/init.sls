python3-setuptools:
  pkg.latest:
    - refresh: True

python-pip-package:
  pkg.purged:
    - name: python-pip

{% if grains['oscodename'] == 'xenial' or grains['oscodename'] == 'bionic' %}
python3-pip:
  pkg.latest:
    - refresh: True
    - reload_modules: True
{% elif grains['oscodename'] == 'trusty' %}
python3-pip:
  cmd.run:
    - name: easy_install pip==19.3.1
    - unless: which pip
    - require:
      - pkg: python3-pip-package
      - pkg: python3-setuptools
    - reload_modules: True
{% endif %}

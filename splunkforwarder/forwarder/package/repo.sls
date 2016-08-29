{% set custom_repo = salt['pillar.get']('splunkforwarder:package:repo', False) %}
{% set custom_version = salt['pillar.get']('splunkforwarder:package:version', False) %}

include:
  - splunkforwarder.certs
  - splunkforwarder.user
  - splunkforwarder.forwarder.config


splunkforwarder:
  pkg.installed:
    - name: {{ salt['pillar.get']('splunkforwarder:package:name') }}
{% if custom_repo %}
    - fromrepo: {{ custom_repo }}
{% endif %}
{% if custom_version %}
    - version: {{ custom_version }}
{% endif %}
  file:
    - managed
    - name: /etc/systemd/system/splunkforwarder.service
    - source: salt://splunkforwarder/init.d/splunkforwarder.service
    - template: jinja
    - mode: 644
  service:
    - running
    - name: splunkforwarder
    - enable: True
    - restart: True
    - require:
      - pkg: splunkforwarder
      - file: splunkforwarder
      - file: /opt/splunkforwarder/etc/system/local/outputs.conf
    - watch:
      - pkg: splunkforwarder
      - file: /opt/splunkforwarder/etc/system/local/outputs.conf
  systemd.enable:
    - name: splunkforwarder.service
    - require:
      - service: splunkforwarder

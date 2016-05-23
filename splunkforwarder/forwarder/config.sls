{%- set self_cert = salt['pillar.get']('splunk:self_cert_filename', 'selfsignedcert.pem') %}

include:
  - splunkforwarder.certs
  - splunkforwarder.user

/opt/splunkforwarder/etc/apps/search/local:
  file:
    - directory
    - user: splunk
    - group: splunk
    - mode: 755
    - makedirs: True

/opt/splunkforwarder/etc/apps/search/local/inputs.conf:
  file:
    - managed
    - name: /opt/splunkforwarder/etc/apps/search/local/inputs.conf
    - source: salt://splunkforwarder/etc-apps-search/local/inputs.conf
    - template: jinja
    - user: splunk
    - group: splunk
    - mode: 644
    - context:
      self_cert: {{ self_cert }}
    - require:
{% if salt['pillar.get']('splunkforwarder:package:name', False) %}
      - pkg: splunkforwarder
{% else %}
      - cmd: splunkforwarder
{% endif %}
      - file: /opt/splunkforwarder/etc/apps/search/local
      - file: /opt/splunkforwarder/etc/certs/{{ self_cert }}
    - require_in:
      - service: splunkforwarder
    - watch_in:
      - service: splunkforwarder

/opt/splunkforwarder/etc/system/local/outputs.conf:
  file:
    - managed
    - name: /opt/splunkforwarder/etc/system/local/outputs.conf
    - source: salt://splunkforwarder/etc-system-local/outputs.conf
    - template: jinja
    - user: splunk
    - group: splunk
    - mode: 600
    - context:
      self_cert: {{ self_cert }}
    - require:
{% if salt['pillar.get']('splunkforwarder:package:name', False) %}
      - pkg: splunkforwarder
{% else %}
      - cmd: splunkforwarder
{% endif %}
      - file: /opt/splunkforwarder/etc/certs/{{ self_cert }}
    - require_in:
      - service: splunkforwarder
    - watch_in:
      - service: splunkforwarder

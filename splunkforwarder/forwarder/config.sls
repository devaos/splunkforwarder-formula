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
{%- if pillar['splunkforwarder']['disable_ssl'] != True %}
    - context:
      self_cert: {{ self_cert }}
{% endif %}
    - require:
      - pkg: splunkforwarder
      - file: /opt/splunkforwarder/etc/apps/search/local
    - require_in:
      - service: splunkforwarder
      - file: /opt/splunkforwarder/etc/apps/search/local
{%- if pillar['splunkforwarder']['disable_ssl'] != True %}
      - file: /opt/splunkforwarder/etc/certs/{{ self_cert }}
{%- endif %}
    - watch_in:
      - service: splunkforwarder

/opt/splunkforwarder/etc/system/local/outputs.conf:
  file:
    - managed
    - name: /opt/splunkforwarder/etc/system/local/outputs.conf
{%- if pillar['splunkforwarder']['disable_ssl'] != True %}
    - source: salt://splunkforwarder/etc-system-local/outputs-ssl.conf
{%- else %}
    - source: salt://splunkforwarder/etc-system-local/outputs.conf
{%- endif %}
    - template: jinja
    - user: splunk
    - group: splunk
    - mode: 600
    - require:
{% if salt['pillar.get']('splunkforwarder:package:name', False) %}
      - pkg: splunkforwarder
{% else %}
      - cmd: splunkforwarder
{% endif %}
{%- if pillar['splunkforwarder']['disable_ssl'] != True %}
      - file: /opt/splunkforwarder/etc/certs/{{ self_cert }}
{% endif %}
    - require_in:
      - service: splunkforwarder
    - watch_in:
      - service: splunkforwarder

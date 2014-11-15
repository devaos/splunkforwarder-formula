
include:
  - splunkforwarder.forwarder

/opt/splunkforwarder/etc/system/local/inputs.conf:
  file:
    - managed
    - name: /opt/splunkforwarder/etc/system/local/inputs.conf
    - source: salt://splunkforwarder/etc-system-local/inputs.conf
    - template: jinja
    - user: splunk
    - group: splunk
    - mode: 600
    - require:
      - pkg: splunkforwarder
    - require_in:
      - service: splunkforwarder
    - watch_in:
      - service: splunkforwarder

/opt/splunkforwarder/etc/apps/search/metadata:
  file:
    - directory
    - user: splunk
    - group: splunk
    - mode: 755
    - makedirs: True

/opt/splunkforwarder/etc/apps/search/metadata/local.metadata:
  file:
    - managed
    - name: /opt/splunkforwarder/etc/apps/search/metadata/local.metadata
    - source: salt://splunkforwarder/etc-apps-search/metadata/local.metadata
    - template: jinja
    - user: splunk
    - group: splunk
    - mode: 600
    - require:
      - pkg: splunkforwarder
      - file: /opt/splunkforwarder/etc/apps/search/metadata
    - require_in:
      - service: splunkforwarder
    - watch_in:
      - service: splunkforwarder

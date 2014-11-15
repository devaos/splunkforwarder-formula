{%- set download_base_url = pillar['splunkforwarder']['download_base_url'] %}
{%- set package_filename = pillar['splunkforwarder']['package_filename'] %}
{%- set source_hash = pillar['splunkforwarder']['source_hash'] %}
{%- set self_cert = salt['pillar.get']('splunk:self_cert_filename', 'selfsignedcert.pem') %}

include:
  - splunkforwarder.certs


splunk_group:
  group.present:
    - name: splunk

splunk_user:
  user.present:
    - name: splunk
    - home: /opt/splunkforwarder
    - groups:
      - splunk
    - require:
      - group: splunk_group

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
      - pkg: splunkforwarder
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
      - pkg: splunkforwarder
      - file: /opt/splunkforwarder/etc/certs/{{ self_cert }}

get-splunkforwarder-package:
  file:
    - managed
    - name: /usr/local/src/{{ package_filename }}
    - source: {{ download_base_url }}{{ package_filename }}
    - source_hash: {{ source_hash }}

is-splunkforwarder-package-outdated:
  cmd.run:
    - cwd: /usr/local/src
    - stateful: True
    - names:
      - new=$(dpkg-deb --showformat='${Package} ${Version}\n' -W {{ package_filename }});
        old=$(dpkg-query --showformat='${Package} ${Version}\n' -W splunkforwarder);
        if test "$new" != "$old";
          then echo; echo "changed=true comment='new($new) vs old($old)'";
          else echo; echo "changed=false";
        fi;
    - require:
      - pkg: splunkforwarder

splunkforwarder:
  pkg.installed:
    - sources:
      - splunkforwarder: /usr/local/src/{{ package_filename }}
    - require:
      - user: splunk_user
      - file: get-splunkforwarder-package
  cmd.watch:
    - cwd: /usr/local/src/
    - name: dpkg -i {{ package_filename }}
    - watch:
      - cmd: is-splunkforwarder-package-outdated
  file:
    - managed
    - name: /etc/init.d/splunkforwarder
    - source: salt://splunkforwarder/init.d/splunkforwarder.sh
    - template: jinja
    - mode: 500
  service:
    - running
    - name: splunkforwarder
    - enable: True
    - restart: True
    - require:
      - pkg: splunkforwarder
      - cmd: splunkforwarder
      - file: splunkforwarder
      - file: /opt/splunkforwarder/etc/system/local/outputs.conf
    - watch:
      - pkg: splunkforwarder
      - cmd: splunkforwarder
      - file: splunkforwarder
      - file: /opt/splunkforwarder/etc/system/local/outputs.conf

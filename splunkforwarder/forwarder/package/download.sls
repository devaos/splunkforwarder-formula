{%- set download_base_url = pillar['splunkforwarder']['download_base_url'] %}
{%- set package_filename = pillar['splunkforwarder']['package_filename'] %}
{%- set source_hash = pillar['splunkforwarder']['source_hash'] %}

include:
  - splunkforwarder.certs
  - splunkforwarder.user
  - splunkforwarder.forwarder.config


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
{%- if grains['init'] == 'sysvinit' %}
    - name: /etc/init.d/splunkforwarder
    - source: salt://splunkforwarder/init.d/splunkforwarder.sh
{%- elif grains['init'] == 'systemd' %}
    - name: /etc/systemd/system/splunkforwarder.service
    - source: salt://splunkforwarder/init.d/splunkforwarder.service.jinja
    - watch_in:
      - cmd: reload_systemd_configuration
{%- endif %}
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

reload_systemd_configuration:
  cmd.wait:
    - name: systemctl daemon-reload

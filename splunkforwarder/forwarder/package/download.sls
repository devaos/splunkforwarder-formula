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
        ver=$(echo "$old" | awk '{ print $2 }');
        if test "$new" != "$old" && test "$ver" != "";
          then echo; echo "changed=true comment='new($new) vs old($old)'";
        elif test "$old" == "";
          then echo; echo "changed=true comment='new($new) vs old($old)'";
        else
          echo; echo "changed=false";
        fi;
    - require:
      - file: get-splunkforwarder-package

splunkforwarder:
  cmd.watch:
    - cwd: /usr/local/src/
    - name: dpkg -i {{ package_filename }}
    - require:
      - cmd: is-splunkforwarder-package-outdated
    - watch:
      - cmd: is-splunkforwarder-package-outdated
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
      - cmd: splunkforwarder
      - file: splunkforwarder
      - file: /opt/splunkforwarder/etc/system/local/outputs.conf
    - watch:
      - cmd: splunkforwarder
      - file: splunkforwarder
      - file: /opt/splunkforwarder/etc/system/local/outputs.conf
  systemd.enable:
    - name: splunkforwarder.service
    - require:
      - service: splunkforwarder

splunkforwarder.service:
  service.running:
    - provider: systemd
    - enable: True
    - require:
      - service: splunkforwarder

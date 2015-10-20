{%- from 'logstash/map.jinja' import logstash with context %}

include:
  - .repo

# This gets around a user permissions bug with the logstash user/group
# being able to read /var/log/syslog, even if the group is properly set for
# the account. The group needs to be defined as 'adm' in the init script,
# so we'll do a pattern replace.

{%- if salt['grains.get']('os', None) == "Ubuntu" %}
change service group in Ubuntu init script:
  file.replace:
    - name: /etc/init.d/logstash
    - pattern: "LS_GROUP=logstash"
    - repl: "LS_GROUP=adm"
    - watch_in:
      - service: logstash

add adm group to logstash service account:
  user.present:
    - name: logstash
    - groups:
      - logstash
      - adm
    - require:
      - pkg: logstash
{%- endif %}

/etc/logstash/conf.d:
  file.recurse:
    - source: salt://logstash/files/conf.d
    - require:
      - pkg: logstash

logstash:
  service.running:
    - name: {{logstash.svc}}
    - enable: true
    - require:
      - pkg: logstash
    - watch:
      - file: logstash-config-inputs
      - file: logstash-config-filters
      - file: logstash-config-outputs
  pkg.{{logstash.pkgstate}}:
    - name: {{logstash.pkg}}
    - require:
      - pkgrepo: logstash-repo


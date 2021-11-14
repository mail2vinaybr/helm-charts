{{/*
Pod Spec
*/}}
{{- define "tomcat.pod" -}}
{{- if .Values.hostAliases }}
hostAliases: {{- include "common.tplvalues.render" (dict "value" .Values.hostAliases "context" $) | nindent 2 }}
{{- end }}
{{- if .Values.affinity }}
affinity: {{- include "common.tplvalues.render" (dict "value" .Values.affinity "context" $) | nindent 2 }}
{{- else }}
affinity:
  podAffinity: {{- include "common.affinities.pods" (dict "type" .Values.podAffinityPreset "context" $) | nindent 4 }}
  podAntiAffinity: {{- include "common.affinities.pods" (dict "type" .Values.podAntiAffinityPreset "context" $) | nindent 4 }}
  nodeAffinity: {{- include "common.affinities.nodes" (dict "type" .Values.nodeAffinityPreset.type "key" .Values.nodeAffinityPreset.key "values" .Values.nodeAffinityPreset.values) | nindent 4 }}
{{- end }}
{{- if .Values.nodeSelector }}
nodeSelector: {{- include "common.tplvalues.render" ( dict "value" .Values.nodeSelector "context" $) | nindent 2 }}
{{- end }}
{{- if .Values.tolerations }}
tolerations: {{- include "common.tplvalues.render" (dict "value" .Values.tolerations "context" .) | nindent 2 }}
{{- end }}
{{- if .Values.podSecurityContext.enabled }}
securityContext: {{- omit .Values.podSecurityContext "enabled" | toYaml | nindent 2 }}
{{- end }}
{{- if .Values.topologySpreadConstraints }}
topologySpreadConstraints: {{- include "common.tplvalues.render" (dict "value" .Values.topologySpreadConstraints "context" $) | nindent 2 }}
{{- end }}
initContainers:
{{- if .Values.initContainers }}
{{ include "common.tplvalues.render" (dict "value" .Values.initContainers "context" $) }}
{{- end }}
containers:
- name: tomcat
  image: {{ template "tomcat.image" . }}
  imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
  {{- if .Values.containerSecurityContext.enabled }}
  securityContext: {{- omit .Values.containerSecurityContext "enabled" | toYaml | nindent 4 }}
  {{- end }}
  {{- if .Values.command }}
  command: {{- include "common.tplvalues.render" (dict "value" .Values.command "context" $) | nindent 4 }}
  {{- end }}
  {{- if .Values.args }}
  args: {{- include "common.tplvalues.render" (dict "value" .Values.args "context" $) | nindent 4 }}
  {{- end }}
  env:
  - name: BITNAMI_DEBUG
    value: {{ ternary "true" "false" .Values.image.debug | quote }}
  - name: TOMCAT_USERNAME
    value: {{ .Values.tomcatUsername | quote }}
  - name: TOMCAT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "common.names.fullname" . }}
        key: tomcat-password
  - name: TOMCAT_ALLOW_REMOTE_MANAGEMENT
    value: {{ .Values.tomcatAllowRemoteManagement | quote }}
  {{- if or .Values.catalinaOpts .Values.metrics.jmx.enabled }}    
  - name: CATALINA_OPTS
    value: {{ include "tomcat.catalinaOpts" . | quote }}
  {{- end }}
  {{- if .Values.extraEnvVars }}
  {{- include "common.tplvalues.render" (dict "value" .Values.extraEnvVars "context" $) | nindent 2 }}
  {{- end }}
  {{- if or .Values.extraEnvVarsCM .Values.extraEnvVarsSecret }}
  envFrom:
  {{- if .Values.extraEnvVarsCM }}
  - configMapRef:
      name: {{ include "common.tplvalues.render" (dict "value" .Values.extraEnvVarsCM "context" $) }}
  {{- end }}
  {{- if .Values.extraEnvVarsSecret }}
  - secretRef:
      name: {{ include "common.tplvalues.render" (dict "value" .Values.extraEnvVarsSecret "context" $) }}
  {{- end }}
  {{- end }}
  ports:
  - name: http
    containerPort: {{ .Values.containerPort }}
  {{- if .Values.containerExtraPorts }}
  {{- include "common.tplvalues.render" (dict "value" .Values.containerExtraPorts "context" $) | nindent 2 }}
  {{- end }}
  {{- if .Values.resources }}
  resources: {{- toYaml .Values.resources | nindent 4 }}
  {{- end }}
{{- if .Values.sidecars }}
{{ include "common.tplvalues.render" ( dict "value" .Values.sidecars "context" $) }}
{{- end }}
{{- if .Values.metrics.jmx.enabled }}
- name: jmx-exporter
  image: {{ template "tomcat.metrics.jmx.image" . }}
  imagePullPolicy: {{ .Values.metrics.jmx.image.pullPolicy | quote }}
  command:
    - java
    - -XX:+UnlockExperimentalVMOptions
    - -XX:+UseCGroupMemoryLimitForHeap
    - -XX:MaxRAMFraction=1
    - -XshowSettings:vm
    - -jar
    - jmx_prometheus_httpserver.jar
    - {{ .Values.metrics.jmx.ports.metrics | quote }}
    - /etc/jmx-tomcat/jmx-tomcat-prometheus.yml  
  ports:
  {{- range $key, $val := .Values.metrics.jmx.ports }}
    - name: {{ $key }}
      containerPort: {{ $val }}
  {{- end }} 
  {{- if .Values.metrics.jmx.resources }}
  resources: {{- toYaml .Values.metrics.jmx.resources | nindent 4 }}
  {{- end }}      	  
{{- end }}
{{- if .Values.metrics.jmx.enabled }}
- name: jmx-config
  configMap:
    name: {{ include "tomcat.metrics.jmx.configmapName" . }}
{{- end }}
{{- if .Values.extraPodSpec }}
{{- include "common.tplvalues.render" (dict "value" .Values.extraPodSpec "context" $) }}
{{- end }}
{{- end -}}

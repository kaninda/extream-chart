{{- define "migrator-config-template" }}

{{- if .Values.enabled }}

{{- $context := include "getFrontEndUrlContextWithLeadingSlash" . }}
{{- $dbNameDictionary := dict "POSTGRES" "postgres" "SQLSERVER" "dbmssql" "ORACLE" "dboracle" }}

{{- $databaseProfileKey := ternary .Values.db.externalDb.dbType .Values.global.exstreamdb.dbType .Values.db.externalDb.enabled }}
{{- $databaseProfile:= index $dbNameDictionary $databaseProfileKey }}
{{- $additionalProfiles := $databaseProfile }}


apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-migrator-config{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
data:


  SERVER_SERVLET_CONTEXT_PATH: "{{$context}}/migrator"

  EXSTREAM_SCHEMA_DEFAULT: {{ required "migrator.db.externalDb.schema required" .Values.db.externalDb.schema }}
  {{- if eq .Values.db.externalDb.dbType "POSTGRES"}}
  SPRING_DATASOURCE_URL: "{{ include "postgresJdbcUrl" (dict "Values" .Values "url" .Values.db.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.db.externalDb.dbType "SQLSERVER"}}
  SPRING_DATASOURCE_URL: "{{ include "sqlServerJdbcUrl" (dict "Values" .Values "url" .Values.db.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.db.externalDb.dbType "ORACLE"}}
  SPRING_DATASOURCE_URL: "{{ include "oracleJdbcUrl" (dict "Values" .Values "url" .Values.db.externalDb.url) }}"
  {{- end }}

  {{- include "getHikariConfiguration" . | nindent 2 }}
  {{- include "databaseConfigMapOptions" .Values.db | nindent 2 }}

  SPRING_PROFILES_ACTIVE: "{{ include "getSpringProfilesActive" (dict "Values" .Values "additionalProfiles" $additionalProfiles) }}"
  {{- if (.Values.async).requestTimeout }}
  SPRING_MVC_ASYNC_REQUEST-TIMEOUT: {{ .Values.async.requestTimeout | quote }}
  {{- end }}
  
  RABBIT_SCHEME: {{ template "exstreamrabbitScheme" . }}
  RABBIT_SERVICE: {{ template "exstreamrabbitHost" . }}
  RABBIT_PORT: {{ template "exstreamrabbitPort" . }}
  {{ if .Values.global.rabbitmq.vhost }}
  RABBIT_VHOST: {{ .Values.global.rabbitmq.vhost }}
  {{ end }}
  {{ if .Values.global.rabbitmq.useQuorumQueues }}
  RABBIT_USEQUORUMQUEUES: "true"
  {{ end }}
  EXSTREAM_MIGRATOR_QUEUE: "{{ include "getRabbitMQMigratorQueueName" . }}"

  OTDS_URL_ROOT_BACKEND: {{ include "OTDS_URL_ROOT_BACKEND" . }}
  EXSTREAM_DAS_BACKEND_URL: {{ include "DAS_URL_ROOT_BACKEND" . }}/api/v1/
  EXSTREAM_EMPOWER_BACKEND_URL: {{ include "EMPOWER_URL_ROOT_BACKEND" . }}/api/v1
  EXSTREAM_ORC_BACKEND_URL: {{ include "ORCH_URL_ROOT_BACKEND" . }}/api/v1/

  {{- include "getEtsConfiguration" . | nindent 2 }}
  {{- include "getOT2ApplicationsConfiguration" . | nindent 2 }}
  {{- include "getVaultEnvVars" (dict "Values" .Values "serviceName" "migrator" "Release" .Release) | nindent 2 }}

# http://masterminds.github.io/sprig/dicts.html#dig
# https://github.com/helm/helm/issues/9266#issue-791870039
  {{- include "configMapJavaLogLevels" . | nindent 2 }}
  {{- include "configMapLoggingConfig" . | nindent 2 }}
# SERVER_TOMCAT_ACCESSLOG_BUFFERED: "false"
# SERVER_TOMCAT_ACCESSLOG_DIRECTORY: "."
# SERVER_TOMCAT_ACCESSLOG_ENABLED: "true"
# SERVER_TOMCAT_ACCESSLOG_PATTERN: "%{yyyy-MM-dd HH:mm:ss.SSSZ}t %a %A '%{User-Agent}i' %r %s %b %D"
# SERVER_TOMCAT_BASEDIR: "logs"

{{- if .Values.allowedOrigins }}
  EXSTREAM_ALLOWED_ORIGINS: "{{.Values.allowedOrigins}}"
{{- end }}
{{- if .Values.contentSecurityPolicy }}
  EXSTREAM_CONTENT_SECURITY_POLICY: {{.Values.contentSecurityPolicy}}
{{- end }}
{{- if .Values.heapFlags }}
  EXSTREAM_HEAP_FLAGS: "{{.Values.heapFlags}}"
{{- end }}
{{- if .Values.db.schema.prefix }}
  EXSTREAM_SCHEMA_PREFIX: {{.Values.db.schema.prefix}}
{{- end }}

{{ if .Values.debugger }}
  EXSTREAM_DEBUG_FLAGS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=9999"
{{ end }}

  EXSTREAM_COOKIE_SAMESITE: "{{ .Values.sameSiteCookie | default "None" }}"
  EXSTREAM_COOKIE_PARTITIONED: "{{ .Values.partitionedCookie | default "true" }}"

  EXSTREAM_SCHEMA_MANAGEMENT_AUTO: "{{ required ".Values.db.schema.autoManage.enabled required" .Values.db.schema.autoManage.enabled }}"

  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  {{- include "newRelicConfigVariables" (dict "Values" .Values "serviceName" "migrator") | nindent 2 }}
  {{- include "getRabbitMQSecurityVariables" . | nindent 2 }}

  {{- include "getHydratedEnvVars" . | nindent 2 }}

{{- end }}

{{- end -}}

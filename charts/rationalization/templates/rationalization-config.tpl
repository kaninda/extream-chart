{{- define "rationalization-config-template" }}

{{- if .Values.global.rationalization }}
{{- if .Values.global.rationalization.enabled}}

{{- $protocol := ternary "https" "http" .Values.global.tls.enabled }}
{{- $dbNameDictionary := dict "POSTGRES" "postgres" "SQLSERVER" "dbmssql" "ORACLE" "dboracle" }}
{{- $databaseProfileKey := ternary .Values.global.rationalizationdb.externalDb.dbType .Values.global.exstreamdb.dbType .Values.global.rationalizationdb.externalDb.enabled }}
{{- $databaseProfile:= index $dbNameDictionary $databaseProfileKey }}
{{- $externalDbSchema := .Values.global.rationalizationdb.externalDb.schema }}
{{- $exstreamOtdsUrl := include "OTDS_URL_ROOT_BACKEND" . }}
{{- $rationalizationFrontendUrl := include "getRationalizationFrontEndUrl" . }}
{{- $rationalizationBackendUrl := include "RATIONALIZATION_URL_ROOT_BACKEND" .}}
{{- $context := include "getFrontEndUrlContextWithLeadingSlash" . }}

apiVersion: v1
kind: ConfigMap
metadata:
  name:  {{ .Release.Name }}-rationalization-config{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
data:
  SERVER_SERVLET_CONTEXT_PATH: "{{$context}}/rationalizationApi"
  {{- include "databaseConfigMapOptions" .Values.global.rationalizationdb | nindent 2 }}
  {{- include "getHikariConfiguration" . | nindent 2 }}

{{- if .Values.heapFlags }}
  EXSTREAM_HEAP_FLAGS: "{{.Values.heapFlags}}"
{{- end }}
  EXSTREAM_SCHEMA_DEFAULT: {{ $externalDbSchema }}
  {{- if eq .Values.global.rationalizationdb.externalDb.dbType "POSTGRES"}}
  SPRING_DATASOURCE_URL: "{{ include "postgresJdbcUrl" (dict "Values" .Values "url" .Values.global.rationalizationdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.rationalizationdb.externalDb.dbType "SQLSERVER"}}
  SPRING_DATASOURCE_URL: "{{ include "sqlServerJdbcUrl" (dict "Values" .Values "url" .Values.global.rationalizationdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.rationalizationdb.externalDb.dbType "ORACLE"}}
  SPRING_DATASOURCE_URL: "{{ include "oracleJdbcUrl" (dict "Values" .Values "url" .Values.global.rationalizationdb.externalDb.url) }}"
  {{- end }}
  {{- if .Values.global.otds.enabled }}
  SPRING_PROFILES_ACTIVE: newWorldOTDSAuth,k8s,{{$databaseProfile}}
  {{- else }}
  SPRING_PROFILES_ACTIVE: noauth,k8s,{{$databaseProfile}}
  {{- end }}
  SPRING_RABBITMQ_SCHEME: {{ template "exstreamrabbitScheme" . }}
  SPRING_RABBITMQ_HOST: {{ template "exstreamrabbitHost" . }}
  SPRING_RABBITMQ_PORT: {{ template "exstreamrabbitPort" . }}
  {{ if .Values.global.rabbitmq.vhost }}
  SPRING_RABBITMQ_VIRTUALHOST: {{ .Values.global.rabbitmq.vhost }}
  {{ end }}
  {{ if .Values.global.rabbitmq.useQuorumQueues }}
  SPRING_RABBITMQ_USEQUORUMQUEUES: "true"
  {{ end }}
  SERVER_PORT: "8051"
  EXSTREAM_RAT_RABBITMQ_QUEUE_NAME: "{{ include "getRabbitMQRatReportGenQueueName" . }}"
  EXSTREAM_RAT_RABBITMQ_EXCHANGE_NAME: "{{ include "getRabbitMQRatReportGenQueueName" . }}"
  EXSTREAM_RAT_RABBITMQ_ROUTING_KEY: "{{ include "getRabbitMQRatReportGenQueueName" . }}"
  OTDS_URL_ROOT_BACKEND: {{ include "OTDS_URL_ROOT_BACKEND" . | quote }}
  {{- include "getEtsConfiguration" . | nindent 2 }}
  {{- include "getOT2ApplicationsConfiguration" . | nindent 2 }}
  {{- include "sharedStorageUmaskEnv" . | nindent 2 }}
  {{- include "getVaultEnvVars" (dict "Values" .Values "serviceName" "rationalization" "Release" .Release) | nindent 2 }}
  {{- include "newRelicConfigVariables" (dict "Values" .Values "serviceName" "rationalization") | nindent 2 }}
  KUBERNETES_NAMESPACE: {{ include "namespaceValue" . }}
  APP_EXTRACT-PATH: "/tmp"
  DAS_URL_ROOT_BACKEND: {{include "DAS_URL_ROOT_BACKEND" .}}/api/v1/
  EXSTREAM_RAT_OTDS_URL: "{{ $exstreamOtdsUrl }}/otdsws/oauth2/token"
  EXSTREAM_URL_FRONTEND_RATIONALIZATION_URL: "{{ $rationalizationFrontendUrl }}"
  EXSTREAM_RAT_API_URL: "{{ $rationalizationBackendUrl }}/api/v1/internal/jobs/{tenant}/{domain}"
{{- if .Values.allowedOrigins }}
  EXSTREAM_ALLOWED_ORIGINS: "{{.Values.allowedOrigins}}"
{{- end }}
{{- if .Values.global.rationalizationdb.schema.prefix }}
  EXSTREAM_SCHEMA_PREFIX: {{.Values.global.rationalizationdb.schema.prefix}}
{{- end }}
  EXSTREAM_SCHEMA_MANAGEMENT_AUTO: "{{ required ".Values.global.rationalizationdb.schema.autoManage.enabled required" .Values.global.rationalizationdb.schema.autoManage.enabled }}"
  {{- include "trustStoreConfigVariables" . | nindent 2 }}
{{- if .Values.debugger }}
  EXSTREAM_RAT_DEBUG_FLAGS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=9999"
{{- end }}
  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  {{- include "configMapJavaLogLevels" . | nindent 2 }}
  {{- include "configMapLoggingConfig" . | nindent 2 }}
  {{- include "getRabbitMQSecurityVariables" . | nindent 2 }}

  {{- include "getHydratedEnvVars" . | nindent 2 }}

{{- end }}
{{- end }}

{{- end -}}

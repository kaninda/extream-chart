{{- define "eep-config-template" }}

{{- if or .Values.global.assuredDelivery.enabled .Values.global.ei.enabled .Values.global.eep.enabled}}

{{- $configAPIInternalUrl := printf "%s/api/v1/config" (include "EI_URL_ROOT_BACKEND" .)  }}
{{- $dbNameDictionary := dict "POSTGRES" "postgres" "SQLSERVER" "dbmssql" "ORACLE" "dboracle" }}
{{- $externalDbSchema := .Values.global.eepdb.externalDb.schema }}
{{- $databaseProfileKey := ternary .Values.global.eepdb.externalDb.dbType .Values.global.exstreamdb.dbType .Values.global.eepdb.externalDb.enabled }}
{{- $databaseProfile:= index $dbNameDictionary $databaseProfileKey }}
{{- $exstreamOrcInternalUrl := include "ORC_URL_ROOT_BACKEND_INTERNAL" . }}
{{- $exstreamUrlFrontEndEEPUrl := include "getEEPFrontEndUrl" . }}
{{- $context := include "getFrontEndUrlContextWithLeadingSlash" . }}

apiVersion: v1
kind: ConfigMap
metadata:
  name:  {{ .Release.Name }}-eep-config{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
data:
  SERVER_SERVLET_CONTEXT_PATH: "{{$context}}/eep"
  {{- include "databaseConfigMapOptions" .Values.global.eepdb | nindent 2 }}
  {{- include "getHikariConfiguration" . | nindent 2 }}
  EXSTREAM_SCHEMA_DEFAULT: {{ $externalDbSchema }}
  {{- if eq .Values.global.eepdb.externalDb.dbType "POSTGRES"}}
  SPRING_DATASOURCE_URL: "{{ include "postgresJdbcUrl" (dict "Values" .Values "url" .Values.global.eepdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.eepdb.externalDb.dbType "SQLSERVER"}}
  SPRING_DATASOURCE_URL: "{{ include "sqlServerJdbcUrl" (dict "Values" .Values "url" .Values.global.eepdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.eepdb.externalDb.dbType "ORACLE"}}
  SPRING_DATASOURCE_URL: "{{ include "oracleJdbcUrl" (dict "Values" .Values "url" .Values.global.eepdb.externalDb.url) }}"
  {{- end }}
  {{- if .Values.global.otds.enabled }}
  SPRING_PROFILES_ACTIVE: newWorldOTDSAuth,k8s,{{$databaseProfile}}
  {{- else }}
  SPRING_PROFILES_ACTIVE: noauth,k8s,{{$databaseProfile}}
  {{- end }}
  OTDS_URL_ROOT_BACKEND: {{ include "OTDS_URL_ROOT_BACKEND" . }}
  {{- include "getEtsConfiguration" . | nindent 2 }}
  {{- include "getOT2ApplicationsConfiguration" . | nindent 2 }}
  {{- include "sharedStorageUmaskEnv" . | nindent 2 }}
{{- if .Values.heapFlags }}
  EXSTREAM_HEAP_FLAGS: "{{.Values.heapFlags}}"
{{- end }}
  {{- if .Values.global.eepdb.schema.prefix }}
  EXSTREAM_SCHEMA_PREFIX: {{.Values.global.eepdb.schema.prefix}}
  {{- end }}
  EXSTREAM_SCHEMA_MANAGEMENT_AUTO: "{{ required ".Values.global.eepdb.schema.autoManage.enabled required" .Values.global.eepdb.schema.autoManage.enabled }}"
  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  {{- include "configMapJavaLogLevels" . | nindent 2 }}
  {{- include "configMapLoggingConfig" . | nindent 2 }}
  {{- include "newRelicConfigVariables" (dict "Values" .Values "serviceName" "eep") | nindent 2 }}
  EXSTREAM_STORAGE_SHARED: {{ .Values.global.storage.shared.type }}
  EEP_RABBITMQ_EXCHANGE_NAME: "{{ include "getCiEventsQueueName" . }}"
  EEP_RABBITMQ_QUEUE_NAME: "{{ include "getEmailEventPullerQueueName" . }}"
  EEP_RABBITMQ_ROUTING_KEY: "{{ include "getEmailEventPullerQueueName" . }}"
  EEP_INTERNAL_RABBITMQ_EXCHANGE_NAME: "{{ include "getEmailEventPullerInternalQueue" . }}"
  EEP_INTERNAL_RABBITMQ_QUEUE_NAME: "{{ include "getEmailEventPullerInternalQueue" . }}"
  EEP_INTERNAL_RABBITMQ_ROUTING_KEY: "{{ include "getEmailEventPullerInternalQueue" . }}"
  CXI_RABBITMQ_EXCHANGE_NAME: "{{ include "getCxiExternalEventsQueueName" . }}"
  CXI_RABBITMQ_QUEUE_NAME: "{{ include "getCxiExternalEventsQueueName" . }}"
  CXI_RABBITMQ_ROUTING_KEY: "{{ include "getCxiExternalEventsQueueName" . }}"
  SPRING_RABBITMQ_SCHEME: {{ template "exstreamrabbitScheme" . }}
  SPRING_RABBITMQ_HOST: {{ template "exstreamrabbitHost" . }}
  SPRING_RABBITMQ_PORT: {{ template "exstreamrabbitPort" . }}
  {{ if .Values.global.rabbitmq.vhost }}
  SPRING_RABBITMQ_VIRTUALHOST: {{ .Values.global.rabbitmq.vhost }}
  {{ end }}
  {{ if .Values.global.rabbitmq.useQuorumQueues }}
  SPRING_RABBITMQ_USEQUORUMQUEUES: "true"
  {{ end }}
  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  {{- include "getRabbitMQSecurityVariables" . | nindent 2 }}
  {{- if .Values.debugger }}
  EXSTREAM_EEP_DEBUG_FLAGS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=10002"
  {{- end }}
  {{- if .Values.global.storage.shared.type }}
  {{- if eq .Values.global.storage.shared.type "s3" }}
  EEP_REPORT-PATH: "/tmp"
  {{- else }}
  EEP_REPORT-PATH: "/mnt/nfs"
  {{- end }}
  {{- end }}
  {{- if .Values.global.ei.enabled }}
  EXSTREAM_CXI_CONFIG_URL_COVISINT: "{{ $configAPIInternalUrl }}/{tenantId}/{domain}/covisint"
  {{- end }}
  EXSTREAM_ORC_URL_FLOWMODEL: "{{ $exstreamOrcInternalUrl }}/internal/v1/flow-model-contexts/all?ignoreDomain=true&tenantId="
  EXSTREAM_ORC_URL_INTERNAL: "{{ $exstreamOrcInternalUrl }}/internal/v1/secrets/{domain}/{secret}?tenantId="
  EXSTREAM_ORC_CONFIG_ORC_URL: "{{ $exstreamOrcInternalUrl }}"
  EXSTREAM_URL_FRONTEND_EEP_URL: "{{ $exstreamUrlFrontEndEEPUrl }}"
  EXSTREAM_ORC_QUEUE_EXTERNALEVENT: "{{ include "getRabbitMQOrcExternalEventQueueName" . }}"
  EXSTREAM_ASSURED_DELIVERY_ENABLED: "{{.Values.global.assuredDelivery.enabled}}"
  EEP_CONSOLIDATION_TIMEOUT: "{{ or .Values.global.assuredDelivery.consolidation.timeout .Values.consolidation.timeout }}"
  EEP_CONSOLIDATION_INTERVAL: "{{ or .Values.global.assuredDelivery.consolidation.interval .Values.consolidation.interval }}"
  {{- include "getVaultEnvVars" (dict "Values" .Values "serviceName" "eep" "Release" .Release) | nindent 2 }}

  {{- include "getHydratedEnvVars" . | nindent 2 }}

{{- end}}

{{- end -}}

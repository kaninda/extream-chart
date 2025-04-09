{{- define "ei-config-api-template" }}

{{- if .Values.global.ei.enabled }}

{{- $configAPIInternalUrl := printf "%s/api/v1/internal" (include "EI_INTERNAL_URL_ROOT_BACKEND" .)  }}
{{- $dbNameDictionary := dict "POSTGRES" "postgres" "SQLSERVER" "dbmssql" "ORACLE" "dboracle" }}
{{- $databaseProfileKey := ternary .Values.global.eidb.externalDb.dbType .Values.global.exstreamdb.dbType .Values.global.eidb.externalDb.enabled }}
{{- $databaseProfile:= index $dbNameDictionary $databaseProfileKey }}
{{- $externalDbSchema := .Values.global.eidb.externalDb.schema }}
{{- $exstreamEIOrcQueue := printf "%s" (include "getRabbitMQOrcEIQueueName" .) -}}
{{- $exstreamCmeCxiQueue := printf "%s" (include "getCxiExternalEventsQueueName" .) -}}
{{- $exstreamOtdsUrl := include "OTDS_URL_ROOT_BACKEND" . }}
{{- $exstreamOrchestrationUrl := include "ORCH_URL_ROOT_BACKEND" . }}
{{- $exstreamUrlFrontEndEIUrl := include "getEIFrontEndUrl" . }}
{{- $context := include "getFrontEndUrlContextWithLeadingSlash" . }}

---
# config-api
apiVersion: v1
kind: ConfigMap
metadata:
  name:  {{ .Release.Name }}-ei-config-api-config{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
data:
  SERVER_SERVLET_CONTEXT_PATH: "{{$context}}/ei"
  EXSTREAM_CXI_MODULE: "config-api"
  {{- include "databaseConfigMapOptions" .Values.global.eidb | nindent 2 }}
  {{- include "getHikariConfiguration" . | nindent 2 }}
  EXSTREAM_SCHEMA_DEFAULT: {{ $externalDbSchema }}
  {{- if eq .Values.global.eidb.externalDb.dbType "POSTGRES"}}
  SPRING_DATASOURCE_URL: "{{ include "postgresJdbcUrl" (dict "Values" .Values "url" .Values.global.eidb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.eidb.externalDb.dbType "SQLSERVER"}}
  SPRING_DATASOURCE_URL: "{{ include "sqlServerJdbcUrl" (dict "Values" .Values "url" .Values.global.eidb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.eidb.externalDb.dbType "ORACLE"}}
  SPRING_DATASOURCE_URL: "{{ include "oracleJdbcUrl" (dict "Values" .Values "url" .Values.global.eidb.externalDb.url) }}"
  {{- end }}
  {{- if .Values.global.otds.enabled }}
  SPRING_PROFILES_ACTIVE: newWorldOTDSAuth,k8s,{{$databaseProfile}}
  {{- else }}
  SPRING_PROFILES_ACTIVE: noauth,k8s,{{$databaseProfile}}
  {{- end }}
  SERVER_PORT: "8041"
  OTDS_URL_ROOT_BACKEND: {{ include "OTDS_URL_ROOT_BACKEND" . }}
  {{- include "getEtsConfiguration" . | nindent 2 }}
  {{- include "getOT2ApplicationsConfiguration" . | nindent 2 }}
  {{- include "getVaultEnvVars" (dict "Values" .Values "serviceName" "ei" "Release" .Release) | nindent 2 }}
  KUBERNETES_NAMESPACE: {{ include "namespaceValue" . }}
  EXSTREAM_URL_FRONTEND_EI_URL: {{ $exstreamUrlFrontEndEIUrl }}
  {{- if .Values.allowedOrigins }}
  EXSTREAM_ALLOWED_ORIGINS: "{{.Values.allowedOrigins}}"
  {{- end }}
  {{- if .Values.contentSecurityPolicy }}
  EXSTREAM_CONTENT_SECURITY_POLICY: {{.Values.contentSecurityPolicy}}
  {{- end }}
  {{- if .Values.debugger }}
  EXSTREAM_EI_DEBUG_FLAGS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=9999"
  {{- end }}
{{- if .Values.heapFlags }}
  EXSTREAM_HEAP_FLAGS: "{{.Values.heapFlags}}"
{{- end }}
  {{- if .Values.global.eidb.schema.prefix }}
  EXSTREAM_SCHEMA_PREFIX: {{.Values.global.eidb.schema.prefix}}
  {{- end }}
  EXSTREAM_SCHEMA_MANAGEMENT_AUTO: "{{ required ".Values.global.eidb.schema.autoManage.enabled required" .Values.global.eidb.schema.autoManage.enabled }}"
  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  {{- include "configMapJavaLogLevels" . | nindent 2 }}
  {{- include "configMapLoggingConfig" . | nindent 2 }}
  SPRING_INTERNALPORT: "{{ .Values.config.api.svc.internalport }}"
  SPRING_INTERNALPROTOCOL: "{{ .Values.config.api.svc.internalProtocol }}"

  {{- include "getHydratedEnvVars" . | nindent 2 }}

{{- end}}

{{- end -}}

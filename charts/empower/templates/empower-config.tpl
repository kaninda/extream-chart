{{- define "empower-config-template" }}

{{- if .Values.global.empower.enabled }}

{{- $exstreamUrlFrontEndIngressUrl := include "getExstreamFrontEndIngressUrl" . -}}
{{- $exstreamUrlFrontEndEmpowerUrl := include "getEmpowerFrontEndUrl" . }}
{{- $exstreamUrlFrontEndDasUrl := include "getDasFrontEndUrl" . }}
{{- $otdsUrlRootFrontEnd := include "getOtdsFrontEndUrl" . }}
{{- $otdsAdmUrlRootFrontEnd := include "getOtdsAdmFrontEndUrl" . }}
{{- $context := include "getFrontEndUrlContext" . }}

{{- $postgresDbPlatform := "POSTGRES" }}
{{- $postgresDriver := "org.postgresql.Driver" }}
{{- $mssqlDbPlatform := "SQLSERVER" }}
{{- $mssqlDriver := "com.microsoft.sqlserver.jdbc.SQLServerDriver" }}
{{- $oracleDbPlatform := "ORACLE" }}
{{- $oracleDriver := "oracle.jdbc.OracleDriver" }}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-empower-config{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
data:

  INGRESSCONTEXT: "{{ $context }}"

{{- if and .Values.global.ot2 .Values.global.ot2.enabled }}
  SPRING_PROFILES_ACTIVE: "{{ include "getSpringProfilesActive" (dict "Values" .Values "additionalProfiles" "cloud,kube") }}"
{{- else }}
  SPRING_PROFILES_ACTIVE: "{{ include "getSpringProfilesActive" (dict "Values" .Values "additionalProfiles" "cloud,kube,cloudedition_otds") }}"
{{- end }}

  EXSTREAM_ONDEMAND_BACKEND: {{ include "ONDEMAND_URL_ROOT_BACKEND" . }}
  EXSTREAM_DAS_BACKEND: {{ include "DAS_URL_ROOT_BACKEND" . }}
  EXSTREAM_URL_FRONTEND_EMPOWER_URL: {{ $exstreamUrlFrontEndEmpowerUrl }}
  EXSTREAM_URL_FRONTEND_DAS_URL: {{ $exstreamUrlFrontEndDasUrl }}
{{- if .Values.global.empower.enabled }}
  EXSTREAM_URL_SERVICE_PATH_EMPOWER: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "empower") }}
{{- else }}
  EXSTREAM_URL_SERVICE_PATH_EMPOWER: ""
{{- end }}	  
  OTDS_URL_ROOT_FRONTEND: {{ $otdsUrlRootFrontEnd }}
{{- if .Values.global.ot2.enabled }}
  OTDS_ADM_URL_ROOT_FRONTEND: {{ $otdsAdmUrlRootFrontEnd }}
{{- end }}
{{- include "getEtsConfiguration" . | nindent 2 }}
{{- include "getOT2ApplicationsConfiguration" . | nindent 2 }}
{{- if .Values.global.tls.enabled }}
  TLS_ENABLED: "true"
{{- else }}
  TLS_ENABLED: "false"
{{- end }}
  OTDS_URL_ROOT_BACKEND: {{ include "OTDS_URL_ROOT_BACKEND" . }}
{{- if .Values.global.ot2.enabled }}
  OTDS_API_URL_ROOT_BACKEND: {{ include "OTDS_API_URL_ROOT_BACKEND" . }}
  OTDS_URL_API: ""
{{- end }}


{{- if and .Values.global.ot2 .Values.global.ot2.enabled }}
  EMPOWER_ADMIN_AUTHORITY: empower_administrator
  EMPOWER_INTEGRATOR_AUTHORITY: empower_integrator
  EMPOWER_EDITOR_AUTHORITY: empower_editor
  EMPOWER_TENANT_ADMIN_AUTHORITY: tenant_admin
{{- else }}
  EMPOWER_ADMIN_AUTHORITY: empoweradmins
  EMPOWER_INTEGRATOR_AUTHORITY: empowerintegrators
  EMPOWER_EDITOR_AUTHORITY: empowereditors
  EMPOWER_TENANT_ADMIN_AUTHORITY: tenantadmins
{{- end }}
  
  EMPOWER_LOG_LEVEL: INFO
  SPRING_LOG_LEVEL: INFO
  SPRING_SECURITY_LOG_LEVEL: INFO
  HIBERNATE_LOG_LEVEL: INFO
  LIQUIBASE_LOG_LEVEL: INFO
  HIKARI_LOG_LEVEL: INFO

{{- include "getHikariConfiguration" . | nindent 2 }}

  SPRING_ZIPKIN_ENABLED: "{{ .Values.spring.zipkinEnabled }}"
  SPRING_ZIPKIN_BASEURL: "{{ .Values.spring.zipkinBaseUrl }}"
  SPRING_SLEUTH_SAMPLER_PROBABILITY: "{{ .Values.spring.sleuthSamplerProbability }}"

  SCHEMA_PREFIX: {{ default "\"\"" .Values.global.empowerdb.schema.prefix }}
{{- if .Values.global.empowerdb.vault }}
  {{- if .Values.global.empowerdb.vault.enginerolepath }}
  {{- if .Values.global.empowerdb.vault.enginerolepath.system }}
  EXSTREAM_VAULT_ENGINEROLEPATH_SYSTEM: "{{.Values.global.empowerdb.vault.enginerolepath.system}}"
  {{- end }}
  {{- end }}
  {{- if .Values.global.empowerdb.vault.enginerolepath }}
  {{- if .Values.global.empowerdb.vault.enginerolepath.schema }}
  EXSTREAM_VAULT_ENGINEROLEPATH_SCHEMA: "{{.Values.global.empowerdb.vault.enginerolepath.schema}}"
  {{- end }}
  {{- end }}
  {{- if .Values.global.empowerdb.vault.enginerolepath }}
  {{- if .Values.global.empowerdb.vault.enginerolepath.shared }}
  EXSTREAM_VAULT_ENGINEROLEPATH_SHARED: "{{.Values.global.empowerdb.vault.enginerolepath.shared}}"
  {{- end }}
  {{- end }}
{{- end }}

{{- if eq .Values.global.empowerdb.externalDb.dbType "POSTGRES" }}
  DB_PLATFORM: {{ $postgresDbPlatform }}
  JDBC_DRIVER: "{{ $postgresDriver }}"
  JDBC_URL: "{{ include "postgresJdbcUrl" (dict "Values" .Values "url" .Values.global.empowerdb.externalDb.url) }}"
{{- else if eq .Values.global.empowerdb.externalDb.dbType "SQLSERVER" }}
  DB_PLATFORM: {{ $mssqlDbPlatform }}
  JDBC_DRIVER: "{{ $mssqlDriver }}"
  JDBC_URL: "{{ include "sqlServerJdbcUrl" (dict "Values" .Values "url" .Values.global.empowerdb.externalDb.url) }}"
{{- else if eq .Values.global.empowerdb.externalDb.dbType "ORACLE" }}
  DB_PLATFORM: {{ $oracleDbPlatform }}
  JDBC_DRIVER: "{{ $oracleDriver }}"
  JDBC_URL: "{{ include "oracleJdbcUrl" (dict "Values" .Values "url" .Values.global.empowerdb.externalDb.url) }}"
{{- end }}

{{- include "databaseConfigMapOptions" .Values.global.empowerdb | nindent 2 }}

{{- if .Values.allowedOrigins }}
  EXSTREAM_ALLOWED_ORIGINS: "{{.Values.allowedOrigins}}"
{{- end }}

  EXSTREAM_COOKIE_SAMESITE: "{{ .Values.sameSiteCookie }}"
  EXSTREAM_COOKIE_PARTITIONED: "{{ .Values.partitionedCookie }}"
  
{{- if .Values.heapFlags }}
  EXSTREAM_HEAP_FLAGS: "{{.Values.heapFlags}}"
{{- end }}

  EXSTREAM_SCHEMA_MANAGEMENT_AUTO: "{{ required ".Values.global.empowerdb.schema.autoManage.enabled required" .Values.global.empowerdb.schema.autoManage.enabled }}"
  
  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  
  EMPOWER_FORWARDED_HEADERS: "true"
  
  EXSTREAM_AUDIT_ENABLED: "{{ .Values.audit.enabled }}"

{{- if .Values.global.empowerdb.externalDb.enabled }}
  SHARED_SCHEMA: {{ .Values.global.empowerdb.schema.shared.name | quote }}
  SYSTEM_SCHEMA: {{ .Values.global.empowerdb.schema.system.name | quote }}
{{- else }}
  SHARED_SCHEMA: "exe_shared"
  SYSTEM_SCHEMA: "exe_system"
{{- end }}

  {{- include "getVaultEnvVars" (dict "Values" .Values "serviceName" "empower" "Release" .Release) | nindent 2 }}


{{ if .Values.debugger }}
  EXSTREAM_EMPOWER_DEBUG_FLAGS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=9999"
{{ end }}

  {{- include "configMapLoggingConfig" . | nindent 2 }}
  {{- include "newRelicConfigVariables" (dict "Values" .Values "serviceName" "empower") | nindent 2 }}

  {{- include "getHydratedEnvVars" . | nindent 2 }}

{{- end }}
{{- end -}}


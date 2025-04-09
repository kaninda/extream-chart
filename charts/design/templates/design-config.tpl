{{- define "design-config-template" }}

{{- if .Values.global.design.enabled }}

{{- $context := include "getFrontEndUrlContextWithLeadingSlash" . }}
{{- $exstreamUrlFrontEndOnDemandUrl := include "getOndemandFrontEndUrl" . }}
{{- $otdsUrlRootFrontEnd := include "getOtdsFrontEndUrl" . }}
{{- $otdsAdmUrlRootFrontEnd := include "getOtdsAdmFrontEndUrl" . }}
{{- $exstreamUrlFrontEndDasUrl := include "getDasFrontEndUrl" . }}
{{- $exstreamUrlFrontEndOrcUrl := include "getOrchestrationFrontEndUrl" . }}
{{- $exstreamUrlFrontEndEIUrl := include "getEIFrontEndUrl" . }}
{{- $exstreamUrlFrontEndEEPUrl := include "getEEPFrontEndUrl" . }}
{{- $exstreamUrlFrontEndOrchestratorUrl := include "getOrchestratorFrontEndUrl" . }}
{{- $exstreamUrlFrontEndRationalizationUrl := include "getRationalizationFrontEndUrl" . }}
{{- $exstreamUrlFrontEndEmpowerUrl := include "getEmpowerFrontEndUrl" . }}
{{- $dbNameDictionary := dict "POSTGRES" "postgres" "SQLSERVER" "dbmssql" "ORACLE" "dboracle" }}

{{- $databaseProfileKey := ternary .Values.global.dasdb.externalDb.dbType .Values.global.exstreamdb.dbType .Values.global.dasdb.externalDb.enabled }}
{{- $databaseProfile:= index $dbNameDictionary $databaseProfileKey }}
{{- $additionalProfiles := $databaseProfile }}
{{- if .Values.global.ot2 -}}
  {{- if .Values.global.ot2.enabled -}}
    {{- $additionalProfiles = printf "%s,ot2TenantEvents" $additionalProfiles -}}
  {{- end -}}
{{- end -}}
{{- $externalDbSchema := .Values.global.dasdb.externalDb.schema }}


apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-design-config{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
data:


  SERVER_SERVLET_CONTEXT_PATH: "{{$context}}/design"

  EXSTREAM_SCHEMA_DEFAULT: {{ $externalDbSchema }}
  {{- if eq .Values.global.dasdb.externalDb.dbType "POSTGRES"}}
  SPRING_DATASOURCE_URL: "{{ include "postgresJdbcUrl" (dict "Values" .Values "url" .Values.global.dasdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.dasdb.externalDb.dbType "SQLSERVER"}}
  SPRING_DATASOURCE_URL: "{{ include "sqlServerJdbcUrl" (dict "Values" .Values "url" .Values.global.dasdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.dasdb.externalDb.dbType "ORACLE"}}
  SPRING_DATASOURCE_URL: "{{ include "oracleJdbcUrl" (dict "Values" .Values "url" .Values.global.dasdb.externalDb.url) }}"
  {{- end }}

  {{- include "getHikariConfiguration" . | nindent 2 }}
  {{- include "databaseConfigMapOptions" .Values.global.dasdb | nindent 2 }}

  SPRING_PROFILES_ACTIVE: "{{ include "getSpringProfilesActive" (dict "Values" .Values "additionalProfiles" $additionalProfiles) }}"
  {{- if (.Values.async).requestTimeout }}
  SPRING_MVC_ASYNC_REQUEST-TIMEOUT: {{ .Values.async.requestTimeout | quote }}
  {{- end }}
  EXSTREAM_URL_FRONTEND_DAS_URL: {{ $exstreamUrlFrontEndDasUrl }}
  EXSTREAM_URL_FRONTEND_ORC_URL: {{ $exstreamUrlFrontEndOrcUrl }}
  {{- if .Values.global.ei.enabled }}
  EXSTREAM_URL_FRONTEND_EI_URL: {{ $exstreamUrlFrontEndEIUrl }}
  {{- else }}
  EXSTREAM_URL_FRONTEND_EI_URL: ""
  {{- end }}
  {{- if or .Values.global.assuredDelivery.enabled .Values.global.ei.enabled .Values.global.eep.enabled}}
  EXSTREAM_URL_FRONTEND_EEP_URL: {{ $exstreamUrlFrontEndEEPUrl }}
  {{- else }}
  EXSTREAM_URL_FRONTEND_EEP_URL: ""
  {{- end }}
  
  EXSTREAM_STORAGE_SHARED: {{ .Values.global.storage.shared.type }}
  
  RABBIT_SCHEME: {{ template "exstreamrabbitScheme" . }}
  RABBIT_SERVICE: {{ template "exstreamrabbitHost" . }}
  RABBIT_PORT: {{ template "exstreamrabbitPort" . }}
  {{ if .Values.global.rabbitmq.vhost }}
  RABBIT_VHOST: {{ .Values.global.rabbitmq.vhost }}
  {{ end }}
  {{ if .Values.global.rabbitmq.useQuorumQueues }}
  RABBIT_USEQUORUMQUEUES: "true"
  {{ end }}

  EXSTREAM_URL_FRONTEND_ORCHESTRATOR_URL: {{ $exstreamUrlFrontEndOrchestratorUrl }}
  EXSTREAM_URL_FRONTEND_ONDEMAND_URL: {{ $exstreamUrlFrontEndOnDemandUrl }}
  EXSTREAM_URL_BACKEND_ONDEMAND_URL: {{ include "ONDEMAND_URL_ROOT_BACKEND" . }}
  {{- if .Values.global.rationalization }}
  {{- if .Values.global.rationalization.enabled }}
  EXSTREAM_URL_FRONTEND_RATIONALIZATION_URL: {{ $exstreamUrlFrontEndRationalizationUrl }}
  {{- else }}
  EXSTREAM_URL_FRONTEND_RATIONALIZATION_URL: ""
  {{- end }}
  {{- end }}
  {{- if .Values.global.empower.enabled }}
  EXSTREAM_URL_FRONTEND_EMPOWER_URL: {{ $exstreamUrlFrontEndEmpowerUrl }}
  {{- else }}
  EXSTREAM_URL_FRONTEND_EMPOWER_URL: ""
  {{- end }}
  EXSTREAM_URL_SERVICE_PATH_DESIGN: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "design") }}
  EXSTREAM_URL_SERVICE_PATH_EEP: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "eep") }}
  EXSTREAM_URL_SERVICE_PATH_EI: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "ei") }}
  {{- if .Values.global.empower.enabled }}
  EXSTREAM_URL_SERVICE_PATH_EMPOWER: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "empower") }}
  {{- else }}
  EXSTREAM_URL_SERVICE_PATH_EMPOWER: ""
  {{- end }}	
  EXSTREAM_URL_SERVICE_PATH_ONDEMAND: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "ondemand") }}
  EXSTREAM_URL_SERVICE_PATH_ORCHESTRATION: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "orchestration") }}
  EXSTREAM_URL_SERVICE_PATH_ORCHESTRATOR: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "design/orchestrator") }}
  {{- if .Values.global.rationalization }}
  {{- if .Values.global.rationalization.enabled }}  
  EXSTREAM_URL_SERVICE_PATH_RATIONALIZATION: {{ include "getFrontEndServicePath" (dict "values" . "serviceName" "rationalizationApi") }}
  {{- else }}
  EXSTREAM_URL_SERVICE_PATH_RATIONALIZATION: ""
  {{- end }}
  {{- end }}
  
  OTDS_URL_ROOT_FRONTEND: {{ $otdsUrlRootFrontEnd }}
{{- if .Values.global.ot2.enabled }}
  OTDS_ADM_URL_ROOT_FRONTEND: {{ $otdsAdmUrlRootFrontEnd }}
{{- end }}
  OTDS_URL_ROOT_BACKEND: {{ include "OTDS_URL_ROOT_BACKEND" . }}
  {{- include "getEtsConfiguration" . | nindent 2 }}
  {{- include "getOT2EventsConfiguration" . | nindent 2 }}
  {{- include "getOT2ApplicationsConfiguration" . | nindent 2 }}
  {{- include "getOT2EtsEventCallbacks" . | nindent 2 }}
  {{- include "getVaultEnvVars" (dict "Values" .Values "serviceName" "design" "Release" .Release) | nindent 2 }}

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
{{- if .Values.global.dasdb.schema.prefix }}
  EXSTREAM_SCHEMA_PREFIX: {{.Values.global.dasdb.schema.prefix}}
{{- end }}
{{- if .Values.global.dasdb.vault }}
  {{- if .Values.global.dasdb.vault.enginerolepath }}
  {{- if .Values.global.dasdb.vault.enginerolepath.system }}
  EXSTREAM_VAULT_ENGINEROLEPATH_SYSTEM: "{{.Values.global.dasdb.vault.enginerolepath.system}}"
  {{- end }}
  {{- end }}
  {{- if .Values.global.dasdb.vault.enginerolepath }}
  {{- if .Values.global.dasdb.vault.enginerolepath.schema }}
  EXSTREAM_VAULT_ENGINEROLEPATH_SCHEMA: "{{.Values.global.dasdb.vault.enginerolepath.schema}}"
  {{- end }}
  {{- end }}
{{- end }}

{{ if .Values.debugger }}
  EXSTREAM_DAS_DEBUG_FLAGS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=9999"
{{ end }}

  EXSTREAM_COOKIE_SAMESITE: "{{ .Values.sameSiteCookie }}"
  EXSTREAM_COOKIE_PARTITIONED: "{{ .Values.partitionedCookie }}"

  EXSTREAM_SCHEMA_MANAGEMENT_AUTO: "{{ required ".Values.global.dasdb.schema.autoManage.enabled required" .Values.global.dasdb.schema.autoManage.enabled }}"

  RABBITMQ_SOLR_QUEUE: "{{ include "getRabbitMQSolrQueueName" . }}"
  RABBITMQ_IMPORT_QUEUE: "{{ include "getRabbitMQImportQueueName" . }}"
{{- if .Values.global.ot2.enabled }}
  RABBITMQ_OT2_TENANT_EVENTS_QUEUE: "{{ include "getRabbitMQOT2EventsQueueName" . }}"
{{- end }}

  TERMINATION_SERVER_DELAY_MILLIS: "{{ .Values.termination.server.delay.millis }}"

  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  {{- include "newRelicConfigVariables" (dict "Values" .Values "serviceName" "design") | nindent 2 }}
  {{- include "getRabbitMQSecurityVariables" . | nindent 2 }}

  {{- include "getHydratedEnvVars" . | nindent 2 }}

{{- end }}

{{- end -}}

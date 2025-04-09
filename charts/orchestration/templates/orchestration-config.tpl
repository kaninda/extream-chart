{{- define "orchestration-config-template" }}

{{- if .Values.global.orchestration.enabled }}

{{- $exstreamUrlFrontEndOrcUrl := include "getOrchestrationFrontEndUrl" . }}
{{- $context := include "getFrontEndUrlContextWithLeadingSlash" . }}
{{- $dbNameDictionary := dict "POSTGRES" "postgres" "SQLSERVER" "dbmssql" "ORACLE" "dboracle" }}

{{- $databaseProfileKey := ternary .Values.global.orcdb.externalDb.dbType .Values.global.exstreamdb.dbType .Values.global.orcdb.externalDb.enabled }}
{{- $databaseProfile:= index $dbNameDictionary $databaseProfileKey }}

{{- $externalDbSchema := .Values.global.orcdb.externalDb.schema }}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-orchestration-config{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
data:
  SERVER_SERVLET_CONTEXT_PATH: "{{$context}}/orchestration"
  EXSTREAM_SCHEMA_DEFAULT: {{ $externalDbSchema }}
  {{- if eq .Values.global.orcdb.externalDb.dbType "POSTGRES"}}
  SPRING_DATASOURCE_URL: "{{ include "postgresJdbcUrl" (dict "Values" .Values "url" .Values.global.orcdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.orcdb.externalDb.dbType "SQLSERVER"}}
  SPRING_DATASOURCE_URL: "{{ include "sqlServerJdbcUrl" (dict "Values" .Values "url" .Values.global.orcdb.externalDb.url) }}"
  {{- end }}
  {{- if eq .Values.global.orcdb.externalDb.dbType "ORACLE"}}
  SPRING_DATASOURCE_URL: "{{ include "oracleJdbcUrl" (dict "Values" .Values "url" .Values.global.orcdb.externalDb.url) }}"
  {{- end }}
  {{- include "databaseConfigMapOptions" .Values.global.orcdb | nindent 2 }}
  {{- include "getHikariConfiguration" . | nindent 2 }}
  {{- include "getVaultEnvVars" (dict "Values" .Values "serviceName" "orchestration" "Release" .Release) | nindent 2 }}
  {{- include "newRelicConfigVariables" (dict "Values" .Values "serviceName" "orchestration") | nindent 2 }}

  SPRING_PROFILES_ACTIVE: "{{ include "getSpringProfilesActive" (dict "Values" .Values "additionalProfiles" $databaseProfile) }}"
  EXSTREAM_ORC_CONFIG_DAS_URL: {{ include "DAS_URL_ROOT_BACKEND" . }}/api/v1/
  EXSTREAM_ORC_CONFIG_ORC_URL: {{ include "ORCH_URL_ROOT_BACKEND" . }}/api/v1/
  EXSTREAM_ORC_CONFIG_ENGINESERVICE_URL: {{ include "ONDEMAND_URL_ROOT_BACKEND" . }}/{exstream.das.domain}/generator
  EXSTREAM_ORC_CONFIG_EMPOWER_URL: {{ include "EMPOWER_URL_ROOT_BACKEND" . }}
  {{- if .Values.global.ei.enabled }}
  EXSTREAM_ORC_CONFIG_EI_URL: {{ include "EI_URL_ROOT_BACKEND" . }}/api/v1/config/{tenantId}/{domain}/covisint
  {{- end }}
  {{- include "configMapJavaLogLevels" . | nindent 2 }}
  {{- include "configMapLoggingConfig" . | nindent 2 }}
  OTDS_URL_ROOT_BACKEND: {{ include "OTDS_URL_ROOT_BACKEND" . }}
  {{- if .Values.global.otds.urlApi }}
  OTDS_URL_API: "{{ .Values.global.otds.urlApi }}"
  {{- end }}
  {{- include "getEtsConfiguration" . | nindent 2 }}
  {{- include "getCssConfiguration" . | nindent 2 }}
  {{- include "getCmsConfiguration" . | nindent 2 }}
  {{- include "getOT2ApplicationsConfiguration" . | nindent 2 }}
  {{- include "sharedStorageUmaskEnv" . | nindent 2 }}
  {{ if eq .Values.global.storage.shared.type "nfs" }}
  EXSTREAM_ORC_CONTEXT_WORKSPACE_ROOT: /mnt/nfs
  {{ end }}
  {{ if .Values.global.storage.tmp.path }}
  EXSTREAM_TEMP_ROOT: {{ .Values.global.storage.tmp.path }}
  {{- else }}
  EXSTREAM_TEMP_ROOT: /tmp
  {{ end }}
  {{ if eq .Values.global.storage.shared.type "s3" }}
  EXSTREAM_ORC_CONTEXT_WORKSPACE_ROOT: share
  {{ end }}
  EXSTREAM_RABBITMQ_SCHEME: {{ template "exstreamrabbitScheme" . }}
  EXSTREAM_RABBITMQ_HOST: {{ template "exstreamrabbitHost" . }}
  EXSTREAM_RABBITMQ_PORT: {{ template "exstreamrabbitPort" . }}
  {{ if .Values.global.rabbitmq.vhost }}
  EXSTREAM_RABBITMQ_VHOST: {{ .Values.global.rabbitmq.vhost }}
  {{ end }}
  {{ if .Values.global.rabbitmq.useQuorumQueues }}
  EXSTREAM_RABBITMQ_USEQUORUMQUEUES: "true"
  {{ end }}
  {{ if .Values.global.rabbitmq.frameMax }}
  RABBIT_FRAME_MAX: "{{ .Values.global.rabbitmq.frameMax | int }}"
  {{- else }}
  RABBIT_FRAME_MAX: "131072"
  {{ end }}
  {{- include "getRabbitMQSecurityVariables" . | nindent 2 }}
  KUBERNETES_NAMESPACE: {{ include "namespaceValue" . }}
  EXSTREAM_URL_FRONTEND_ORC_URL: {{ $exstreamUrlFrontEndOrcUrl }}
 
  EXSTREAM_ORC_CONFIG_ENGINESERVICE_BATCH_QUEUE: "{{ include "getRabbitMQBatchQueueName" . }}"
  EXSTREAM_ORC_CONFIG_ENGINESERVICE_BATCH_CANCELLATION_QUEUE: "{{ include "getRabbitMQBatchCancelationQueueName" . }}"
  EXSTREAM_ORC_CONFIG_QUEUE: "{{ include "getRabbitMQOrcQueueName" . }}"
  EXSTREAM_ORC_CONFIG_MESSAGING_QUEUE: "{{ include "getRabbitMQOrcDirectMessagingQueueName" . }}"
  EXSTREAM_ORC_CONFIG_EXTERNALEVENT_QUEUE: "{{ include "getRabbitMQOrcExternalEventQueueName" . }}"
  EXSTREAM_ORC_CONFIG_EXTERNALEVENT_INPUT_QUEUE: "{{ include "getRabbitMQOrcExternalEventInputQueueName" . }}"
  EXSTREAM_ORC_CONFIG_BROADCAST_QUEUE: "{{ include "getRabbitMQOrcBroadcastQueueName" . }}"
  EXSTREAM_ORC_CONFIG_EI_QUEUE: "{{ include "getRabbitMQOrcEIQueueName" . }}"
  EXSTREAM_ORC_CONFIG_EVENT_QUEUE: "{{ include "getRabbitMQOrcEventQueueName" . }}"
  EXSTREAM_ORC_CONFIG_SECRETS_CROSSDOMAINS: "{{ .Values.secrets.crossdomains }}"
  EXSTREAM_ORC_STORAGE_S3_TESTENABLED: "{{ .Values.storage.s3.testEnabled }}"
  {{- if not .Values.storage.s3.asynchronousUpload }}
  EXSTREAM_STORAGE_S3_ASYNCUPLOAD_ENABLED: "false"
  {{- end }}
  
  EXSTREAM_STORAGE_SHARED: {{ .Values.global.storage.shared.type }}
  {{- if .Values.tempFilenameSuffix }}
  EXSTREAM_ORC_TEMP_FILENAME_SUFFIX: "{{.Values.tempFilenameSuffix}}"
  {{- end }}
  {{- if .Values.useTempFile }}
  EXSTREAM_ORC_USE_TEMP_FILE: "{{.Values.useTempFile}}"
  {{- end }}
  {{- include "trustStoreConfigVariables" . | nindent 2 }}
  EXSTREAM_TRUST_CHECK_TRUST: "{{ .Values.trust.check.trust }}"
  EXSTREAM_TRUST_CHECK_IDENTITY: "{{ .Values.trust.check.identity }}"
  {{ if .Values.sqs.enabled }}
  EXSTREAM_ORC_SQS_QUEUENAME: {{ .Values.sqs.queueName }}
  EXSTREAM_ORC_SQS_REGION: {{ .Values.sqs.region }}
  {{ if .Values.sqs.endpoint }}
  EXSTREAM_ORC_SQS_ENDPOINT: {{ .Values.sqs.endpoint }}
  {{ end }}
  {{ if (.Values.sqs.vault).enginerolepath }}
  EXSTREAM_ORC_SQS_VAULT_ENGINEROLEPATH: {{ .Values.sqs.vault.enginerolepath }}
  {{ end }}
  {{ end }}
  {{ if .Values.azure.enabled }}
  EXSTREAM_ORC_AZURE_STORAGEACCOUNT: {{ .Values.azure.storageaccount }}
  EXSTREAM_ORC_AZURE_QUEUE: {{ .Values.azure.queue }}
  {{ end }}
  {{ if .Values.gcs.enabled }}
  EXSTREAM_ORC_GCS_PROJECTID: {{ .Values.gcs.projectid }}
  EXSTREAM_ORC_GCS_SUBSCRIPTIONID: {{ .Values.gcs.subscriptionid }}
  {{ end }}
  {{ if .Values.debugger }}
  EXSTREAM_ORC_DEBUG_FLAGS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=9999"
  {{ end }}

  EXSTREAM_SCHEMA_MANAGEMENT_AUTO: "{{ required ".Values.global.orcdb.schema.autoManage.enabled required" .Values.global.orcdb.schema.autoManage.enabled }}"
  {{- if .Values.global.orchestration.customPlugins.enabled }}
  LOGGING_LEVEL_ORCHESTRATION_CUSTOM: {{ include "digChartOrGlobalValue" (list "logging" "level" "orchestration" "custom" "INFO" .Values) }}
  {{- if .Values.global.orchestration.customPlugins.embedded }}
  EXSTREAM_ORC_CUSTOM_PLUGINS: -Dloader.path=file:/home/exstream/{{ required "Values.global.orchestration.customPlugins.path required" .Values.global.orchestration.customPlugins.path }}
  {{- end }}
  {{- if and (eq .Values.global.orchestration.customPlugins.embedded false) (eq .Values.global.storage.shared.type "nfs") }}
  EXSTREAM_ORC_CUSTOM_PLUGINS: -Dloader.path=file:/mnt/nfs/{{ required "Values.global.orchestration.customPlugins.path required" .Values.global.orchestration.customPlugins.path }}
  {{- end }}
  {{- end }}
  {{- if .Values.multiPartMaxFileSize }}
  EXSTREAM_ORC_MULTIPART_MAX_FILE_SIZE: "{{ .Values.multiPartMaxFileSize }}"
  {{- end }}
  {{- if .Values.maxJobsToFetch }}
  EXSTREAM_ORC_MAX_JOBS_TO_FETCH: "{{ .Values.maxJobsToFetch }}"
  {{- end }}
  {{- if .Values.maxJobsToDelete }}
  EXSTREAM_ORC_MAX_JOBS_TO_DELETE: "{{ .Values.maxJobsToDelete }}"
  {{- end }}
  {{- if .Values.maxSqlQueryParameters }}
  EXSTREAM_ORC_MAX_SQL_QUERY_PARAMETERS: "{{ .Values.maxSqlQueryParameters }}"
  {{- end }}
  {{- if .Values.maxDeleteJobTracingSize }}
  EXSTREAM_ORC_MAX_DELETE_JOB_TRACING_SIZE: "{{ .Values.maxDeleteJobTracingSize }}"
  {{- end }}
  {{- if hasKey .Values "flowScriptsAllowImport" }}
  EXSTREAM_ORC_FLOW_SCRIPTS_ALLOW_IMPORT: "{{ .Values.flowScriptsAllowImport }}"
  {{- else }}
  EXSTREAM_ORC_FLOW_SCRIPTS_ALLOW_IMPORT: "true"
  {{- end }}
  {{- if .Values.transactionsDeletionDays }}
  EXSTREAM_ORC_TRANSACTIONS_DELETION_DAYS: "{{.Values.transactionsDeletionDays}}"
  {{- end }}
{{- if .Values.allowedOrigins }}
  EXSTREAM_ALLOWED_ORIGINS: "{{.Values.allowedOrigins}}"
{{- end }}
{{- if .Values.contentSecurityPolicy }}
  EXSTREAM_CONTENT_SECURITY_POLICY: {{.Values.contentSecurityPolicy}}
{{- end }}
{{- if .Values.heapFlags }}
  EXSTREAM_HEAP_FLAGS: "{{.Values.heapFlags}}"
{{- end }}
{{- if .Values.heapSettings }}
  EXSTREAM_ORC_HEAP_FLAGS: {{.Values.heapSettings}}
{{- end }}
{{- if .Values.global.orcdb.schema.prefix }}
  EXSTREAM_SCHEMA_PREFIX: {{.Values.global.orcdb.schema.prefix}}
{{- end }}
  EXSTREAM_ASSURED_DELIVERY_ENABLED: "{{.Values.global.assuredDelivery.enabled}}"
{{- if .Values.global.orcdb.vault }}
  {{- if .Values.global.orcdb.vault.enginerolepath }}
  {{- if .Values.global.orcdb.vault.enginerolepath.system }}
  EXSTREAM_VAULT_ENGINEROLEPATH_SYSTEM: "{{.Values.global.orcdb.vault.enginerolepath.system}}"
  {{- end }}
  {{- end }}
  {{- if .Values.global.orcdb.vault.enginerolepath }}
  {{- if .Values.global.orcdb.vault.enginerolepath.schema }}
  EXSTREAM_VAULT_ENGINEROLEPATH_SCHEMA: "{{.Values.global.orcdb.vault.enginerolepath.schema}}"
  {{- end }}
  {{- end }}
{{- end }}

  EXSTREAM_ORC_CONFIG_PRIORITY_QUEUES_ENABLE: "true"
  EXSTREAM_ORC_CONFIG_PRIORITY_INCREASE_PERIOD: "900000"
  EXSTREAM_ORC_CONFIG_PRIORITY_TWO_THRESHOLD: "10000"
  EXSTREAM_ORC_CONFIG_PRIORITY_THREE_THRESHOLD: "200000"
  EXSTREAM_ORC_CONFIG_ENQUEUED-MESSAGES_REDUCE_FACTOR: "2"
  EXSTREAM_ORC_CONFIG_SHOVELING_P2_TO_P1_MSG: "1000"
  EXSTREAM_ORC_CONFIG_SHOVELING_P3_TO_P2_MSG: "2500"
  EXSTREAM_ORC_CONFIG_SHOVELING_P2_TO_P1_PERIOD_SEC: "30"
  EXSTREAM_ORC_CONFIG_SHOVELING_P3_TO_P2_PERIOD_SEC: "10"
  EXSTREAM_ORC_CONFIG_SHOVELING_MAX_MESSAGES_TARGET_QUEUE: "1000"
  EXSTREAM_ORC_CONFIG_SHOVELING_ENABLE: "true"

  {{- include "getHydratedEnvVars" . | nindent 2 }}

{{- end }}
{{- end -}}

{{- define "rationalizationdb-secret-template" }}

{{- if include "needDatabaseSecret" . }}
{{- if .Values.global.rationalization }}
{{- if .Values.global.rationalization.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-rationalizationdb-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  system-schema-username: {{ required "global.rationalizationdb.externalDb.usernameSecretKey is required" .Values.global.rationalizationdb.externalDb.usernameSecretKey | b64enc | quote }}
  system-schema-password: {{ required "global.rationalizationdb.externalDb.passwordSecretKey is required" .Values.global.rationalizationdb.externalDb.passwordSecretKey | b64enc | quote }}
  schema-management-username: {{ .Values.global.rationalizationdb.schema.autoManage.usernameSecretKey | b64enc | quote }}
  schema-management-password: {{ .Values.global.rationalizationdb.schema.autoManage.passwordSecretKey | b64enc | quote }}
{{- else }}
  system-schema-username: {{ required "global.rationalizationdb.externalDb.username is required" .Values.global.rationalizationdb.externalDb.username | b64enc | quote }}
  system-schema-password: {{ required "global.rationalizationdb.externalDb.password is required" .Values.global.rationalizationdb.externalDb.password | b64enc | quote }}
{{- if .Values.global.rationalizationdb.schema.autoManage.enabled }}
  schema-management-username: {{ .Values.global.rationalizationdb.schema.autoManage.username | b64enc | quote }}
  schema-management-password: {{ .Values.global.rationalizationdb.schema.autoManage.password | b64enc | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- end -}}

{{- define "migratordb-secret-template" }}

{{- if include "needDatabaseSecret" . }}
{{- if .Values.enabled }}

apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-migratordb-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  system-schema-username: {{ required "migrator.db.externalDb.usernameSecretKey is required" .Values.db.externalDb.usernameSecretKey | b64enc | quote }}
  system-schema-password: {{ required "migrator.db.externalDb.passwordSecretKey is required" .Values.db.externalDb.passwordSecretKey | b64enc | quote }}
  schema-management-username: {{ .Values.db.schema.autoManage.usernameSecretKey | b64enc | quote }}
  schema-management-password: {{ .Values.db.schema.autoManage.passwordSecretKey | b64enc | quote }}
{{- else }}
  system-schema-username: {{ required "migrator.db.externalDb.username is required" .Values.db.externalDb.username | b64enc | quote }}
  system-schema-password: {{ required "migrator.db.externalDb.password is required" .Values.db.externalDb.password | b64enc | quote }}
{{- if .Values.db.schema.autoManage.enabled }}
  schema-management-username: {{ .Values.db.schema.autoManage.username | b64enc | quote }}
  schema-management-password: {{ .Values.db.schema.autoManage.password | b64enc | quote }}
{{- end }}
{{- end }}

{{- end }}
{{- end }}

{{- end -}}

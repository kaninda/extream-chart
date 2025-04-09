{{- define "dasdb-secret-template" }}

{{- if include "needDatabaseSecret" . }}
{{- if .Values.global.design.enabled }}

apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-dasdb-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  system-schema-username: {{ required "global.dasdb.externalDb.usernameSecretKey is required" .Values.global.dasdb.externalDb.usernameSecretKey | b64enc | quote }}
  system-schema-password: {{ required "global.dasdb.externalDb.passwordSecretKey is required" .Values.global.dasdb.externalDb.passwordSecretKey | b64enc | quote }}
  schema-management-username: {{ .Values.global.dasdb.schema.autoManage.usernameSecretKey | b64enc | quote }}
  schema-management-password: {{ .Values.global.dasdb.schema.autoManage.passwordSecretKey | b64enc | quote }}
{{- else }}
  system-schema-username: {{ required "global.dasdb.externalDb.username is required" .Values.global.dasdb.externalDb.username | b64enc | quote }}
  system-schema-password: {{ required "global.dasdb.externalDb.password is required" .Values.global.dasdb.externalDb.password | b64enc | quote }}
{{- if .Values.global.dasdb.schema.autoManage.enabled }}
  schema-management-username: {{ .Values.global.dasdb.schema.autoManage.username | b64enc | quote }}
  schema-management-password: {{ .Values.global.dasdb.schema.autoManage.password | b64enc | quote }}
{{- end }}
{{- end }}

{{- end }}
{{- end }}

{{- end -}}

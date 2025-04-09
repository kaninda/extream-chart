{{- define "orcdb-secret-template" }}

{{- if .Values.global.orchestration.enabled }}
{{- if include "needDatabaseSecret" . }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-orcdb-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  system-schema-username: {{ required "global.orcdb.externalDb.usernameSecretKey is required" .Values.global.orcdb.externalDb.usernameSecretKey | b64enc | quote }}
  system-schema-password: {{ required "global.orcdb.externalDb.passwordSecretKey is required" .Values.global.orcdb.externalDb.passwordSecretKey | b64enc | quote }}
  schema-management-username: {{ .Values.global.orcdb.schema.autoManage.usernameSecretKey | b64enc | quote }}
  schema-management-password: {{ .Values.global.orcdb.schema.autoManage.passwordSecretKey | b64enc | quote }}
{{- else }}
  system-schema-username: {{ required "global.orcdb.externalDb.username is required" .Values.global.orcdb.externalDb.username | b64enc | quote }}
  system-schema-password: {{ required "global.orcdb.externalDb.password is required" .Values.global.orcdb.externalDb.password | b64enc | quote }}
{{- if .Values.global.orcdb.schema.autoManage.enabled }}
  schema-management-username: {{ .Values.global.orcdb.schema.autoManage.username | b64enc | quote }}
  schema-management-password: {{ .Values.global.orcdb.schema.autoManage.password | b64enc | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- end -}}

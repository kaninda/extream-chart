{{- define "eidb-secret-template" }}

{{- if include "needDatabaseSecret" . }}
{{- if .Values.global.ei.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-eidb-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  system-schema-username: {{ required "global.eidb.externalDb.usernameSecretKey is required" .Values.global.eidb.externalDb.usernameSecretKey | b64enc | quote }}
  system-schema-password: {{ required "global.eidb.externalDb.passwordSecretKey is required" .Values.global.eidb.externalDb.passwordSecretKey | b64enc | quote }}
  schema-management-username: {{ .Values.global.eidb.schema.autoManage.usernameSecretKey | b64enc | quote }}
  schema-management-password: {{ .Values.global.eidb.schema.autoManage.passwordSecretKey | b64enc | quote }}
{{- else }}
  system-schema-username: {{ required "global.eidb.externalDb.username is required" .Values.global.eidb.externalDb.username | b64enc | quote }}
  system-schema-password: {{ required "global.eidb.externalDb.password is required" .Values.global.eidb.externalDb.password | b64enc | quote }}
{{- if .Values.global.eidb.schema.autoManage.enabled }}
  schema-management-username: {{ .Values.global.eidb.schema.autoManage.username | b64enc | quote }}
  schema-management-password: {{ .Values.global.eidb.schema.autoManage.password | b64enc | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- end -}}

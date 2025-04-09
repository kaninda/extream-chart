{{- define "eepdb-secret-template" }}

{{- if include "needDatabaseSecret" . }}
{{- if or .Values.global.assuredDelivery.enabled .Values.global.ei.enabled .Values.global.eep.enabled}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-eepdb-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  system-schema-username: {{ required "global.eepdb.externalDb.usernameSecretKey is required" .Values.global.eepdb.externalDb.usernameSecretKey | b64enc | quote }}
  system-schema-password: {{ required "global.eepdb.externalDb.passwordSecretKey is required" .Values.global.eepdb.externalDb.passwordSecretKey | b64enc | quote }}
  schema-management-username: {{ .Values.global.eepdb.schema.autoManage.usernameSecretKey | b64enc | quote }}
  schema-management-password: {{ .Values.global.eepdb.schema.autoManage.passwordSecretKey | b64enc | quote }}
{{- else }}
  system-schema-username: {{ required "global.eepdb.externalDb.username is required" .Values.global.eepdb.externalDb.username | b64enc | quote }}
  system-schema-password: {{ required "global.eepdb.externalDb.password is required" .Values.global.eepdb.externalDb.password | b64enc | quote }}
{{- if .Values.global.eepdb.schema.autoManage.enabled }}
  schema-management-username: {{ .Values.global.eepdb.schema.autoManage.username | b64enc | quote }}
  schema-management-password: {{ .Values.global.eepdb.schema.autoManage.password | b64enc | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- end -}}

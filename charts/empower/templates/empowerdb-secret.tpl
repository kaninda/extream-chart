{{- define "empowerdb-secret-template" }}

{{- if include "needDatabaseSecret" . }}
{{- if .Values.global.empower.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-empowerdb-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  shared-schema-username: {{ required "global.empowerdb.schema.shared.usernameSecretKey is required" .Values.global.empowerdb.schema.shared.usernameSecretKey | b64enc | quote }}
  shared-schema-password: {{ required "global.empowerdb.schema.shared.passwordSecretKey is required" .Values.global.empowerdb.schema.shared.passwordSecretKey | b64enc | quote }}
  system-schema-username: {{ required "global.empowerdb.schema.system.usernameSecretKey is required" .Values.global.empowerdb.schema.system.usernameSecretKey | b64enc | quote }}
  system-schema-password: {{ required "global.empowerdb.schema.system.passwordSecretKey is required" .Values.global.empowerdb.schema.system.passwordSecretKey | b64enc | quote }}
  schema-management-username: {{ .Values.global.empowerdb.schema.autoManage.usernameSecretKey | b64enc | quote }}
  schema-management-password: {{ .Values.global.empowerdb.schema.autoManage.passwordSecretKey | b64enc | quote }}
{{- else }}
  shared-schema-username: {{ required "global.empowerdb.schema.shared.username is required" .Values.global.empowerdb.schema.shared.username | b64enc | quote }}
  shared-schema-password: {{ required "global.empowerdb.schema.shared.password is required" .Values.global.empowerdb.schema.shared.password | b64enc | quote }}
  system-schema-username: {{ required "global.empowerdb.schema.system.username is required" .Values.global.empowerdb.schema.system.username | b64enc | quote }}
  system-schema-password: {{ required "global.empowerdb.schema.system.password is required" .Values.global.empowerdb.schema.system.password | b64enc | quote }}
{{- if .Values.global.empowerdb.schema.autoManage.enabled }}
  schema-management-username: {{ .Values.global.empowerdb.schema.autoManage.username | b64enc | quote }}
  schema-management-password: {{ .Values.global.empowerdb.schema.autoManage.password | b64enc | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- end -}}

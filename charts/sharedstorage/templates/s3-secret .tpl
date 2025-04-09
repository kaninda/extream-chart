{{- define "s3-secret-template" }}

{{- if eq .Values.global.storage.shared.type "s3"}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-shared-s3{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}  
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
  s3-secretkey: {{ .Values.global.storage.shared.s3.secretkey | b64enc | quote }}
{{- end }}

{{- end -}}
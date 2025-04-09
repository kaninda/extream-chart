{{- define "truststore-secret-template" }}

{{- if .Values.global.trust.custom.enabled -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-truststore-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
{{- if include "isGcpEnabled" . }}
  password: {{ required "global.trust.custom.passwordSecretKey is required" .Values.global.trust.custom.passwordSecretKey | b64enc | quote }}
{{- else }}
  password: {{ required "global.trust.custom.password is required" .Values.global.trust.custom.password | b64enc | quote }}
{{- end }}

---
# https://kubernetes.io/docs/concepts/configuration/secret/
# Individual secrets are limited to 1MiB in size
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-truststore{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "configMap") | nindent 4 }}
binaryData:
  truststore: {{ required "global.trust.custom.source is required" .Values.global.trust.custom.source | b64enc | quote }}
{{- end }}
{{- end -}}

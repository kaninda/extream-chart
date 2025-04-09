{{- define "encryption-secret-template" }}

---
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-keys-secret{{ include "preInstallHookNameSuffix" . }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  labels:
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
stringData:
{{- if include "isGcpEnabled" . }}
  {{- if .Values.encryption }}
    defaultKey: {{ .Values.encryption.defaultKeySecretKey | default "" | quote }}
    keys: {{ .Values.encryption.keysSecretKey | default "" | quote }}
  {{- else }}
    defaultKey: ""
    keys: ""
  {{- end }}
{{- else }}
  defaultKey: {{ .Values.encryption.defaultKey | default "" | quote }}
  keys: |-
{{ toYaml .Values.encryption.keys | indent 4}}
{{- end }}
---

{{- end -}}

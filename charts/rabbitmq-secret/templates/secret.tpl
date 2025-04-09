{{- define "rabbit-secret-template" }}

{{- if include "isRabbitMQUsernamePasswordRequired" . }}

## This pulls the rabbitmq username and password into an exstream secret,
## provided that we are not installing rabbitmq-ha as part of the exstream deployment
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-rabbitmq-ha{{ include "preInstallHookNameSuffix" . }}
  annotations:
{{ include "preInstallHookConfigAnnotations" . | indent 4 }}
{{ include "getExtraResourceAnnotations" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
  {{- include "namespaceMetadata" . | nindent 2 }}
  labels:
    app: {{ .Chart.Name }}
    chart: {{ .Chart.Name }}
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
{{ include "getExtraResourceLabels" (dict "dot" . "typeLabel" "secret") | nindent 4 }}
type: Opaque
data:
  {{- if .Values.global.rabbitmq.username }}
  {{ $_:= set .Values "rabbitmqUsername" .Values.global.rabbitmq.username}}
  {{ end }}
  {{- if .Values.global.rabbitmq.password }}
  {{ $_:= set .Values "rabbitmqPassword" .Values.global.rabbitmq.password}}
  {{ end }}
  {{- if .Values.global.rabbitmq.usernameSecretKey }}
  {{ $_:= set .Values "rabbitmqUsernameSecretKey" .Values.global.rabbitmq.usernameSecretKey}}
  {{ end }}
  {{- if .Values.global.rabbitmq.passwordSecretKey }}
  {{ $_:= set .Values "rabbitmqPasswordSecretKey" .Values.global.rabbitmq.passwordSecretKey}}
  {{ end }}
{{- if include "isGcpEnabled" . }}
  rabbitmq-username: {{ .Values.rabbitmqUsernameSecretKey | default "" | b64enc | quote }}
  rabbitmq-password: {{ required "global.rabbitmq.passwordSecretKey required" .Values.rabbitmqPasswordSecretKey | b64enc | quote }}
{{- else }}
  rabbitmq-username: {{ required "global.rabbitmq.username required" .Values.rabbitmqUsername | b64enc | quote }}
  rabbitmq-password: {{ required "global.rabbitmq.password required" .Values.rabbitmqPassword | b64enc | quote }}
{{- end }}
{{- end }}

{{- end -}}
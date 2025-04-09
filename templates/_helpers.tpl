/********************************************* Utility Functions ***********************************************/

/** Try to mimick sprig's new dig function (not yet available in helm). http://masterminds.github.io/sprig/dicts.html **/
/** Example Use: include "dig" (list "key1" "key2" "defaultValue" .Values)
/** The above will return "value" if .Values.key1.key2==value, or "defaultValue" if key1 or key2 dne **/
{{- define "dig" -}}
  {{- $length := len . -}}
  {{- if lt $length 2 -}}
    {{- fail "dig function arguments must end with a default value followed by the source map." -}}
  {{- end -}}
  {{- $source := index . (add $length -1) -}}
  {{- $default := index . (add $length -2) -}}
  {{- $useDefault := false -}}
  {{- /* loop over every item in the input list except the last two items */ -}}
  {{- range $index, $key := . -}}
    {{- if lt $index (add $length -2) -}}
      {{- /* if our last item was not a map, then we want to return the specified default value */ -}}
      {{- if not (kindIs "map" $source) -}}
        {{- $useDefault = true -}}
      {{- else if not (hasKey $source $key) -}}
        {{- $useDefault = true -}}
      {{- else -}}
        {{- $source = index $source $key -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if $useDefault -}}
    {{- $source = $default -}}
  {{- end -}}
  {{- if not $source -}}
  {{- else if (not (kindIs "string" $source)) -}}
    {{ toYaml $source }}
  {{- else -}}
    {{ $source }}
  {{- end -}}
{{- end }}

/** Dig a value either from the current chart's map of values, or the global map of values **/
{{- define "digChartOrGlobalValue" -}}
  {{- $globalResult := include "dig" (prepend . "global") -}}
  {{- /* The next 4 lines update the n-2nd value in the input list */ -}}
  {{- $length := len . -}}
  {{- $newList := slice . 0 (add $length -2) -}}
  {{- $newList = append $newList $globalResult -}}
  {{- $newList = append $newList (index . (add $length -1)) -}}
  {{  include "dig" $newList }}
{{- end -}}

/** Example Use: include "digPath" (list "key1.key2" "defaultValue" .Values)
{{- define "digPath" -}}
  {{- $newList := splitList "." (index . 0) -}}
  {{- $newList = append $newList (index . 1) -}}
  {{- $newList = append $newList (index . 2) -}}
  {{ include "dig" $newList }}
{{- end -}}


/********************************************* Exstream vs Supporting Chart Functions **************************/

{{- define "isExstreamChart" -}}
  {{- if not ((((.Values).global).exstream).release) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "isSameClusterChart" -}}
  {{- if not (or (include "isExstreamChart" .) (include "isForeignClusterChart" .)) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "isForeignClusterChart" -}}
  {{- if (((((.Values).global).exstream).release).backend) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "getExstreamReleaseName" -}}
  {{- if include "isExstreamChart" . -}}
    {{- printf .Release.Name -}}
  {{- else if include "isSameClusterChart" . -}}
    {{- printf .Values.global.exstream.release.name -}}
  {{- else -}}
    {{ fail "Must not require an Exstream release name in a foreign cluster." }}
  {{- end -}}
{{- end -}}

{{- define "getExstreamReleaseNamespace" -}}
  {{- if include "isExstreamChart" . -}}
    {{- include "namespaceValue" . -}}
  {{- else if include "isSameClusterChart" . -}}
    {{- printf .Values.global.exstream.release.namespace -}}
  {{- else -}}
    {{ fail "Must not require an Exstream release name in a foreign cluster." }}
  {{- end -}}
{{- end -}}

{{- define "getExstreamReleaseContext" -}}
  {{- if include "isExstreamChart" . -}}
    {{- if .Values.global.ingress.context -}}
      {{- .Values.global.ingress.context }}
    {{- end -}}
  {{- else -}}
    {{- .Values.global.exstream.release.context }}
  {{- end -}}
{{- end -}}


/**********************************************   Front end urls  **********************************************/

{{- define "getOtdsFrontEndUrl" -}}
{{- printf "%s" .Values.global.otds.externalFrontEnd }}
{{- end -}}

{{- define "getOtdsAdmFrontEndUrl" -}}
{{- printf "%s" (default (include "getOtdsFrontEndUrl" .) ((.Values.global.otds).adm).externalFrontEnd) }}
{{- end -}}

{{- define "getDasFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "design") }}
{{- end -}}

{{- define "getDasFrontEndUrlWithTrailingSlash" -}}
  {{- $url := include "getDasFrontEndUrl" . -}}
  {{- if not (hasSuffix $url "/") -}}
    {{- $url = printf "%s/" $url -}}
  {{- end -}}
  {{- printf "%s" $url }}
{{- end -}}

{{- define "getEmpowerFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "empower") }}
{{- end -}}

{{- define "getOrchestrationFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "orchestration") }}
{{- end -}}

{{- define "getOrchestratorFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "design/orchestrator") }}
{{- end -}}

{{- define "getOndemandFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "ondemand") }}
{{- end -}}

{{- define "getRealtimeFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "realtime") }}
{{- end -}}

{{- define "getBatchFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "batch") }}
{{- end -}}

{{- define "getRationalizationFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "rationalizationApi") }}
{{- end -}}

{{- define "getEIFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "ei") }}
{{- end -}}

{{- define "getEEPFrontEndUrl" -}}
  {{- include "getFrontEndServiceUrl" (dict "values" . "serviceName" "eep") }}
{{- end -}}

{{- define "getFrontEndServicePath" -}}
  {{- $context := include "getFrontEndUrlContext" .values }}
  {{- if $context -}}
    {{- printf "%s/%s" $context .serviceName }}
  {{- else -}}
    {{- printf "%s" .serviceName }}
  {{- end -}}
{{- end -}}

{{- define "getFrontEndServiceUrl" -}}
  {{- $context := include "getFrontEndUrlContextWithLeadingSlash" .values }}
  {{- $frontEndProtocol := include "getExstreamFrontEndProtocol" .values }}
  {{- $exstreamUrlFrontEndIngressUrl :=  include "getExstreamFrontEndIngressUrl" .values -}}
  {{- printf "%s://%s%s/%s" $frontEndProtocol $exstreamUrlFrontEndIngressUrl $context .serviceName }}
{{- end -}}

{{- define "getDasServiceUrlFilter" -}}
  {{- include "getServiceUrlFilter" (dict "values" . "serviceName" "design") }}
{{- end -}}

{{- define "getEmpowerServiceUrlFilter" -}}
  {{- include "getServiceUrlFilter" (dict "values" . "serviceName" "empower") }}
{{- end -}}

{{- define "getOrchestrationServiceUrlFilter" -}}
  {{- include "getServiceUrlFilter" (dict "values" . "serviceName" "orchestration") }}
{{- end -}}

{{- define "getOndemandServiceUrlFilter" -}}
  {{- include "getServiceUrlFilter" (dict "values" . "serviceName" "ondemand") }}
{{- end -}}

{{- define "getBatchServiceUrlFilter" -}}
  {{- include "getServiceUrlFilter" (dict "values" . "serviceName" "batch") }}
{{- end -}}

{{- define "getRationalizationServiceUrlFilter" -}}
  {{- include "getServiceUrlFilter" (dict "values" . "serviceName" "rationalizationApi") }}
{{- end -}}

{{- define "getServiceUrlFilter" -}}
  {{- $context := include "getFrontEndUrlContextWithLeadingSlash" .values }}
  {{- $exstreamUrlFrontEndIngressUrl :=  include "getExstreamFrontEndIngressUrl" .values -}}
  {{- printf "^https?://%s%s/%s.*" $exstreamUrlFrontEndIngressUrl $context .serviceName }}
{{- end -}}


{{- define "getFrontEndUrlContext" -}}
  {{- if .Values.global.ingress.context -}}
    {{- .Values.global.ingress.context }}
  {{- else }}
  {{- end -}}
{{- end -}}

{{- define "getFrontEndUrlContextWithLeadingSlash" -}}
  {{- $context := include "getFrontEndUrlContext" . }}
  {{- if $context -}}
    {{- printf "/%s" $context -}}
  {{- end -}}
{{- end -}}


{{- define "getFrontEndUrlContextWithTrailingSlash" -}}
  {{- $context := include "getFrontEndUrlContext" . }}
  {{- if $context -}}
    {{- printf "%s/" $context -}}
  {{- end -}}
{{- end -}}

{{- define "getExstreamReleaseFrontEndUrlContext" -}}
  {{- if include "isExstreamChart" . -}}
    {{- include "getFrontEndUrlContext" . }}
  {{- else -}}
    {{- .Values.global.exstream.release.context }}
  {{- end }}
{{- end -}}

{{- define "getExstreamReleaseFrontEndUrlContextWithTrailingSlash" -}}
  {{- $context := include "getExstreamReleaseFrontEndUrlContext" . }}
  {{- if $context -}}
    {{- printf "%s/" $context -}}
  {{- end -}}
{{- end -}}

{{- define "getExstreamFrontEndIngressUrl" -}}
  {{- if .Values.global.ingress.hostport -}}
    {{- printf "%s:%d" .Values.global.ingress.hostname (int .Values.global.ingress.hostport) -}}
  {{- else -}}
    {{- printf "%s" .Values.global.ingress.hostname -}}
  {{- end -}}
{{- end -}}

{{- define "getExstreamFrontEndProtocol" -}}
  {{- if eq .Values.global.frontEnd.protocol "auto" -}}
    {{- if .Values.global.tls.enabled -}}
      {{- printf "https" -}}
    {{- else -}}
      {{- printf "http" -}}
    {{- end -}}
  {{- else -}}
    {{- printf "%s" .Values.global.frontEnd.protocol -}}
  {{- end -}}
{{- end -}}

{{- define "exstreamrabbitScheme" -}}
  {{- if .Values.global.rabbitmq.tls.enabled -}}
    {{- printf "amqps" -}}
  {{- else -}}
    {{- printf "amqp" -}}
  {{- end -}}
{{- end -}}

/* Normally we require global.rabbitmq.host. But OCP embeds the host in an amqp url along with the secret credentials. */
{{- define "exstreamrabbitHost" -}}
  {{- if .Values.global.rabbitmq.host -}}
    {{- printf "%s" (required "global.rabbitmq.host is required" .Values.global.rabbitmq.host) -}}
  {{- else if not (or .Values.global.rabbitmq.usernameSecretKey .Values.global.rabbitmq.passwordSecretKey) -}}
    {{- fail "global.rabbitmq.host is required" -}}
  {{- end -}}
{{- end -}}

{{- define "exstreamrabbitPort" -}}
  {{- $rabbitmqPort := include "digChartOrGlobalValue" (list "rabbitmq" "port" "" .Values) -}}
  {{- if not $rabbitmqPort -}}
    {{- $rabbitmqScheme := include "exstreamrabbitScheme" . -}}
	{{- if eq (lower $rabbitmqScheme) "amqps" -}}
	  {{- $rabbitmqPort = 5671 -}}
    {{- else -}}
	  {{- $rabbitmqPort = 5672 -}}
	{{- end -}}
  {{- end -}}
  {{ quote $rabbitmqPort }}
{{- end }}

{{- define "getRabbitMQSecurityVariables" -}}
{{- if .Values.global.rabbitmq.tls.enabled }}
RABBIT_TLS_USECLIENTCERTIFICATE: "{{ .Values.global.rabbitmq.tls.useClientCertificate }}"
RABBIT_TLS_AUTHMECHANISM: "{{ .Values.global.rabbitmq.tls.authMechanism }}"
{{- end -}}
{{- end -}}

{{- define "rabbitmqSecretVolumeMount" -}}
  {{- if and (include "needRabbitSecret" .) .Values.global.rabbitmq.tls.enabled .Values.global.rabbitmq.tls.useClientCertificate }}
- name: rabbitmq-certs
  mountPath: "/rabbitmqcerts"
  readOnly: true
  {{- end -}}
{{- end -}}

{{- define "rabbitmqSecretVolume" -}}
  {{- if and (include "needRabbitSecret" .) .Values.global.rabbitmq.tls.enabled .Values.global.rabbitmq.tls.useClientCertificate }}
- name: rabbitmq-certs
  secret:
    secretName: {{ include "getExstreamReleaseName" . }}-rabbitmq-certs
    optional: false
  {{- end -}}
{{- end -}}

{{- define "isRabbitMQUsernamePasswordRequired" -}}
  {{- if and (include "needRabbitSecret" .) (not (and .Values.global.rabbitmq.tls.enabled .Values.global.rabbitmq.tls.useClientCertificate (eq (lower .Values.global.rabbitmq.tls.authMechanism) "external"))) }}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}


/**********************************************   Deployment functions    *************************************/

/* include "getDeploymentName" (dict "dot" . "path" "deployment.name" "defaultValue" (print .Release.Name "-design")) */
{{- define "getDeploymentName" -}}
  {{- $name := include "digPath" (list .path .defaultValue .dot.Values) -}}
  {{- printf "%s" $name -}}
{{- end -}}

/* include "getContainerName" (dict "dot" . "path" "deployment.container.name" "defaultValue" "design") */
{{- define "getContainerName" -}}
  {{- $name := include "digPath" (list .path .defaultValue .dot.Values) -}}
  {{- printf "%s" $name -}}
{{- end -}}


/**********************************************   Docker images  **********************************************/

/* include "getDockerImage" (dict "dot" . "imageValues" ".Values" "defaultName" "exstream-design" "defaultTagPath" "global.design.version" ) */
{{- define "getDockerImage" -}}
  {{- $source := include "dig" (list "image" "source" "" .imageValues) -}}
  {{- if not $source -}}
    {{- $source = include "dig" (list "image" "source" "" .dot.Values.global) -}}
  {{- end -}}
  {{- if not $source -}}
    {{- $source = (required "global.dockerRepository is required" .dot.Values.global.dockerRepository) -}}
  {{- end -}}

  {{- $name := include "dig" (list "image" "name" "" .imageValues) -}}
  {{- if not $name -}}
    {{- $name = .defaultName -}}
  {{- end -}}

  {{- $tag := include "dig" (list "image" "tag" "" .imageValues) -}}
  {{- if not $tag -}}
    {{- $tag = include "digPath" (list .defaultTagPath "" .dot.Values) -}}
    {{- $tag = (required (cat .defaultTagPath " required") $tag) -}}
  {{- end -}}

  {{- if not $source }}
    {{- printf "%s:%s" $name $tag -}}
  {{- else if (regexFind "\\/$" $source ) }}
    {{- printf "%s%s:%s" $source $name $tag -}}
  {{- else }}
    {{- printf "%s/%s:%s" $source $name $tag -}}
  {{- end }}
{{- end -}}

{{- define "getDesignDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-design" "defaultTagPath" "global.design.version") -}}
{{- end -}}

{{- define "getEepDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-eep-service" "defaultTagPath" "global.eep.version") -}}
{{- end -}}

{{- define "getEiApiDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values.api "defaultName" "exstream-cxi-integration" "defaultTagPath" "global.ei.version") -}}
{{- end -}}

{{- define "getEiCiDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values.ci "defaultName" "exstream-cxi-integration" "defaultTagPath" "global.ei.version") -}}
{{- end -}}

{{- define "getEiCmeDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values.cme "defaultName" "exstream-cxi-integration" "defaultTagPath" "global.ei.version") -}}
{{- end -}}

{{- define "getBatchDocgenDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-docgen" "defaultTagPath" "global.batch.version") -}}
{{- end -}}

{{- define "getOndemandDocgenDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-docgen" "defaultTagPath" "global.ondemand.version") -}}
{{- end -}}

{{- define "getOrcDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-orchestration" "defaultTagPath" "global.orchestration.version") -}}
{{- end -}}

{{- define "getRatApiDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values.api "defaultName" "exstream-rationalization" "defaultTagPath" "global.rationalization.version") -}}
{{- end -}}

{{- define "getRatJobDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values.job "defaultName" "exstream-rationalization" "defaultTagPath" "global.rationalization.version") -}}
{{- end -}}

{{- define "getRealtimeDocgenDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-docgen" "defaultTagPath" "global.realtime.version") -}}
{{- end -}}

{{- define "getEngineUploadDocgenDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-docgen" "defaultTagPath" "version") -}}
{{- end -}}

{{- define "getMqShovelDocgenDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-docgen" "defaultTagPath" "global.mqshovel.version") -}}
{{- end -}}

{{- define "getEmpowerDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-empower" "defaultTagPath" "global.empower.version") -}}
{{- end -}}

{{- define "getOT2UtilsDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-ot2utils" "defaultTagPath" "global.ot2.utils.version") -}}
{{- end -}}

{{- define "getSquidDockerImage" -}}
  {{- include "getDockerImage" (dict "dot" . "imageValues" .Values "defaultName" "exstream-squid" "defaultTagPath" "global.squid.version") -}}
{{- end -}}


/**********************************************   Topology Templates *********************************************/

/*
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: zone
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
      foo: bar
*/

{{- define "getTopologySpreadConstraints" -}}
  {{- $key := "topologySpreadConstraints" -}}
  {{- $topology := include "digChartOrGlobalValue" (list $key "" .Values) -}}
  {{- if $topology -}}
    {{ $topology = fromYaml (printf "%s:\n%s" $key $topology) }}
    {{- if and .appLabelKey .appLabelValue -}}	
	  {{- $sourceDict := dict "labelSelector" (dict "matchLabels" (dict $.appLabelKey $.appLabelValue)) -}}
	  {{- range $topologySpreadConstraint := get $topology $key -}}
        {{- $topologySpreadConstraint := merge $topologySpreadConstraint $topologySpreadConstraint $sourceDict -}}
      {{- end -}}
    {{- end -}}
{{ toYaml $topology }}
  {{- else -}}
    {{- if or (hasKey .Values $key) (hasKey .Values.global $key) -}}
{{ $key }}:
	{{- end -}}
  {{- end -}}
{{- end }}


/**********************************************   RabbitMQ queues**********************************************/

{{- define "getRabbitMQQueueName" -}}
  {{- $queueName := include "dig" (list "global" "rabbitmq" "queues" .QueueKey "name" "" .Values) -}}
  {{- if not $queueName -}}
    {{- $queuePrefix := include "dig" (list "global" "rabbitmq" "queue" "namePrefix" "" .Values) -}}
    {{- if not $queuePrefix -}}
      {{ fail "Either all Exstream rabbitmq queue names must be specifed, or global.rabbitmq.queue.namePrefix must be specified." }}
    {{- end -}}
    {{- $queueName = printf "%s%s" $queuePrefix .DefaultQueueSuffix -}}
    {{- if and (.Values.global.rabbitmq.useQuorumQueues) (.IsQuorumQueue) -}}
      {{- $queueName = printf "%s%s" $queueName "-qq" -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s" $queueName }}
{{- end }}

{{- define "getRabbitMQBatchQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-docgen-batch" "QueueKey" "docgen-batch" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQBatchCancelationQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-batch-job-cancellation" "QueueKey" "batch-job-cancellation" "IsQuorumQueue" false) }}
{{- end }}

{{- define "getRabbitMQOrcBroadcastQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-orchestration-broadcast-msgs" "QueueKey" "orchestration-broadcast-msgs" "IsQuorumQueue" false) }}
{{- end }}

{{- define "getRabbitMQOrcDirectMessagingQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-orchestration-direct-msgs" "QueueKey" "orchestration-direct-msgs" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQOrcExternalEventQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-orchestration-externalevent" "QueueKey" "orchestration-externalevent" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQOrcExternalEventInputQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-orchestration-externalevent-input" "QueueKey" "orchestration-externalevent-input" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQOrcEventQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-orchestration-event" "QueueKey" "orchestration-event" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQMigratorQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-migrator-main" "QueueKey" "migrator-main" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQOrcQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-orchestration-main" "QueueKey" "orchestration-main" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQOrcEIQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-orchestration-ei" "QueueKey" "orchestration-ei" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQSPSQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-sps" "QueueKey" "sps" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQSolrQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-solr" "QueueKey" "solr" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQImportQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-import" "QueueKey" "import" "IsQuorumQueue" true) }}
{{- end }}

/** Rationalization **/
{{- define "getRabbitMQRatReportGenQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-rationalization-report-generator-job" "QueueKey" "rationalization-report-generator-job" "IsQuorumQueue" true) }}
{{- end }}

/** CXI **/
{{- define "getCiCleanupQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-ci-events-CleanUp" "QueueKey" "ci-events-CleanUp" "IsQuorumQueue" false) }}
{{- end }}

{{- define "getCovisintIntegratorQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-ci-events-CovisintIntegrator" "QueueKey" "ci-events-CovisintIntegrator" "IsQuorumQueue" false) }}
{{- end }}

/** EEP **/
{{- define "getCiEventsQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-ci-events" "QueueKey" "ci-events" "IsQuorumQueue" false) }}
{{- end }}

{{- define "getEmailEventPullerQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-ci-events-EmailEventPuller" "QueueKey" "ci-events-EmailEventPuller" "IsQuorumQueue" false) }}
{{- end }}

{{- define "getEmailEventPullerInternalQueue" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-eep-internal-queue" "QueueKey" "eep-internal-queue" "IsQuorumQueue" false) }}
{{- end }}

{{- define "getCxiExternalEventsQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-cxi-external-events-queue" "QueueKey" "cxi-external-events-queue" "IsQuorumQueue" true) }}
{{- end }}

{{- define "getRabbitMQOT2EventsQueueName" -}}
  {{- include "getRabbitMQQueueName" (dict "Values" .Values "DefaultQueueSuffix" "-ot2-tenant-events" "QueueKey" "ot2-tenant-events" "IsQuorumQueue" true) }}
{{- end }}

{{- define "rabbitmqChecksum" -}}
{{- if include "needRabbitSecret" . }}
checksum/rabbitmq: {{ include (print "exstream/charts/rabbitmq-secret/templates/secret-main.yaml") . | sha256sum }}
{{- end }}
{{- end -}}


/**********************************************   ReadOnlyRootFilesystem Templates **********************************************/
{{- define "getReadOnlyRootFilesystemProperty" -}}
{{- if .Values.global.readOnlyRootFilesystem -}}
readOnlyRootFilesystem: {{ .Values.global.readOnlyRootFilesystem }}
{{- end -}}
{{- end -}}

{{- define "tempVolumeMount" -}}
{{- if .Values.global.readOnlyRootFilesystem -}}
- name: temp-volume
  mountPath: "/tmp"
{{- end -}}
{{- end -}}

{{- define "tempVolume" -}}
{{- if .Values.global.readOnlyRootFilesystem -}}
- name: temp-volume
  {{- if .Values.storage.tempVolume.sizeLimit }}
  emptyDir:
    sizeLimit: {{ .Values.storage.tempVolume.sizeLimit }}
  {{- else }}
  emptyDir: {}
  {{- end }}
{{- end -}}
{{- end -}}


/**********************************************   Truststore Templates **********************************************/
{{- define "trustStoreChecksum" -}}
{{- if .Values.global.trust.custom.enabled }}
checksum/truststore: {{ printf "%s%s" .Values.global.trust.custom.source .Values.global.trust.custom.password  | sha256sum }}
{{- end }}
{{- end -}}

{{- define "trustStorePassword" -}}
{{- if .Values.global.trust.custom.enabled }}
- name: EXSTREAM_TRUST_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "getExstreamReleaseName" . }}-truststore-secret{{ include "preInstallHookNameSuffix" . }}
      key: password
{{- end }}
{{- end -}}

{{- define "trustStoreVolumeMount" -}}
{{ if .Values.global.trust.custom.enabled }}
- name: truststore-volume
  mountPath: "/opt/config/truststore/"
  readOnly: true
{{ end }}
{{- end -}}

{{- define "trustStoreVolume" -}}
{{ if .Values.global.trust.custom.enabled }}
- name: truststore-volume
  configMap:
    name: {{ include "getExstreamReleaseName" . }}-truststore{{ include "preInstallHookNameSuffix" . }}
    items:
    - key: truststore
      path: truststore
{{ end }}
{{- end -}}

{{- define "trustStoreConfigVariables" -}}
{{ if .Values.global.trust.custom.enabled }}
EXSTREAM_TRUST_STORE_PATH: "/opt/config/truststore/truststore"
{{ end }}
{{- end -}}


/**********************************************   Docgen Storage Templates **********************************************/

{{- define "docgenVolumeMount" -}}
{{- if eq "s3" .Values.global.storage.shared.type -}}
  {{- if not .Values.storage.volumeMount -}}
- mountPath: /docgen
  name: docgen-work
  {{- else -}}
    {{- printf "%s" .Values.storage.volumeMount }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "docgenVolume" -}}
{{- if eq "s3" .Values.global.storage.shared.type -}}
  {{- if not .Values.storage.volume -}}
- name: docgen-work
  emptyDir: {}
  {{- else -}}
    {{- printf "%s" .Values.storage.volume }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "docgenStorageMountPath" -}}
{{- if eq "s3" .Values.global.storage.shared.type -}}
  {{- if not .Values.storage.mountPath -}}
    {{- printf "/docgen" }}
  {{- else -}}
    {{- printf "%s" .Values.storage.mountPath }}
  {{- end -}}
{{- end -}}
{{- end -}}

/**********************************************   New Relic Templates **********************************************/

{{- define "isGcpOcpNewRelic" -}}
{{- if and (include "isGcpEnabled" .) ((.Values.global).newrelic).environment ((.Values.global).newrelic).securityScope -}}
  true
{{- end }}
{{- end -}}

{{- define "newRelicConfigVariables" -}}
{{- $newrelicconfig := include "digChartOrGlobalValue" (list "newrelic" "config" "" .Values) -}}
{{- if or $newrelicconfig (include "isGcpOcpNewRelic" .) }}
NEW_RELIC_ENABLED: "true"
  {{- if include "isGcpOcpNewRelic" . }}
NEW_RELIC_APP_NAME: "ocp-extr-{{ .Values.global.newrelic.securityScope }}-{{ .Values.global.newrelic.environment }}-{{ .serviceName }}"
  {{- end -}}
{{- end -}}
{{- end -}}

/* Must define these in container specs, and not in ConfigMaps, so that the embedded env var references will work */
{{- define "newRelicPodVariables" -}}
{{- $newrelicconfig := include "digChartOrGlobalValue" (list "newrelic" "config" "" .Values) -}}
{{- if $newrelicconfig }}
{{- $newrelicappname := include "digChartOrGlobalValue" (list "newrelic" "component" "name" "Exstream" .Values) -}}
- name: NEW_RELIC_APP_NAME
  value: "{{ $newrelicappname }}_{{ .Chart.Name }}-$(ENV)-$(PLATFORM)_$(CELL)_$(ZONE)_$(DC)-$(BU)"
- name: NEW_RELIC_LABELS
  value: "ENV:$(ENV);Platform:$(PLATFORM);Cell:$(CELL);Zone:$(ZONE);DC:$(DC);BU:$(BU)"
{{- end -}}
{{- end -}}

{{- define "newRelicConfigMapRef" -}}
{{- $releaseName := include "getExstreamReleaseName" . }}
{{- $newrelicconfig := or (include "digChartOrGlobalValue" (list "newrelic" "config" "" .Values)) (and (include "isGcpOcpNewRelic" .) (printf "%s-newrelic-gcp-ocp-config" $releaseName)) -}}
{{- if $newrelicconfig }}
- configMapRef:
    name: {{ $newrelicconfig }}
{{- $newrelicsecret := or (include "digChartOrGlobalValue" (list "newrelic" "secret" "" .Values)) (and (include "isGcpOcpNewRelic" .) (printf "%s-newrelic-gcp-ocp-secret" $releaseName)) -}}
{{- if $newrelicsecret }}
- secretRef:
    name: {{ $newrelicsecret }}
{{- end -}}
{{- end -}}
{{- end -}}


/*
 Convert extra secrets + optional keys specified in values.yaml (or via --set)
 into a dictionary whose keys are secret names, and whose values
 represent the volume names, secret names, and optional secret keys to mount.
 Then convert that dictionary into volumes and volumeMounts.
 Assign "set" valus to $dummy, because not doing so pollutes the final template.
 Use sha1sum for volume names because secret names can contain characters that are illegal for volume names.
 global extraSecrets will be applied to all charts.
 Example:
  --set global.extraSecrets[0].secret=SECRET1,global.extraSecrets[0].key=username
  --set global.extraSecrets[1].secret=SECRET1,global.extraSecrets[1].key=password
  --set design.extraSecrets[0].secret=SECRET2
  --set design.extraSecrets[1].secret=SECRET1,design.extraSecrets[1].key=token
  For the design pod, this results in volumes being mounted at /opt/secret/extra/SECRET1 and /opt/secret/extra/SECRET2
  /opt/secret/extra/SECRET1 will contain files username, password, and token
  /opt/secret/extra/SECRET2 will contain all files in the secret SECRET2
*/
{{- define "extraSecretsDictAppend" -}}
  {{- if $.Values.extraSecrets -}}
    {{- range $extraSecret := $.Values.extraSecrets }}
      {{- $secret := $extraSecret -}}
      {{- $key := 0 -}}
      {{- if not (eq (typeOf $secret) "string") -}}
        {{- $key = $secret.key -}}
        {{- $secret = $secret.secret -}}
      {{- end -}}
      {{- if eq (typeOf $secret) "string" -}}
        {{- if not (hasKey $.extraSecrets $secret) -}}
          {{- $secretDict := dict -}}
          {{- $dummy := set $.extraSecrets $secret $secretDict -}}
          {{- $dummy := set $secretDict "secret" $secret -}}
          {{- $dummy := set $secretDict "keys" dict -}}
          {{- $dummy := set $secretDict "volume" (sha1sum (printf "secret:%s" $secret)) -}}
        {{- end -}}
        {{- $secretDict := get $.extraSecrets $secret -}}
        {{- if not (eq (typeOf $key) "string") -}}
          {{- $dummy := set $secretDict "all" "true" -}}
        {{- else -}}
          {{- $dummy := set $secretDict.keys $key $key -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "extraSecretsDict" -}}
  {{- include "extraSecretsDictAppend" (dict "Values" $.Values "extraSecrets" $.extraSecrets) -}}
  {{- include "extraSecretsDictAppend" (dict "Values" $.global "extraSecrets" $.extraSecrets) -}}
{{- end -}}

{{- define "extraSecretVolumeMount" -}}
  {{- $extraSecrets := dict -}}
  {{- include "extraSecretsDict" (dict "Values" .Values "global" .Values.global "extraSecrets" $extraSecrets) -}}
  {{- range $key, $extraSecret := $extraSecrets }}
- name: {{ $extraSecret.volume }}
  mountPath: {{ printf "/opt/secret/extra/%s" $extraSecret.secret }}
  readOnly: true
  {{- end -}}
{{- end -}}

{{- define "extraSecretVolume" -}}
  {{- $extraSecrets := dict -}}
  {{- include "extraSecretsDict" (dict "Values" .Values "global" .Values.global "extraSecrets" $extraSecrets) -}}
  {{- range $key, $extraSecret := $extraSecrets }}
- name: {{ $extraSecret.volume }}
  secret:
    secretName: {{ $extraSecret.secret }}
    {{- if not $extraSecret.all }}
    items:
      {{- range $key, $value := $extraSecret.keys }}
    - key: {{ $key }}
      path: {{ $key }}
      {{- end }}
    {{- end -}}
  {{- end -}}
{{- end -}}


/**********************************************   JDBC URL Templates *****************************************/
{{- define "postgresJdbcUrl" -}}
  {{- $sslExtraArguments := "sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory" -}}
  {{- if (and (regexFind "\\?.*(ssl=true|sslmode=)" .url) (not (regexFind "\\?.*(sslfactory)" .url))) -}}
    {{ .url }}&{{ $sslExtraArguments }}
  {{- else -}}
    {{ .url }}
  {{- end -}}
{{- end -}}

{{- define "sqlServerJdbcUrl" -}}
  {{- $fixedArguments := "sendStringParametersAsUnicode=false" -}}
  {{ .url }};{{ $fixedArguments }}
{{- end -}}

{{- define "oracleJdbcUrl" -}}
  {{- $fixedArguments := "" -}}
  {{ .url }}{{ $fixedArguments }}
{{- end -}}

{{- define "databaseConfigMapOptions" -}}
  {{- if .externalDb.usernameSuffix -}}
    EXSTREAM_DATABASE_USERNAME_SUFFIX: {{.externalDb.usernameSuffix | quote }}
  {{- end -}}
{{- end -}}


/**********************************************   Hikari Configuration Templates *****************************/

{{- define "getHikariConfiguration" -}}
HIKARI_CONFIG_MIN_IDLE: "{{ include "digChartOrGlobalValue" (list "hikari" "minIdle" "" .Values) }}"
HIKARI_CONFIG_MAX_POOL_SIZE: "{{ include "digChartOrGlobalValue" (list "hikari" "maxPool" "" .Values) }}"
HIKARI_CONFIG_MAX_LIFETIME: "{{ include "digChartOrGlobalValue" (list "hikari" "maxLifetime" "" .Values) }}"
HIKARI_CONFIG_IDLE_TIMEOUT: "{{ include "digChartOrGlobalValue" (list "hikari" "idleTimeout" "" .Values) }}"
HIKARI_CONFIG_CONNECTION_TIMEOUT: "{{ include "digChartOrGlobalValue" (list "hikari" "connTimeout" "" .Values) }}"
{{- end -}}


/**********************************************   Extra Properties Templates *********************************/

{{- define "extraEnvironmentVars" -}}
{{- if .extraEnvironmentVars -}}
{{- range $key, $value := .extraEnvironmentVars }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}
{{- if .global.extraEnvironmentVars -}}
{{- range $key, $value := .global.extraEnvironmentVars }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}
{{- if .extraSecretEnvironmentVars -}}
{{- range .extraSecretEnvironmentVars }}
- name: {{ .envName }}
  valueFrom:
   secretKeyRef:
     name: {{ .secretName }}
     key: {{ .secretKey }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "extraContainerProperties" -}}
{{- if .extraContainerProperties -}}
  {{- toYaml .extraContainerProperties -}}
{{- end -}}
{{- end -}}

/* We can use tpl+toYaml to replace scalar values (simple strings). */
/* But it cannot replace complex, or structred, values. */
/* We can support that by piping toYaml's output through the replace function, */
/* and enclose structured values in single-quote-triple-curly-brace, but then we would have to support that hack forever. */
/* Let's not do that if we don't have to. */
{{- define "extraContainersImpl" -}}
{{- range $key, $value := .extraContainers }}
- {{ tpl (toYaml $value) $.dot | nindent 2 }}
{{- end }}
{{- end }}

{{- define "extraContainers" -}}
  {{- if .dot.Values.global.extraContainers -}}
    {{- include "extraContainersImpl" (dict "dot" .dot "extraContainers" .dot.Values.global.extraContainers) -}}
  {{- end -}}
  {{- if (((.dot.Values.extraPodSettings).all).extraContainers) -}}
    {{- include "extraContainersImpl" (dict "dot" .dot "extraContainers" .dot.Values.extraPodSettings.all.extraContainers) -}}
  {{- end -}}
  {{- if (hasKey .dot.Values "extraPodSettings")  -}}
    {{- if (hasKey .dot.Values.extraPodSettings .pod)  -}}
      {{- if (hasKey (index .dot.Values.extraPodSettings .pod) "extraContainers") -}}
        {{- include "extraContainersImpl" (dict "dot" .dot "extraContainers" (index (index .dot.Values.extraPodSettings .pod) "extraContainers")) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "extraDeploymentProperties" -}}
{{- if .extraDeploymentProperties -}}
  {{- toYaml .extraDeploymentProperties -}}
{{- end -}}
{{- end -}}

{{- define "imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets -}}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "imagePullPolicy" -}}
{{- $imagePullPolicy := include "digChartOrGlobalValue" (list "deployment" "imagePullPolicy" "Always" .Values) -}}
{{- if not $imagePullPolicy -}}
    {{ fail "deployment.imagePullPolicy required" }}
{{- end -}}
{{- printf "imagePullPolicy: %s" $imagePullPolicy }}
{{- end -}}


/**************************************   Kubernetes Orchestration Templates *********************************/

{{- define "getExtraEndpointsImpl" -}}
  {{- range $key, $value := .extraEndpoints }}
    {{- if $value -}}
      {{- $_ := set $.endpointsListDict "list" (append $.endpointsListDict.list $value) -}}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "getExtraEndpoints" -}}
  {{- $endpointsListDict := dict "list" list -}}
  {{- if (hasKey .dot.Values.global .extraEndpointsKey) -}}
    {{- $_ := include "getExtraEndpointsImpl" (dict "dot" .dot "endpointsListDict" $endpointsListDict "extraEndpoints" (index .dot.Values.global .extraEndpointsKey)) -}}
  {{- end -}}
  {{- if (.dot.Values.extraPodSettings) -}}
    {{- if (.dot.Values.extraPodSettings.all) -}}
      {{- if (hasKey .dot.Values.extraPodSettings.all .extraEndpointsKey) -}}
        {{- $_ := include "getExtraEndpointsImpl" (dict "dot" .dot "endpointsListDict" $endpointsListDict "extraEndpoints" (index .dot.Values.extraPodSettings.all .extraEndpointsKey)) -}}
      {{- end -}}
	{{- end -}}
    {{- if (hasKey .dot.Values.extraPodSettings .pod)  -}}
      {{- if (hasKey (index .dot.Values.extraPodSettings .pod) .extraEndpointsKey) -}}
        {{- $_ := include "getExtraEndpointsImpl" (dict "dot" .dot "endpointsListDict" $endpointsListDict "extraEndpoints" (index (index .dot.Values.extraPodSettings .pod) .extraEndpointsKey)) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if .endpoints -}}
    {{- $_ := set $endpointsListDict "list" (append $endpointsListDict.list .endpoints) -}}
  {{- end -}}
  {{ (join "," $endpointsListDict.list ) }}
{{- end -}}

{{- define "getWaitForEndpointsVar" -}}
- name: WAIT_FOR_SERVICES
  value: "{{ include "getExtraEndpoints" (dict "dot" .dot "pod" .pod "endpoints" .endpoints "extraEndpointsKey" "extraWaitForEndpoints") }}"
{{- end }}

{{- define "getShutdownEndpointsVar" -}}
- name: SIGNAL_ON_SHUTDOWN_ENDPOINTS
  value: "{{ include "getExtraEndpoints" (dict "dot" .dot "pod" .pod "endpoints" .endpoints "extraEndpointsKey" "extraSignalOnShutdownEndpoints") }}"
{{- end }}


/**********************************************   URL Templates   ********************************************/

{{- define "OTDS_URL_ROOT_BACKEND" -}}
{{- if .Values.global.otds.externalBackEnd -}}
  {{- .Values.global.otds.externalBackEnd -}}
{{- else -}}
  {{- .Values.global.otds.externalFrontEnd -}}
{{- end -}}
{{- end }}

{{- define "OTDS_URL_ROOT_BACKEND_HOST" -}}
  {{- $otdsUrlRoot := include "OTDS_URL_ROOT_BACKEND" . -}}
  {{- $otdsUrlRoot = (urlParse $otdsUrlRoot) -}}
  {{- $otdsUrlHost := required "global.otds.externalFrontEnd or global.otds.externalBackEnd must be a valid URL" $otdsUrlRoot.host -}}
  {{- $otdsUrlHost := split ":" $otdsUrlHost -}}
  {{- printf "%s" $otdsUrlHost._0 -}}
{{- end -}}

{{- define "OTDS_URL_ROOT_BACKEND_PORT" -}}
  {{- $otdsUrlRoot := include "OTDS_URL_ROOT_BACKEND" . -}}
  {{- $otdsUrlRoot = (urlParse $otdsUrlRoot) -}}
  {{- $otdsUrlHost := required "global.otds.externalFrontEnd or global.otds.externalBackEnd must be a valid URL" $otdsUrlRoot.host -}}
  {{- $otdsUrlScheme := required "global.otds.externalFrontEnd or global.otds.externalBackEnd must be a valid URL" $otdsUrlRoot.scheme -}}
  {{- $otdsUrlHost := split ":" $otdsUrlHost -}}
  {{- if gt (len $otdsUrlHost) 1 -}}
    {{- printf "%s" $otdsUrlHost._1 -}}
  {{- else -}}
    {{- if eq $otdsUrlScheme "http" -}}
      {{- printf "80" -}}
    {{- else -}}
      {{- printf "443" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "OTDS_API_URL_ROOT_BACKEND" -}}
{{- if .Values.global.otds.apiBackEnd -}}
  {{- .Values.global.otds.apiBackEnd -}}
{{- else -}}
  {{- include "OTDS_URL_ROOT_BACKEND" . -}}
{{- end -}}
{{- end }}


{{- define "GET_URL_ROOT_BACKEND" -}}
  {{- $context := include "getExstreamReleaseFrontEndUrlContextWithTrailingSlash" .values }}
  {{- if include "isForeignClusterChart" . -}}
    printf "%s/%s%s" .values.Values.global.exstream.release.backend $context .serviceName
  {{- else }}
    {{- $releaseName := include "getExstreamReleaseName" .values }}
    {{- $releaseNamespace := include "getExstreamReleaseNamespace" .values }}
    {{- printf "http://%s-%s.%s.svc:%s/%s%s" $releaseName .service $releaseNamespace .port $context .serviceName }}
  {{- end }}
{{- end }}

{{- define "DAS_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "design" "service" "das-service" "port" "8081" ) }}
{{- end }}

{{- define "DAS_URL_ROOT_BACKEND_INTERNAL" -}}
  {{- $internalPort := include "digChartOrGlobalValue" (list "svc" "internal" "port" "8900" .Values) -}}
  {{- $internalUrl := include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "design" "service" "das-service" "port" $internalPort ) }}
  {{- printf "%s/internal/api/v1" $internalUrl }}
{{- end }}

{{- define "ORC_URL_ROOT_BACKEND_INTERNAL" -}}
  {{- $internalPort := include "digChartOrGlobalValue" (list "svc" "internal" "port" "8900" .Values) -}}
  {{- $internalUrl := include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "orchestration" "service" "orchestration-service" "port" $internalPort ) }}
  {{- printf "%s" $internalUrl }}
{{- end }}

{{- define "ORCH_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "orchestration" "service" "orchestration-service" "port" "8300" ) }}
{{- end }}

{{- define "BATCH_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "batch" "service" "batch-service" "port" "8100" ) }}
{{- end }}

{{- define "ONDEMAND_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "ondemand" "service" "ondemand-service" "port" "8200" ) }}
{{- end }}

{{- define "REALTIME_URL_ROOT_BACKEND" -}}
  {{- $context := include "getFrontEndUrlContextWithTrailingSlash" . }}
  {{- $releaseName := .Release.Name }}
  {{- $releaseNamespace := include "namespaceValue" . }}
  {{- printf "http://%s-%s.%s.svc:%s/%s%s" $releaseName "realtime-service" $releaseNamespace "8200" $context "realtime" }}
{{- end }}

{{- define "EMPOWER_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "empower" "service" "empower-service" "port" "9090" ) }}
{{- end }}

{{- define "EI_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "ei" "service" "ei-config-api-service" "port" "8041" ) }}
{{- end }}
{{- define "EI_INTERNAL_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "ei" "service" "ei-config-api-internal-service" "port" "9090" ) }}
{{- end }}
{{- define "EEP_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "eep" "service" "eep-service" "port" "8091" ) }}
{{- end }}
{{- define "RATIONALIZATION_URL_ROOT_BACKEND" -}}
  {{- include "GET_URL_ROOT_BACKEND" (dict "values" . "serviceName" "rationalizationApi" "service" "rationalization-api-service" "port" "8051" ) }}
{{- end }}



{{- define "getSpringProfilesActive" -}}
  {{- $activeSpringProfiles := "" -}}
  {{- if .Values.global.otds.enabled -}}
    {{- $activeSpringProfiles = printf "newWorldOTDSAuth" -}}
  {{- else -}}
    {{- $activeSpringProfiles = printf "noauth" -}}
  {{- end -}}
  {{- $activeSpringProfiles = printf "%s,k8s" $activeSpringProfiles -}}
  {{- if .additionalProfiles -}}
    {{- $activeSpringProfiles = printf "%s,%s" $activeSpringProfiles .additionalProfiles -}}
  {{- end -}}
  {{- if .Values.global.ot2 -}}
    {{- if .Values.global.ot2.enabled -}}
      {{- $activeSpringProfiles = printf "%s,ot2" $activeSpringProfiles -}}
    {{- end -}}
  {{- end -}}
  {{- if .Values.global.privateCloud -}}
    {{- $activeSpringProfiles = printf "%s,privateCloud" $activeSpringProfiles -}}
  {{- end -}}
  {{- printf "%s" $activeSpringProfiles -}}
{{- end -}}

{{- define "ETS_URL_ROOT_BACKEND" -}}
  {{ include "digChartOrGlobalValue" (list "ot2" "ets" "backend" "url" "" .Values) }}
{{- end -}}

{{- define "getEtsConfiguration" -}}
  {{- if .Values.global.ot2.enabled -}}
    ETS_URL_ROOT_BACKEND: {{ include "ETS_URL_ROOT_BACKEND" . }}
  {{- end -}}
{{- end -}}

{{- define "OT2_CONTENTSERVICE_URL_ROOT_BACKEND" -}}
  {{ include "digChartOrGlobalValue" (list "ot2" "css" "backend" "url" "" .Values) }}
{{- end -}}

{{- define "getCssConfiguration" -}}
  {{- if .Values.global.ot2.enabled -}}
    OT2_CONTENTSERVICE_URL_ROOT_BACKEND: {{ include "OT2_CONTENTSERVICE_URL_ROOT_BACKEND" . }}
  {{- end -}}
{{- end -}}

{{- define "OT2_CONTENTMETADATASERVICE_URL_ROOT_BACKEND" -}}
  {{ include "digChartOrGlobalValue" (list "ot2" "cms" "backend" "url" "" .Values) }}
{{- end -}}

{{- define "getCmsConfiguration" -}}
  {{- if .Values.global.ot2.enabled -}}
    OT2_CONTENTMETADATASERVICE_URL_ROOT_BACKEND: {{ include "OT2_CONTENTMETADATASERVICE_URL_ROOT_BACKEND" . }}
  {{- end -}}
{{- end -}}

{{- define "getOT2EventsConfiguration" -}}
  {{- if .Values.global.ot2.enabled -}}
EXSTREAM_OT2_EVENTS_WEBHOOK_NAME: {{ .Release.Name }}-exstream-{{ .Chart.Name }}-webhook
OT2_EVENTADMIN_URL_ROOT_BACKEND: {{ required (printf "%s.ot2.events.admin.backend.url is required" .Chart.Name) (include "digChartOrGlobalValue" (list "ot2" "events" "admin" "backend" "url" "" .Values)) }}
	{{- $eventsCallbackUrl := include "dig" (list "ot2" "events" "callback" "root" "url" "" .Values) -}}
    {{- if not $eventsCallbackUrl -}}
	  {{- if include "dig" (list "ot2" "events" "callback" "useBackEndUrl" "" .Values) -}}
        {{- $eventsCallbackUrl = include "DAS_URL_ROOT_BACKEND" . -}}
      {{- else -}}
	    {{- $eventsCallbackUrl = include "getDasFrontEndUrl" . -}}
      {{- end -}}
    {{- end }}
EXSTREAM_OT2_EVENTS_CALLBACK_ROOT_URL: "{{ $eventsCallbackUrl }}"
  {{- end -}}
{{- end -}}

{{- define "getOT2Applications" -}}
{{ include "digChartOrGlobalValue" (list "ot2" "applications" "ExstreamCS" .Values) }}
{{- end -}}

{{- define "getOT2ApplicationsConfiguration" -}}
  {{- if .Values.global.ot2.enabled -}}
    EXSTREAM_OT2_APPLICATIONS: {{ include "getOT2Applications" . }}
  {{- end -}}
{{- end -}}

{{- define "getOT2EtsEventCallbacks" -}}
  {{- if .Values.global.ot2.enabled -}}
    {{- $etsEventCallbacks := "" -}}
    {{- if .Values.global.batch.enabled -}}
      {{- if $etsEventCallbacks -}}
        {{- $etsEventCallbacks = printf "%s," $etsEventCallbacks -}}
      {{- end -}}
      {{- $etsEventCallbacks = printf "%s%s/api/v1/ot2/internal/events/callback" $etsEventCallbacks (include "BATCH_URL_ROOT_BACKEND" .) -}}
    {{- end -}}
    {{- if .Values.global.orchestration.enabled -}}
      {{- if $etsEventCallbacks -}}
        {{- $etsEventCallbacks = printf "%s," $etsEventCallbacks -}}
      {{- end -}}
      {{- $etsEventCallbacks = printf "%s%s/api/v1/ot2/internal/events/callback" $etsEventCallbacks (include "ORCH_URL_ROOT_BACKEND" .) -}}
    {{- end -}}
    {{- if .Values.global.empower.enabled -}}
      {{- if $etsEventCallbacks -}}
        {{- $etsEventCallbacks = printf "%s," $etsEventCallbacks -}}
      {{- end -}}
      {{- $etsEventCallbacks = printf "%s%s/api/v1/ot2/internal/events/callback" $etsEventCallbacks (include "EMPOWER_URL_ROOT_BACKEND" .) -}}
    {{- end -}}
    {{- printf "EXSTREAM_OT2_ETS_EVENT_CALLBACKS: \"%s\"" $etsEventCallbacks -}}
  {{- end -}}
{{- end -}}

{{- define "getDocGenOtdsConfiguration" -}}
{{- $otdsUrlRootFrontEnd := include "getOtdsFrontEndUrl" . }}
  {{- if .Values.global.ot2.enabled }}
SPRING_PROFILES_ACTIVE: ot2
OTDS_URL: {{ include "OTDS_URL_ROOT_BACKEND" . }}
    {{- if .Values.global.ot2.systemTenantUuid }}
OT2_CENTRAL_SYSTEM_TENANT_UUID: {{ .Values.global.ot2.systemTenantUuid }}
    {{- end }}
  {{- else }}
OTDS_URL: {{ include "OTDS_URL_ROOT_BACKEND" . }}/otdsws
  {{- end }}
OTDS_URL_ROOT_FRONTEND: {{ $otdsUrlRootFrontEnd }}
{{- end -}}


/********************************************* Shared Storage Functions **************************************/

{{- define "getS3Properties" -}}
{{- if eq .Values.global.storage.shared.type "s3" }}
{{- if and (.Values.global.storage.shared.s3.vault.enabled) (.Values.global.storage.shared.s3.vault.enginerolepath) }}
- name: EXSTREAM_STORAGE_S3_VAULTPATH
  value: "{{ .Values.global.storage.shared.s3.vault.enginerolepath }}"
{{- end }}
{{- if not .Values.global.storage.shared.s3.vault.enabled }}
- name: EXSTREAM_STORAGE_S3_ACCESSKEY
  value: "{{ .Values.global.storage.shared.s3.accesskey }}"
- name: EXSTREAM_STORAGE_S3_SECRETKEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-shared-s3{{ include "preInstallHookNameSuffix" . }}
      key: s3-secretkey
{{- end }}
- name: EXSTREAM_STORAGE_S3_ENDPOINT
  value: "{{ .Values.global.storage.shared.s3.endpoint }}"
- name: EXSTREAM_STORAGE_S3_REGION
  value: "{{ .Values.global.storage.shared.s3.region }}"
- name: EXSTREAM_STORAGE_S3_BUCKET
  value: "{{ .Values.global.storage.shared.s3.bucket }}"
- name: EXSTREAM_STORAGE_S3_FORCEPATHSTYLE
  value: "{{ .Values.global.storage.shared.s3.forcepathstyle }}"
{{- end }}
{{- end -}}

{{- define "sharedStorageRunAsIds" -}}
  {{ include "runAsIds" . }}
  {{- if .Values.global.storage.shared.fsGroup }}
  # Specify the group to use for files written to shared storage volumes using fsGroup.
  fsGroup: {{ .Values.global.storage.shared.fsGroup }}
  {{- end }}
{{- end -}}

{{- define "runAsIds" -}}
  # 5001 is the default uid:gid specified in exstream containers.
  runAsUser: {{ default 5001 .Values.global.storage.shared.userId }}
  # k8s defaults containers to run as group 0. OpenShift does, too.  Let's not change this unless explicitly told to do so.
  runAsGroup: {{ default 5001 .Values.global.storage.shared.groupId }}
{{- end -}}

{{- define "sharedStorageUmaskEnv" -}}
  {{- if .Values.global.storage.shared.umask -}}
    EXSTREAM_UMASK: "{{ .Values.global.storage.shared.umask }}"
  {{- end }}
{{- end -}}


/********************************************* Preinstall Hook Functions *********************************************/
{{- define "preInstallHookNameSuffix" -}}
{{- if .PreHook -}}
-pre
{{- end -}}
{{- end -}}

{{ define "preInstallHookCustomAnnotations" -}}
{{ if not (include "isHydrated" .dot ) -}}
"helm.sh/hook": pre-install, pre-upgrade
"helm.sh/hook-weight": "{{ .hookWeight }}"
"helm.sh/hook-delete-policy": {{ include "dig" (list "dev" "install" "hookDeletePolicy" "before-hook-creation, hook-succeeded" .dot.Values) }}
{{ end -}}
{{ end -}}

{{ define "preInstallHookConfigAnnotations" -}}
{{ if .PreHook -}}
{{ include "preInstallHookCustomAnnotations" (dict "dot" . "hookWeight" "-10") }}
{{ end -}}
{{ end -}}

{{ define "preInstallHookJobAnnotations" -}}
{{ include "preInstallHookCustomAnnotations" (dict "dot" . "hookWeight" "-1") }}
{{ end -}}

{{ define "preInstallHeavyHookJobAnnotations" -}}
{{ include "preInstallHookCustomAnnotations" (dict "dot" . "hookWeight" "10") }}
{{ end -}}

{{ define "preInstallHookSpecs" -}}
restartPolicy: Never
activeDeadlineSeconds: {{ include "digChartOrGlobalValue" (list "schema" "activeDeadlineSeconds" "1200" .Values) }}
{{ end -}}

{{ define "bootstrapInstallHookSpecs" -}}
restartPolicy: Never
activeDeadlineSeconds: {{ include "digChartOrGlobalValue" (list "upgrade" "activeDeadlineSeconds" "360" .Values) }}
{{ end -}}

{{ define "preInstallSchemaSpecs" }}
backoffLimit: {{ include "digChartOrGlobalValue" (list "schema" "backoffLimit" "6" .Values) }}
{{ if include "isHydrated" . }}
ttlSecondsAfterFinished: {{ include "digChartOrGlobalValue" (list "schema" "ttlSecondsAfterFinished" "86400" .Values) }}
{{ end }}
{{ end }}

{{ define "preInstallUpgradeSpecs" }}
backoffLimit: {{ include "digChartOrGlobalValue" (list "upgrade" "backoffLimit" "6" .Values) }}
{{ if include "isHydrated" . }}
ttlSecondsAfterFinished: {{ include "digChartOrGlobalValue" (list "upgrade" "ttlSecondsAfterFinished" "86400" .Values) }}
{{ end }}
{{ end }}

{{ define "postInstallHookCustomAnnotations" -}}
{{ if not (include "isHydrated" .dot ) -}}
"helm.sh/hook": {{ default "post-install, post-upgrade" .hook }}
"helm.sh/hook-weight": "{{ .hookWeight }}"
"helm.sh/hook-delete-policy": {{ include "dig" (list "dev" "install" "hookDeletePolicy" "before-hook-creation, hook-succeeded" .dot.Values) }}
{{ end -}}
{{ end -}}


/********************************************* Hydration Specific Functions ************************************/

{{- define "isHydrated" -}}
  {{- if ((.Values).global.hydration).enabled -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{ define "beginPreHookAsset" -}}
{{ if not (include "isHydrated" .) }}
{{ $_ := set . "PreHook" true }}
{{ end }}
{{ end -}}

{{- define "endPreHookAsset" -}}
{{ if not (include "isHydrated" .) }}
{{ $_ := unset . "PreHook" }}
{{ end }}
{{- end -}}

{{- define "beginPreHookConfigAsset" -}}
{{ if not (include "isHydrated" .) }}
{{ include "beginPreHookAsset" . }}
{{- printf "true" -}}
{{ end }}
{{- end -}}

{{- define "endPreHookConfigAsset" -}}
{{ include "endPreHookAsset" . }}
{{- end -}}

/* example: include "hasCapability" (dict "dot" . "capability" "batch/v1/CronJob") */
{{- define "hasCapability" -}}
  {{- if and (include "isHydrated" .dot) ((.dot.Values.global).hydration).capabilities -}}
    {{- if (get .dot.Values.global.hydration.capabilities .capability) -}}
      {{- printf "true" -}}
    {{- end -}}
  {{- else -}}
    {{- if .dot.Capabilities.APIVersions.Has .capability -}}
      {{- printf "true" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "getHydratedEnvVars" -}}
{{- if include "isHydrated" . -}}
EXSTREAM_SYSTEMVERSIONINFO_WAITFORSCHEMAS: "true"
EXSTREAM_SYSTEMVERSIONINFO_WAITFORUPDATERS: "true"
{{- end -}}
{{- end -}}

/** kubectl apply will choke when trying to upgrade the image for a job that already exists on an upgrade. Resolve this by giving jobs unique names. **/
/** We need a unique suffix that can be in a pod name.  Pod names are restricted to 63 lower-case alphanumeric characters plus hyphens **/
{{- define "getHookJobNameSuffix" -}}
{{- if include "isHydrated" . -}}
{{- printf "-%s" (lower (randAlphaNum 10)) -}}
{{- end -}}
{{- end -}}


/********************************************* Log level Functions *********************************************/
{{- define "configMapJavaLogLevels" -}}
LOGGING_LEVEL_COM_OPENTEXT_EXSTREAM: {{ include "digChartOrGlobalValue" (list "logging" "level" "com" "opentext" "exstream" "INFO" .Values) }}
LOGGING_LEVEL_ORG_APACHE_HTTP_WIRE: {{ include "digChartOrGlobalValue" (list "logging" "level" "org" "apache" "http" "wire" "INFO" .Values) }}
LOGGING_LEVEL_ORG_APACHE_HC_CLIENT5_HTTP_WIRE: {{ include "digChartOrGlobalValue" (list "logging" "level" "org" "apache" "hc" "client5" "http" "wire" "INFO" .Values) }}
LOGGING_LEVEL_ROOT: {{ include "digChartOrGlobalValue" (list "logging" "level" "root" "INFO" .Values) }}
{{- end -}}

{{- define "configMapNodeLogLevels" -}}
LOG_LEVEL: {{ include "digChartOrGlobalValue" (list "logging" "level" "root" "info" .Values) }}
{{- end -}}

{{- define "configMapLoggingConfig" -}}
{{- $loggingFormat := include "digChartOrGlobalValue" (list "logging" "config" "format" "" .Values) -}}
{{- if $loggingFormat -}}
{{- if and (ne $loggingFormat "ot2-gcp") (ne $loggingFormat "default") -}}
{{ fail "logging.config.format must be either 'default' or 'ot2-gcp'" }}
{{- end -}}
EXSTREAM_LOGGING_FORMAT: "{{ $loggingFormat }}"
{{ end }}
{{- end -}}

{{- define "getPodMetadataEnvVars" -}}
- name: EXSTREAM_CHART_VERSION
  value: "{{ .values.Chart.Version }}"
{{- if ((.values.Values.global).cluster).injectMetadataToPods -}}
{{- $clusterName := ((.values.Values.global).cluster).name -}}
{{- $gcpProjectId := (((.values.Values.global).cluster).gcp).projectId -}}
{{- $ot2LogName := ((((.values.Values.global).cluster).gcp).ot2).logName -}}
{{- if $clusterName }}
- name: EXSTREAM_K8S_METADTA_CLUSTER_NAME
  value: "{{ $clusterName }}"
{{- end }}
{{- if .containerName }}
- name: EXSTREAM_K8S_METADTA_CONTAINER_NAME
  value: "{{ .containerName }}"
{{- end }}
- name: EXSTREAM_K8S_METADTA_NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: EXSTREAM_K8S_METADTA_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: EXSTREAM_K8S_METADTA_POD_ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- if $gcpProjectId }}
- name: EXSTREAM_K8S_METADTA_GCP_PROJECT_ID
  value: {{ $gcpProjectId }}
{{- end }}
{{- if $ot2LogName }}
- name: EXSTREAM_K8S_METADTA_OT2_LOG_NAME
  value: {{ $ot2LogName }}
{{- end }}
{{- end -}}
{{- end -}}


/********************************************* Ingress Functions *********************************************/
{{- define "tlsCertName" -}}
{{- if .Values.global.tls.secretName -}}
{{- .Values.global.tls.secretName -}}
{{- else -}}
{{- printf "%s-cert"  (include "getExstreamReleaseName" .)  -}}
{{- end -}}
{{- end -}}

{{- define "supportsIngressClass" -}}
  {{- if or (include "hasCapability" (dict "dot" . "capability" "networking.k8s.io/v1/IngressClass")) (include "hasCapability" (dict "dot" . "capability" "networking.k8s.io/v1beta1/IngressClass")) -}}
    "true"
  {{- end -}}
{{- end -}}

{{- define "getIngressType" -}}
  {{- include "digChartOrGlobalValue" (list "ingress" "defaultAnnotationsType" "nginx" .Values) -}}
{{- end -}}

{{- define "nginxSSLAnnotations" -}}
  {{- if .Values.global.tls.enabled }}
    {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/ssl-redirect" "true" -}}
  {{- else }}
    {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/ssl-redirect" "false" -}}
  {{- end }}
{{- end -}}

{{- define "nginxBaseAnnotations" -}}
  {{- if not (include "supportsIngressClass" .) -}}
    {{- $result := set .annotationsDict "kubernetes.io/ingress.class" "nginx" -}}
  {{- end -}}
  {{- include "nginxSSLAnnotations" . }}
  {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-body-size" "0" -}}
  {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-request-buffering" "off" -}}
  {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-buffering" "off" -}}
  {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-store" "off" -}}  
  {{ if .Values.global.ot2.enabled -}}
    {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-buffer-size" "32k" -}}
  {{ end -}}  
{{- end -}}

{{- define "nginxLargeFileSupportAnnotations" -}}
  {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-connect-timeout" "240" -}}
  {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-read-timeout" "240" -}}
  {{- $result := set .annotationsDict "nginx.ingress.kubernetes.io/proxy-send-timeout" "240" -}}
{{- end -}}

{{- define "osRouteAnnotations" -}}
{{- end -}}

{{- define "osRouteLargeFileSupportAnnotations" -}}
  {{- $result := set .annotationsDict "haproxy.router.openshift.io/timeout" "240s" -}}
{{- end -}}

/* function to define ingress annotations. */
/* Call from a chart with {{ include "ingressAnnotations" . }} */
/* For charts which must support large file uploads/downloads, call with {{ include "ingressAnnotations" (dict "Values" .Values "Capabilities" .Capabilities "Chart" .Chart "largeFileSupport" "true") }} */
{{- define "ingressAnnotations" -}}
  {{- $ingressType := include "getIngressType" . -}}
  {{- $annotationsDict := dict -}}
  {{- if eq $ingressType "none" -}}
  {{- else if eq $ingressType "nginx" -}}
    {{- include "nginxBaseAnnotations" (dict "Values" .Values "Chart" .Chart "Capabilities" .Capabilities "annotationsDict" $annotationsDict "Release" .Release)  -}}
    {{- if eq "true" (include "dig" (list "largeFileSupport" "false" .)) -}}
      {{- include "nginxLargeFileSupportAnnotations" (dict "Values" .Values "Chart" .Chart "annotationsDict" $annotationsDict "Release" .Release) -}}
    {{- end -}}
  {{- else if eq $ingressType "openshiftRoute" -}}
    {{- include "osRouteAnnotations" (dict "Values" .Values "Chart" .Chart "annotationsDict" $annotationsDict) -}}
    {{- if eq "true" (include "dig" (list "largeFileSupport" "false" .)) -}}
      {{- include "osRouteLargeFileSupportAnnotations" (dict "Values" .Values "Chart" .Chart "annotationsDict" $annotationsDict) -}}
    {{- end -}}
  {{- else -}}
    {{ fail "ingress.annotations.type must be empty (defaults to nginx) or one of: none, nginx, openshiftRoute" }}
  {{- end -}}
  
  {{- $customAnnotations := include "digChartOrGlobalValue" (list "ingress" "annotations" "" .Values) -}}
  {{- if $customAnnotations -}}
    {{- $annotationsDict = mergeOverwrite $annotationsDict $annotationsDict (fromYaml $customAnnotations) -}}
  {{- end -}}

{{- range $key, $value := $annotationsDict -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{- define "ingressClassName" -}}
  {{- if include "supportsIngressClass" . -}}
    {{- if hasKey .Values.global.ingress "className" -}}
      {{- if .Values.global.ingress.className -}}
ingressClassName: {{ .Values.global.ingress.className -}}
      {{- end -}}
    {{- else -}}
      {{- $ingressType := include "getIngressType" . -}}
      {{- if eq $ingressType "none" -}}
      {{- else if eq $ingressType "nginx" -}}
ingressClassName: "nginx"
      {{- else if eq $ingressType "openshiftRoute" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{- define "getVirtualServiceGateways" -}}
  {{- if (((((.Values).global).istio).virtualService).gateways) -}}
    {{- range $gateway := $.Values.global.istio.virtualService.gateways -}}
- {{ $gateway }}
    {{ end -}}
  {{- end -}}
{{- end -}}

{{- define "getNodeSelector" -}}
{{- if .nodeSelector -}}
  nodeSelector:
  {{ .nodeSelector | toYaml }}
{{- end -}}
{{- end -}}

{{- define "getIngressServiceName" -}}

{{- if .Values.global.squid.enabled -}}
{{ .Release.Name }}-squid-service
{{- else -}}
{{- if eq .Chart.Name "rationalization" -}}
{{ .Release.Name }}-{{ .Chart.Name }}-api-service {{/* Rationalization add api to its' service name */}}
{{- else if eq .Chart.Name "design" -}}
{{ .Release.Name }}-das-service
{{- else -}}
{{ .Release.Name }}-{{ .Chart.Name }}-service
{{- end -}}
{{- end -}}

{{- end -}}

{{- define "getIngressServicePort" -}}

{{- if .Values.global.squid.enabled -}}
{{ .Values.global.squid.port }}
{{- else -}}

{{- if eq .Chart.Name "rationalization" -}}
{{ .Values.api.port }} {{/* Rationalization uses .Values.api.port */}}
{{- else -}}
{{ .Values.svc.port }}
{{- end -}}

{{- end -}}

{{- end -}}

{{- define "getIngressBackend" -}}

{{- if include "hasCapability" (dict "dot" . "capability" "networking.k8s.io/v1/Ingress") }}
service:
  name: {{ include "getIngressServiceName" . }}
  port:
    number: {{ include "getIngressServicePort" . }}
{{- else -}}
serviceName: {{ include "getIngressServiceName" . }}
servicePort: {{ include "getIngressServicePort" . }}
{{- end -}}

{{- end -}}

{{- define "getServiceFqn" -}}

{{- $releaseName := include "getExstreamReleaseName" .values }}
{{- $releaseNamespace := include "getExstreamReleaseNamespace" .values }}

{{- if eq .serviceName "rationalization" -}}
{{- printf "%s-%s-api-service.%s.svc.cluster.local" $releaseName .serviceName $releaseNamespace }}
{{- else -}}
{{- printf "%s-%s-service.%s.svc.cluster.local" $releaseName .serviceName $releaseNamespace }}
{{- end -}}

{{- end -}}

{{- define "getServiceAnnotations" -}}
  {{- $serviceAnnotationsDict := dict -}}
  {{- if (.Values.global.service).annotations -}}
    {{- $serviceAnnotationsDict = mergeOverwrite $serviceAnnotationsDict $serviceAnnotationsDict .Values.global.service.annotations -}}
  {{- end -}}
  {{- if (.Values.service).annotations -}}
    {{- $serviceAnnotationsDict = mergeOverwrite $serviceAnnotationsDict $serviceAnnotationsDict .Values.service.annotations -}}
  {{- end -}}
{{ range $key, $value := $serviceAnnotationsDict }}
{{ printf "%s: %s" (include "validateLabelOrAnnotationKey" $key) (quote (toString $value)) }}
{{ end }}
{{- end -}}


/********************************************* Secrets Functions ******************************************/

{{- define "getServiceAccount" -}}
{{- if .serviceAccountName -}}
  serviceAccountName: {{ .serviceAccountName}}
{{- end -}}
{{- end -}}

{{- define "isGcpEnabled" -}}
{{- if .Values.global.vault.url }}
{{- else if .Values.global.gcp -}}
  {{- if .Values.global.gcp.projectId -}}
    true
  {{- end }}
{{- end }}
{{- end -}}

{{- define "getVaultEnvVars" -}}
{{- if .Values.global.vault.url }}
VAULT_URI: {{ .Values.global.vault.url }}
{{- if .Values.global.vault.namespace }}
VAULT_NAMESPACE: {{ .Values.global.vault.namespace }}
{{- end }}
{{- if .Values.global.vault.token }}
VAULT_TOKEN: {{ .Values.global.vault.token }}
{{- end }}
VAULT_AUTHENTICATION: {{ default "KUBERNETES" .Values.global.vault.authentication }}
{{- if .Values.global.vault.secretEngine }}
VAULT_SECRETENGINE: {{ .Values.global.vault.secretEngine }}
{{- end }}
{{- if .Values.global.vault.secretBasePath }}
VAULT_SECRETBASEPATH: {{ .Values.global.vault.secretBasePath }}
{{- end }}
{{- if .Values.global.vault.authenticationPath }}
VAULT_KUBERNETES_KUBERNETES_PATH: {{ .Values.global.vault.authenticationPath }}
{{- end }}
VAULT_KUBERNETES_ROLE: {{ .Values.vaultRole }}
VAULT_SERVICE_NAME: {{.serviceName }}
VAULT_RELEASE: {{ include "getExstreamReleaseName" . }}
{{- else if .Values.global.gcp -}}
{{- if .Values.global.gcp.projectId -}}
GCP_PROJECT_ID: {{ .Values.global.gcp.projectId }}
GCP_RELEASE: {{ include "getExstreamReleaseName" . }}
GCP_SERVICE_NAME: {{.serviceName }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "getVaultEnvVarsInEnvVars" -}}
{{- if .Values.global.vault.url }}
- name: VAULT_URI
  value: {{ .Values.global.vault.url }}
{{- if .Values.global.vault.namespace }}
- name: VAULT_NAMESPACE
  value: {{ .Values.global.vault.namespace }}
{{- end }}
{{- if .Values.global.vault.token }}
- name: VAULT_TOKEN
  value: {{ .Values.global.vault.token }}
{{- end }}
- name: VAULT_AUTHENTICATION
  value: {{ default "KUBERNETES" .Values.global.vault.authentication }}
- name: VAULT_KUBERNETES_ROLE
  value: {{ required "Invalid vaultRole" .Values.vaultRole  }}
- name: VAULT_RELEASE
  value: {{ include "getExstreamReleaseName" . }}
{{- if .Values.global.vault.secretEngine }}
- name: VAULT_SECRETENGINE
  value: {{ .Values.global.vault.secretEngine }}
{{- end }}
{{- if .Values.global.vault.secretBasePath }}
- name: VAULT_SECRETBASEPATH
  value: {{.Values.global.vault.secretBasePath }}
{{- end }}
{{- if .Values.global.vault.authenticationPath }}
- name: VAULT_KUBERNETES_KUBERNETES_PATH
  value: {{ .Values.global.vault.authenticationPath }}
{{- end }}

{{- else if .Values.global.gcp -}}
{{- if .Values.global.gcp.projectId -}}
- name: GCP_PROJECT_ID
  value: {{ .Values.global.gcp.projectId }}
- name: GCP_RELEASE
  value: {{ include "getExstreamReleaseName" . }}
- name: GCP_SERVICE_NAME
  value: {{.serviceName }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "needOauthSecret" -}}
  {{- if (and (and (not .Values.global.vault.url) (not (.Values.global.corpvault).enabled)) (not ((.Values.global.azure).keyVault).enabled)) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "needRabbitSecret" -}}
  {{- if (and (and (not .Values.global.vault.url) (not (.Values.global.corpvault).enabled)) (not ((.Values.global.azure).keyVault).enabled)) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "needDatabaseSecret" -}}
  {{- if (and (and (not .Values.global.vault.url) (not (.Values.global.corpvault).enabled)) (not ((.Values.global.azure).keyVault).enabled)) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "needSolrSecret" -}}
  {{- if (and (and (not .Values.global.vault.url) (not (.Values.global.corpvault).enabled)) (not ((.Values.global.azure).keyVault).enabled)) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "needGcpAiSecret" -}}
  {{- if (and (and (not .Values.global.vault.url) (not (.Values.global.corpvault).enabled)) (not ((.Values.global.azure).keyVault).enabled)) -}}
    {{- printf "true" -}}
  {{- end -}}
{{- end -}}

{{- define "oauthEnvSecretsCustomNames" -}}
{{- if include "needOauthSecret" .dot }}
- name: {{ .idName }}
  valueFrom:
    secretKeyRef:
      name: {{ include "getExstreamReleaseName" .dot }}-otds-client-secret
      key: oauth2_clientId
- name: {{ .secretName }}
  valueFrom:
    secretKeyRef:
      name: {{ include "getExstreamReleaseName" .dot }}-otds-client-secret
      key: oauth2_clientSecret
{{- end }}
{{- end -}}

{{- define "oauthEnvSecrets" -}}
{{- include "oauthEnvSecretsCustomNames" (dict "dot" . "idName" "oauth2_clientId" "secretName" "oauth2_clientSecret" ) -}}
{{- end -}}

{{- define "rabbitSecrets" -}}
{{- if include "isRabbitMQUsernamePasswordRequired" . }}
- name: EXSTREAM_RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ include "getExstreamReleaseName" . }}-rabbitmq-ha{{ include "preInstallHookNameSuffix" . }}
      key: rabbitmq-username
- name: EXSTREAM_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "getExstreamReleaseName" . }}-rabbitmq-ha{{ include "preInstallHookNameSuffix" . }}
      key: rabbitmq-password
{{- end }}
{{- end -}}

{{- define "rabbitSecretsDocGen" -}}
{{- if include "isRabbitMQUsernamePasswordRequired" . }}
- name: RABBIT_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "getExstreamReleaseName" . }}-rabbitmq-ha{{ include "preInstallHookNameSuffix" . }}
      key: rabbitmq-username
- name: RABBIT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "getExstreamReleaseName" . }}-rabbitmq-ha{{ include "preInstallHookNameSuffix" . }}
      key: rabbitmq-password
{{- end }}
{{- end -}}


/********************************************* Service Functions ******************************************/

{{- define "getServiceType" -}}
{{- include "digChartOrGlobalValue" (list "svc" "type" "ClusterIP" .Values) -}}
{{- end -}}

/* see https://github.com/kubernetes/kubectl/issues/221 */
{{- define "getNodePortFix" -}}
{{- $svcType := include "getServiceType" . -}}
{{- if eq $svcType "ClusterIP" -}}
nodePort: null
{{- end -}}
{{- end -}}


/********************************************* Probe Functions *********************************************/

/* include "getProbeSetting" (dict "dot" . "probeName" "livenessProbe" "settingName" "failureThreshold" ) */
{{ define "getProbeSetting" -}}
{{- $defaultValue := include "dig" (list .probeName "default" .settingName "" .dot.Values) -}}
{{- $value := include "digChartOrGlobalValue" (list .probeName .settingName $defaultValue .dot.Values) -}}
{{- if $value -}}
{{- printf "%s: %s" .settingName $value -}}
{{- end -}}
{{- end -}}

{{- define "livenessProbeSettings" }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "livenessProbe" "settingName" "failureThreshold") }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "livenessProbe" "settingName" "initialDelaySeconds") }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "livenessProbe" "settingName" "periodSeconds") }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "livenessProbe" "settingName" "timeoutSeconds") }}
{{- end }}

{{- define "readinessProbeSettings" }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "readinessProbe" "settingName" "failureThreshold") }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "readinessProbe" "settingName" "initialDelaySeconds") }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "readinessProbe" "settingName" "periodSeconds") }}
{{ include "getProbeSetting" (dict "dot" . "probeName" "readinessProbe" "settingName" "timeoutSeconds") }}
{{- end }}


/********************************************* Misc Functions *********************************************/

{{- define "namespaceValue" -}}
{{- if .Values.global.namespace -}}
{{- printf .Values.global.namespace -}}
{{- else -}}
{{- printf .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{- define "namespaceMetadata" -}}
{{- if or .Values.global.namespace (and .Values.global.ot2.enabled (include "isHydrated" .)) }}
namespace: {{ include "namespaceValue" . }}
{{- end }}
{{- end -}}

/* validate that the passed label is a valid K8s label. */
/* return the passed label if valid */
/* fail with cause if invalid */
{{- define "validateLabelValue" -}}
{{- $validCharacters := ( regexMatch "^(([a-zA-Z0-9]([-a-zA-Z0-9_.]*)?[a-zA-Z0-9]))?$" . ) -}}
{{- $validLength := le (len .) 63 -}}
{{- if $validLength -}}
  {{- if gt (len .) 0 -}}
    {{- if not $validCharacters -}}
      {{ fail (println "The specified label value has invalid characters : " .) }}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{ fail (println "The specified label value does not have a valid length (max 63 characters) : " .) }}
{{- end -}}
{{- print . -}}
{{- end -}}

/* validate that the passed key is a valid K8s key. */
/* return the passed key if valid */
/* fail with cause if invalid */
{{- define "validateLabelOrAnnotationKey" -}}
{{ $nameSegment := "" -}}
{{- if contains "/" . -}}
  {{ $nameSegment = index (regexSplit "/" . -1) 1 }}
{{- else -}}
  {{- $nameSegment = . -}}
{{- end -}}
{{- $validCharacters := ( regexMatch "^([a-zA-Z0-9]([-a-zA-Z0-9_.]*)?[a-zA-Z0-9])$" $nameSegment ) -}}
{{- $validLength := (gt (len $nameSegment) 0) -}}
{{- if $validLength -}}
  {{- if not $validCharacters -}}
    {{ fail (println "The specified key has invalid characters : " .) }}
  {{- end -}}
{{- else -}}
  {{ fail (println "The specified key does not have a valid length (min 1 max 63 characters) : " .) }}
{{- end -}}
{{- print . -}}
{{- end -}}

{{- define "getJavaVersionLabels" -}}
  {{- if (.Values.versions).jdkVersion }}
{{ printf "app.framework/openjdk: %s" (quote (include "validateLabelValue" (toString .Values.versions.jdkVersion))) }}
  {{- end }}
  {{- if (.Values.versions).springBootVersion }}
{{ printf "app.framework/spring-boot: %s" (quote (include "validateLabelValue" (toString .Values.versions.springBootVersion))) }}
  {{- end }}
{{- end -}}

{{/*
Insert additional labels for resources.
Additional labels can be global, global by resource type, sub-chart, or sub-chart by resource type.

@param .dot      		The root scope
@param .typeLabel 		The resource type key used for resource type specific labels
@param .keyName         The key for the custom attribute. Can be extraResourceLabels or extraPodMatchLabels.
@param .defaultExtras   Extras to always add.
*/}}
{{- define "getExtraLabelKeyValues" -}}
{{- $typeLabel := .typeLabel -}}
{{- $keyName := .keyName -}}
{{- $extraLabels := (default (dict) .defaultExtras) -}}
{{- if .dot.Values.global -}}
  {{/* support global level labels */}}
  {{- if (hasKey .dot.Values.global $keyName) -}}
    {{- $extraLabels = mergeOverwrite $extraLabels (get .dot.Values.global $keyName) -}}
  {{- end -}}
  {{/* support global level by type labels */}}
  {{- if $typeLabel -}}
    {{- $globalTypeValues := index .dot.Values.global $typeLabel -}}
    {{- if $globalTypeValues -}}
      {{- $globalTypeLabels := index $globalTypeValues $keyName -}}
      {{- if $globalTypeLabels -}}
        {{- $extraLabels = mergeOverwrite $extraLabels $globalTypeLabels -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* support subchart level labels */}}
{{- if (hasKey .dot.Values $keyName) -}}
  {{- $extraLabels = mergeOverwrite $extraLabels (get .dot.Values $keyName) -}}
{{- end -}}
{{/* support subchart level by type labels */}}
{{- if $typeLabel -}}
  {{- $subchartTypeValues := index .dot.Values $typeLabel -}}
  {{- if $subchartTypeValues -}}
    {{- $subchartTypeLabels := index $subchartTypeValues $keyName -}}
    {{- if $subchartTypeLabels -}}
      {{- $extraLabels = mergeOverwrite $extraLabels $subchartTypeLabels -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{ range $key, $value := $extraLabels -}}
{{ printf "%s: %s" (include "validateLabelOrAnnotationKey" $key) (quote (include "validateLabelValue" (toString $value))) }}
{{ end -}}
{{ end -}}

{{- define "getExtraResourceLabels" -}}
{{- $defaultExtras := dict "app.kubernetes.io/managed-by" "Helm" "app.kubernetes.io/name" .dot.Chart.Name "app.kubernetes.io/part-of" .dot.Release.Name "app.kubernetes.io/version" (.dot.Chart.Version | replace "+" "_") -}}
{{- $_ := set . "keyName" "extraResourceLabels" -}}
{{- $_ := set . "defaultExtras" $defaultExtras -}}
{{ include "getExtraLabelKeyValues" . -}}
{{ end -}}

{{- define "getExtraPodMatchLabels" -}}
{{- $_ := set . "keyName" "extraPodMatchLabels" -}}
{{ include "getExtraLabelKeyValues" . -}}
{{ end -}}

{{/*
Insert additional annotations for resources.
Additional annotations can be global, global by resource type, sub-chart, or sub-chart by resource type.

@param .dot      		The root scope
@param .typeLabel 		The resource type key used for resource type specific annotations
*/}}
{{- define "getExtraResourceAnnotations" -}}
{{- $typeLabel := .typeLabel -}}
{{- $extraAnnotations := (dict) -}}
{{- if .dot.Values.global -}}
  {{/* backwards compatibility, support Values.global.extraPodAnnotations for backwards compatibility */}}
  {{- if eq $typeLabel "pod" -}}
    {{- if .dot.Values.global.extraPodAnnotations -}}
	  {{- $extraAnnotations = mergeOverwrite $extraAnnotations .dot.Values.global.extraPodAnnotations -}}
	{{- end -}}
  {{- end -}}
  {{/* support global level annotations */}}
  {{- if .dot.Values.global.extraResourceAnnotations -}}
    {{- $extraAnnotations = mergeOverwrite $extraAnnotations .dot.Values.global.extraResourceAnnotations -}}
  {{- end -}}
  {{/* support global level by type annotations */}}
  {{- $globalTypeValues := index .dot.Values.global $typeLabel -}}
  {{- if $globalTypeValues -}}
    {{- $globalTypeAnnotations := index $globalTypeValues "extraResourceAnnotations" -}}
    {{- if $globalTypeAnnotations -}}
      {{- $extraAnnotations = mergeOverwrite $extraAnnotations $globalTypeAnnotations -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* support subchart level annotations */}}
{{- if .dot.Values.extraResourceAnnotations -}}
  {{- $extraAnnotations = mergeOverwrite $extraAnnotations .dot.Values.extraResourceAnnotations -}}
{{- end -}}
{{/* support subchart level by type annotations */}}
{{- $subchartTypeValues := index .dot.Values $typeLabel -}}
{{- if $subchartTypeValues -}}
  {{- $subchartTypeAnnotations := index $subchartTypeValues "extraResourceAnnotations" -}}
  {{- if $subchartTypeAnnotations -}}
    {{- $extraAnnotations = mergeOverwrite $extraAnnotations $subchartTypeAnnotations -}}
  {{- end -}}
{{- end -}}
{{ range $key, $value := $extraAnnotations -}}
{{ printf "%s: %s" (include "validateLabelOrAnnotationKey" $key) (quote (toString $value)) }}
{{ end -}}
{{ end -}}


{{- define "otdsClientChecksum" -}}
{{- if include "needOauthSecret" . }}
checksum/otds-client-secret: {{ include (print "exstream/templates/otds-client-secret.yaml") . | sha256sum }}
{{- end }}
{{- end -}}

{{- define "convertCpuResourceToNumber" -}}
  {{- $cpu := 1 -}}
  {{- if not (eq (typeOf .cpu) "string") -}}
    {{ $cpu = .cpu }}
  {{- else if not (hasSuffix "m" .cpu) -}}
    {{ $cpu = float64 .cpu }}
  {{- else -}}
    {{ $cpu = (div (float64 (trimSuffix "m" .cpu)) 1000) }}
  {{- end -}}
  {{ max 1 $cpu }}
{{- end -}}

/** A user can configure the maximum number of concurrent engines in an ondemand pod. **/
/** --set ondemand.maxConcurrentEngineProcesses=INTEGER      if specified, ondemand will run no more than this number of concurrent engines. **/
/** if maxConcurrentEngineProcesses is not set, we fall through to the ondemand cpu limit **/
/** --set ondemand.resources.ondemand.limits.cpu=NUMBER     if specified, ondemand will run no more than floor(NUMBER), but at least 1, engines **/
/** If number is specified in millcores (e.g. cpu=1500m), then NUMBER is first divided by 1000. **/
/** if maxConcurrentEngineProcesses and limits.cpu are not specified, then we default to 4 concurrent engines per ondemand pod. **/
/** The above will return "value" if .Values.key1.key2==value, or "defaultValue" if key1 or key2 dne **/
{{- define "getMaxConcurrentOndemandEngines" -}}
  {{- if .Values.maxConcurrentEngineProcesses -}}
    {{ .Values.maxConcurrentEngineProcesses }}
  {{- else if ((((.Values).resources).ondemand).limits).cpu -}}
    {{- $cpu := include "convertCpuResourceToNumber" (dict "cpu" .Values.resources.ondemand.limits.cpu) -}}
	{{ float64 $cpu }}
  {{- else -}}
    4
  {{- end -}}
{{- end -}}


{{- define "getDefaultSecurityContextProperties" -}}
capabilities:
  drop:
  - NET_RAW
  - ALL
runAsNonRoot: true
allowPrivilegeEscalation: false
{{- end -}}

{{- define "getAzureKeyVaultProperties" -}}
{{- if .Values.global.azure.keyVault.enabled -}}
- name: AZURE_VAULT_VAULTURL
  value: {{ required "Key Vault URL is required" .Values.global.azure.keyVault.vaultUrl }}
- name: AZURE_VAULT_SECRETBASEPATH
{{- if .Values.global.azure.keyVault.secretBasePath }}
  value: {{ .Values.global.azure.keyVault.secretBasePath }}
{{- end }}
- name: AZURE_VAULT_RELEASE
{{- if .Values.global.azure.keyVault.release }}
  value: {{ .Values.global.azure.keyVault.release }}
{{- end }}
- name: AZURE_VAULT_SERVICE_NAME
  value: {{ required "service name is required" .Chart.Name }}
{{ end }}
{{- end -}}

{{/*
# Set the strategy used by Deployments to replace old Pods with new ones.
# ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
*/}}
{{- define "deployment.strategy" -}}
type: {{ .Values.updateStrategy }}
{{- if eq .Values.updateStrategy "RollingUpdate" }}
  {{- include "deployment.rollingUpdate" . }}
{{- end }}
{{- end }}

{{/*
# Optionally set maxUnavailable/maxSurge for Deployments that use a RollingUpdate
# strategy.
# - Parsing these values is tricky because Helm treats 0 and "0" differently,
#   but there's a hacky way to get around it: https://github.com/helm/helm/issues/3164
# - Per the Kubernetes documentation, maxUnavailable and maxSurge cannot both be
#   set to 0. If the user tries to do that we fail during templating.
*/}}
{{- define "deployment.rollingUpdate" -}}
{{- $maxUnavailable := ((.Values).rollingUpdate).maxUnavailable }}
{{- $maxSurge := ((.Values).rollingUpdate).maxSurge }}
{{- if or (has (kindOf $maxUnavailable) (list "string" "int" "int64" "float" "float64")) (has (kindOf $maxSurge) (list "string" "int" "int64" "float" "float64")) }}
rollingUpdate:
  {{- if and (eq ($maxUnavailable | toString) "0") (eq ($maxSurge| toString) "0") }}
    {{- fail "rollingUpdate.maxUnavailable and rollingUpdate.maxSurge cannot both be set to 0" }}
  {{- end }}
  {{- if (has (kindOf $maxUnavailable) (list "string" "int" "int64" "float" "float64")) }}
  maxUnavailable: {{ $maxUnavailable }}
  {{- end }}
  {{- if (has (kindOf $maxSurge) (list "string" "int" "int64" "float" "float64")) }}
  maxSurge: {{ $maxSurge }}
  {{- end }}
{{- end }}
{{- end }}

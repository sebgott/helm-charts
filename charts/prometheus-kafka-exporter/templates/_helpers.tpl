{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "prometheus-kafka-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "prometheus-kafka-exporter.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "prometheus-kafka-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "prometheus-kafka-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "prometheus-kafka-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "rbac.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}} 

{{/*
Create the name of the SASL SCRAM secret to use
*/}}
{{- define "prometheus-kafka-exporter.saslScramSecretName" -}}
{{- if .Values.sasl.scram.secretName -}}
    {{ .Values.sasl.scram.secretName }}
{{- else -}}
    {{ include "prometheus-kafka-exporter.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the SASL OAUTHBEARER client credentials secret to use
*/}}
{{- define "prometheus-kafka-exporter.saslOAuthBearerSecretName" -}}
{{- if .Values.sasl.oauthbearer.secretName -}}
    {{ .Values.sasl.oauthbearer.secretName }}
{{- else -}}
    {{ printf "%s-oauthbearer" (include "prometheus-kafka-exporter.fullname" . | trunc 51 | trimSuffix "-") }}
{{- end -}}
{{- end -}}

{{/*
Whether SASL OAUTHBEARER uses the client credentials flow (token URL) rather than a token file
*/}}
{{- define "prometheus-kafka-exporter.saslOAuthBearerClientCredentials" -}}
{{- $o := .Values.sasl.oauthbearer -}}
{{- if and .Values.sasl.enabled $o.enabled (not $o.serviceAccountToken.enabled) (not $o.tokenFile) $o.tokenUrl -}}
true
{{- end -}}
{{- end -}}

{{/*
Validate SASL OAUTHBEARER values
*/}}
{{- define "prometheus-kafka-exporter.validateSaslOAuthBearer" -}}
{{- $o := .Values.sasl.oauthbearer -}}
{{- if $o.enabled -}}
  {{- if not .Values.sasl.enabled -}}
    {{- fail "sasl.oauthbearer.enabled requires sasl.enabled to be true" -}}
  {{- end -}}
  {{- if or .Values.sasl.scram.enabled .Values.sasl.awsiam.enabled .Values.sasl.kerberos.enabled -}}
    {{- fail "sasl.oauthbearer cannot be combined with sasl.scram, sasl.awsiam or sasl.kerberos" -}}
  {{- end -}}
  {{- if not (or $o.serviceAccountToken.enabled $o.tokenFile $o.tokenUrl) -}}
    {{- fail "sasl.oauthbearer requires one of sasl.oauthbearer.serviceAccountToken.enabled, sasl.oauthbearer.tokenFile or sasl.oauthbearer.tokenUrl" -}}
  {{- end -}}
  {{- if and (include "prometheus-kafka-exporter.saslOAuthBearerClientCredentials" .) (not $o.secretName) (not $o.clientId) -}}
    {{- fail "sasl.oauthbearer.tokenUrl requires sasl.oauthbearer.clientId or sasl.oauthbearer.secretName" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Formats imagePullSecrets. Input is (dict "Values" .Values "imagePullSecrets" .{specific imagePullSecrets})
*/}}
{{- define "prometheus-kafka-exporter.imagePullSecrets" -}}
{{- range (concat .Values.global.imagePullSecrets .imagePullSecrets) }}
  {{- if eq (typeOf .) "map[string]interface {}" }}
- {{ toYaml . | trim }}
  {{- else }}
- name: {{ . }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Adds kafka cluster server label to prometheus metrics
*/}}
{{- define "prometheus-kafka-exporter.kafkaLabels" -}}
{{- if .Values.kafkaLabels }}
  {{- $kafkaLabelsList := list }}
  {{- range $key, $value := .Values.kafkaLabels }}
    {{- $kafkaLabelsList = append $kafkaLabelsList (printf "%s=%s" $key $value) }}
  {{- end }}
  {{- $kafkaLabelsArgs := join "," $kafkaLabelsList }}
  {{- $kafkaLabelsArgs -}}
{{- end -}}
{{- end -}}

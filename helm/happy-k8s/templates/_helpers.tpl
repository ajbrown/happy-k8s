{{/*
Expand the name of the chart.
*/}}
{{- define "happy-k8s.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "happy-k8s.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "happy-k8s.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "happy-k8s.labels" -}}
helm.sh/chart: {{ include "happy-k8s.chart" . }}
{{ include "happy-k8s.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "happy-k8s.selectorLabels" -}}
app.kubernetes.io/name: {{ include "happy-k8s.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "happy-k8s.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "happy-k8s.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the credentials secret
*/}}
{{- define "happy-k8s.credentialsSecretName" -}}
{{- printf "%s-credentials" (include "happy-k8s.fullname" .) }}
{{- end }}

{{/*
Create the name of the env secret
*/}}
{{- define "happy-k8s.envSecretName" -}}
{{- printf "%s-env" (include "happy-k8s.fullname" .) }}
{{- end }}

{{/*
Create the name of the configmap
*/}}
{{- define "happy-k8s.configMapName" -}}
{{- printf "%s-config" (include "happy-k8s.fullname" .) }}
{{- end }}

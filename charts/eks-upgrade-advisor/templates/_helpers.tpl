{{/*
Expand the name of the chart.
*/}}
{{- define "eks-upgrade-advisor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "eks-upgrade-advisor.fullname" -}}
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
Create chart label.
*/}}
{{- define "eks-upgrade-advisor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "eks-upgrade-advisor.labels" -}}
helm.sh/chart: {{ include "eks-upgrade-advisor.chart" . }}
{{ include "eks-upgrade-advisor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "eks-upgrade-advisor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "eks-upgrade-advisor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "eks-upgrade-advisor.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "eks-upgrade-advisor.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Copilot CLI token Secret name.
*/}}
{{- define "eks-upgrade-advisor.copilotSecretName" -}}
{{- .Values.secrets.copilotCli.existingSecret | default (printf "%s-copilot-cli" (include "eks-upgrade-advisor.fullname" .)) }}
{{- end }}

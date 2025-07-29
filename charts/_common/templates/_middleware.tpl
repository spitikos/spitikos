{{/*
Define the common middleware resource.
*/}}
{{- define "common.middleware" -}}
{{- if .Values.ingress.enabled -}}
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: {{ include "common.fullname" . }}-middleware
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  stripPrefix:
    prefixes:
      - {{ .Values.ingress.path }}
{{- end }}
{{- end -}}

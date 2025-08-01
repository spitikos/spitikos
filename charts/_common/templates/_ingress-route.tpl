{{/*
Define the common ingress-route resource.
*/}}
{{- define "common.ingress-route" -}}
{{- if .Values.ingress.enabled -}}
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ include "common.fullname" . }}-ingress-route
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`{{ .Values.ingress.host }}`) && PathPrefix(`{{ .Values.ingress.path }}`)
      kind: Rule
      services:
        - name: {{ include "common.fullname" . }}
          port: {{ .Values.service.port }}
      middlewares:
        - name: {{ include "common.fullname" . }}-middleware
          namespace: {{ .Release.Namespace }}
{{- end }}
{{- end -}}

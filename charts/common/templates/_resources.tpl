{{/*
Define the common deployment resource.
*/}}
{{- define "common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}-deployment
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ include "common.fullname" . }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
{{- end -}}

{{/*
Define the common service resource.
*/}}
{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}-service
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
{{- end -}}

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
        - name: {{ include "common.fullname" . }}-service
          port: {{ .Values.service.port }}
      middlewares:
        - name: {{ include "common.fullname" . }}-middleware
          namespace: {{ .Release.Namespace }}
{{- end }}
{{- end -}}

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

.PHONY: ssh
ssh:
	ssh ethantlee@pi.local

.PHONY: apply
apply:
	kubectl apply -f apps/$(APP)


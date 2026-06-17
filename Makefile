.PHONY: help deploy reboot-game

help:
	@echo "Available targets:"
	@echo "  make deploy       - Deploy the main service using Kamal"
	@echo "  make reboot-game  - Reboot the SSH game accessory to apply changes/updates"

deploy:
	kamal deploy -c ssh_service/config/deploy.yml

reboot-game:
	kamal accessory reboot game -c ssh_service/config/deploy.yml

CONFIG_FILE := mongod-rs0-1.conf mongod-rs0-2.conf mongod-rs0-3.conf

spin-up: 
	@for file in $(CONFIG_FILE); do \
		if [ -f "$$file" ]; then \
			sudo mongod --config $$file --fork
		else \
			echo "File not found: $$file (creating it)"; \
			touch "$$file"; \
		fi; \
	done
	echo "Provision all MongoDB database"

kill-all:
	ps aux | grep mongod | grep -v grep | awk '{print $2}' | xargs kill -9
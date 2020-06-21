DOCKER != which docker 2>/dev/null || echo docker
COMPOSER = $(DOCKER) run \
  --rm -it \
  -v $$PWD:/app \
  -v $${COMPOSER_HOME:-$$HOME/.composer}:/tmp \
  --volume $$SSH_AUTH_SOCK:/ssh-auth.sock \
  --env SSH_AUTH_SOCK=/ssh-auth.sock \
  --user $$(id -u):$$(id -g) \
  composer

IMAGE=johmanx10/feed
ENTRYPOINT=$$PWD/entrypoint

define assert_program_exists
	@if ! [ -x "$(shell readlink -f $(1))" ]; then \
		echo "Please install $(shell basename $(1))!"; \
		echo "See: $(2)"; \
		echo ""; \
		echo "The following verifies your installation:" \
		echo '    [ -x "$$(sh -c "which $(shell basename $(1))")" ] && echo Installed!;' \
		echo ""; \
		exit 1; \
	fi
endef

# Docker
$(DOCKER):
	$(call assert_program_exists,$(DOCKER),https://docs.docker.com/get-docker/)

build-image: $(DOCKER) $(ENTRYPOINT)
ifndef VERSION
	@: $(eval VERSION != read -p "Version: " version && echo "$$$$version";);
endif
	@if ! $(DOCKER) image ls "$(IMAGE)" --filter label=version="$(VERSION)" \
		| grep -q "$(VERSION)"; \
	then \
		$(DOCKER) build \
			--label version="$(VERSION)" \
			--tag "$(IMAGE):$(VERSION)" \
			.; \
	fi

promote-image: $(DOCKER)
ifndef VERSION
	@: $(eval VERSION != read -p "Version: " version && echo "$$$$version";);
endif
	@$(DOCKER) push $(IMAGE):$(VERSION);

# PHP dependencies
composer.json: $(DOCKER)
	@$(COMPOSER) init \
		--name johmanx10/feed \
		--description "Feed parser and emitter" \
		--author "Jan-Marten de Boer <github@johmanx.com>" \
		--type project \
		--license MIT \
		--require php:^7.4 \
		--require ext-json:* \
		--require ext-libxml:* \
		--require lib-libxml:* \
		--require justinrainbow/json-schema:@stable \
		--require mtdowling/jmespath.php:@stable \
		--no-interaction;

composer.lock: vendor/autoload.php vendor/composer/installed.json
vendor/autoload.php: composer.json
	@$(COMPOSER) install --no-dev --no-scripts --optimize-autoloader;

$(ENTRYPOINT): composer.lock

update-composer: composer.json $(DOCKER)
	@$(COMPOSER) update --no-dev --no-scripts --optimize-autoloader;

# Install the application.
install: composer.lock

# Update the application.
update: update-composer

# Build the application
build: install build-image

# Promote the application.
promote: build promote-image

# Test the application
test: $(DOCKER)
	@$(DOCKER) run -v $$PWD/feeds:/feeds $(IMAGE):$(VERSION)

test-entrypoint: $(ENTRYPOINT)
	@FEED_PATTERN=$$PWD/feeds/*.json $(ENTRYPOINT)

# Clean the project.
clean:
	@rm -f composer.*;
	@rm -rf vendor;
	@rm -rf cache;

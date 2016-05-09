.PHONY: tests, release

tests:
	pushd src && APP_ENV=test go test $$(glide novendor) && popd

release:
	chmod 755 ./news-frameworks/scripts/tag-by-cosmos-release.sh
	$(shell ./news-frameworks/scripts/tag-by-cosmos-release.sh mozart-requester)

lock_local_config:
	git update-index --assume-unchanged ./src/config/cosmos.json

unlock_local_config:
	git update-index --no-assume-unchanged ./src/config/cosmos.json

stash_pop:
	git stash pop

stash:
	git stash

rebase: stash
	git rebase -i master

rebase_master: | unlock_local_config rebase stash_pop lock_local_config
	# the pipe is used to enforce order in case user tries using -j (parallel jobs) flag

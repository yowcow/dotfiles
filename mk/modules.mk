_modules/%:
	mkdir -p $(@D)
	[ -d $@ ] || git clone \
		--recurse-submodules \
		git@$$(echo $* | sed -e 's|/|:|') \
		$@

update/_modules/%: FORCE $(HOME)/.gitconfig _modules/%
	git -C _modules/$* pull \
		&& git -C _modules/$* submodule sync --recursive \
		&& git -C _modules/$* submodule update --init --recursive

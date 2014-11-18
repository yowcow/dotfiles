all: update-submodule create-symlinks

CURRENT_PATH := $(shell pwd)

update-submodule:
	git submodule update --init

create-symlinks:
	cd ~/ && rm -f .vimrc && ln -s $(CURRENT_PATH)/vimrc .vimrc;
	cd ~/ && rm -f .zshrc && ln -s $(CURRENT_PATH)/zshrc .zshrc;
	cd ~/ && rm -f .screenrc && ln -s $(CURRENT_PATH)/screenrc .screenrc;
	mkdir -p ~/.vim && cd ~/.vim && rm vundle && ln -s $(CURRENT_PATH)/vundle;

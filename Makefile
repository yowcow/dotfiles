all: update-submodule

install: create-symlinks

CURRENT_PATH := $(shell pwd)

update-submodule:
	git submodule update --init

create-symlinks:
	cd ~/ && rm -f .vimrc && ln -s $(CURRENT_PATH)/vimrc .vimrc;
	cd ~/ && rm -f .zshrc && ln -s $(CURRENT_PATH)/zshrc .zshrc;
	cd ~/ && rm -f .screenrc && ln -s $(CURRENT_PATH)/screenrc .screenrc;
	cd ~/ && rm -f .perltidyrc && ln -s $(CURRENT_PATH)/perltidyrc .perltidyrc;
	cd ~/ && rm -f .tmux.conf && ln -s $(CURRENT_PATH)/tmux.conf .tmux.conf;
	cd ~/ && rm -f .ocamlinit && ln -s $(CURRENT_PATH)/ocamlinit .ocamlinit;
	mkdir -p ~/.vim && cd ~/.vim && rm -f vundle && ln -s $(CURRENT_PATH)/vundle;

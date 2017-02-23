.PHONY: install install-ncurses clean

LOCAL := $(HOME)/local
BUILD := build

NCURSES_VER := 6.0
LIBEVENT_VER := 2.1.8-stable
TMUX_VER := 2.3
VIM_VER := 8.0.0348

all: $(BUILD) $(BUILD)/ncurses-$(NCURSES_VER).tar.gz $(BUILD)/libevent-$(LIBEVENT_VER).tar.gz $(BUILD)/tmux-$(TMUX_VER).tar.gz $(BUILD)/v$(VIM_VER).tar.gz

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/ncurses-$(NCURSES_VER).tar.gz:
	curl -L http://ftp.gnu.org/gnu/ncurses/ncurses-$(NCURSES_VER).tar.gz -o $@

$(BUILD)/libevent-$(LIBEVENT_VER).tar.gz:
	curl -L https://github.com/libevent/libevent/releases/download/release-$(LIBEVENT_VER)/libevent-$(LIBEVENT_VER).tar.gz -o $@

$(BUILD)/tmux-$(TMUX_VER).tar.gz:
	curl -L https://github.com/tmux/tmux/releases/download/$(TMUX_VER)/tmux-$(TMUX_VER).tar.gz -o $@

$(BUILD)/v$(VIM_VER).tar.gz:
	curl -L https://github.com/vim/vim/archive/v$(VIM_VER).tar.gz -o $@

install: $(LOCAL) install-ncurses install-libevent install-vim install-tmux

$(LOCAL):
	mkdir -p $(LOCAL)

install-ncurses:
	cd $(BUILD) && tar xzf ncurses-$(NCURSES_VER).tar.gz
	cd $(BUILD)/ncurses-$(NCURSES_VER) && \
	./configure --prefix $(LOCAL) && \
	make && make install

install-libevent:
	cd $(BUILD) && tar xzf libevent-$(LIBEVENT_VER).tar.gz
	cd $(BUILD)/libevent-$(LIBEVENT_VER) && \
	./configure --prefix $(LOCAL) && \
	make && make install

install-tmux:
	cd $(BUILD) && tar xzf tmux-$(TMUX_VER).tar.gz
	cd $(BUILD)/tmux-$(TMUX_VER) && \
	LDFLAGS="-L$(LOCAL)/lib" CFLAGS="-I$(LOCAL)/include -I$(LOCAL)/include/ncurses" ./configure --prefix $(LOCAL) && \
	make && make install

install-vim:
	cd $(BUILD) && tar xzf v$(VIM_VER).tar.gz
	cd $(BUILD)/vim-$(VIM_VER) && \
	./configure --with-local-dir=$(LOCAL) --prefix=$(LOCAL) && \
	make && make install

clean:
	rm -rf $(BUILD)

curl -LO http://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz
curl -LO https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
curl -LO https://github.com/tmux/tmux/releases/download/2.3/tmux-2.3.tar.gz

# ncurses
tar xzf ncurses-6.0.tar.gz && \
  cd ncurses-6.0 && \
  ./configure --prefix $HOME/local && \
  make && make install && \
  cd ..

# libevent
tar xzf libevent-2.1.8-stable.tar.gz && \
  cd libevent-2.1.8-stable && \
  ./configure --prefix $HOME/local && \
  make && make install && \
  cd ..

# vim
git clone https://github.com/vim/vim.git && \
    cd vim && \
    ./configure --with-local-dir $HOME/local --prefix $HOME/local && \
    make && make install && \
    cd ..

# tmux
tar xzf tmux-2.3.tar.gz && \
  cd tmux-2.3 && \
  LDFLAGS="-L$HOME/local/lib" CFLAGS="-I$HOME/local/include -I$HOME/local/include/ncurses" ./configure --prefix ~/local && \
  make && make install && \
  cd ..

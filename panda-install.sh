ITEMS=( \
    Algorithm::BloomFilter \
    App::Mi6 \
    Compress::Zlib \
    Digest::MurmurHash3 \
    Digest::SHA \
    HTTP::UserAgent \
    IO::Socket::SSL \
    LibraryCheck \
    LibraryMake \
    Linenoise \
    p6doc \
    Task::Star \
    Test::META \
    String::CamelCase \
    WebService::SOP \
)

for item in ${ITEMS[@]}; do
    echo "Installing ${item}";
    panda --notests install ${item};
done;

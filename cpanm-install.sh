#!/bin/bash

cpanm -n \
    AnyEvent \
    App::cpanoutdated \
    Carton \
    common::sense \
    EV \
    ExtUtils::MakeMaker \
    JSON::XS \
    Log::Dispatch::CronoDir \
    Log::Dispatch::Pipe \
    Log::Log4perl \
    LWP::UserAgent \
    LWP::Protocol::https \
    Minilla \
    Mojolicious \
    MojoX::Log::Log4perl::Tiny \
    MojoX::Renderer::JSON::XS \
    MojoX::Session::Simple \
    Parallel::Prefork \
    Perl::Tidy \
    Plack \
    Starlet \
    String::CamelCase \
    String::Random \
    Test::CPAN::Meta \
    Test::Deep \
    Test::Exception \
    Test::MinimumVersion::Fast \
    Test::Mock::Guard \
    Test::More \
    Test::PAUSE::Permissions \
    Test::Pod \
    Test::Spellunker \
    Test::Stub \
    Time::Piece \
    TOML::Parser \
    WebService::SOP::Auth::V1_1

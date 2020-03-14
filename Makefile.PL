use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Telegram::Bot',
    VERSION_FROM => 'lib/Telegram/Bot.pm',
    AUTHOR       => 'Antonio Lassandro (lassandroan@gmail.com)',
    ABSTRACT     => 'Perl interface for the Telegram Bot API',
    PREREQ_PM    => {
                     'IO::Socket::SSL' => 2.067,
                     'Net::SSLeay'     => 1.88,
                     'LWP::UserAgent'  => 6.43,
                     'JSON'            => 4.02,
                    },
    LICENSE      => 'perl_5'
);

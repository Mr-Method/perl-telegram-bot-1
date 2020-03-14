package Telegram::Bot;

use v5.10;
use strict;
use warnings;

use Encode qw(encode decode);
use JSON;
use LWP::UserAgent;

binmode STDOUT, ":utf8";

our $VERSION  = "1.0.0";

my $agent = LWP::UserAgent->new();
$agent->agent("$0/$VERSION" . $agent->agent);

sub new {
    my $class    = shift;
    my $token    = shift or die "Missing token";

    return bless {
        token       => $token,
        quit        => 0,
        contenttype => "application/json",
    }, $class;
}

sub run {
    my $self      = shift;
    my $commands  = shift or die "Missing commands";
    my $offset    = -1;
    my $callbacks = {};

    # Get initial message offset, if applicable
    {
        my $res = $self->getupdates(
            offset          => $offset,
            timeout         => 1,
            allowed_updates => ["message"]
        );

        if ($res->{result}) {
            $offset = @{$res->{result}}[0]->{update_id} + 1;
        }
    }

    while (not $self->{quit}) {
        # TODO (02/23/20): Configurable getUpdates() parameters
        my $res = $self->getupdates(
            offset          => $offset,
            timeout         => 1,
            allowed_updates => ["message"]
        );

        foreach my $msg (@{$res->{result}}) {
            $offset = $msg->{update_id} + 1;

            my $callback;
            my $chat_id = $msg->{message}{chat}{id};
            my $user_id = $msg->{message}{from}{id};

            if (my $current_callback = $callbacks->{$chat_id}{$user_id}) {
                $callback = $current_callback->($self, $msg->{message});
            } else {
                # TODO (02/23/20): Allow non-command messages? We would need this
                #                  anyway for non-message updates
                $msg->{message}{text} =~ /^\/([^\s]+)/;
                next if not $1 or not $commands->{$1};

                $callback = $commands->{$1}->($self, $msg->{message});
            }

            if ($callback) {
                $callbacks->{$chat_id}{$user_id} = $callback;
            } else {
                delete $callbacks->{$chat_id}{$user_id};
            }
        }
    }
}


sub AUTOLOAD {
    my $self        =  shift;
    (our $AUTOLOAD) =~ s/.*:://gms;

    my $res = $agent->post(
        "https://api.telegram.org/bot" . $self->{token} . "/" . $AUTOLOAD,
        Content_Type => $self->{contenttype},
        Content      => (
            $self->{contenttype} =~ "application/json"
                ? JSON::encode_json({@_})
                : {@_}
        )
    );

    return JSON::decode_json($res->decoded_content);
}

1;

__END__

=head1 NAME

Telegram::Bot - Perl interface for the Telegram Bot API

=head1 VERSION

Version 1.0.0

=head1 SYNOPSIS

    use Telegram::Bot;

    Telegram::Bot->new($api_token)->run(%commands);

=head1 DESCRIPTION

Telegram::Bot provides a very simple, yet powerful, wrapper for creating quick
Telegram chat bots.

=head1 DEPENDENCIES

=over 4

=item * IO::Socket::SSL (2.067+)
=item * NET::SSLeay (1.88+)
=item * LWP::UserAgent (6.43+)
=item * JSON (4.02+)

=back

=head1 INSTALLATION

    perl Makefile.PL
    make test
    sudo make install

=head1 METHODS

Telegram::Bot employs the following methods:

=head2 AUTOLOAD

This module uses Perl's AUTOLOAD feature to allow Telegram API methods to be
called directly on the bot:

    $bot->getMe();
    $bot->sendMessage(chat_id => ..., text => 'Hello world!');

Available API methods are listed on
L<Telegram's Bot API documenation|https://core.telegram.org/bots/api>.

Because Telegram's API is case insensitive, you may use any form of
capitalization when calling AUTOLOAD methods.

=head2 new

    my $api_token = "...";
    my $bot = Telegram::Bot->new($api_token);

A bot can be created by simply providing an
L<API token|https://core.telegram.org/bots/api#authorizing-your-bot>.

=head2 run

    sub greet {
        my $self = shift;
        my $msg  = shift;

        $self->sendmessage(
            chat_id => $msg->{chat}{id},
            text=>"Hello \@$msg->{from}{username}!",
        );

        return;
    }

    $bot->run({
        '/greet' => \&greet,
    });

Receives incoming Telegram messages (via short polling) and calls the
appropriate callback for a given command.

=head1 COMMAND HANDLERS

When the return value of a command is a reference to another subroutine,
Telegram::Bot will store the chat id and user id associated with the message.

Once the same user sends another message in that chat, the bot will
automatically forward the message to the new subroutine.

This allows you to easily create multi-step commands that allow the bot to be
more interactive.

=head1 CONTENT TYPE

The Telegram::Bot instance provides a `contenttype` attribute which is used to
set appropriate headers and convert parameters before sending a Telegram API
request.

Uploading files, for example, requires you to use the `form-data` content type:

    $self->{contenttype} = "form-data";

    $self->sendphoto(
        chat_id=>$msg->{chat}{id},
        photo=>["/path/to/an/image.png"]
    );

Most Telegram calls can be done using the default `application/json`, but check
Telegram's documentation to make sure!

The `contenttype` parameter is not reset between method calls, so if you change
it from `application/json` you must make sure to reset it yourself before making
API calls that require JSON.

=head1 CAVEATS

=over 4

=item * Certain chat actions display improperly in Telegram clients despite their listing in the Telegram documentation

=back

=head1 SUPPORT

Please report any bugs or feature requests to
L<https://github.com/lassandroan/perl-telegram-bot>.

=head1 AUTHOR

    Antonio Lassandro
    CPAN ID: LASSANDRO
    lassandroan@gmail.com
    http://www.github.com/lassandroan

=head1 LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<https://core.telegram.org/bots/api>

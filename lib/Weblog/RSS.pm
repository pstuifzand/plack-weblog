package Weblog::RSS;
use parent 'Plack::Component';
use strict;
use warnings;
use Data::Dumper;
use DBIx::DWIW;

use YAML::XS 'LoadFile';
use Plack::Util::Accessor qw/config/;

use XML::RSS;

sub call {
    my $self = shift;
    my $env = shift;

    my $title = $self->config->{weblog}{title};

    my $db = DBIx::DWIW->Connect(%{$self->config->{db}{weblog}});

    my @entries = $db->Hashes("SELECT * FROM `entry` ORDER BY `created` DESC LIMIT 10");

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title       => $title,
        link        => 'http://tweevijtig.nl/rss',
        description => 'Tweevijfig - a weblog of blog',
    );

    for (@entries) {
        $rss->add_item(link => 'http://tweevijftig.nl/' . $_->{slug}, title => $_->{title}, description => $_->{content});
    }

    return [ 200, [ 'Content-Type', 'application/rss+xml' ], [ $rss->as_string ] ];
}

1;



package Weblog::RSS;
use parent 'Plack::Component';
use strict;
use warnings;
use Data::Dumper;
use DBIx::DWIW;

use YAML::XS 'LoadFile';
use Plack::Util::Accessor qw/config/;
use DateTime::Format::RSS;

use Weblog::DB;
use XML::RSS;

sub call {
    my $self = shift;
    my $env = shift;

    my $title = $self->config->{weblog}{title};

    my $db = $env->{'weblog.db'};
    my $site_id = $env->{'weblog.site_id'};

    my @entries = $db->Entries($site_id);

    my $fmt = DateTime::Format::RSS->new(version => '2.0');

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title       => $title,
        link        => 'http://tweevijtig.nl/rss',
        description => 'Tweevijfig - a weblog of blog',
    );

    for (@entries) {
        $rss->add_item(
            link => 'http://tweevijftig.nl/' . $_->{slug},
            title => $_->{title},
            description => $_->{content},
            pubDate => $_->{created}->strftime( "%a, %d %b %Y %H:%M:%S %z" ),
         );
    }

    return [ 200, [ 'Content-Type', 'application/rss+xml' ], [ $rss->as_string ] ];
}

1;



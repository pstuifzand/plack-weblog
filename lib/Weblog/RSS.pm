package Weblog::RSS;
use parent 'Plack::Component';
use strict;
use warnings;
use DBIx::DWIW;

use YAML::XS 'LoadFile';
use Plack::Util::Accessor qw/config/;

use Weblog::DB;
use XML::RSS;
use DateTime::Format::RSS;
use DateTime::Format::HTTP;
use DateTime::Format::MySQL;

sub call {
    my $self = shift;
    my $env = shift;

    my $title = $self->config->{weblog}{title};
    my $db = $env->{'weblog.db'};
    my $site_id = $env->{'weblog.site_id'};

    my $fmt = DateTime::Format::RSS->new(version => '2.0');

    if (defined $env->{HTTP_IF_MODIFIED_SINCE}) {
        my $if_modified_since = DateTime::Format::HTTP->parse_datetime($env->{HTTP_IF_MODIFIED_SINCE});
        if ($if_modified_since) {
            my $last_pub = DateTime::Format::MySQL->parse_datetime($db->Scalar("SELECT `created` FROM `entry` WHERE `site_id` = ? ORDER BY `created` DESC", $site_id));
            if ($last_pub <= $if_modified_since) {
                return [ 304, [ 'Date', DateTime::Format::HTTP->format_datetime($last_pub) ], [] ];
            }
        }
    }

    my @entries = $db->Entries($site_id);

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

    return [ 200, [ 'Content-Type', 'application/rss+xml; charset=UTF-8' ], [ $rss->as_string ] ];
}

1;



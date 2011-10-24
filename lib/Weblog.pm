package Weblog;
use parent 'Plack::Component';

use strict;
use warnings;

use Data::Dumper;
use Weblog::DB;

use YAML::XS 'LoadFile';
use Plack::Util::Accessor qw/config/;
use Date::Period::Human;
use Template;

sub call {
    my $self = shift;
    my $env = shift;

    if ($env->{PATH_INFO} =~ m{^/code}) {
        return [ 302, [ 'Location', 'http://github.com/pstuifzand/plack-weblog' ], [] ];
    }

    my $title = $self->config->{weblog}{title};
    my $db = Weblog::DB->Connect(%{$self->config->{db}{weblog}});

    my $dph = Date::Period::Human->new();
    my $template = Template->new(INCLUDE_PATH => './share');

    my $out = '';

    if ($env->{PATH_INFO} =~ m{^/post/([a-z\-]+)$}) {
        my $slug = $1;
        my $entry = $db->Entry($slug);
        $template->process('entry.tp', { title => $title, human_readable_date => sub { $dph->human_readable($_[0]) }, entry => $entry }, \$out) or die $Template::ERROR;
    }
    else {
        my @entries = $db->Entries;
        for my $entry (@entries) {
            $template->process('entry.tp', { title => $title, human_readable_date => sub { $dph->human_readable($_[0]) }, entry => $entry }, \$out) or die $Template::ERROR;
        }
    }

    my $out2 = '';
    $template->process('layout.tp', { title => $title, insert_content_here => $out }, \$out2) or die $Template::ERROR;


    return [ 200, [ 'Content-Type', 'text/html' ], [ $out2 ] ];
}

1;


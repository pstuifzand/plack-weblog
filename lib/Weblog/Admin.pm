package Weblog::Admin;
use parent 'Plack::Component';

use strict;
use warnings;

use Data::Dumper;

use Plack::Util::Accessor qw/config/;
use Date::Period::Human;
use Template;
use Plack::Request;

sub call {
    my $self = shift;
    my $env = shift;

    my $title = $self->config->{weblog}{title};

    my $db = $env->{'weblog.db'};
    my $site_id = $env->{'weblog.site_id'};

    my $dph = Date::Period::Human->new();
    my $template = Template->new(INCLUDE_PATH => './share');

    my $out = '';

    if ($env->{PATH_INFO} =~ m{^/post$}) {
        my $req = Plack::Request->new($env);

        my $entry = {
            title => $req->param('title'),
            content  => $req->param('content'),
        };

        $db->CreateEntry($site_id, $entry);

        return [ 302, [ 'Location', '/admin' ], [] ];
    }
    elsif ($env->{PATH_INFO} =~ m{^/newpost$}) {
        $template->process('admin/post.tp', {}, \$out)
    }
    else {
        my @entries = $db->Entries($site_id);
        $template->process('admin/index.tp', {
                title               => $title,
                human_readable_date => sub { $dph->human_readable($_[0]) },
                entries             => \@entries,
            }, \$out) or die $Template::ERROR;
    }

    my $out2 = '';
    $template->process('admin/layout.tp', { title => $title, insert_content_here => $out }, \$out2) or die $Template::ERROR;

    return [ 200, [ 'Content-Type', 'text/html' ], [ $out2 ] ];
}

1;


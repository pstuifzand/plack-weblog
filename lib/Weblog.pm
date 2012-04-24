package Weblog;
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
    
    if ($env->{PATH_INFO} =~ m{^/code}) {
        return [ 302, [ 'Location', 'http://github.com/pstuifzand/plack-weblog' ], [] ];
    }

    my $db = $env->{'weblog.db'};
    my $site_id = $env->{'weblog.site_id'};

    my $site_info = $db->GetSiteInfo($site_id);

    my $dph = Date::Period::Human->new();
    my $template = Template->new(INCLUDE_PATH => './share');

    my $out = '';

    if ($env->{PATH_INFO} =~ m{^/post/([a-z0-9\-]+)$}) {
        my $slug = $1;

        my $entry = $db->Entry($site_id, $slug);
        $template->process('entry.tp', {
            show_comments => 1,
            human_readable_date => sub { $dph->human_readable($_[0]) },
            entry => $entry,
            site_info => $site_info,
        }, \$out) or die $Template::ERROR;
    }
    elsif ($env->{PATH_INFO} =~ m{^/post/([a-z0-9\-]+)/comment$}) {
        my $slug = $1;

        my $req = Plack::Request->new($env);

        my $comment = {
            name       => $req->param('name'),
            comment    => $req->param('comment'),
            email      => $req->param('email'),
            user_agent => $req->header('User-Agent'),
            remote_ip  => $req->header('X-Real-IP'),
        };

        $db->AddComment($site_id, $slug, $comment);

        return [ 302, [ 'Location', '/post/' . $slug ], [] ];
    }
    else {
        my @entries = $db->Entries($site_id);
        for my $entry (@entries) {
            $template->process('entry.tp', {
                show_comments => 0,
                human_readable_date => sub { $dph->human_readable($_[0]) },
                entry => $entry,
                site_info => $site_info,
            }, \$out) or die $Template::ERROR;
        }
    }

    my $out2 = '';
    $template->process('layout.tp', { site_info => $site_info, insert_content_here => $out }, \$out2) or die $Template::ERROR;


    return [ 200, [ 'Content-Type', 'text/html;charset=utf-8' ], [ $out2 ] ];
}

1;


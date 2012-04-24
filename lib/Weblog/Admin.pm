package Weblog::Admin;
use parent 'Weblog::Controller','Plack::Component';

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

    return [ 403, [], [] ] if $env->{HTTP_X_REAL_IP} ne '188.201.141.97' and $env->{HTTP_X_REAL_IP} ne '192.168.1.59';

    my $title = $self->config->{weblog}{title};

    my $db = $env->{'weblog.db'};
    my $site_id = $env->{'weblog.site_id'};
    my $site_info = $db->GetSiteInfo($site_id);

    my $dph = Date::Period::Human->new();
    my $template = $self->template;

    my $out = '';

    my $params = {
        site_info => $site_info,
    };

    my $types = [
        {type=>'blogpost',name=>'Bericht'},
        {type=>'page',name=>'Pagina'},
    ];
    my $type_names = {
        map { $_->{type} => $_->{name} } @$types,
    };
    if ($env->{PATH_INFO} =~ m{^/post$}) {
        my $req = Plack::Request->new($env);

        my $entry = {
            title => $req->param('title'),
            content  => $req->param('content'),
            type    => $req->param('type'),
        };

        $db->CreateEntry($site_id, $entry);

        return [ 302, [ 'Location', '/admin' ], [] ];
    }
    if ($env->{PATH_INFO} =~ m{^/post/(\d+)/update$}) {
        my $req = Plack::Request->new($env);

        my $entry = {
            id      => $1,
            title   => $req->param('title'),
            slug    => $req->param('slug'),
            content => $req->param('content'),
            type    => $req->param('type'),
        };

        $db->UpdateEntry($site_id, $entry);

        return [ 302, [ 'Location', '/admin' ], [] ];
    }
    elsif ($env->{PATH_INFO} =~ m{^/post/([a-z0-9\-]+)/edit$}) {
        my $slug = $1;

        my $entry = $db->Entry($site_id, $slug);
        $template->process('admin/entry-edit.tp', {
            show_comments       => 1,
            human_readable_date => sub { $dph->human_readable($_[0]) },
            entry               => $entry,
            site_info           => $site_info,
            types               => $types,
            type_names          => $type_names,
        }, \$out) or die $Template::ERROR;
    }
    elsif ($env->{PATH_INFO} =~ m{^/newpost$}) {
        $template->process('admin/post.tp', {type_names=>$type_names,types=>$types}, \$out)
    }
    elsif ($env->{PATH_INFO} =~ m{^/config$}) {
        $template->process('admin/config.tp', $params, \$out)
    }
    elsif ($env->{PATH_INFO} =~ m{^/config_set$}) {
        my $req = Plack::Request->new($env);
        my $site_id = $env->{'weblog.site_id'};
        my $title = $req->param('title');
        $db->SetSiteInfo($site_id, { title => $title });
        return [ 302, [ 'Location', '/admin' ], [] ];
    }
    else {
        my @entries = $db->Entries($site_id);
        my @pages = $db->Pages($site_id);
        $template->process('admin/index.tp', {
                title               => $title,
                human_readable_date => sub { $dph->human_readable($_[0]) },
                entries             => \@entries,
                pages               => \@pages,
            }, \$out) or die $Template::ERROR;
    }

    my $out2 = '';

    $template->process('admin/layout.tp', {
            insert_content_here => $out,
            site_info           => $site_info,
        }, \$out2) or die $Template::ERROR;

    return [ 200, [ 'Content-Type', 'text/html' ], [ $out2 ] ];
}

1;


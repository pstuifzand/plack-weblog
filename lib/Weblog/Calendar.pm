package Weblog::Calendar;
use parent 'Weblog::Controller', 'Plack::Component';
use strict;
use warnings;

use Date::Period::Human;

use Plack::Util::Accessor qw/config/;

sub call {
    my ($self, $env) = @_;

    my $db      = $env->{'weblog.db'};
    my $site_id = $env->{'weblog.site_id'};

    my $site_info = $db->GetSiteInfo($site_id);

    my $dph = Date::Period::Human->new();
    my $template = $self->template;

    if ($env->{PATH_INFO} =~ m{^/(\d{4})(?:/(\d{2})(?:/(\d{2})(?:/([a-z0-9]+))?)?)?$}) {
        my ($year, $month, $day, $slug) = ($1,$2,$3,$4);

        my $out = '';

        if ($slug) {
            my $event = $db->Event($site_id, $year, $month, $day, $slug);

            $template->process('event.tp', {
                entry     => $event,
                site_info => $site_info,
            }, \$out) or die $Template::ERROR;
        }
        else {
            $template->process('events.tp', {
                events    => [],
                site_info => $site_info,
            }, \$out) or die $Template::ERROR;
        }

        my @entries = $db->Events($site_id);

        my $out2 = '';
        $template->process('layout.tp', {
                site_info           => $site_info,
                insert_content_here => $out,
                events              => \@entries,
            }, \$out2) or die $Template::ERROR;
        return [ 200, [ 'Content-Type', 'text/html;charset=utf-8' ], [ $out2 ] ];
        #return [ 200, [], [ $year . $month . $day . $slug ] ];
    }

    return [ 404, [], [ 'Not found' ] ];
}

1;

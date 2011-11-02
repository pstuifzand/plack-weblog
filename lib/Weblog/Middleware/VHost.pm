package Weblog::Middleware::VHost;
use strict;
use parent 'Plack::Middleware';
use Data::Dumper;

sub call {
    my ($self, $env) = @_;

    $env->{'weblog.site_id'} = $env->{'weblog.db'}->Scalar(
        "SELECT `id` FROM `site` WHERE `domain` = ?",
        $env->{HTTP_HOST}
    );

    if (!$env->{'weblog.site_id'}) {
        my $body = '<p>Unknown website</p><p>' . $@ . '</p><p>' . $env->{'weblog.site_id'} . '</p>';
        return [ 
            500, 
            [ 'Content-Type', 'text/html', 'Content-Length', length $body ], 
            [ $body ],
        ];
    }

    return $self->app->($env);
}

1;

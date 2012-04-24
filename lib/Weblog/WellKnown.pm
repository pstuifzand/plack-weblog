package Weblog::WellKnown;
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

    my $host = $env->{HTTP_HOST};
    if ($env->{PATH_INFO} eq '/host-meta') {
        return 
        [ 
            200,
            [ 'Content-Type' => 'application/xrd+xml'],
            [ qq{<?xml version='1.0' encoding='UTF-8'?>
<XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'>
    <hm:Host xmlns:hm="http://host-meta.net/xrd/1.0">$host</hm:Host>

    <Link rel='lrdd' type='application/xrd+xml'
          template='http://$host/describe?uri={uri}' />
</XRD>
}],
        ];
    }
    return [ 404, [], [ 'Not Found' ] ];
}

1;

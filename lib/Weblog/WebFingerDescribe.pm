package Weblog::WebFingerDescribe;
use parent 'Plack::Component';

use strict;
use warnings;

use Plack::Util::Accessor qw/config/;
use Plack::Request;

sub call {
    my $self = shift;
    my $env = shift;

    my $req = Plack::Request->new($env);
    my $uri = $req->param('uri');

    $uri =~ s/^acct://;

    if ($uri ne 'peter@tweevijftig.nl') {
        return $req->new_response(404, [], ['Not Found'])->finalize;
    }

    my $out = <<"XML";
<?xml version='1.0' encoding='UTF-8'?>
<XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'>
<Subject>acct:peter\@tweevijftig.nl</Subject>
<Link rel='http://portablecontacts.net/spec/1.0#me' href='http://peterstuifzand.com/contact.json' />
<Link rel='http://webfinger.net/rel/profile-page' href='http://peterstuifzand.com' type='text/html' />
<Link rel='http://webfinger.net/rel/user-photo' href='http://peterstuifzand.com/nieuw_profiel_cropped_300.jpg' type='image/jpeg' />
<Link rel='describedby' href='http://tweevijftig.nl/' type='text/html' />
<Link rel='http://microformats.org/profile/hcard' href='http://peterstuifzand.com/' type='text/html' />
<Link rel='http://schemas.google.com/g/2010#updates-from' href='http://shattr.net:8086/feed/pstuifzand/rss.xml' type='application/rss+xml' />
<Link rel='http://specs.openid.net/auth/2.0/provider' href='http://peterstuifzand.nl'/>
</XRD>

XML

    return [ 200, [ 'Content-Type', 'application/xrd+xml' ], [ $out ] ];
}

1;


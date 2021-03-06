# vim:ft=perl
use lib 'lib';
#use local::lib;

use Plack::Builder;
use Plack::App::File;
use YAML::XS 'LoadFile';

use Weblog;
use Weblog::Admin;
use Weblog::WellKnown;
use Weblog::WebFingerDescribe;
use Weblog::Calendar;
use Weblog::RSS;

my $config = LoadFile('config.yml');

builder {
    enable "+Weblog::Middleware::DB", config => $config;
    enable "+Weblog::Middleware::VHost";

    mount '/admin'    => Weblog::Admin->new(config => $config);
    mount '/public'   => Plack::App::File->new(root => $config->{weblog}{document_root});
    mount '/rss'      => Weblog::RSS->new(config => $config);
    mount '/describe' => Weblog::WebFingerDescribe->new(config => $config);
    mount '/.well-known' => Weblog::WellKnown->new(config=>$config);
    mount '/events'   => Weblog::Calendar->new(config => $config);
    mount '/'         => Weblog->new(config => $config);
};


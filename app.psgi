use lib 'lib';
use Plack::Builder;
use Plack::App::File;
use YAML::XS 'LoadFile';

use Weblog;

my $config = LoadFile('config.yml');

builder {
    mount '/public' => Plack::App::File->new(root => $config->{weblog}{document_root});
    mount '/'       => Weblog->new(config => $config);
};


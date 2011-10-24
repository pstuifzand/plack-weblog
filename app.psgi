use lib 'lib';

use Plack::Builder;
use Plack::App::File;
use YAML::XS 'LoadFile';

use Weblog;
use Weblog::RSS;

my $config = LoadFile('config.yml');

builder {
    mount '/public' => Plack::App::File->new(root => $config->{weblog}{document_root});
    mount '/rss'    => Weblog::RSS->new(config => $config);
    mount '/'       => Weblog->new(config => $config);
};


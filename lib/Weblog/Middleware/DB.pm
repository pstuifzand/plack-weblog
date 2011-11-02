package Weblog::Middleware::DB;
use parent 'Plack::Middleware';

use Weblog::DB;
use Plack::Util::Accessor qw/config/;

sub call {
    my ($self, $env) = @_;
    $env->{'weblog.db'} = Weblog::DB->Connect(%{$self->config->{db}{weblog}});
    return $self->app->($env);
}
1;

package Weblog::Controller;

use strict;

sub template {
    my ($self) = @_;
    $self->{template} ||= Template->new(INCLUDE_PATH => ['./share/custom', './share/default']);
    return $self->{template};
}

1;

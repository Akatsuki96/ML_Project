package Point;
#!/usr/bin/perl


sub new{
	my $class=shift;
	my $self={@_};
	bless ($self,$class);
	return $self;
}

sub getX{
 return shift->{X};
}

sub getY{
	return shift->{Y};
}

sub getLabel{
	return shift->{Label};
}
12;

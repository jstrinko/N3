package N3::States;

our @States = qw{
    al ak az ar ca co ct de dc fl ga hi id il in ia ks 
    ky la me md ma mi mn ms mo mt ne nv nh nj nm ny nc 
    nd oh ok or pa ri sc sd tn tx ut vt va wa wv wi wy
};

sub states {
    return wantarray ? @States : \@States;
}

1;

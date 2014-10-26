#############################################################################
## This file was generated automatically by Class::HPLOO/0.20
##
## Original file:    ./lib/AI/NNEasy/NN/backprop.hploo
## Generation date:  2005-01-15 20:22:46
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        backprop.pm
## Purpose:     AI::NNEasy::NN::backprop
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-14
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package AI::NNEasy::NN::backprop ;


use strict qw(vars) ; no warnings ;


use vars qw(%CLASS_HPLOO @ISA) ;


@ISA = qw(Class::HPLOO::Base UNIVERSAL) ;


my $CLASS = 'AI::NNEasy::NN::backprop' ; sub __CLASS__ { 'AI::NNEasy::NN::backprop' } ;


use Class::HPLOO::Base ;



  sub calc_error { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $outputPatternRef = shift(@_) ;
    
    my @outputPattern = @$outputPatternRef;

    my $outputLayer = $this->{layers}->[-1]->{nodes} ;

    return 0 if @$outputLayer != @outputPattern ;

    my $counter = 0 ;
    foreach my $node (@$outputLayer) {
      $node->{error} = $node->{activation} - $outputPattern[$counter] ;
      ++$counter ;
    }
  }
  
  sub learn { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $outputPatternRef = shift(@_) ;
    
    $this->calc_error($outputPatternRef) ;
    $this->hiddenToOutput ;
    $this->hiddenOrInputToHidden if @{$this->{layers}} > 2 ;
    return $this->RMSErr($outputPatternRef) ;    
  }
  
  *hiddenToOutput = \&hiddenToOutput_c ;
  
  sub hiddenToOutput_pl { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    foreach my $node ( @{ $this->{layers}->[-1]->{nodes} } ) {
      foreach my $connectedNode ( @{$node->{connectedNodesWest}->{nodes}} ) {
        $node->{connectedNodesWest}->{weights}->{ $connectedNode->{nodeid} } -= $this->{learning_rate} * $node->{error} * $connectedNode->{activation} ;
        $node->{connectedNodesWest}->{weights}->{ $connectedNode->{nodeid} } = 5 if $node->{connectedNodesWest}->{weights}->{ $connectedNode->{nodeid} } > 5 ;
        $node->{connectedNodesWest}->{weights}->{ $connectedNode->{nodeid} } = -5 if $node->{connectedNodesWest}->{weights}->{ $connectedNode->{nodeid} } < -5 ;
      }
    }
  }
  
  
  
  *hiddenOrInputToHidden = \&hiddenOrInputToHidden_c ;
  
  sub hiddenOrInputToHidden_pl { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    
    my ( $nodeid , $nodeError , $nodeActivation ) ;
    
    my $learningRate = $this->{learning_rate} ;

    foreach my $layer ( reverse @{$this->{layers}}[0 .. $#{$this->{layers}}-1 ] ) {
      foreach my $node ( @{$layer->{nodes}} ) {
        last if !$node->{connectedNodesWest} ;
        
        $nodeid = $node->{nodeid} ;

        $nodeError = 0 ;
        foreach my $connectedNode ( @{$node->{connectedNodesEast}->{nodes}} ) {
          my $noderr = $connectedNode->{error} * $connectedNode->{connectedNodesWest}->{weights}->{$nodeid} ;
          $nodeError += $noderr ;
        }
        $node->{error} = $nodeError ;
        
        $nodeActivation = $node->{activation} ;

        # update the weights from nodes inputting to here
        foreach my $westNodes ( @{$node->{connectedNodesWest}->{nodes}} ) {
          $node->{connectedNodesWest}->{weights}->{ $westNodes->{nodeid} } -= ( 1 - ($nodeActivation*$nodeActivation) ) * $nodeError * $learningRate * $westNodes->{activation} ;
        }
        
      }
    }
    
  }

  
  
  sub RMSErr { 
    my $this = ref($_[0]) ? shift : undef ;
    my $CLASS = ref($this) || __PACKAGE__ ;
    my $outputPatternRef = shift(@_) ;
    
    my @outputPattern = @$outputPatternRef ;

    my $outputLayer = $this->{layers}->[-1]->{nodes} ;

    return 0 if @$outputLayer != @outputPattern ;

    my $sqrErr ;
    my $counter = 0 ;
    foreach my $node (@$outputLayer) {
      $sqrErr += ($node->{activation} - $outputPattern[$counter])**2 ;
      ++$counter ;
    }

    my $error = sqrt($sqrErr) ;

    return $error;
  }

use Inline C => <<'__INLINE_C_SRC__';


#define OBJ_HV(self)		(HV*) SvRV( self )
#define OBJ_AV(self)		(AV*) SvRV( self )

#define FETCH_ATTR(hv,k)	*hv_fetch(hv, k , strlen(k) , 0)
#define FETCH_ATTR_PV(hv,k)	SvPV( FETCH_ATTR(hv,k) , len)
#define FETCH_ATTR_NV(hv,k)	SvNV( FETCH_ATTR(hv,k) )
#define FETCH_ATTR_IV(hv,k)	SvIV( FETCH_ATTR(hv,k) )  
#define FETCH_ATTR_HV(hv,k)	(HV*) FETCH_ATTR(hv,k)
#define FETCH_ATTR_AV(hv,k)	(AV*) FETCH_ATTR(hv,k)
#define FETCH_ATTR_HV_REF(hv,k)	(HV*) SvRV( FETCH_ATTR(hv,k) )
#define FETCH_ATTR_AV_REF(hv,k)	(AV*) SvRV( FETCH_ATTR(hv,k) )

#define FETCH_ELEM(av,i)		*av_fetch(av,i,0)
#define FETCH_ELEM_HV_REF(av,i)	(HV*) SvRV( FETCH_ELEM(av,i) )
#define FETCH_ELEM_AV_REF(av,i)	(AV*) SvRV( FETCH_ELEM(av,i) )

void hiddenToOutput_c( SV* self ) {
    STRLEN len;
    int i , j , k ;
    HV* self_hv = OBJ_HV( self );
        
    AV* nodes = FETCH_ATTR_AV_REF( FETCH_ELEM_HV_REF( FETCH_ATTR_AV_REF(self_hv , "layers") , -1) , "nodes") ;
    for (i = 0 ; i <= av_len(nodes) ; ++i) {
      HV* node = OBJ_HV( *av_fetch(nodes, i ,0) ) ;

      AV* westNodes = FETCH_ATTR_AV_REF( FETCH_ATTR_HV_REF(node , "connectedNodesWest") , "nodes") ;
      for (j = 0 ; j <= av_len(westNodes) ; ++j) {
        HV* connectedNode = OBJ_HV( *av_fetch(westNodes, j ,0) ) ;
        SV* weight = FETCH_ATTR( FETCH_ATTR_HV_REF( FETCH_ATTR_HV_REF(node , "connectedNodesWest") , "weights" ) , FETCH_ATTR_PV(connectedNode , "nodeid") );

        double val = FETCH_ATTR_NV(self_hv , "learning_rate") * FETCH_ATTR_NV(node , "error") * FETCH_ATTR_NV(connectedNode , "activation") ;
        val = SvNV(weight) - val ;

        if      ( val > 5 ) { val = 5 ;}
        else if ( val < -5 ) { val = -5 ;}
        
        sv_setnv(weight , val) ;
      }
      
    }
}

void hiddenOrInputToHidden_c( SV* self ) {
    STRLEN len;
    int i , j , k ;
    double nodeError , nodeActivation ;
    char* nodeid ;
    AV* layers ;
    HV* self_hv = OBJ_HV( self );
    double learningRate = FETCH_ATTR_NV(self_hv , "learning_rate") ;
    
    layers = FETCH_ATTR_AV_REF(self_hv , "layers") ;
    for (i = (av_len(layers)-1) ; i >= 0 ; --i) {
      SV* layer = *av_fetch(layers, i ,0) ;
  
      AV* nodes = FETCH_ATTR_AV_REF(OBJ_HV(layer) , "nodes") ;
      for (j = 0 ; j <= av_len(nodes) ; ++j) {
        HV* node = OBJ_HV( *av_fetch(nodes, j ,0) ) ;
        AV* eastNodes ;
        AV* westNodes ;
        
        if (!SvTRUE( FETCH_ATTR(node , "connectedNodesWest") ) ) break ;
        
        nodeid = FETCH_ATTR_PV(node , "nodeid") ;
        
        nodeError = 0 ;
        
        eastNodes = FETCH_ATTR_AV_REF( FETCH_ATTR_HV_REF(node , "connectedNodesEast") , "nodes") ;
        for (k = 0 ; k <= av_len(eastNodes) ; ++k) {
          HV* connectedNode = OBJ_HV( *av_fetch(eastNodes, k ,0) ) ;
          nodeError += FETCH_ATTR_NV(connectedNode , "error") * FETCH_ATTR_NV( FETCH_ATTR_HV_REF( FETCH_ATTR_HV_REF(connectedNode , "connectedNodesWest") , "weights") , nodeid) ;
        }
        
        hv_store(node , "error" , 5 , newSVnv(nodeError) , 0) ;
        
        nodeActivation = FETCH_ATTR_NV(node , "activation") ;
        
        westNodes = FETCH_ATTR_AV_REF( FETCH_ATTR_HV_REF(node , "connectedNodesWest") , "nodes") ;
        for (k = 0 ; k <= av_len(westNodes) ; ++k) {
          HV* connectedNode = OBJ_HV( *av_fetch(westNodes, k ,0) ) ;
          char* connectedNode_id = FETCH_ATTR_PV(connectedNode , "nodeid") ;
  
          HV* hv = FETCH_ATTR_HV_REF( FETCH_ATTR_HV_REF(node , "connectedNodesWest") , "weights") ;
          SV* weight_prev = FETCH_ATTR(hv , connectedNode_id) ;
  
          double weight = SvNV(weight_prev) - ( (1 - (nodeActivation*nodeActivation)) * nodeError * learningRate * FETCH_ATTR_NV(connectedNode , "activation") ) ;
  
          sv_setnv(weight_prev , weight) ;
        }
      }
    }
}

__INLINE_C_SRC__


}


1;



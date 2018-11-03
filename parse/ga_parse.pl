#!/usr/bin/perl
use strict;
use warnings;

$| = 1;
binmode STDIN;

while(read STDIN, my $soh, 1) {

    next unless ($soh =~ /\x01/);

    my @sum;
    push @sum, $soh;
    
    read STDIN, my $type, 1;
    push @sum, $type;
    
    read STDIN, my $count, 1;
    push @sum, $count;
    
    read STDIN, my $cc_data, ord($count)-5;
    my @cc_data = split(//, $cc_data);
    push @sum, @cc_data;
    
    read STDIN, my $checksum, 1;
    push @sum, $checksum;
    
    read STDIN, my $eot, 1;
    push @sum, $eot;
    
    if (($eot =~ /\x04/) && checksum(\@sum)) {
    
        # DTVCC packet (ATVCC data)
        next unless ($type =~ /\x41/);           
        next unless @cc_data;
        my $seq_num = ord($cc_data[0]) >> 6 & 0b11;
        my $packet_size = ord($cc_data[0]) & 0b111111;
        my @packet_data = splice @cc_data, 1, $packet_size*2-1;
        
        # Service Block Packet
        next unless @packet_data;
        my $service_num = ord($packet_data[0]) >> 5 & 0b111;
        my $block_size = ord($packet_data[0]) & 0b11111;
        if ($service_num == 7) {
            my $ext_service_num = ord(shift @packet_data) & 0b111111;
            #print qq/ext_service_num = $ext_service_num\n/;
        }
        my @block_data = splice @packet_data, 1, $block_size;
        
        # block_data
        while (my $signi_code = shift @block_data) {
            # CL Group: C0 Subset of ASCII Control Codes
            if ($signi_code =~ /[\x00-\x1F]/) {
                c0_table($signi_code, \@block_data);
            }
            # CR Group: C1 Caption Control Codes
            elsif ($signi_code =~ /[\x80-\x9F]/) {                 
                c1_table($signi_code, \@block_data);
            }
            # GL Group: G0 Modified version of ANSI X3.4 Printable Character Set (ASCII)
            elsif ($signi_code =~ /[\x20-\x7F]/) {                 
                g0_table($signi_code);
            }
            # GR Group: G1 ISO 8859-1 Latin 1 Characters (>chcp 28591)
            elsif ($signi_code =~ /[\xA0-\xFF]/) {                 
                g1_table($signi_code);
            }
        }
    } else {
        print qq/\nChecksum err:\n\n/;
    }
}



sub checksum {
    my $vals = shift;
    my $sum = 0;
    $sum += ord($_) for(@$vals);
    return !($sum % 256);
}

# CL Group: C0 Subset of ASCII Control Codes
sub c0_table {
    my ($signi_code, $block_data) = @_;
=pod
    if ($signi_code =~ /\x00/) {print qq/[NUL]/;}
    elsif ($signi_code =~ /\x03/) {print qq/[ETX]/;}
    elsif ($signi_code =~ /\x08/) {print qq/[BS]/;}
    elsif ($signi_code =~ /\x0C/) {print qq/[FF]/;}
    elsif ($signi_code =~ /\x0D/) {print qq/[CR]/;}
    elsif ($signi_code =~ /\x0E/) {print qq/[HCR]/;}
=cut
    if ($signi_code =~ /\x10/) {
        #print qq/[EXT1]/;
        my $extended_signi_code = shift @$block_data;
        
        # CL Group: C2 Extended Miscellaneous Control Codes
        if ($extended_signi_code =~ /[\x00-\x07]/) {
            ;
        }
        elsif ($extended_signi_code =~ /[\x08-\x0F]/) {
            for (0 .. 0) {shift @$block_data;}
        }
        elsif ($extended_signi_code =~ /[\x10-\x17]/) {
            for (0 .. 1) {shift @$block_data;}
        }
        elsif ($extended_signi_code =~ /[\x18-\x1F]/) {
            for (0 .. 2) {shift @$block_data;}
        }
        
        # CR Group: C3 Extended Control Code Set 2
        elsif ($extended_signi_code =~ /[\x80-\x87]/) {
            for (0 .. 3) {shift @$block_data;}
        }
        elsif ($extended_signi_code =~ /[\x88-\x8F]/) {
            for (0 .. 4) {shift @$block_data;}
        }
        
        # GL Group: G2 Extended Control Code Set 1
        elsif ($extended_signi_code =~ /[\x20-\x7F]/) {
            ;
        }
        
        # GR Group: G3 Future characters and icons (0x10A0:[CC]Icon.)
        elsif ($extended_signi_code =~ /[\xA0-\xFF]/) {
            ;
        }
    }
    elsif ($signi_code =~ /\x18/) {
        #print qq/[P16]/;
        for (0 .. 1) {shift @$block_data;}
    }
}

# CR Group: C1 Caption Control Codes
sub c1_table {
    my ($signi_code, $block_data) = @_;

    # SetCurrentWindow0-7
    if ($signi_code =~ /[\x80-\x87]/) {
        my $currentwindow_num = $signi_code & 0b1111;
        #print qq/[CW$currentwindow_num]/;
    }
    
    # CtrlWindows
    elsif ($signi_code =~ /[\x88-\x8C]/) {
        my $window_bitmap = shift @$block_data;
=pod
        # ClearWindows
        if ($signi_code =~ /\x88/) {
            print qq/[CLW]/; printf "{%08b}", ord($window_bitmap);
        }
        # DisplayWindows
        elsif ($signi_code =~ /\x89/) {
            print qq/[DSW]/; printf "{%08b}", ord($window_bitmap);
        } 
        # HideWindows
        elsif ($signi_code =~ /\x8A/) {
            print qq/[HDW]/; printf "{%08b}", ord($window_bitmap);
        }
        # ToggleWindows
        elsif ($signi_code =~ /\x8B/) {
            print qq/[TGW]/; printf "{%08b}", ord($window_bitmap);
        }
        # DeleteWindows
        elsif ($signi_code =~ /\x8C/) {
            print qq/[DLW]/; printf "{%08b}", ord($window_bitmap);
        }
=cut
    }
                    
    # Delay
    elsif ($signi_code =~ /\x8D/) {
        my $tenths_of_seconds = ord(shift @$block_data) / 10;
        #print qq/[DLY]/, qq/{$tenths_of_seconds}/;
    }
=pod
    # DelayCancel
    elsif ($signi_code =~ /\x8E/) {print qq/[DLC]/;}
    # Reset
    elsif ($signi_code =~ /\x8F/) {print qq/[RST]/;}
=cut

    # SetPenAttributes
    elsif ($signi_code =~ /\x90/) {
        my @SetPenAttributes;
        for (0 .. 1) {
            push @SetPenAttributes, ord(shift @$block_data);
        }
=pod
        my $pen_size = $SetPenAttributes[0] & 0b11;
        my $offset = $SetPenAttributes[0] >> 2 & 0b11;
        my $text_tag = $SetPenAttributes[0] >> 4 & 0b1111;
        my $font_tag = $SetPenAttributes[1] & 0b0111;
        my $edge_type = $SetPenAttributes[1] >> 3 & 0b111;
        my $underline = $SetPenAttributes[1] >> 6 & 0b1;
        my $italic = $SetPenAttributes[1] >> 7 & 0b1;
        print qq/[SPA]/, qq/{$pen_size:$offset:$text_tag:$font_tag:$edge_type:$underline:$italic}/;
=cut
    }
    # SetPenColor
    elsif ($signi_code =~ /\x91/) {
        my @SetPenColor;
        for (0 .. 2) {
            push @SetPenColor, ord(shift @$block_data);
        }
=pod
        my $forground_color_op = $SetPenColor[0] >> 6 & 0b11;
        my $forground_color_r = $SetPenColor[0] >> 4 & 0b11;
        my $forground_color_g = $SetPenColor[0] >> 2 & 0b11;
        my $forground_color_b = $SetPenColor[0] >> 0 & 0b11;
        my $background_color_op = $SetPenColor[1] >> 6 & 0b11;
        my $background_color_r = $SetPenColor[1] >> 4 & 0b11;
        my $background_color_g = $SetPenColor[1] >> 2 & 0b11;
        my $background_color_b = $SetPenColor[1] >> 0 & 0b11;
        my $edge_color_op = $SetPenColor[2] >> 6 & 0b11;
        my $edge_color_r = $SetPenColor[2] >> 4 & 0b11;
        my $edge_color_g = $SetPenColor[2] >> 2 & 0b11;
        my $edge_color_b = $SetPenColor[2] >> 0 & 0b11;
        print qq/[SPC]/, qq/{$forground_color_op$forground_color_r$forground_color_g$forground_color_b:$background_color_op$background_color_r$background_color_g$background_color_b:$edge_color_op$edge_color_r$edge_color_g$edge_color_b}/;
=cut
    }
    # SetPenLocation
    elsif ($signi_code =~ /\x92/) {
        my @SetPenLocation;
        for (0 .. 1) {
            push @SetPenLocation, ord(shift @$block_data);
        }
        my $row = $SetPenLocation[0] & 0b1111;
        my $column = $SetPenLocation[1] & 0b111111;
        #print qq/[SPL]/, qq/{$row:$column}/;
        if ($column == 0) {print qq/\n/;}
    }
    # SetWindowAttributes
    elsif ($signi_code =~ /\x97/) {
        my @SetWindowAttributes;
        for (0 .. 3) {
            push @SetWindowAttributes, ord(shift @$block_data);
        }
=pod
        my $fill_color_op = $SetWindowAttributes[0] >> 6 & 0b11;
        my $fill_color_r = $SetWindowAttributes[0] >> 4 & 0b11;
        my $fill_color_g = $SetWindowAttributes[0] >> 2 & 0b11;
        my $fill_color_b = $SetWindowAttributes[0] >> 0 & 0b11;
        my $border_color_r = $SetWindowAttributes[1] >> 4 & 0b11;
        my $border_color_g = $SetWindowAttributes[1] >> 2 & 0b11;
        my $border_color_b = $SetWindowAttributes[1] >> 0 & 0b11;
        my $border_type_01 = $SetWindowAttributes[1] >> 6 & 0b11;
        my $justify = $SetWindowAttributes[2] >> 0 & 0b0011;
        my $scroll_direction = $SetWindowAttributes[2] >> 2 & 0b11;
        my $print_direction = $SetWindowAttributes[2] >> 4 & 0b11;
        my $word_wrap = $SetWindowAttributes[2] >> 6 & 0b1;
        my $border_type_2 = $SetWindowAttributes[2] >> 7 & 0b1;
        my $border_type = $border_type_01 + $border_type_2 << 2;
        my $display_effect = $SetWindowAttributes[3] >> 0 & 0b11;
        my $effect_direction = $SetWindowAttributes[3] >> 2 & 0b11;
        my $effect_speed = ($SetWindowAttributes[3] >> 4 & 0b1111) * 0.5;
        print qq/[SWA]/, qq/{$fill_color_r$fill_color_g$fill_color_b:$fill_color_op:$border_color_r$border_color_g$border_color_b:$border_type:$justify:$scroll_direction:$print_direction:$word_wrap $display_effect:$effect_direction:$effect_speed}/;
=cut
    }
    
    # DefineWindow0–7
    elsif ($signi_code =~ /[\x98-\x9F]/) {
        my @definewindow_parameters;
        for (0 .. 5) {
            push @definewindow_parameters, ord(shift @$block_data);
        }
=pod
        my $definewindow_num = $signi_code & 0b111;
        my $priority = $definewindow_parameters[0] & 0b111;
        my $column_lock = $definewindow_parameters[0] >> 3 & 0b1;
        my $row_lock = $definewindow_parameters[0] >> 4 & 0b1;
        my $visible = $definewindow_parameters[0] >> 5 & 0b1;
        my $anchor_vertical = $definewindow_parameters[1] & 0b1111111;
        my $relative_positioning = $definewindow_parameters[1] >> 7 & 0b1;
        my $anchor_horizontal = $definewindow_parameters[2];
        my $row_count = $definewindow_parameters[3] & 0b1111;
        my $anchor_ID = $definewindow_parameters[3] >> 4 & 0b1111;
        my $colmn_count = $definewindow_parameters[4] & 0b111111;
        my $pen_style = $definewindow_parameters[5] & 0b111;
        my $window_style = $definewindow_parameters[5] >> 3 & 0b111;
        print qq/[DF$definewindow_num]/, qq/{$priority:$column_lock:$row_lock:$visible:$anchor_vertical:$relative_positioning:$anchor_horizontal:$row_count:$anchor_ID:$colmn_count:$pen_style:$window_style}/;
=cut
    }
}
                
# GL Group: G0 Modified version of ANSI X3.4 Printable Character Set (ASCII)
sub g0_table {
    my $signi_code = shift;
    print $signi_code;
}

# GR Group: G1 ISO 8859-1 Latin 1 Characters (>chcp 28591)
sub g1_table {
    my $signi_code = shift;
    print $signi_code;
}

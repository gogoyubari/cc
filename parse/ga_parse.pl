#!/usr/bin/perl
use strict;
use warnings;

# Enable command buffering.
$| = 1;
binmode STDIN;

my $val;
while(read STDIN, $val, 1) {

    if (ord($val) == 0x01) {
        my $sum = ord($val);
        
        read STDIN, my $type, 1;
        $sum += ord($type);
        
        read STDIN, my $count, 1;
        $sum += ord($count);
        
        my @cc_data;
        for (my $i = 0; $i < ord($count)-5; $i++) {
            read STDIN, $val, 1;
            push @cc_data, $val;
            $sum += ord($val);
        }
        
        read STDIN, my $checksum, 1;
        $sum += ord($checksum);
        
        read STDIN, my $eot, 1;
        $sum += ord($eot);
        
        if ((ord($eot) == 0x04) && ($sum % 256 == 0)) {
        
            # DTVCC packet (ATVCC data)
            next if (ord($type) != 0x41);           
            next if (!@cc_data);
            my $seq_num = ord($cc_data[0]) >> 6 & 0b11;
            my $packet_size = ord($cc_data[0]) & 0b111111;
            my @packet_data;
            for (my $i = 1; $i < $packet_size*2; $i++) {
                push @packet_data, $cc_data[$i];
            }
            
            # Service Block Packet
            next if(!@packet_data);
            my $service_num = ord($packet_data[0]) >> 5 & 0b111;
            my $block_size = ord($packet_data[0]) & 0b11111;
            if ($service_num == 7) {
                my $ext_service_num = ord(shift @packet_data) & 0b111111;
                #print qq/ext_service_num = $ext_service_num\n/;
            }
            my @block_data;
            for (my $i = 0; $i < $block_size; $i++) {
                push @block_data, $packet_data[$i+1];
            }
            
            # block_data
            while (my $block_data = shift @block_data) {
                my $signi_code = ord($block_data);
                
                # CL Group: C0 Subset of ASCII Control Codes
                if ($signi_code >= 0x00 && $signi_code <= 0x0F) {
=pod
                    if ($signi_code == 0x00) {print qq/[NUL]/;}
                    if ($signi_code == 0x03) {print qq/[ETX]/;}
                    if ($signi_code == 0x08) {print qq/[BS]/;}
                    if ($signi_code == 0x0C) {print qq/[FF]/;}
                    if ($signi_code == 0x0D) {print qq/[CR]/;}
                    if ($signi_code == 0x0E) {print qq/[HCR]/;}
=cut
                    if ($signi_code == 0x10) {
                        #print qq/[EXT1]/;
                        my $extended_signi_code = ord(shift @block_data);
                        
                        # CL Group: C2 Extended Miscellaneous Control Codes
                        if ($extended_signi_code >= 0x00 && $extended_signi_code <= 0x07) {
                            ;
                        }
                        if ($extended_signi_code >= 0x08 && $extended_signi_code <= 0x0f) {
                            for (my $i = 0; $i < 1; $i++) {shift @block_data;}
                        }
                        if ($extended_signi_code >= 0x10 && $extended_signi_code <= 0x17) {
                            for (my $i = 0; $i < 2; $i++) {shift @block_data;}
                        }
                        if ($extended_signi_code >= 0x18 && $extended_signi_code <= 0x1F) {
                            for (my $i = 0; $i < 3; $i++) {shift @block_data;}
                        }
                        
                        # CR Group: C3 Extended Control Code Set 2
                        if ($extended_signi_code >= 0x80 && $extended_signi_code <= 0x87) {
                            for (my $i = 0; $i < 4; $i++) {shift @block_data;}
                        }
                        if ($extended_signi_code >= 0x88 && $extended_signi_code <= 0x8F) {
                            for (my $i = 0; $i < 5; $i++) {shift @block_data;}
                        }
                        
                        # GL Group: G2 Extended Control Code Set 1
                        if ($extended_signi_code >= 0x20 && $extended_signi_code <= 0x7F) {
                            ;
                        }
                        
                        # GR Group: G3 Future characters and icons (0x10A0:[CC]Icon.)
                        if ($extended_signi_code >= 0xA0 && $extended_signi_code <= 0xFF) {
                            ;
                        }
                    }
                    if ($signi_code == 0x18) {
                        #print qq/[P16]/;
                        for (my $i = 0; $i < 2; $i++) {shift @block_data;}
                    }
                }
                
                # CR Group: C1 Caption Control Codes
                if ($signi_code >= 0x80 && $signi_code <= 0x9F) {                 
=pod
                    # SetCurrentWindow0-7
                    if ($signi_code >= 0x80 && $signi_code <= 0x87) {
                        my $currentwindow_num = $signi_code & 0b1111;
                        print qq/[CW$currentwindow_num]/;
                    }
=cut
                    
                    # CtrlWindows
                    if ($signi_code >= 0x88 && $signi_code <= 0x8C) {
                        my $window_bitmap = shift @block_data;
=pod
                        # ClearWindows
                        if ($signi_code == 0x88) {
                            print qq/[CLW]/; printf "{%08b}", ord($window_bitmap);
                        }
                        # DisplayWindows
                        if ($signi_code == 0x89) {
                            print qq/[DSW]/; printf "{%08b}", ord($window_bitmap);
                        } 
                        # HideWindows
                        if ($signi_code == 0x8A) {
                            print qq/[HDW]/; printf "{%08b}", ord($window_bitmap);
                        }
                        # ToggleWindows
                        if ($signi_code == 0x8B) {
                            print qq/[TGW]/; printf "{%08b}", ord($window_bitmap);
                        }
                        # DeleteWindows
                        if ($signi_code == 0x8C) {
                            print qq/[DLW]/; printf "{%08b}", ord($window_bitmap);
                        }
=cut
                    }
                    
=pod
                    # Delay
                    if ($signi_code == 0x8D) {
                        my $tenths_of_seconds = ord(shift @block_data) / 10;
                        print qq/[DLY]/, qq/{$tenths_of_seconds}/;
                    }
                    # DelayCancel
                    if ($signi_code == 0x8E) {print qq/[DLC]/;} 
                    # Reset
                    if ($signi_code == 0x8F) {print qq/[RST]/;} 
=cut

                    # SetPenAttributes
                    if ($signi_code == 0x90) { 
                        my @SetPenAttributes;
                        for (my $i = 0; $i < 2; $i++) {
                            push @SetPenAttributes, ord(shift @block_data);
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
                    if ($signi_code == 0x91) { 
                        my @SetPenColor;
                        for (my $i = 0; $i < 3; $i++) {
                            push @SetPenColor, ord(shift @block_data);
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
                    if ($signi_code == 0x92) { 
                        my @SetPenLocation;
                        for (my $i = 0; $i < 2; $i++) {
                            push @SetPenLocation, ord(shift @block_data);
                        }
                        my $row = $SetPenLocation[0] & 0b1111;
                        my $column = $SetPenLocation[1] & 0b111111;
                        #print qq/[SPL]/, qq/{$row:$column}/;
                        if ($column == 0) {print qq/\n/;}
                    }
                    # SetWindowAttributes
                    if ($signi_code == 0x97) {
                        my @SetWindowAttributes;
                        for (my $i = 0; $i < 4; $i++) {
                            push @SetWindowAttributes, ord(shift @block_data);
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
                    if ($signi_code >= 0x98 && $signi_code <= 0x9F) {
                        my @definewindow_parameters;
                        for (my $i = 0; $i < 6; $i++) {
                            push @definewindow_parameters, ord(shift @block_data);
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
                if ($signi_code >= 0x20 && $signi_code <= 0x7F) {
                    print pack("C", $signi_code);
                }
                
                # GR Group: G1 ISO 8859-1 Latin 1 Characters (>chcp 28591)
                if ($signi_code >= 0xA0 && $signi_code <= 0xFF) {
                    print pack("C", $signi_code);
                }
            }
        } else {
            print qq/\nChecksum err:\n\n/;
        }
    }
}

close STDIN;



# theme.tcl - colour palettes. The active palette lives in the global array T.
namespace eval theme {
    variable dark {
        bg #0B0F1A  surface #141A2C  surface2 #1D2540  border #2A3454
        text #EEF2FF  muted #93A0C6  primary #6B58EC  primaryText #A99EFF  success #34D8A0
        error #FF5D7A  warn #FFC857  info #4CC9F0  codebg #0A0F1D
        onprimary #FFFFFF
        c_cmd #7FB2FF  c_kw #C792EA  c_var #FFC857  c_str #8BE0A4
        c_num #FF9E7A  c_cmt #7684A8  c_punct #93A0C6  c_out #4CC9F0
    }
    variable light {
        bg #F3F5FC  surface #FFFFFF  surface2 #E8ECFA  border #CDD4EC
        text #1B2140  muted #5F6992  primary #5B49E0  primaryText #5B49E0  success #086B4C
        error #B01F33  warn #7F5200  info #0A6591  codebg #EDF0FA
        onprimary #FFFFFF
        c_cmd #1F5FD0  c_kw #8E3FC0  c_var #8F5200  c_str #17703D
        c_num #B03A0A  c_cmt #5F6A8F  c_punct #5F6992  c_out #0A6F9E
    }
    proc apply {name} {
        variable dark
        variable light
        array unset ::T
        array set ::T [set $name]
        set ::T(name) $name
    }
}
theme::apply dark

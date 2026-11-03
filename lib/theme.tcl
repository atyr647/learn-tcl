# theme.tcl - colour palettes. The active palette lives in the global array T.
namespace eval theme {
    variable dark {
        bg #0E1320  surface #19203A  surface2 #232C4D  border #34406B
        text #EEF2FF  muted #93A0C6  primary #7C6CFF  success #2FD39A
        error #FF5D7A  warn #FFC857  info #4CC9F0  codebg #0A0F1D
        onprimary #FFFFFF
        c_cmd #7FB2FF  c_kw #C792EA  c_var #FFC857  c_str #8BE0A4
        c_num #FF9E7A  c_cmt #6C7A9E  c_punct #93A0C6  c_out #4CC9F0
    }
    variable light {
        bg #F3F5FC  surface #FFFFFF  surface2 #E8ECFA  border #CDD4EC
        text #1B2140  muted #5F6992  primary #6A5AF0  success #13A777
        error #E5384F  warn #C98A00  info #0A93C8  codebg #EDF0FA
        onprimary #FFFFFF
        c_cmd #1F5FD0  c_kw #8E3FC0  c_var #B26A00  c_str #1B7F46
        c_num #C2410C  c_cmt #7C86A8  c_punct #5F6992  c_out #0A7FB0
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

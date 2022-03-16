*! version 1.0.0  04feb2022
program define iefonts
    version 8
    syntax [, Serif Restore]

    if "`serif'" != "" & "`restore'" != "" {
        display as error "Options serif and restore may not be combined."
        exit 184
    }

    if "`restore'" == "restore" {
        graph set window fontface default
        graph set ps fontface default
        graph set eps fontface default
        graph set svg fontface default

        graph set window fontfacemono default
        graph set ps fontfacemono default
        graph set eps fontfacemono default
        graph set svg fontfacemono default

        graph set window fontfacesans default
        graph set ps fontfacesans default
        graph set eps fontfacesans default
        graph set svg fontfacesans default

        graph set window fontfaceserif default
        graph set ps fontfaceserif default
        graph set eps fontfaceserif default
        graph set svg fontfaceserif default

        graph set window fontfacesymbol default
        graph set ps fontfacesymbol default
        graph set eps fontfacesymbol default
        graph set svg fontfacesymbol default

        exit
    }
    else if "`serif'" == "serif" {
        graph set window fontface Lora
        graph set ps fontface Lora
        graph set eps fontface Lora
        graph set svg fontface Lora

        graph set window fontfacemono default
        graph set ps fontfacemono default
        graph set eps fontfacemono default
        graph set svg fontfacemono default

        graph set window fontfacesans Montserrat
        graph set ps fontfacesans Montserrat
        graph set eps fontfacesans Montserrat
        graph set svg fontfacesans Montserrat

        graph set window fontfaceserif Lora
        graph set ps fontfaceserif Lora
        graph set eps fontfaceserif Lora
        graph set svg fontfaceserif Lora

        graph set window fontfacesymbol Montserrat
        graph set ps fontfacesymbol Montserrat
        graph set eps fontfacesymbol Montserrat
        graph set svg fontfacesymbol Montserrat
    }
    else {
        graph set window fontface Montserrat
        graph set ps fontface Montserrat
        graph set eps fontface Montserrat
        graph set svg fontface Montserrat

        graph set window fontfacemono default
        graph set ps fontfacemono default
        graph set eps fontfacemono default
        graph set svg fontfacemono default

        graph set window fontfacesans Montserrat
        graph set ps fontfacesans Montserrat
        graph set eps fontfacesans Montserrat
        graph set svg fontfacesans Montserrat

        graph set window fontfaceserif Lora
        graph set ps fontfaceserif Lora
        graph set eps fontfaceserif Lora
        graph set svg fontfaceserif Lora

        graph set window fontfacesymbol Montserrat
        graph set ps fontfacesymbol Montserrat
        graph set eps fontfacesymbol Montserrat
        graph set svg fontfacesymbol Montserrat
    }
end

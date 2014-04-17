Sahli Editor
============

Editor for Sahli files.

- open existing file
- create new item
 * get filename from dir
 * insert SAUCE data if available
 * use SAUCE data to find font
 * allow Amiga choices
 * colorpicker
- edit existing item
- remove item
- clear whole file
- copy/clone
- move items around
- sort items
- output to screen (copy into file)
 * run from node - save filename dialog

***
It should be noted that this does not do bounds checking, and it would be very
possible to overflow this by using a debugger and such.  As the purpose of this
is limited, and this should NOT be put on a live website, I feel that is ok for
now. Perhaps I will fix it after Revision.

***

== Create Initial crappage
We need to make a screen that has a few things in it for starters
Title, load existing, and new file options.

Silliness for checking that this works.

    $(-> $("h1").hide().slideDown(500))

Create buttos to choose between the New and Load functionalities
(As we aren't going to ever load a file _and_ do a new file.)
(If someone wants to do that, they can restart with F5 or something.)
Also hide the editor until needed, and initialize some elements.

    $(->
        $("#newsahli")
        .button { disabled: false}
        .click -> newsahli()
        )

    $(->
        $("#loadsahli")
        .button { disabled: false}
        .click -> loadsahli()
        )
    $(->
        $(".hidden").hide()
        $("#entryamiga").button {icons: {primary:"ui-icon-gear"}}
            .click ->
                stuff = $(@).children()
                if @.value == "1"
                    stuff[1].textContent = 'Ansi'
                    @.value = "0"
                else
                    stuff[1].textContent = 'Ascii'
                    @.value = "1"
        $(".45box").css {width:'45%',display:'inline-block'}
        $(".groupbox p").css {margin:"0 0 .25em 0"}
        $("#entryfilepick").change ->
            if @.files[0]? then $("#entryfile").val @.files[0].name
        $("#entryfile").click ->
            $("#entryfilepick").click()
    )

The sahli file definition format is as follows:
"file" - the actual filename on disk, "name" - the title of the piece,
the boolean 'amiga' indicates if it is ansi or ascii (True = ascii),
width is the width (widest point of the file), author the author of the piece,
the color and bg items define the color for amiga ascii, and the font
defines the font similarly.  For PC ansi, this should be 'ansifont.'
The three remaining lines are informational and optional.

The slide format is currently unused, but consists of a background picture,
a html template, and a css file.

    class Sahli
        constructor: ->
            @emptyfiledef = {
                "file": "",
                "name": "",
                "amiga": true,
                "width": "",
                "author": "",
                "font": "Propaz",
                "color": [ 0,0,0,0 ],
                "bg": [ 0,0,0,0 ],
                "line1": "",
                "line2": "",
                "text": ""
            }
            @emptyslidesdef = {
                "background": "",
                "template": "",
                "css": ""
            }
            @empty = {
                "slides": @emptyslidesdef,
                "filedata": [ ]
            }

        loader: ->
            $.ajax {
                url: '../list.sahli',
                dataType: "json",
                success: (result) =>
                    @data = result
                    @.edit()
            }

Editor functionality:
Close the new/load buttons - unneeded now.
list, and allow dragon-droppings for sorting.  Doubleclick to edit, or use
edit button.

        edit: ->
            $('#buttonbox').hide()
            $('#listsave').button {icons: {primary:"ui-icon-disk"}}
                .click =>
                    console.log dumpjson @.data


You need to save the order, and extract these in that order; moving around
does not alter the array. Alternately, _have_ it alter the array.

            @buildlist @data

        buildlist: (data) ->
            $('#list').show 100
            x = 0
            $('#sortlist').append @.additem item,x++ for item in @data.filedata
            $('#sortlist').sortable
                start: (event,ui) ->
                    ui.item.data {startpos:ui.item.index()}
                stop: (event,ui) =>
                    s = ui.item.data().startpos
                    e = ui.item.index()
                    @data.filedata = @.rearrangearray s,e,@data.filedata
                    console.log name.author for name in @data.filedata
                    console.log '---'

Given a start and and end position, pop the array element at start off and
insert it into the array at end position.  A la the draggon-dropping.

        rearrangearray: (startpos,endpos,a) ->
            moving = a[startpos]
            alen = a.length
            tarr = a[0...startpos].concat a[startpos+1..-1]
            tarr[0...endpos].concat [moving].concat tarr[endpos..-1]


        additem: (item,pos) ->
            entry = $("<li class='entry' id='#{item.file}'><span class='ui-icon ui-icon-arrowthick-2-n-s'></span>#{ansiorascii booltoint item.amiga} | #{item.author} : #{item.name} : #{item.file}</li>")
            entry.dblclick =>
                    @.editline item,pos

        save: ->
            pos = $("#entryindex").val()
            entry = @data.filedata[pos]
            entry.name = $("#entryname").val()
            entry.author = $("#entryauthor").val()
            entry.amiga = statustobool $("#entryamiga").children()[1].textContent
            console.log $("#entryamiga").children()[1].textContent,entry.amiga,entry.author
            entry.color = colortoarray $("#entrycolor").val()
            entry.bg = colortoarray $("#entrybg").val()
            entry.width = $("#entrywidth").val()
            entry.line1 = $("#entryline1").val()
            entry.line2 = $("#entryline2").val()
            entry.text = $("#entrytext").val()
            entry.file = $("#entryfile").val()

        editline: (data,pos) ->
            $("#formica").dialog {
                width:'800',
                modal: false,
                title:"Entry #{data.file} ",
                buttons: [{
                    text: "Cancel",
                    icons: {primary: 'ui-icon-trash'},
                    click: ->
                        $(@).dialog "close"
                },{
                    text: "Save",
                    icons: {primary: 'ui-icon-disk'},
                    click: ((_this) ->
                      (event) ->
                        event.preventDefault()
                        _this.save()
                        $(this).dialog "close"
                    )(this)
                }]
            }

            data.amiga = booltoint data.amiga

            $("#entryindex").val pos
            $("#entryname").val data.name
            $("#entryauthor").val data.author
            $("#entryamiga").val data.amiga
            $("#entryamiga").children()[1].textContent = ansiorascii data.amiga
            $("#entryfont").val data.font
            $("#entrycolor").val colortoname arraytocolor data.color
            $("#entrybg").val colortoname arraytocolor data.bg
            $("#entrywidth").val data.width
            $("#entryline1").val data.line1
            $("#entryline2").val data.line2
            $("#entrytext").val data.text
            $("#entryfile").val data.file


A Helper function to dump json out of an object as text:

    dumpjson = (obj) ->
        JSON.stringify obj,null,"\t"

Boolean / integer Helpers

    booltoint = (bool) ->
        bool + 1 - 1

    inttobool = (intstr) ->
        (intstr == 1).toString()

    statustobool = (status) ->
        if status is 'Ascii' then true else false

Resolve ansi or ascii status

    ansiorascii = (status) ->
        if status is 0 then "Ansi" else "Ascii"


Color conversion from array to color item:

This decimal to hex conversion only handles 00-FF but it's fine for this purpose;
we actually _want_ that limitation in the output.

    dec2hex = (num) ->
        "#{('000'+num.toString 16).slice -2}"

    hex2dec = (num) ->
        parseInt num,16

    arraytocolor = (array) ->
         c = (dec2hex x for x in array)[0..2].join ''
         "##{c}"

    colortoarray = (color) ->
        color = color.slice(1)
        c1 = [ color[0..1], color[2..3], color[4..5] ]
        x = (hex2dec i for i in c1)
        x.push 0
        x


Need a way to convert the array back to the color name.

    colortoname = (color) ->
        names = {
            "#E0E0E0":"Light Grey"
            "#A0A0E0":"Light Blue"
            "#9AFE2E":"Light Green"
            "#FF0000":"Red"
            "#FF8000":"Orange"
            "#FFFF00":"Yellow"
            "#00f000":"Green"
            "#2EFEF7":"Cyan"
            "#2EFEF7":"Blue"
            "#0B0B3B":"Navy"
            "#FF00FF":"Magenta"
            "#8000FF":"Purple"
            "#0A2A0A":"Dark Green"
            "#3B3B3B":"Dark Grey"
            "#FFFFFF":"White"
            "#000000":"Black"
        }
        color = color.toUpperCase()
        x = if hex2dec(color.slice(1)) > 8421504 then "#FFFFFF" else "#000000"

When clicking 'New' we want to make a brand new Sahli, and then clear out
the buttons and create the editor bit as blank.

    newsahli = ->
        sahli = new Sahli
        sahli.data = sahli.empty
        sahli.data.filedata.push sahli.emptyfiledef
        sahli.edit()

And when clicking 'load' we want to load the existing sahli file.

    loadsahli = ->
        sahli = new Sahli
        sahli.loader 'list.sahli'

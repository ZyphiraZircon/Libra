# Libra #

# A updated and upgraded target information bar for FFXI Windower.

Displays a configurable bar showing information on your targets.

Data and assets retrieved from the BG Wiki (https://www.bg-wiki.com)

----

### Commands: ###

#### help ####
`//libra help`

Shows a list of commands and you current settings

#### scale ####
`//libra scale <number 0.5 through 3>`

Specifies the visual size of the addon. Numbers with decimals are accepted, between 0.5 and 3

#### position ####
`//libra pos <x_value> <y_value>`

Specifies the position in pixels of the addon on your screen. Accepts integers. The upper left corner of the screen is x0,y0, with x increasing rightwards and y increasing downwards.

#### padding ####
`//libra padding <number>`

Specifies the space between the edge of the background and the display text. Whole numbers with decimals are accepted, measured in pixels.

#### alpha ####
`//libra alpha <number 0 through 1>`

Specifies the transparency of the background. Numbers with decimals are accepted, between 0 and 1, with 0 being fully transparent and 1 being fully opaque

#### multi-line mode ####
`//libra multiline <yes or no>`

Specifies if Libra should have its information segments in individual lines of text, or if should all exist on one line

----

### Installation: ###

* Click the green `<> Code` icon on the top right of this page and Download ZIP
* Open the .zip file
* Move the folder called Libra-main into your Windower/AddOns directory
* Important: Remove the "-main" part of the folder name
* Go to your Windower/scripts directory
* Open init.txt
* Add the line `lua l libra` to the bottom of the file; save and close
* NOTE: This plugin might overlap with InfoBar if you have it installed, make sure to move or disable InfoBar from the AddOns configuration when you next launch Windower

----

### Reporting Issues: ###

While the database is pretty up to date I may have missed a few mobs or resistances, if you see any issues send an email to zyphira.libra@gmail.com or hit me up on Bluesky [@zyphira.vanadiel.network](https://bsky.app/profile/zyphira.vanadiel.network)

Check back every so often for database updates and improvements!

----

### Credits: ###

* Zyphira (Dhizi on Bahamut) ((that's me!)) for the coding, putting together the database, and the layout
* The BG Wiki for being the actual data source, as well as most of the icons
* Kenshi for the original InfoBar
* DTR (Daleterrance on Bahamut) for kicking this whole thing off
* The AzureSkies Linkshell on Bahamut! (<3)
* And you!


No AI was used to make this AddOn
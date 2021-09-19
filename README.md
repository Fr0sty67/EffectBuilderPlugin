# EffectBuilderPlugin
A plugin for LuckyAPI
Effect Builder Plugin utility package for Luck be a Landlord

Developed by PudgePlays for LBAL Content Patch #11
Document Version 1.0


Overview
======================================================
This package is meant to supplement LuckyAPI as an extension to functionality.
It allows modders to pick from a handful of ready-built tools, allowing them
to bypass the difficult process of debugging

Simply follow the instructions to create custom LBAL symbols with ease!

Limitations:
  - There are no current nor future plans to accommodate Patched Symbols
  - Most logic is 'AND', therefore some things won't be possible with the
    current version
  - A bug is present in the base game which causes "eater" (Mrs Fruit et al)
    symbols to not gain their gold bonus effects if there are multiple in the
    reels and their targets are not adjacent. This is a very rare occurrance
    but must be noted nonetheless


Installation
======================================================
Drop the .zip folder inside the mods directory alongside your other mods

Within your mod.json file, add "effect-builder-plugin" as a dependency

Done! You should now be able to use the packgage


Applying EBP to your mods
======================================================
EBP acts as a go-between for the LuckyAPI effect builder and the modder.
It allows for people with very little coding experience to create relatively
complex symbols in a manner of minutes

To access the functions provided by this plugin, you must first include the
abstract base class (ABC) "AbstractSymbol.gd" in each of your modded symbols.

2.i. Adding EBP functions to a modded symbol
======================================================
Replace any other inheritance with the following:

extends "res://effects-builder-plugin/symbols/AbstractSymbol.gd"


The AbstractSymbol class extends the LuckyAPI ModSymbol, so all the usual
parameters and methods will remain accessible


Additionally, the 'init' function for symbols MUST always start with:

func init(modloader: Reference, params):
	.init(modloader, params)


Once that is done, you're ready to build a symbol!


Symbol effects
======================================================
There are currently four supported effects that can be added to a symbol.

All effects can utilize any number of Conditions (see below). There is no
limit to how many can be applied (however having too many may cause issues)

Destroying, Transforming and Buffing can also each have a Target (see below)

All of these can be set witin your 'init' block. No further function
declarations are required


The following setters are consistent between all effects:

.random(value : int) // Accepts an integer between 1 and 100
.animate(animation : String, sfx_index : int) // SFX defaults to index 0
.add_condition(condition : Dictionary) // See below about how to write conditions
.consumes() // Destroys the current symbol after the effect


Adding
======================================================
Attribute: self.adds : Array (of Spawnables)

'New' function: add()


Setters:

.set_new_type(type : String) *
.set_new_group(group : String, minimum_rarity : String) * 
.set_quantity(quantity : int) // Defaults to 1

* mutually exclusive, at least one mandatory

An example:

  self.adds.push_back(add().set_new_type("dog").set_quantity(3).animate("bounce")) >> Adds 3 dogs each spin


Destroying
======================================================
Attribute: self.destroys : Array (of Destroyers)

'New' function: destroy()


Setters:

.set_type(type : String) *
.set_group(group : String) * 
.set_buff(buff_type : String, value : int) // For if you want an on-kill reward for the consuming symbol
.set_target(target : Dictionary, number : int, random : bool) // See below for more info on targeting

* mutually exclusive, NOT mandatory

An example:

  self.destroys.push_back(destroy().set_group("human").set_buff("temporary_bonus", 20).animate("bounce")) >> General Zaroff's code remade


Transforming
======================================================
Attribute: self.transforms : Array (of Transformables)

'New' function: transform()


Setters:
.set_type(type : String) *
.set_group(group : String) * 
.set_new_type(type : String) **
.set_new_group(group : String, minimum_rarity : String) **
.empties() // If you want to be able to transform "empty" tiles. Ignored if a type or group is provided
.set_target(target : Dictionary, number : int, random : bool) // See below for more info on targeting

* mutually exclusive, NOT mandatory
** also mutually exclusive, at least one mandatory

An example:

  self.transforms.push_back(transform().set_type("monkey").set_new_group("human", "rare").animate("shake")) >> Transforms adjacent monkeys into rare or better humans


Buffing
======================================================
Attribute: self.buffs : Array (of Transformables)

'New' function: buff()


Setters:
.set_type(type : String) *
.set_group(group : String) * 
.set_buff_type(buff_type : String) // Defaults to "temporary_multiplier"
.set_value(value : int) // Defaults to '2'
.empties() // If you want to be able to buff "empty" tiles. Ignored if a type or group is provided
.set_target(target : Dictionary, number : int, random : bool) // See below for more info on targeting

* mutually exclusive, NOT mandatory

An example:

  self.buffs.push_back(buff().set_type("rabbit").set_buff_type("permanent_bonus").consumes().animate("bounce")) >> Gives adjacent rabbits +2 permanently and is destroyed after


The Target builder
======================================================
Sometimes you may want to affect symbols that aren't adjacent. For this, you can use
the TargetBuilder

A target can be added to selected effects by calling .set_target()

Do NOT attempt to create a TargetBuilder object yourself (as it has a ton of logic to
confirm that you aren't sending it junk data)


An example target:
  .set_target({"all" : {})

This basic target affects all symbols on the reels (pseudo-global adjacency)
NOTE: Targeting doesn't modify a symbol's actual adjacency


Every type of targeting also has an equivalent NOT:
  .set_target({"edges" : {"not" : true}})

This will only affect symbols in the middle 6 spaces of the reels


You can also chain targets together within the same dictionary. Here's a more
complex target:
  .set_target({
    "row" : {"include_self": true},
    "column" : {},
    "corners" : {},
  })

This code gets all symbols in the same row, same column, and corners. The "include_self"
parameter causes the calling symbol to add itself to its targets


Symbols that are present in more than one targeting condition are only added ONCE to
the pool of targets

Currently all targeting is additive ('AND').
There are plans for future updates to overhaul targeting to allow for more complex logical
operations, including number of targets and whether the targeting is random or by grid order*

(*The parameters exist but the functionality is not yet implemented)


Conditions
======================================================
There are a multitude of conditions that can be applied to effect

These can be chained together to make more complex scenarios

A condition can be added to any effect by calling .add_condition()

Conditions accept dictionaries that at the very least must have the key "condition"

Do NOT attempt to create a Condition object yourself (as it has a ton of logic to
confirm that you aren't sending it junk data)

An example condition:
  .add_condition({
    "condition" : "turns",
    "operator" : "at_least",
    "value" : 3
  })

The above condition will prevent the effect from firing if the age of the symbol is < 3 spins

Put into practice:
  self.adds.push_back(add().set_new_type("cheese").add_condition({
    "condition" : "adjacent",
    "type" : "cow"
  }).add_condition({
    "condition" : "symbol_count",
    "operator" : "less_than",
    "source" : "inventory"
    "type" : "cheese",
    "value" : 5
  }).animate("shake"))

This code will add cheese if the symbol is next to a cow, but only if there are
fewer than 5 cheese already in the inventory

There are many other conditions that can be applied. See the next section for a
list of currently added checks


Accepted parameter values
======================================================

Buffable (including Destroyer buff effects)
===========================================
"temporary_bonus"
"temporary_multiplier"
"permanent_bonus"
"permanent_multiplier"
"draining"

The Hex of Draining ability can only be applied to buffables and not destroyers:

  self.buffs.push_back(buff().set_type("human").set_buff_type("draining").animate("rotate")) >> Drains adjacent humans


TargetBuilder
=============
"adjacent" // default behavior
"all" // all displayed symbols*
"self" // the current symbol
"row" // symbols in the same row*
"column" // symbols in the same column*
"corners" // symbols in the corners
"edges" // symbols on an edge
"above" // symbols above the current symbol in the same column
"below" // symbols below the current symbol in the same column
"left" // symbols left of the current symbol in the same row
"right" // symbols right of the current symbol in the same row
"diagonal" // symbols in any four diagonals from the current symbol

        "not" : bool // inverts the selected symbols (all - selection)
        "include_self" : bool // will add the current symbol to the list of targets


Condition
=========

Adjacency
---------
"condition" : "adjacent"
"type"* : String // the type of symbol
"group"* : String // the group of symbol
"operator" : one of > "at_least"
                    > "less_than"
                    > "exactly"
                    > "every"
"value"** : int
"not" : bool
"target" : one of > "self" // the current symbol
                  > "other" // the symbol affected by the effect

*NOT mutually exclusive, mandatory
** NOT mandatory if you select the "every" operator

Turn Count (spins displayed)
----------------------------
"condition" : "turns"
"operator" : one of > "at_least"
                    > "less_than"
                    > "exactly"
                    > "every"
"value" : int
"not" : bool
"target" : one of > "self" // the current symbol
                  > "other" // the symbol affected by the effect

Count Symbols
-------------
"condition" : "symbol_count"
"type"* : String // the type of symbol
"group"* : String // the group of symbol
"operator" : one of > "at_least"
                    > "less_than"
                    > "exactly"
                    > "every"
"value" : int
"not" : bool

*mutually exclusive, NOT mandatory

Has Item
--------
"condition" : "item"
"type" : String // the type of item
"not" : bool

In Corner
---------
"condition" : "corner"
"not" : bool
"target" : one of > "self" // the current symbol
                  > "other" // the symbol affected by the effect

On Edge
-------
"condition" : "edge"
"not" : bool
"target" : one of > "self" // the current symbol
                  > "other" // the symbol affected by the effect

Destroyed
---------
"condition" : "destroyed"
"not" : bool


FAQ
======================================================
Q: Something doesn't work! Help!!!
A: Not a question. Use your head


Q: But I don't want to use my head!
A: Shh! You're killing the Buzz around here. Also not a question


Q: Why are your jokes so lame?
A: Deal with it


Q: Okay, so something isn't working and I don't know why. Your plugin must be broken
A: Check the Godot log file to see if there is an error. I've thrown many errors
   into the code to break out if the wrong parameters are supplied to an effect.
   (Isn't it much nicer for the game to break right away with a clean error message?)


Q: There's nothing in the log file. Your code is trash
A: Did you check that you have called the right functions?
   Is the symbol.gd file inheriting AbstractSymbol?
   Have you included '.init(modloader, params)' inside the symbol's init function?


Q: Everything checks out. There are no spelling mistakes, all the parameters are correct
   but it still isn't working. What do I do?
A: Post your code in the Discord server and tag me


Q: You're not responding on Discord
A: I'm a busy person working on a ton of projects. Somebody else might be able to help you


Q: Nobody else can find the problem with my code
A: Post a bug on my GitHub page and I'll get around to looking at it
   DO NOT POST BUGS WITHOUT EXHAUSTING YOUR OTHER OPTIONS FIRST

Q: The game keeps crashing after a spin. Why?
A: This shouldn't happen if you're using only my effect builder.
   It may be another mod doing that. Uninstall other mods and try again


Q: It's still crashing
A: Comment out lines within your symbols until it stops crashing, then send me the broken
   function call in a DM on Discord


Q: My symbols don't have a description! Why?
A: The parent never sets the description, so that still needs to be done on each of the symbols.

   Simply add:
     self.description = .get_description()
   
   After ALL of the other sets within the 'init'
   This will populate the description for you


Q: What is this "flavor_text" attribute?
A: You can now add flavor text to any symbol.
   Set the self.flavor_text to any String then add it to your description
   
   e.g.
     self.description = .get_description() + .get_flavor_text()
   
   It will format itself and change the text color


Contact
======================================================
LuckyAPI Discord: https://Discord.gg/7ZncdvbXp7
My GitHub (find the EBP repository): https://GitHub.com/Fr0sty67
Phone number: piss off
Email: also piss off


Feature Requests and Updates
======================================================
If you would like anything added please post a request on the GitHub
or Discord (tag me)

Feel like contributing yourself? Branch and send me a pull request of
your changes

NOTE: I reserve the right to accept or reject any changes made to the plugin


Legal S#%t
======================================================
Effects Builder Plugin for LBAL is provided under the MIT Licence

Copyright 2021 "PudgePlays"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

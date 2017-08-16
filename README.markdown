# "why", and some teasers

I have way too many little functions and aliases (you probably do too).  In
most of them, except for the simplest cases, option/argument validation and
processing is a pain, taking up far more code than the real stuff.

That's what active aliases helps with.  (I know that's a silly name, so most
of the documentation will call it **aa**.  Also, for reasons I no longer
remember, the actual binary is `__` -- yes, that's two underscores as a binary
name!).

## teaser example: multi-grep with negations

I want to say `grep word1 word2 -word3 -word4` to find lines that contain both
word1 and word2, but NOT word 3 or word4.

I didn't have the energy to even try this in shell; feel free to try it out
and email me (sitaramc@gmail.com). I am sure it will be nowhere near as simple
as this **aa** code:

    mgrep % %%
        @__ mgrep %1 | __ mgrep %2
    mgrep -%$
        mgrep -v %1
    mgrep
        @grep -i

## teaser example: implicit command

I got tired of typing 'geoiplookup' on suspicious IP addresses found in my
logs.  My initial thought was to alias 'geoiplookup' to 'gl' or something, but
the way I get those IP addresses is usually mouse driven so if I could just
paste the IP and hit enter, that would be *great*!

    (\d+\.\d+\.\d+\.\d+)$
        @geoiplookup %1

That's it!  Just drop an IP on the command line and hit enter.  (And yes I
know that regex catches invalid IPs also; in this use I don't care.  I'm
getting the IPs from a log file so they're already valid.)

## getting started

There are two ways to use **aa**.  The first is to create a file called
`.__rc` in your home directory, into which you'll put **aa** code for your
most common command line tasks.  The other is to embed **aa** code in a shell
script.

**Install**: just copy the `__` script to some place in your PATH.

**Examples**: mostly in this file, though some may still be hiding in the
[reference documentation][md].

**Syntax, etc.**: the [reference documentation][md] has slightly more formal syntax
and semantics, though the examples should cover mostly everything anyway.

[md]: http://gitolite.com/active-aliases/index.html

# making aa work at the command line

## example 1: the most common find options

The `find` command has lots of options, but I only use a few regularly.  And
those, I use a lot -- enough that typing them in full each time is a pain.  I
want to type in, say `ff . -f -n foo -t -4`, and it should run `find . -type f
-name "*foo*" -mtime -4`.

Again, I didn't have the energy to try it in shell; feel free to do so and
compare to this:

    ff %% -n %
        ff %1 -name "*%2*"
    ff %% -(f|d)
        ff %1 -type %2
    ff %% -t
        ff %1 -mtime
    ff %% -s
        ff %1 -size
    ff
        find

Put this in your `~/.__rc`, then run `__ ff . -f n foo -t -4`.  Once you see
it works, look in the appendix in the [reference documentation][md] for how to make
`ff` run directly, without having to prefix it with `__`.

## how does it work?

**Here's how the above code works**.  In each pair of lines, the first one is
a **pattern** that the current command (say `ff . -f -n foo`) will be matched
against.  In this matching, `%%` means any number of any characters, and `%`
is any number of non-space characters.

If the match succeeds, the next line is treated as a **replacement**, with
matched substrings replacing the corresponding `%1`, `%2`, etc.  (It helps if
you know a little about regular expressions but it's not strictly necessary).

If the match does not succeed, we move on to the next pattern.

What remains at the end, after all the pattern/replacement pairs have been
traversed, is simply executed.

A pattern starts matching from the beginning of the current command, but does
not have to match the entire command.  Whatever was not matched is kept as-is
and appended to the replacement.  (This is used in all the patterns above, but
is most visible in the last pattern/replacement pair, which are both just one
word!)  This also means you can add any other find option from the man page,
it will be retained in its proper place!

## example 2: use shortcuts and set default values

My old laptop sometimes had some temperature issues, so I would have to set an
appropriate CPU frequency "governor".  Instead of the full command, I want to
just type `cpu cool` or `cpu fast`.

Here's the **aa** code to do this, with my old shell function on its right for
comparison.

    cpu$                                    |   # my old shell function
        cpu cool                            |   cpu() {
    cpu cool$                               |       [ -z "$1" ] || [ "$1" = "cool" ] &&
        cpu powersave                       |           cpupower -c all frequency-set -g powersave && return
    cpu fast$                               |       [ "$1" = "fast" ]                &&
        cpu performance                     |           cpupower -c all frequency-set -g performance && return
    cpu                                     |       cpupower -c all frequency-set -g "$1"
        cpupower -c all frequency-set -g    |   }

Sure, it's not much different in terms of lines of code, but the
correspondence between the shortcuts and the long forms is much clearer, and
there's a lot less *noise* overall.

Oh and did you notice this example doesn't even use `%` or `%%`?

You can use governors other than `powersave` and `performance`, for example by
saying `cpu ondemand`.  This skips the first 3 patterns (and their
replacements), and goes to the last one, making the command `cpupower -c all
frequency-set -g ondemand`.

## example 3: forcing wget to use https

I want to force `wget` to use https, even if I mistakenly supply an http URL.
*Note that the URL may not be the first argument*, since I should be able to
use any valid wget option before and/or after the URL.

I'd like an alias/function named `wg` to do this.

Here are the two pieces of code, for comparison:

    wg %% http://%          |   # (untested)
        wg %1 https://%2    |   wg() {
    wg http://%             |       args=
        wg https://%1       |       for j
    wg                      |       do
        wget                |           [[ "$j" =~ ^http: ]] && j=${j/http/https}
                            |           args="$args $j"
                            |       done
                            |       wget $args
                            |   }

## other examples

`glg` shows the last N (default 5) git commit subject lines.

    glg$
        glg 5
    glg (\d+)$
        git log --oneline -%1 | less -R -F

These are my most frequently used chmod options.  Like in the 'cpupower'
example, we're not even using `%` or `%%` here.

    ch r
        chmod -R go+rX
    ch w
        chmod u+w
    ch x
        chmod +x

# using aa inside a shell script

The examples till now have all been snippets of code from my `~/.__rc`.  The
shell function shown in the appendix in the [reference documentation][md] helps
turn them into commands I can run directly, like `cpu cool`, or `ff .  -f -n
foo`, without having to run `__` explicitly.

But **aa** can also be used **within** shell scripts as a parsing helper.  In
extreme cases, the entire script can be **aa** code too!

## example 1: the whole thing is an aa script

Take a quick look at this script (line numbers added for convenience):

     1  #!/bin/bash
     2
     3  __ $0 args $@
     4  exit $?
     5  #!__
     6
     7  # main code
     8
     9  args status$
    10      args 1 status
    11
    12  args (\d+) status$
    13      some-command --block %1 --status
    14
    15  args (\d+) (start|stop)$
    16      args %1 %2 1
    17
    18  args (\d+) (start|stop) (\d+)$
    19      some-command --block %1 --cmd %2 --from %3
    20
    21  args (\d+) (start|stop) (\d+) (\d+)$
    22      some-command --block %1 --cmd %2 --from %3 --to %4
    23
    24  args.*
    25      @echo >&2 "Usage:
    26      $__SCRIPT [<block number>] status
    27      ... default block number is 1
    28      $__SCRIPT <block number> start|stop  [<from-index> [<to-index>]]
    29      ... default from-index is 1, no default for to-index
    30      "
    31      exit 1

This is a bash "wrapper" script for "some-command", helping to use the most
common features.  The first subcommand is 'status', which takes an optional
"block number" (whatever that is!), and defaults to 1.

Then you have 'start' and 'stop' subcommands that require a block number, and
operate on some "indexes" (whatever *they* are!), and have some defaults as
described there.

*   Lines 3-5 take the command line arguments, and pass them to the "args"
    active alias in *this* file (because of the `$0`).

*   Lines 9 and on work just like the examples you saw previously -- a pattern
    and a replacement.  When the matching runs off the end, what's left is
    executed.  (Also, notice how line 9 and 10 deal with setting up the
    default when the user does not specify one.)

    The only thing new about this is in lines 25-31, which show that a
    replacement can be multi-line too.

Try to do this in pure shell.  Don't forget to make sure the block and index
numbers are actually *numbers* (the code above does that too!)

## example 2: using aa in part of a script

The previous example was exclusively an aa script.  But more often, your
script will be a normal bash (or sh) script, while using aa for any tricky
parsing situations.

For example, say at some point in the script you need the current mouse
position on screen.  The simplest way to do this is to install `xdotool` and
use `xdotool getmouselocation`, which produces output like this:

    x:425 y:228 screen:0 window:50331651

We need to get that 425 into a variable called `POS_X` and the 228 into a
variable called `POS_Y` so that the rest of the script can use it.

In shell, that would be at least

    eval $( eval `xdotool getmouselocation|sed -e 's/:/=/'g`; echo POS_X=$x POS_Y=$y )

which is not bad if you like that sort of thing...

...but the **aa** code looks cleaner and more maintainable.  The invocation
happens wherever you need it in your shell script:

    eval $(__ $0 parse `xdotool getmouselocation`)
    # can use $POS_X and $POS_Y now

though the actual code is always at the bottom of your shell script:

    exit $?     # bash should not be allowed to execute beyond this point
    #!__        # required marker for start of aa code
    parse x:% y:% %%
        @echo POS_X=%1 POS_Y=%2

Here's another example: finding the IP address of the interface that has your
default route.  This takes two steps: get the device name from `ip route`,
then the inet address from `ip address show`.

In shell, these two steps are:

    dev=`ip route | grep default | egrep -o 'dev [^ ]+' | cut -f2 -d' '`
    IP=`ip address show $dev | egrep -o 'inet [^ ]+' | cut -f2 -d' ' | cut -f1 -d/`
    # now use $IP

(which again is not bad at all, if a bit noisy).

With active aliases, you'd do this.

    # somewhere in the script
    IP=`__ $0 IP`

    .
    .
    .

    # bottom of script:
    exit $?
    #!__

    IP
        IP `ip ro | grep default`
    IP %% dev % %%
        IP `ip addr show dev %2 | grep 'inet '`
    IP inet %/% %%
        @echo %1

Sure that's a bit longer, but it looks cleaner, and makes the positions of the
bits of info you're pulling out very clear, including how easy it was to
extract the IP from something 1.2.3.4/24.

# more examples

Note: you won't get these example until you read about **conditions** in the
[reference documentation][md].  They're here because I decided all *examples*
should be in one place.

## mgrep with smartcase

We've already seen mgrep earlier.  By adding just 3 lines (lines 5-7 below),
you get "smartcase" -- a nice feature where a pattern is treated as
case-sensitive if it contains any uppercase letter, else it ignores case.
This applies to each search pattern separately.

    1  mgrep % %%
    2      @__ mgrep %1 | __ mgrep %2
    3  mgrep -%$
    4      mgrep -v %1
    5  mgrep %%
    6      @grep %1
    7      ?   "%1" =~ /[A-Z]/
    8  mgrep
    9      @grep -i

## argument parsing the easy way

Here's our final example, showing several tricks.

What it does is allow me to start youtube downloads using either the URL
itself, or the name of a file that was (maybe partially) downloaded, since the
file name contains the youtube "id" (that random 10-digit string you see in
youtube URLs).

    yd
        yd
        ?   chdir "$ENV{HOME}/yt"
    yd http%
        _yd http%1
    yd %.part
        yd %1
    yd .*-(\S{10,})\.\w+$
        _yd https://www.youtube.com/watch?v=%1
    _yd
        youtube-dl

Points to note:

*   the first rule shows a side-effect being used (change directory); notice
    that the replacement is the same as the pattern so the actual command does
    not change, but now your $PWD is different.

*   if an argument starting with http is seen, the second rule *changes the
    command name* from `yd` to `_yd`.  This is a clever way to *bypass* all
    other rules matching the 'yd' command.

*   a trailing ".part" is removed from the argument in the 3rd rule.  This is
    the kind of thing where the idea of step-by-step morphing a command rule
    becomes really intuitive.

*   and finally, the 4th rule gets the juicy bit (the 10-character youtube
    "id") from the file name, constructs a URL from it, and (like rule 2)
    changes the command name to `_yd`.  In spirit, this isn't much different
    from rule 3, just that the expression is a bit more complex.

Why couldn't we remove rule 5 and simply use 'youtube-dl' in rules 2 and 4?
We could, but if we want to add any default arguments etc., later, we'd need
to add them in two places.

Now... try that in any shell :)


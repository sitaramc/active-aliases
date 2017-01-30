Full documentation is [here](http://gitolite.com/active-aliases/index.html).

# "why", and some teasers

I have way too many little functions and aliases (you probably do too).

Except for the simplest cases, option/argument processing is a pain.

I want a quick and easy way to deal with options/arguments I care about, while
leaving the rest of the command as-is.

Here are some examples.  Don't worry about the syntax while reading them; this
is just a teaser, and the [main
documentation](http://gitolite.com/active-aliases/index.html) has all the
details.

## example 1: modify an argument

I want to force `wget` to use https, even if I mistakenly supply an http URL.
*Note that the URL may not be the first argument* -- you should be able to use
any valid wget option before and/or after the URL.

I'd like an alias/function named `wg` to do this.

My shell function would have looked like this:

    # (untested)
    wg() {
        args=
        for j
        do
            [[ "$j" =~ ^http: ]] && j=`echo $j|sed -e 's/http/https/'`
            args="$args $j"
        done
        wget $args
    }

but with active-aliases, I use this:

    wg %% http://%      wg %1 https://%2
    wg http://%         wg https://%1
    wg                  wget

(Although I said "don't worry about the syntax", you can probably see that
there is a "left side" and a "right side", and also guess that the `%`, `%%`,
on the left side correspond to `%1`, `%2`, etc., on the right).

## example 2: use shortcuts and set default values

My laptop sometimes has temperature issues, and then I need to throttle the
CPU frequencies down.

This was my shell function (in days gone by):

    cpu() {
        [ -z "$1" ] || [ "$1" = "cool" ] && cpupower -c all frequency-set -g powersave && return
        [ "$1" = "fast" ]                && cpupower -c all frequency-set -g performance && return
        cpupower -c all frequency-set -g "$1"
    }

But now I use this:

    cpu$                cpu cool
    cpu cool$           cpu powersave
    cpu fast$           cpu performance
    cpu                 cpupower -c all frequency-set -g

This does exactly the same thing, but the default value, as well as the
correspondence between the shortcuts and the long forms is much clearer.

(You may have guessed that the command morphs as it goes -- "cpu" becomes "cpu
cool", which then becomes "cpu powersave", which then becomes the longer
version that actually runs, because it can't change any more).

## example 3: multi-grep with negations

This is a doozy.

I want to say

    grep word1 word2 -word3 -word4

to find lines that contain both word1 and word2, but NOT word 3 or word4.

    mgrep % %%          __ mgrep %1 | __ mgrep %2
    mgrep -%$           grep -v -i %1
    mgrep %$            grep -i %1

(Note that the active-alias binary is called `__`; yup two underscores; for
more details see the
[documentation](http://gitolite.com/active-aliases/index.html)).

The shell version for this would be fairly similar and fairly straightforward,
but would look much uglier.

## example 4: changing many arguments

By now you can guess what this does (briefly, a laziness-aid for the most
common `find` options I use):

    ff %% -n %          ff %1 -name "*%2*"
    ff %% -i %          ff %1 -iname "*%2*"
    ff %% -(f|d|l)      ff %1 -type %2
    ff %% -t            ff %1 -mtime
    ff %% -m            ff %1 -mmin
    ff %% -s            ff %1 -size
    ff                  find

You may want to start with `ff . -f -t -10 -s +100M` and run that through each
rule in succession, in your mind.


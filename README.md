# Jawaska team Computercraft programs

Jawaska Team's Computercraft code repository.

Contains programs and libraries.

# Installing

Installing pac in a new computer is easy, just run `pastebin run Ume1aeq1` and
you're done.

It copies a portable version of pac 1.0 and then updates and installs in the
system.

# Structure

Centralization has been abandoned, packages are now free to use, but official
packages are contained under this group.

This means that you can install any package like:

```
pac install @my-user/my-package
# or
pac install official-package
```

# Capabilities

The philosophy of pac has been simplified to it's minimum expression. This means
that things like dependencies or versioning is primarily controlled by the
install and update script.

Pac only needs that at the top of the repository, at master, a `info.lua` file
is present, which exposes at least the authorship of the package, and the
install, remove and update functions:

```lua
return {
  author = "sigmasoldier",
  description = "Here shall be a description",
  name = "Super duper package",
  install = function()
    -- Download files and copy them!
    return true
  end,
  remove = function()
    -- Delete them!
    return true
  end,
  update = function()
    -- I'm told to be updated!
    return true
  end
}
```

In fact, what pac does is call the function based on what parameters are passed.
For example if you do `pac install` the install function is invoked.

The unique difference is that install and remove will call also register() and
unregister() functions.

Functions should return `true` if the process went OK. In all cases will cause
the package info to update in the database except for remove, which will
remove the entry.

# Versioning

Versioning is simple: The update script will tell what and how to update, so
the author package responsible of proper handling.

Pac will use, at least with the default scheme, branches and tags if supplied,
or master if skipped.

This means that if you have a tag `1.0.0` one can run:

```
pac install my-package 1.0.0
```

And the `info.lua` file in that tag will be used.

# Extending

By default, pac only supports github scheme, but more schemes can be added as
modules in order to retrieve them from other repositories (Eg: From gitlab).

## The old format

If you see the tag https://github.com/JawaskaTeam/computercraft-programs/releases/tag/pre-patch
you can tell that the structure was very different.

The reason behind the change is simple: Simplification.

We've removed two main things that added complexity:
+ Custom data formats (.info file)
+ Complex and fragile versioning system (All need to follow sorted semver.)

For sake of simplicity, ease of maintenance and robustness.

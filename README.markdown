# ZipStripper

A utility to remove `__MACOSX` directories and `.DS_Store` files from existing Zip archives.

Uses `unzip -ql <zipfile>` to read the contents of the zip file,
then presents the contents to you in a window with `__MACOSX` directories and `.DS_Store` files
pre-selected, and a "Remove Selected" button.
When you click the button, it uses `zip -d <zipfile> <filelist>` to actually remove the selected files.

Note that this doesn't do any zip file parsing itself, but just shells out to `/usr/bin/zip`
and `/usr/bin/unzip` to do the heavy lifting.

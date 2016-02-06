#!/bin/sh

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Explain usage
usage() {
    echo "Usage:"
    echo "    $(basename "$0") init directory"
    echo "        Create mkblog.sh skeleton in directory."
    echo "    $(basename "$0") build directory"
    echo "        Build blog using files in directory."
}

# Init blog
init() {
    # Create directory if nonexistant
    if [ ! -d "$1/templates" ]; then
        mkdir -p "$1/templates"
    fi

# Write example header to templates
cat <<EOF >"$1/templates/header.html"
<!DOCTYPE HTML>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>My Blog</title>
  <style>
    body {
      width: 640px;
      max-width: 100%;
      margin: auto;
    }
    p {
      line-height: 1.6;
    }
    .title {
      margin-bottom: 0px;
    }
    .readmorelink {
      text-decoration: none;
      font-weight: bold;
      font-style: italic;
    }
  </style>
</head>
<body>
EOF

# Write example footer to templates
cat <<EOF >"$1/templates/footer.html"
<p><small>This blog was generated by <a href="https://notabug.org/SylvieLorxu/mkblog.sh" target="_blank">mkblog.sh</a></small></p>
</body>
</html>
EOF
}

# Build blog
build() {
    # Ensure directory exists
    if [ ! -d "$1" ]; then
        echo "$1 does not exist. Try $(basename "$0") init $1"
        exit 3
    fi

    # Clean build directory
    if [ -d "$1/build" ]; then
        rm -rf "$1/build"
    fi
    mkdir -p "$1/build/posts"

    # Write header to index file
    cat "$1/templates/header.html" >> "$1/build/index.html"

    # For each blog entry...
    for doc in $(find "$1" -iname \*.md | sort -r); do
        # Make sure there are blog entries
        if [ "$doc" = "$1/*.md" ]; then
            echo "$1 has no posts, create some first"
            exit 4
        fi

        # Get desired filename
        docbasename=$(basename "$doc")
        docnoext=${docbasename%md}
        posthtmlfilename="$1/build/posts/${docnoext}html"

        # Make sure the filename is correct (yyyy-mm-dd-title.md)
        # This is a very simple check because we want to avoid extended regular
        # expressions, just catch the worst user errors
        if ! echo "$docbasename" | grep -q "^[0-9]*-[0-9]*-[0-9]*-.*.md$"; then
            echo "$docbasename is not named correctly, skipping..."
            continue
        fi

        # Get date and title
        postdate=${docbasename%-*-*}
        posttitle=$(echo "${docbasename#*-*-*-}" | tr '-' ' ' )
        posttitle=${posttitle%.md}

        beforeposthtml="<h1 class='title'>$posttitle</h1><small class='postdate'>Posted on $postdate</small><article class='post'>"
        afterposthtml="</article>"

        # Create a page
        cat "$1/templates/header.html" >> "$posthtmlfilename"
        echo "$beforeposthtml" >> "$posthtmlfilename"
        < "$doc" markdown >> "$posthtmlfilename"
        echo "$afterposthtml" >> "$posthtmlfilename"
        cat "$1/templates/footer.html" >> "$posthtmlfilename"

        # And a short preview and read more link
        echo "$beforeposthtml" >> "$1/build/index.html"
        entrypreview=$(< "$doc" head -n 5 | sed -e 's/[[:space:]|.|?|!]*$//')"..."
        echo "$entrypreview" | markdown >> "$1/build/index.html"
        echo "$afterposthtml<p><a class='readmorelink' href='posts/${docnoext}html'>Read more</a></p>" >> "$1/build/index.html"
    done

    # Write footer to index file
    cat "$1/templates/footer.html" >> "$1/build/index.html"
}

# Check input
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

# Parse command
if [ "$1" = "init" ]; then
    if [ $# -ne 2 ]; then
        usage
        exit 2
    fi

    init "$2"
    exit 0
elif [ "$1" = "build" ]; then
    if [ $# -ne 2 ]; then
        usage
        exit 2
    fi

    build "$2"
    exit 0
else
    usage
    exit 1
fi

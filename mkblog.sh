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
    mkdir "$1"
    mkdir "$1/templates"
    mkdir "$1/pages"
    mkdir "$1/posts"

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
    #skip a
    {
      position: absolute;
      left: -10000px;
      top: auto;
      width: 1px;
      height: 1px;
      overflow: hidden;
    }
    #skip a:focus
    {
      position: static;
      width: auto;
      height: auto;
    }
    p {
      line-height: 1.6;
    }
    a {
      text-decoration: none;
      color: teal;
    }
    #pages li {
      display: inline-block;
      margin: 0 1em;
    }
    #pages a {
      font-size: 1.25em;
    }
    .backlink, .title {
      display: inline-block;
      margin-bottom: 0px;
    }
  </style>
</head>
<body>
EOF

# Write example footer to templates
cat <<EOF >"$1/templates/footer.html"
<p><small>This blog was generated by <a href="https://notabug.org/SylvieLorxu/mkblog.sh" target="_blank">mkblog.sh</a>.</small></p>
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
    mkdir "$1/build"
    mkdir "$1/build/posts"
    mkdir "$1/build/pages"

    # Write header and navigation start to index file
    { cat "$1/templates/header.html";
      echo "<div id='skip'><a href='#content'>Skip to Main Content</a></div>";
      echo "<nav id='pages'><ul>"; } >> "$1/build/index.html"

    # Create pages
    find "$1/pages" -name "$(printf "*\n")" -name '*.md' |
    while IFS= read -r page
    do
        helper_build_setfileinfovars "$1" "$page" "pages"
        echo "<li><a href='pages/${docnoext}.html'>$(echo "$docnoext" | tr '-' ' ')</a></li>" >> "$1/build/index.html"

        helper_build_createpage "$1" "$page" "$beforedochtml" "$afterdochtml" "$dochtmlfilename"
    done
    echo "</ul></nav><div id='content'>" >> "$1/build/index.html"

    # Create posts
    find "$1/posts" -name "$(printf "*\n")" -name '*.md' | sort -r |
    while IFS= read -r post
    do
        helper_build_setfileinfovars "$1" "$post" "posts"

        helper_build_createpage "$1" "$post" "$beforedochtml" "$afterdochtml" "$dochtmlfilename"

        # Add a short preview and read more link to the homepage
        entrypreview=$(< "$post" head -n 5 | sed -e 's/[[:space:]|.|?|!]*$//')"..."

        { echo "$beforedochtmlwithlink";
          echo "$entrypreview" | markdown;
          echo "$afterdochtml"; } >> "$1/build/index.html"
    done

    # Write footer to index file
    { echo "</div>";
      cat "$1/templates/footer.html"; } >> "$1/build/index.html"
}

# $1 = blog directory
# $2 = input document
# $3 = header html
# $4 = footer html
# $5 = output filename
helper_build_createpage() {
    { cat "$1/templates/header.html";
      echo "<h1 class='backlink'><a href='../index.html'>&#66306; </a></h1>";
      echo "$3";
      < "$2" markdown;
      echo "$4";
      cat "$1/templates/footer.html"; } >> "$5"
}

# $1 = blog directory
# $2 = file name
# $3 = file directory (pages/posts)
helper_build_setfileinfovars() {
    # Get desired filename
    docbasename=$(basename "$2")
    docnoext=${docbasename%.md}
    dochtmlfilename="$1/build/$3/${docnoext}.html"

    if [ "$3" = "pages" ]; then
        beforedochtml="<h1 class='title'>${docnoext}</h1><article class='page'>"
        afterdochtml="</article>"
    elif [ "$3" = "posts" ]; then
        docdate=$(echo "$docbasename" | cut -d '-' -f 1-3)
        doctitle=${docbasename#*-*-*-}
        doctitle=${doctitle%.md}
        beforedochtml="<h1 class='title'>$doctitle</h1><br><small class='postdate'>$docdate</small><article class='post'>"
        beforedochtmlwithlink="<h1 class='title'><a href='$3/${docnoext}.html'>$doctitle</a></h1><br><small class='postdate'>$docdate</small><article class='post'>"
        afterdochtml="</article>"
    else
        echo "Software error"
        exit 5
    fi
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

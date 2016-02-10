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
    if [ ! -d "$1/" ]; then
        mkdir "$1/"
    fi
    if [ ! -d "$1/templates/" ]; then
        mkdir "$1/templates/"
    fi
    if [ ! -d "$1/pages/" ]; then
        mkdir "$1/pages/"
    fi
    if [ ! -d "$1/posts/" ]; then
        mkdir "$1/posts/"
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
    img {
      max-width: 100%;
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
    .title {
      margin-bottom: 0px;
    }
    #prevnext {
      width: 100%;
      text-align: center;
    }
    .prev, .cur, .next {
      display: inline-block;
      font-size: 3em;
      width: 30%;
    }
  </style>
</head>
<body>
  <div id='skip'><a href='#content'>Skip to Main Content</a></div>
  <h1>My Blog</h1>
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
    if [ -d "$1/build/" ]; then
        rm -rf "$1/build/"
    fi
    mkdir "$1/build/"
    mkdir "$1/build/posts/"
    mkdir "$1/build/pages/"

    # Setup navbar and create pages
    navdata="<nav id='pages'><ul>"
    find "$1/pages/" -name "$(printf "*\n")" -name '*.md' > tmp
    while IFS= read -r page
    do
        helper_build_setfileinfovars "$1" "$page" "pages"
        navdata="$navdata<li><a href='pages/${docnoext}.html'>$docnoext</a></li>"

        helper_build_initpage "$1" "" "$dochtmlfilename"
        helper_build_endpage "$1" "$beforedochtml$(< "$page" markdown)$afterdochtml" "$dochtmlfilename"
    done < tmp
    rm tmp
    navdata="$navdata</ul></nav><div id='content'>"

    helper_build_initpage "$1" "$navdata" "$1/build/index.html"
    # Create posts
    count=-1
    find "$1/posts/" -name "$(printf "*\n")" -name '*.md' | sort -r > tmp
    while IFS= read -r post
    do
        count=$((count + 1))
        if [ $count -gt 0 ] && [ $((count%10)) -eq 0 ]; then
            nextpage=$((page + 1))
            helper_build_endpage "$1" "$(helper_build_generateprevnext "$page" "True")" "$1/build/index$page.html"
            page=$nextpage
            helper_build_initpage "$1" "$navdata" "$1/build/index$page.html"
        fi
        helper_build_setfileinfovars "$1" "$post" "posts"

        postmarkdown=$(< "$post" markdown)

        helper_build_initpage "$1" "$navdata" "$dochtmlfilename"
        helper_build_endpage "$1" "$beforedochtml$postmarkdown$afterdochtml" "$dochtmlfilename"

        # Shorten long posts in the preview
        if [ "$(echo "$postmarkdown" | wc -w)" -gt 50 ]; then
            # http://stackoverflow.com/a/15612523
            entrypreview=$(echo "$postmarkdown" | awk -v n=50 'n==c{exit}n-c>=NF{print;c+=NF;next}{for(i=1;i<=n-c;i++)printf "%s ",$i;print x;exit}' | sed -e 's/[[:space:]|,|.|?|!|-]]*$//')"..."
        else
            entrypreview=$postmarkdown
        fi

        { echo "$beforedochtmlwithlink";
          echo "$entrypreview" | markdown;
          echo "$afterdochtml"; } >> "$1/build/index$page.html"
    done < tmp
    rm tmp

    helper_build_endpage "$1" "$(helper_build_generateprevnext "$page")" "$1/build/index$page.html"
}

# $1 = blog directory
# $2 = nav html
# $3 = pagename
helper_build_initpage() {
  { cat "$1/templates/header.html";
    echo "$2"; } >> "$3"
}

# $1 = blog directory
# $2 = extra html (for example pagination or blog article)
# $3 = pagename
helper_build_endpage() {
  { echo "$2";
    echo "</div>";
    cat "$1/templates/footer.html"; } >> "$3"
}

# $1 pagenumber
# $2 hasnext
helper_build_generateprevnext() {
    page=$1
    extrahtml="<div id='prevnext'>"
    pagesfound=0
    if [ ! -z "$1" ]; then
        pagesfound=$((pagesfound + 1))
        previouspage=$(($1 - 1))
        if [ $previouspage -eq 0 ]; then
            previouspage=""
        fi
        extrahtml="$extrahtml<a class='prev' href='index$previouspage.html'>&laquo;</a>"
        page=$(($1 + 1))
    else
        extrahtml="$extrahtml<a class='prev'></a>"
        page="1"
    fi
    extrahtml="$extrahtml<span class='cur'>$page</span>"
    if [ ! -z "$2" ]; then
        pagesfound=$((pagesfound + 1))
        extrahtml="$extrahtml<a class='next' href='index$page.html'>&raquo;</a>"
    else
        extrahtml="$extrahtml<a class='next'></a>"
    fi

    # Don't print pagination if there are no other pages
    if [ $pagesfound -gt 0 ]; then
        echo "$extrahtml</div>"
    fi
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
        beforedochtml="<h1 class='title'>${docnoext}</h1><article id='content' class='page'>"
        afterdochtml="</article>"
    elif [ "$3" = "posts" ]; then
        docdate=$(echo "$docbasename" | cut -d '-' -f 1-3)
        doctitle=${docbasename#*-*-*-}
        doctitle=${doctitle%.md}
        beforedochtml="<h1 class='title'>$doctitle</h1><br><small class='postdate'>$docdate</small><article id='content' class='post'>"
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

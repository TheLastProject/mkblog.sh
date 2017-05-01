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
    printf "Usage:\n"
    helper_print_instruction "init" "Create mkblog.sh skeleton"
    helper_print_instruction "new page" "Create a new page"
    helper_print_instruction "new post" "Create a new blog post"
    helper_print_instruction "build" "Build blog using files"
}

# Init blog
init() {
    # Create directory if nonexistent
    if [ ! -d "$1/" ]; then
        mkdir "$1/"
    else
        helper_prompt_overwrite "directory"
    fi

    # set up blog variables
    printf "" > "$1/variables"
    helper_read_and_export "Blog title" "title" "$1/variables"
    helper_read_and_export "Blog subtitle" "subtitle" "$1/variables"
    helper_read_and_export "Blog URL" "url" "$1/variables"
    printf "var_mdproc=markdown\n" >> "$1/variables"

    # create relevant directories if nonexistent
    helper_check_and_make_dir "$1/templates/"
    helper_check_and_make_dir "$1/static/"
    helper_check_and_make_dir "$1/pages/"
    helper_check_and_make_dir "$1/posts/"

# Write example CSS to static
cat <<EOF >"$1/static/style.css"
body {
  width: 640px;
  max-width: 90%;
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
EOF

# Write example header to templates
cat <<'EOF' >"$1/templates/header.html"
<!DOCTYPE HTML>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="mkblog.sh" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${var_page} - ${var_title}</title>
  <link rel="stylesheet" type="text/css" href="${var_url}/static/style.css">
</head>
<body>
  <div id='skip'><a href='#content'>Skip to Main Content</a></div>
  <h1>${var_title}</h1>
  <h2>${var_subtitle}</h2>
EOF

# Write example footer to templates
cat <<EOF >"$1/templates/footer.html"
<p><small>This blog was generated by <a href="https://notabug.org/SylvieLorxu/mkblog.sh" target="_blank">mkblog.sh</a>.</small></p>
</body>
</html>
EOF
}

# Make a new page
new_page() {
    helper_directory_exists "$1"
    helper_read_into "Page title" "page_title"
    # this is assigned in helper_read_into, so we're safe
    # shellcheck disable=SC2154
    if [ -f "$1/pages/${page_title}.md" ]; then
        helper_prompt_overwrite "page"
    fi
    ${EDITOR} "$1/pages/${page_title}.md"
}

# Make a new blog post
new_post() {
    helper_directory_exists "$1"
    helper_read_into "Blog post title" "blog_post_title"
    blog_post_title=$(date "+%Y-%m-%d-%H:%M")-${blog_post_title}.md
    if [ -f "$1/posts/${blog_post_title}" ]; then
        helper_prompt_overwrite "post"
    fi
    ${EDITOR} "$1/posts/${blog_post_title}"
}

# Build blog
build() {
    helper_directory_exists "$1"

    # Clean build directory
    if [ -d "$1/build/" ]; then
        rm -rf "$1/build/"
    fi
    mkdir "$1/build/"
    mkdir "$1/build/posts/"
    mkdir "$1/build/pages/"
    mkdir "$1/build/static/"

    # Copy static files
    cp -r "$1/static/" "$1/build/"

    # Get blog info
    # shellcheck disable=SC1090
    . "$1/variables"

    # Setup navbar
    # shellcheck disable=SC2154
    navdata="<nav id='pages'><ul><li><a href='$var_url/index.html'>Home</a></li>"
    find "$1/pages/" -name "$(printf "*\n")" -name '*.md' > tmp
    while IFS= read -r page
    do
        helper_build_setfileinfovars "$1" "$page" "pages"
        navdata="$navdata<li><a href='$var_url/pages/${docnoext}.html'>$docnoext</a></li>"
    done < tmp
    rm tmp
    navdata="$navdata</ul></nav><div id='content'>"

    # Create pages
    find "$1/pages/" -name "$(printf "*\n")" -name '*.md' > tmp
    while IFS= read -r page
    do
        helper_build_setfileinfovars "$1" "$page" "pages"

        export var_page="$doctitle"

        helper_build_initpage "$1" "" "$dochtmlfilename"
        # shellcheck disable=SC2154
        helper_build_endpage "$1" "$navdata$beforedochtml$(< "$page" "$var_mdproc")$afterdochtml" "$dochtmlfilename"
    done < tmp
    rm tmp

    export var_page="Home"
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

        postmarkdown=$(< "$post" "$var_mdproc")

        export var_page="$doctitle"
        helper_build_initpage "$1" "$navdata" "$dochtmlfilename"
        helper_build_endpage "$1" "$beforedochtml$postmarkdown$afterdochtml" "$dochtmlfilename"

        # Shorten long posts in the preview
        if [ "$(echo "$postmarkdown" | wc -w)" -gt 50 ]; then
            # http://stackoverflow.com/a/15612523
            entrypreview=$(echo "$postmarkdown" | awk -v n=50 'n==c{exit}n-c>=NF{print;c+=NF;next}{for(i=1;i<=n-c;i++)printf "%s ",$i;print x;exit}' | sed -e 's/[[:space:]|,|.|?|!|-]]*$//')"..."
        else
            entrypreview=$postmarkdown
        fi

        # Add preview to page
        { echo "$beforedochtmlwithlink";
          echo "$entrypreview";
          echo "$afterdochtml"; } >> "$1/build/index$page.html"
    done < tmp
    rm tmp

    # Finish last page
    helper_build_endpage "$1" "$(helper_build_generateprevnext "$page")" "$1/build/index$page.html"
}

# $1 = blog directory
# $2 = nav html
# $3 = pagename
helper_build_initpage() {
    { envsubst < "$1/templates/header.html"; echo "$2"; } >> "$3"
}

# $1 = blog directory
# $2 = extra html (for example pagination or blog article)
# $3 = pagename
helper_build_endpage() {
  { echo "$2";
    echo "</div>";
    envsubst < "$1/templates/footer.html"; } >> "$3"
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
        extrahtml="$extrahtml<a class='prev' href='$var_url/index$previouspage.html'>&laquo;</a>"
        page=$(($1 + 1))
    else
        extrahtml="$extrahtml<a class='prev'></a>"
        page="1"
    fi
    extrahtml="$extrahtml<span class='cur'>$page</span>"
    if [ ! -z "$2" ]; then
        pagesfound=$((pagesfound + 1))
        extrahtml="$extrahtml<a class='next' href='$var_url/index$page.html'>&raquo;</a>"
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
        doctitle=${docnoext}
    elif [ "$3" = "posts" ]; then
        docdate=$(echo "$docbasename" | awk -F '-' '{ printf "%s-%s-%s %s", $1, $2, $3, $4 }')
        doctitle=${docbasename#*-*-*-*-}
        doctitle=${doctitle%.md}
        beforedochtml="<h1 class='title'>$doctitle</h1><br><small class='postdate'>$docdate</small><article id='content' class='post'>"
        beforedochtmlwithlink="<h1 class='title'><a href='$var_url/$3/${docnoext}.html'>$doctitle</a></h1><br><small class='postdate'>$docdate</small><article class='post'>"
        afterdochtml="</article>"
    else
        echo "Software error"
        exit 5
    fi
}

# $1 = directory to check for
helper_directory_exists() {
    if [ ! -d "$1" ]; then
        echo "$1 does not exist. Try mkblog.sh init $1."
        exit 3
    fi
}

helper_remind_usage() {
    usage
    exit 2
}

# $1 = name of the instruction
# $2 = description of instruction
helper_print_instruction() {
    printf "    mkblog.sh %s directory\n        %s in directory.\n" "$1" "$2"
}

# $1 = what kind of thing
helper_prompt_overwrite() {
    printf "This %s already exists. Overwrite? (y/N)\n" "$1"
    read -r yn
    case ${yn} in
        [Yy]* ) ;;
        * ) printf "No confirmation, quitting.\n"; exit;;
    esac
}

# $1 = desired directory loc
helper_check_and_make_dir() {
    if [ ! -d "$1" ]; then
        mkdir "$1"
    fi
}

# $1 = desired variable as a string
# $2 = desired location
# use of eval is safe - only done on constructed strings which aren't
# user-defined
helper_export_into() {
    eval printf 'export\ var_%s=\"%s\"\\n' "$1" \"\$"$1"\" >> "$2"
}

# $1 = prompt message
# $2 = target variable
helper_read_into() {
    printf '%s: ' "$1"
    read -r "$2"
}

# $1 = prompt message
# $2 = target variable
# $3 = destination
helper_read_and_export() {
    helper_read_into "$1" "$2"
    helper_export_into "$2" "$3"
}

# The actual 'main function'
# Check input
if [ $# -lt 1 ]; then
    helper_remind_usage
fi

# Parse command
if [ "$1" = "init" ]; then
    if [ $# -ne 2 ]; then
        helper_remind_usage
    fi

    init "$2"
    exit 0
elif [ "$1" = "new" ]; then
    if [ "$#" -ne 3 ]; then
        helper_remind_usage
    elif [ "$2" = "page" ]; then
        new_page "$3"
        exit 0
    elif [ "$2" = "post" ]; then
        new_post "$3"
        exit 0
    else
        helper_remind_usage
    fi
elif [ "$1" = "build" ]; then
    if [ $# -ne 2 ]; then
        helper_remind_usage
    fi

    build "$2"
    exit 0
else
    helper_remind_usage
fi

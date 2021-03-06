# mkblog.sh

mkblog.sh is a simple blogging system, written in sh. It allows you to write
blog posts in Markdown and compile them into a nice HTML site with a single
command.

## Usage

First, create a skeleton for your new blog using `mkblog.sh init <directory>`.
This will start a setup wizard to allow you to configure your blog. To change
an answer given to the wizard, just change the relevant export in the variables
subdirectory. You can also add custom variables to use in your template.

To add content to your blog, use `mkblog.sh new`. This requires two arguments:
first, what type of content you want (currently one of `page` for an ordinary
page and `post` for a blog post) and the directory where the blog currently
lives. This will prompt you for a title for the page or post you want to add. If
a page or post by the title you give exists already, you will have the option to
overwrite it. The new post or page will be opened in your editor, which is
determined as follows:

* If you have the `VISUAL` environment variable set, the script will use
  whatever it refers to as your editor.
* If you don't have `VISUAL` set, but have `EDITOR` set instead, the script will
  use that.
* Otherwise, the script will use `vi`.

If you want to add page source files manually, add Markdown files to the `pages`
subdirectory. The title of the resulting page will be the same as the file,
minus the extension. If you want to add blog post source files manually, add
Markdown files to the `posts` subdirectory; make sure you follow the
`yyyy-mm-dd-time-title.md` naming convention. For example:
`2016-02-04-17:00-Hello, world!.md`. It is fine to leave out the time, as long
as the amount of dashes match up. Feel free to name your file
`2016-02-04--Untimed article.md` if you do not want to add a time.

Then, run `mkblog.sh build <directory>` to build your blog. The HTML will be
placed in a subdirectory named `build` in the directory you are building.

To edit what your blog looks like, just edit `templates/header.html` and
`templates/footer.html` according to your wishes. However, try to not remove
the skip div element, as it aids accessibility.

## Example directory structure

If you are doing everything right, your blog directory should look like this.

    .
    ├── pages
    │   ├── About.md
    │   └── Contact.md
    ├── posts
    │   ├── 2016-02-06-17:00-Hello again.md
    │   └── 2016-02-04--Hello, world!.md
    ├── templates
    │   ├── footer.html
    │   └── header.html
    └── variables

## Dependencies

Aside from standard tooling, mkblog.sh has two dependencies:

* `envsubst`, which is part of GNU Gettext.
* A Markdown parser that parses standard input and sends the HTML to standard
  output.

By default, mkblog.sh assumes that the parser program is named "markdown". You
can change this by editing the `var_mdproc` variable in the `variables` file. We
recommend `discount` as a parser program (which conveniently does the right
thing by default).

## Known limitations

Blog titles and blog subtitles cannot contain double quotes anywhere - this will
cause unpredictable results if you try.

## License

mkblog.sh is licensed under the GNU AGPLv3+. Its output is not copyrighted.

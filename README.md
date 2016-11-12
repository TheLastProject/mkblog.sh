# mkblog.sh

mkblog.sh is a simple blogging system, written in sh. It allows you to write
blog posts in Markdown and compile them into a nice HTML site with a single
command.

## Usage

First, create a skeleton for your new blog using `mkblog.sh init <directory>`.
This will start a setup wizard to allow you to configure your blog. To change
an answer given to the wizard, just change the relevant file in the variables
subdirectory.

Add Markdown files in the subdirectory pages to create additional pages, or in
posts to create blog posts. For the posts, make sure you follow the
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
        ├── blog_title
        ├── blog_url
        ├── blog_subtitle
        └── blog_mdproc

## Dependencies

Aside from standard tooling, mkblog.sh requires a markdown parser that parses
standard input and sends the HTML to standard output. By default, this is named
"markdown", but you can change this by editing the `blog_mdproc` file. We
recommend `discount` (which conveniently does the right thing by default).

## License

mkblog.sh is licensed under the GNU AGPLv3+, with the exception of the files
generated by the init command, which are licensed under CC0.

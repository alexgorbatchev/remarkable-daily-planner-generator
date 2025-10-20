- Compile a file once: `typst compile file.typ | tail -n 20`
- Compile a file on every change: `typst watch file.typ`
- Set up a project from a template: `typst init @preview/<TEMPLATE>`
- use `mdls -name kMDItemNumberOfPages day.pdf` to see number of pages
- Global variables should be SHOUT_CASE

use context7 to get the docs

we are building a daily planner that will be rendered as a PDF using typst.

components that we build will be used to generate multiple pages of the PDF
and so they need to be parameterized to allow for this.

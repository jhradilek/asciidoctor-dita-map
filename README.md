# dita-map

**dita-map** is a command line utility that converts a single AsciiDoc file to a DITA map. It recognizes the [document title](https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/#section-level-syntax) as the map title and uses the [include directives](https://docs.asciidoctor.org/asciidoc/latest/directives/include/) and their respective [leveloffset](https://docs.asciidoctor.org/asciidoc/latest/directives/include-with-leveloffset/#manipulate-heading-levels-with-leveloffset) values to compose the tree of `<mapref>` and `<topicref>` elements.

## Installation

Install the `asciidoctor-dita-map` Ruby gem:

```console
gem install asciidoctor-dita-map
```

## Usage

To convert a single AsciiDoc file to a DITA map, supply it as an argument to the `dita-map` command:

```console
$ dita-map your_file.adoc
```

By default, `dita-map` creates a new file, `your_file.ditamap`, in the same directory as the source file. You can supply multiple files at the same time or use wildcards:

```console
$ dita-map *.adoc
```

When you do not supply any file names or specify `-` as the first argument, `dita-map` reads from standard input and prints the result to standard output. For example:

```console
$ echo 'include::task.adoc[leveloffset=+1]' | dita-map
<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE map PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd">
<map>
  <topicref href="task.dita" navtitle="A topic title" type="task" />
</map>
```

### Specifying the output file name

To change the output file name or location, use the `-o` or `--out-file` command-line option:

```console
$ dita-map input_file.adoc -o output_file.ditamap
```

To print the result to standard output, use `-` as the output file name. For example:

```console
$ dita-map input_file.adoc -o -
<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE map PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd">
<map>
  <title>A map title</title>
  <mapref href="another_map.ditamap" format="ditamap" type="map" />
  <topicref href="concept.dita" navtitle="A concept title" type="concept">
    <topicref href="task.dita" navtitle="A task title" type="task" />
  </topicref>
</map>
```

## Recognized content types

To correctly recognize when to use the `<topicref>` and `<mapref>` elements and what values to assign to their `type` attributes, `dita-map` recognizes the following `:_mod-docs-content-type:` attribute definition values in included AsciiDoc files:

| AsciiDoc attribute | Output element | Output type value |
| --- | --- | --- |
| `ASSEMBLY` | `<topicref>` | `concept` |
| `CONCEPT` | `<topicref>` | `concept` |
| `PROCEDURE` | `<topicref>` | `task` |
| `REFERENCE` | `<topicref>` | `reference` |
| `MAP` | `<mapref>` | `map` |

For example, to ensure an included AsciiDoc file is recognized as a DITA map, add the following line at the top of the file:

```asciidoc
:_mod-docs-content-type: MAP
```

## Copyright

Copyright © 2026 Jaromir Hradilek

This program is free software, released under the terms of the MIT license. It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

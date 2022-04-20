# CALS Table Viewer for Visual Studio Code #

The CALS Table Viewer renders CALS tables found in an XML file opened in VS Code. 
The viewer also highlights differences in the tables identified by DeltaXML's DeltaV2 Markup.

![Screenshot](resources/images/viewer-main.png)


## Features
- Visually verify the validity of CALS tables
- See differences in CALS table content
- Infer differences in CALS table structure
- Understand the effect of different DeltaXML copmparison settings
- A VS Code message displays any CALS table processing errors

## Getting Started
1. Launch VS Code and install the `CALS Table Viewer` extension
2. In VS Code, open an XML file containing CALS tables
3. From the Command Palette (**⇧⌘P**), invoke `CALS viewer: Open`
	- A **CALS Table Viewer** Pane is shown alongside the current view
	- CALS tables found in the file are rendered with basic styling
4. Open further XML files to append to the current view
	- Each file view in the pane is identified by a header with the filename

## More Details

- Initially renders the content of the current editor 
- Updates the view from file contents when the `CALS viewer: Open` command is invoked again
- The 'CALS View' is reset by closing it and then invoking the `CALS viewer: Open` command again

---

## Project Goals

This project started as a DeltaXML 'free-sprint' project. There are two main goals for this project:

1. Provide a developer tool to help with analysing results from CALS table processing
2. Demonstrate how XSLT 3.0 and Saxon JS can be used to enhance data visualisation inside Visual Studio Code.

---
## Development Setup

*Note: Install **NodeJS** if it's not already installed*

### 1. VS Code Extension Setup

- Open in VS Code 1.47+
- `npm install`
- `npm run watch` or `npm run compile`
- `F5` to start debugging

### 2. Editing/Compiling XSLT in VS Code

This project uses XSLT and the SaxonJS XSLT processor to convert CALS tables to HTML that is shown in a VS Code **WebView**.
SaxonJS uses a compiled form of XSLT. To generate this from the `style-tables.xsl` source:

1. From the Command Palette, invoke **Run Task**
2. Select `Compile style-tables.xsl` from the task list

### 3. Technical Detail

**Coding and Security**

- This extension uses the VS Code [WebView API](https://code.visualstudio.com/api/extension-guides/webview) to render the CALS tables.
- An HTML content security policy is used to ensure scripts can only access file system resources that are explicitly listed. 

**WebView Messages**

The WebView and Visual Studio Code environment communicate in both directions via JSON messages. For example:

- A message is sent to the WebView when the active editor changes
- A message is sent from the WebView when an XSLT processing error is enountered

---
## Who do I talk to? ###

* phil.fearon@deltaxml.com